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

## 安全建议

- 不要把 `.env` 上传到 GitHub
- 不要在 issue 里贴真实密码
- 不要把抓包原文里的 Cookie、token、学号、密码直接公开
- 如果你 fork 本项目，请先确认自己 fork 的仓库没有包含本地配置文件

## 合规与风险说明

这部分是基于公开资料做的谨慎判断，不构成正式法律意见。

一个更稳妥的公开结论是：

- 自动化对学校官方认证页面的正常登录请求，通常不等于违法破解
- 但它并不是“零风险”，风险主要集中在学校网络使用规则、账号安全和传播方式

更具体地说：

1. 这个脚本调用的是学校现有认证入口，不是绕过认证，也不是攻击或爆破
2. 仅在已授权账号和对应设备上低频使用，风险通常较低
3. 更需要避免的是：
   - 公开真实凭据
   - 帮他人批量代登
   - 改造成爆破、扫描、绕过认证工具
   - 在未授权情况下处理他人账号信息
4. 我暂时没有在公开可检索的中国矿业大学信息化页面里找到“明确禁止脚本化调用校园网登录页”的官方条款
5. 但学校公开资料明确持续强调网络安全、个人信息保护和规范使用，因此更稳妥的公开方式应当是：
   - 只公开代码
   - 不公开真实配置
   - 明确标注非官方项目
   - 明确说明仅限已授权账号使用
   - 提醒用户自行确认学校最新规定

这个判断参考了公开来源：

- 中国矿业大学信息化建设与管理处关于新版 VPN 服务的通知：
  - [关于启用新版VPN服务的通知](https://nic.cumt.edu.cn/info/1004/1081.htm)
- 中国矿业大学信息化建设与管理处公开强调网络安全建设：
  - [我校承办2024年江苏省教育系统第五期网络安全技能培训](https://nic.cumt.edu.cn/info/1005/2341.htm)
- 国家层面的个人信息保护与数据安全背景：
  - [个人信息保护法背景解读（中国人大网）](https://www.npc.gov.cn/npc/c2/c30834/202108/t20210824_313166.html)
  - [国家互联网信息办公室公布《个人信息保护合规审计管理办法》](https://www.cac.gov.cn/2025-02/14/c_1741232791991016.htm)

## 是否适合开源

在不包含任何真实账号密码、Cookie、私有日志和个人配置的前提下，一个更稳妥的公开结论是：

- 开源代码本身通常是可控的
- 公开实际配置并不合适

换句话说：

- 可以开源脚本
- 不要开源 `.env`

## 已知限制

- 当前实现针对的是当前观察到的一类中国矿业大学认证页面
- 如果学校改版，脚本可能需要重新适配
- 这个仓库目前主要在 macOS 环境中整理和验证
- Linux 也尽量兼容，但未像 macOS 一样完整验证

## License

MIT
