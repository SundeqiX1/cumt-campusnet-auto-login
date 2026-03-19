#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"
DRY_RUN=0

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

: "${CUMT_ACCOUNT:=}"
: "${CUMT_PASSWORD:=}"
: "${CUMT_PROVIDER_NAME:=}"
: "${CUMT_PROVIDER_SUFFIX_CANDIDATES:=}"
: "${CUMT_PORTAL_HOST:=10.2.5.251}"
: "${CUMT_PORTAL_ENTRY_URL:=http://$CUMT_PORTAL_HOST}"
: "${CUMT_TRIGGER_URL:=http://1.1.1.1/}"
: "${CUMT_LOGIN_SCHEME:=http}"
: "${CUMT_LOGIN_PORT:=801}"
: "${CUMT_LOGIN_PATH:=/eportal/}"
: "${CUMT_WLANACNAME:=NAS}"
: "${CUMT_WLANACIP:=10.2.4.1}"
: "${CUMT_FALLBACK_REDIRECT_URL:=http://1.1.1.1/}"
: "${CUMT_MAC:=}"
: "${CUMT_TIMEOUT_SECONDS:=15}"
: "${CUMT_USER_AGENT:=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36}"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

provider_suffix_candidates() {
  case "${CUMT_PROVIDER_NAME}" in
    中国电信)
      printf '%s\n' '@telecom,@dx'
      ;;
    中国移动)
      printf '%s\n' '@cmcc,@yd,@mobile'
      ;;
    中国联通)
      printf '%s\n' '@unicom,@lt'
      ;;
    *)
      return 1
      ;;
  esac
}

first_non_empty() {
  local value
  for value in "$@"; do
    if [[ -n "$value" ]]; then
      printf '%s\n' "$value"
      return 0
    fi
  done
  return 1
}

query_param() {
  /usr/bin/python3 - "$1" "$2" <<'PY'
import sys
from urllib.parse import parse_qs, urlsplit

url = sys.argv[1]
key = sys.argv[2]
values = parse_qs(urlsplit(url).query).get(key, [""])
print(values[0])
PY
}

build_url() {
  /usr/bin/python3 - "$@" <<'PY'
import sys
from urllib.parse import urlencode

base = sys.argv[1]
pairs = []
for raw in sys.argv[2:]:
    key, value = raw.split("=", 1)
    pairs.append((key, value))

sep = "&" if "?" in base else "?"
print(base + sep + urlencode(pairs))
PY
}

detect_local_ip() {
  local interface_name ip_value

  if command -v ipconfig >/dev/null 2>&1; then
    for interface_name in en0 en1 bridge0; do
      ip_value="$(ipconfig getifaddr "$interface_name" 2>/dev/null || true)"
      if [[ -n "$ip_value" ]]; then
        printf '%s\n' "$ip_value"
        return 0
      fi
    done
  fi

  if command -v ip >/dev/null 2>&1; then
    ip_value="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '/src/ {for (i=1; i<=NF; i++) if ($i=="src") {print $(i+1); exit}}')"
    if [[ -n "$ip_value" ]]; then
      printf '%s\n' "$ip_value"
      return 0
    fi
  fi

  return 1
}

discover_portal_url() {
  local candidate effective_url
  for candidate in "$CUMT_PORTAL_ENTRY_URL" "$CUMT_TRIGGER_URL"; do
    effective_url="$(
      /usr/bin/curl -sS -L \
        --max-time "$CUMT_TIMEOUT_SECONDS" \
        -A "$CUMT_USER_AGENT" \
        -o /dev/null \
        -w '%{url_effective}' \
        "$candidate" 2>/dev/null || true
    )"
    if [[ -n "$effective_url" ]]; then
      printf '%s\n' "$effective_url"
      return 0
    fi
  done

  printf '%s\n' "$CUMT_PORTAL_ENTRY_URL"
}

response_looks_good() {
  local response="$1"
  [[ "$response" == *"Dr.COMWebLoginID_3.htm"* ]] && return 0
  [[ "$response" == *"uid='"* ]] && return 0
  [[ "$response" == *"logout"* ]] && return 0
  [[ "$response" == *"success"* && "$response" != *"fail"* ]] && return 0
  return 1
}

try_get_login() {
  local portal_url="$1"
  local user_ip="$2"
  local wlanacip="$3"
  local wlanacname="$4"
  local mac_value="$5"
  local redirect_value="$6"
  local suffix_value="$7"
  local full_account="${CUMT_ACCOUNT}${suffix_value}"
  local ddddd_value=",0,${full_account}"
  local login_base="${CUMT_LOGIN_SCHEME}://${CUMT_PORTAL_HOST}:${CUMT_LOGIN_PORT}${CUMT_LOGIN_PATH}"
  local login_url response

  login_url="$(
    build_url "$login_base" \
      "c=ACSetting" \
      "a=Login" \
      "loginMethod=1" \
      "protocol=${CUMT_LOGIN_SCHEME}:" \
      "hostname=${CUMT_PORTAL_HOST}" \
      "port=" \
      "iTermType=1" \
      "wlanuserip=${user_ip}" \
      "wlanacip=${wlanacip}" \
      "wlanacname=${wlanacname}" \
      "redirect=${redirect_value}" \
      "session=" \
      "vlanid=0" \
      "mac=${mac_value}" \
      "ip=${user_ip}" \
      "enAdvert=0" \
      "queryACIP=0" \
      "jsVersion=3.3.3" \
      "DDDDD=${ddddd_value}" \
      "upass=${CUMT_PASSWORD}" \
      "R1=0" \
      "R2=0" \
      "R3=0" \
      "R6=0" \
      "para=00" \
      "0MKKey=123456" \
      "buttonClicked=" \
      "redirect_url=" \
      "err_flag=" \
      "username=" \
      "password=" \
      "user=" \
      "cmd=" \
      "Login=" \
      "v6ip="
  )"

  if [[ "$DRY_RUN" == "1" ]]; then
    log "Dry run GET URL: $login_url"
    return 0
  fi

  response="$(
    /usr/bin/curl -sS -L \
      --max-time "$CUMT_TIMEOUT_SECONDS" \
      -A "$CUMT_USER_AGENT" \
      -e "$portal_url" \
      "$login_url" 2>&1 || true
  )"

  response_looks_good "$response"
}

try_post_login() {
  local portal_url="$1"
  local user_ip="$2"
  local wlanacip="$3"
  local wlanacname="$4"
  local mac_value="$5"
  local redirect_value="$6"
  local suffix_value="$7"
  local full_account="${CUMT_ACCOUNT}${suffix_value}"
  local ddddd_value=",0,${full_account}"
  local login_url response

  login_url="$(
    build_url "${CUMT_LOGIN_SCHEME}://${CUMT_PORTAL_HOST}:${CUMT_LOGIN_PORT}${CUMT_LOGIN_PATH}" \
      "c=ACSetting" \
      "a=Login" \
      "loginMethod=1" \
      "protocol=${CUMT_LOGIN_SCHEME}:" \
      "hostname=${CUMT_PORTAL_HOST}" \
      "port=" \
      "iTermType=1" \
      "wlanuserip=${user_ip}" \
      "wlanacip=${wlanacip}" \
      "wlanacname=${wlanacname}" \
      "redirect=${redirect_value}" \
      "session=" \
      "vlanid=0" \
      "mac=${mac_value}" \
      "ip=${user_ip}" \
      "enAdvert=0" \
      "queryACIP=0" \
      "jsVersion=3.3.3"
  )"

  if [[ "$DRY_RUN" == "1" ]]; then
    log "Dry run POST URL: $login_url"
    return 0
  fi

  response="$(
    /usr/bin/curl -sS -L \
      --max-time "$CUMT_TIMEOUT_SECONDS" \
      -A "$CUMT_USER_AGENT" \
      -e "$portal_url" \
      -H "Origin: ${CUMT_LOGIN_SCHEME}://${CUMT_PORTAL_HOST}" \
      -H 'Content-Type: application/x-www-form-urlencoded' \
      -X POST \
      "$login_url" \
      --data-urlencode "DDDDD=${ddddd_value}" \
      --data-urlencode "upass=${CUMT_PASSWORD}" \
      --data-urlencode 'R1=0' \
      --data-urlencode 'R2=0' \
      --data-urlencode 'R3=0' \
      --data-urlencode 'R6=0' \
      --data-urlencode 'para=00' \
      --data-urlencode '0MKKey=123456' \
      --data-urlencode 'buttonClicked=' \
      --data-urlencode 'redirect_url=' \
      --data-urlencode 'err_flag=' \
      --data-urlencode 'username=' \
      --data-urlencode 'password=' \
      --data-urlencode 'user=' \
      --data-urlencode 'cmd=' \
      --data-urlencode 'Login=' \
      --data-urlencode 'v6ip=' 2>&1 || true
  )"

  response_looks_good "$response"
}

if [[ -z "$CUMT_ACCOUNT" || -z "$CUMT_PASSWORD" || -z "$CUMT_PROVIDER_NAME" ]]; then
  log "Copy .env.example to .env and set CUMT_ACCOUNT / CUMT_PASSWORD / CUMT_PROVIDER_NAME first."
  exit 1
fi

suffix_candidates="$CUMT_PROVIDER_SUFFIX_CANDIDATES"
if [[ -z "$suffix_candidates" ]]; then
  if ! suffix_candidates="$(provider_suffix_candidates)"; then
    log "Unsupported CUMT_PROVIDER_NAME: $CUMT_PROVIDER_NAME"
    log "Supported values: 中国电信 / 中国移动 / 中国联通"
    exit 1
  fi
fi

portal_url="$(discover_portal_url)"
user_ip="$(
  first_non_empty \
    "$(query_param "$portal_url" "wlanuserip")" \
    "$(query_param "$portal_url" "ip")" \
    "$(detect_local_ip || true)" \
    "" || true
)"
wlanacip="$(
  first_non_empty \
    "$(query_param "$portal_url" "nasip")" \
    "$(query_param "$portal_url" "wlanacip")" \
    "$CUMT_WLANACIP" || true
)"
wlanacname="$(
  first_non_empty \
    "$(query_param "$portal_url" "wlanacname")" \
    "$CUMT_WLANACNAME" || true
)"
redirect_value="$(
  first_non_empty \
    "$(query_param "$portal_url" "url")" \
    "$CUMT_FALLBACK_REDIRECT_URL" || true
)"
mac_value="$(
  first_non_empty \
    "$(query_param "$portal_url" "mac")" \
    "$CUMT_MAC" || true
)"

if [[ -z "$user_ip" ]]; then
  log "Could not determine local campus IP."
  exit 1
fi

log "Portal URL: $portal_url"
log "Using campus IP: $user_ip"
log "Using AC name: $wlanacname"
log "Using provider: $CUMT_PROVIDER_NAME"

IFS=',' read -r -a suffixes <<< "$suffix_candidates"
if [[ "${#suffixes[@]}" -eq 0 ]]; then
  suffixes=("")
fi

for suffix_value in "${suffixes[@]}"; do
  log "Trying carrier suffix: ${suffix_value:-<none>}"
  if try_get_login "$portal_url" "$user_ip" "$wlanacip" "$wlanacname" "$mac_value" "$redirect_value" "$suffix_value"; then
    log "Campus login request accepted via GET flow."
    exit 0
  fi

  if try_post_login "$portal_url" "$user_ip" "$wlanacip" "$wlanacname" "$mac_value" "$redirect_value" "$suffix_value"; then
    log "Campus login request accepted via POST flow."
    exit 0
  fi
done

log "Campus login request did not return a clear success marker."
exit 1
