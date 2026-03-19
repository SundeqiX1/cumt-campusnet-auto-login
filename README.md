# 中国矿业大学校园网自动登录脚本

English repository name: `cumt-campusnet-auto-login`

一个面向中国矿业大学校园网认证页面的非官方自动登录脚本项目。  
它的目标很简单：把手动点击登录按钮的过程，整理成一个可复用、可审查、可自行修改的本地脚本。

非官方项目，与中国矿业大学及其信息化建设与管理处不存在隶属、认证或背书关系。

## 这个项目是做什么的

这个仓库只做一件事：

- 使用合法授权的校园网账号，向学校当前可见的认证门户发起正常登录请求

它不做这些事：

- 不绕过认证
- 不破解密码
- 不共享账号
- 不代替学校官方认证系统
- 不包含任何真实凭据

## 项目特点

- 面向中国矿业大学校园网门户整理
- 支持通过门户跳转 URL 自动提取关键参数
- 支持根据运营商自动映射登录后缀
- 优先尝试 GET 登录，失败后自动回退 POST 登录
- 配置文件与脚本正文分离，便于开源与自用
- 默认不包含任何真实账号、密码、Cookie、日志

## 适用前提

使用本项目之前，建议先确认下面几个前提：

- 使用者是中国矿业大学校园网合法用户
- 使用的是已授权账号
- 愿意自行维护本地 `.env` 配置
- 理解学校后续若修改认证页面，脚本可能需要重新适配

## 当前适配的门户特征

本项目是基于当前观察到的一类 Dr.COM / ePortal 风格认证页面整理出来的，典型特征包括：

- 门户主机：`10.2.5.251`
- 登录路径：`/eportal/?c=ACSetting&a=Login`
- 用户字段：`DDDDD`
- 密码字段：`upass`

脚本会自动尝试：

1. 先触发门户跳转
2. 解析 URL 中的 `wlanuserip`、`wlanacname`、`nasip`、`mac` 等参数
3. 根据配置中的运营商中文名称，映射后缀候选
4. 依次执行登录尝试

## 支持的运营商填写方式

在配置文件里，只需要填写官方中文名称：

- `中国电信`
- `中国移动`
- `中国联通`

脚本会自动把它们映射成对应的后缀候选。

当前默认映射规则如下：

- `中国电信` -> `@telecom,@dx`
- `中国移动` -> `@cmcc,@yd,@mobile`
- `中国联通` -> `@unicom,@lt`

如果学校将来修改了后缀规则，仍然可以用高级配置项 `CUMT_PROVIDER_SUFFIX_CANDIDATES` 手动覆盖。

## 目录结构

```text
cumt-campusnet-auto-login/
  .env.example
  .gitignore
  LICENSE
  README.md
  scripts/
    cumt-campus-login.sh
    install_shortcut.sh
    run_login.sh
    uninstall_shortcut.sh
```

## 快速开始

### 1. 克隆仓库

```bash
git clone <your-repo-url>
cd cumt-campusnet-auto-login
```

### 2. 准备配置文件

```bash
cp .env.example .env
```

### 3. 填写本地配置

编辑 `.env`，至少填写这三项：

```env
CUMT_ACCOUNT=
CUMT_PASSWORD=
CUMT_PROVIDER_NAME=
```

例如：

```env
CUMT_ACCOUNT=2024XXXXXX
CUMT_PASSWORD=your_password_here
CUMT_PROVIDER_NAME=中国电信
```

注意：

- `CUMT_PROVIDER_NAME` 只能填写 `中国电信`、`中国移动`、`中国联通`
- 不要把 `.env` 提交到 GitHub

### 4. 赋予执行权限

```bash
chmod +x scripts/cumt-campus-login.sh scripts/run_login.sh
```

### 5. 运行

```bash
bash scripts/run_login.sh
```

## 安装快捷指令

如果希望把这个项目安装成终端命令，可以执行：

```bash
bash scripts/install_shortcut.sh
```

默认会安装一个名为 `cumt-login` 的命令，指向项目里的 `scripts/run_login.sh`。

安装后可直接运行：

```bash
cumt-login
```

如果想自定义命令名，例如 `cumt-net`：

```bash
bash scripts/install_shortcut.sh cumt-net
```

卸载默认命令：

```bash
bash scripts/uninstall_shortcut.sh
```

卸载自定义命令：

```bash
bash scripts/uninstall_shortcut.sh cumt-net
```

## 干跑模式

如果想先确认脚本拼出来的登录 URL，而不真正发起登录，可执行：

```bash
bash scripts/cumt-campus-login.sh --dry-run
```

这适合在调试门户参数时使用。

## 配置说明

### 必填项

- `CUMT_ACCOUNT`
  - 校园网账号或学号

- `CUMT_PASSWORD`
  - 校园网密码

- `CUMT_PROVIDER_NAME`
  - 运营商中文名称
  - 仅支持：
    - `中国电信`
    - `中国移动`
    - `中国联通`

### 选填高级项

- `CUMT_PROVIDER_SUFFIX_CANDIDATES`
  - 手动覆盖运营商后缀映射
  - 例如：
    - `@telecom,@dx`
    - `@cmcc,@yd,@mobile`
    - `@unicom,@lt`

- `CUMT_PORTAL_HOST`
  - 门户主机

- `CUMT_PORTAL_ENTRY_URL`
  - 门户入口地址

- `CUMT_TRIGGER_URL`
  - 用于触发认证跳转的地址

- `CUMT_WLANACNAME`
  - 默认 AC 名称

- `CUMT_WLANACIP`
  - 默认 AC IP

- `CUMT_MAC`
  - 手动指定 MAC
  - 正常情况下可留空

### 为什么默认保留这些门户参数

因为这个项目就是针对当前中国矿业大学校园网认证场景整理的。  
公开仓库里保留默认门户参数，可以让后来使用的人少走很多弯路；真正敏感的内容只有账号密码，所以它们必须留空。

## 运行日志

通过 `scripts/run_login.sh` 运行时，日志会追加写入：

```text
logs/login.log
```

## 故障排查

### 1. 提示没有填写配置

检查 `.env` 是否存在，以及下面三项是否都已填写：

- `CUMT_ACCOUNT`
- `CUMT_PASSWORD`
- `CUMT_PROVIDER_NAME`

### 2. 提示运营商不支持

确认 `CUMT_PROVIDER_NAME` 是否填写为以下三者之一：

- `中国电信`
- `中国移动`
- `中国联通`

### 3. 脚本运行但仍然登录失败

可能原因包括：

- 学校门户参数已经更新
- 运营商后缀规则发生变化
- 当前网络没有正确跳到认证页
- 本地 IP / AC 参数与门户返回不一致

建议排查顺序：

1. 先执行 `--dry-run`
2. 再用浏览器手动登录一次
3. 打开开发者工具重新抓登录请求
4. 对照脚本里的参数重新适配

### 4. 学校改了后缀规则怎么办

先不要改脚本正文，可以优先在 `.env` 里直接覆盖：

```env
CUMT_PROVIDER_SUFFIX_CANDIDATES=@your_new_suffix
```

## 安全与凭据管理

本仓库的设计原则是“代码可公开，配置仅本地保存”。

建议遵守以下做法：

- 不要将 `.env` 上传到 GitHub 或其他公开平台
- 不要在 issue、discussion、commit message 或截图中暴露真实账号密码
- 不要公开抓包原文中的 Cookie、token、学号、密码、MAC 地址等敏感字段
- fork 或二次发布前，先确认仓库中未包含本地配置、日志和调试产物

## 合规与风险边界

以下内容基于公开资料整理，仅作为项目级风险提示，不构成法律意见或校方授权说明。

从功能边界看，本项目属于“对现有认证入口的常规登录动作进行本地自动化”：

- 调用的是学校现有认证入口
- 不提供绕过认证、破解口令、爆破、扫描或批量代登能力
- 依赖账号持有人自行提供本地配置，不内置任何真实凭据

这类脚本通常不等同于“破解系统”，但并不意味着没有风险。实际风险主要集中在以下几类：

1. 学校网络使用规则或服务条款发生变化
2. 账号、密码、Cookie 或日志泄露
3. 脚本被改造成批量代登、爆破或其他未授权用途
4. 在未经授权的情况下处理他人账号信息

在本仓库整理阶段，未在公开可检索的中国矿业大学信息化页面中检索到“明确禁止脚本化调用校园网登录页”的公开条款；但这不应被理解为校方对该行为的正式许可。学校后续公告、网络管理要求或服务条款如有更新，应以最新官方规则为准。

更稳妥的使用边界包括：

- 仅用于已授权账号的本地登录自动化
- 仅在对应设备和合法网络场景下使用
- 保持低频、克制、可审计的调用方式
- 不将脚本用于共享账号、代他人登录或批量操作
- 对外发布时明确标注“非官方项目”

## 公开发布说明

在不包含真实账号密码、Cookie、私有日志和个人配置的前提下，公开脚本代码通常是可控的；但以下内容不适合公开发布：

- `.env` 及其衍生配置文件
- 含真实凭据的抓包记录或调试输出
- 带有个人账号信息的日志、截图和终端历史
- 任何可直接复用到真实账户的私有参数

因此，适合公开的是脚本与说明文档本身，不适合公开的是本地配置与个人数据。

## 公开资料参考

- 中国矿业大学信息化建设与管理处关于新版 VPN 服务的通知：
  - [关于启用新版VPN服务的通知](https://nic.cumt.edu.cn/info/1004/1081.htm)
- 中国矿业大学信息化建设与管理处公开强调网络安全建设：
  - [我校承办2024年江苏省教育系统第五期网络安全技能培训](https://nic.cumt.edu.cn/info/1005/2341.htm)
- 国家层面的个人信息保护与数据安全背景：
  - [个人信息保护法背景解读（中国人大网）](https://www.npc.gov.cn/npc/c2/c30834/202108/t20210824_313166.html)
  - [国家互联网信息办公室公布《个人信息保护合规审计管理办法》](https://www.cac.gov.cn/2025-02/14/c_1741232791991016.htm)

## 已知限制

- 当前实现针对的是当前观察到的一类中国矿业大学认证页面
- 如果学校改版，脚本可能需要重新适配
- 这个仓库目前主要在 macOS 环境中整理和验证
- Linux 也尽量兼容，但未像 macOS 一样完整验证

## License

MIT
