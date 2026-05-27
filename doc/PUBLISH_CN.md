# 发布到 pub.dev（网络受限环境）

## 本机 `dart pub login` 失败时

若出现：

- 浏览器 `Pub Authorized Successfully`，但 `localhost` **连接被拒绝**
- 终端 `accounts.google.com` **信号灯超时**

说明本机 CLI 无法完成 OAuth，**不要反复重试**同一流程。

## 方案 A：GitHub Actions（推荐，无需本机 `flutter pub login`）

Cloud Shell / 本机的 `localhost` OAuth 容易失败（`did not contain required parameter "code"`），请用 **打 tag 触发发布**：

1. 浏览器登录 https://pub.dev（Google 账号：`xiaodong986@gmail.com`）。
2. 在本机执行：

```bash
cd C:\Users\Administrator\IdeaProjects\sw\tools\skywalking_flutter_otlp
git pull
git tag v0.1.0
git push origin v0.1.0
```

3. 打开 https://github.com/songzhendong/skywalking-flutter/actions 查看 **Publish to pub.dev** 是否成功。
4. 首发成功后，在 https://pub.dev/packages/skywalking_flutter/admin 开启 **Publish from GitHub Actions**（仓库 `songzhendong/skywalking-flutter`，标签 `v{{version}}`）。

首发成功后，在 https://pub.dev/packages/skywalking_flutter/admin 开启 **Publish from GitHub Actions**，标签模式 `v{{version}}`。

## 方案 B：Google Cloud Shell（浏览器 + CLI 同在 Google 网络）

1. 打开 https://shell.cloud.google.com
2. 执行：

```bash
git clone https://github.com/songzhendong/skywalking-flutter.git
cd skywalking-flutter
dart pub login
dart pub publish --force
```

## 方案 C：本机 TUN 全局代理（不用 HTTP_PROXY）

1. 开 VPN **TUN/系统代理**（不要只设 `HTTP_PROXY`）。
2. **不要**设置 `HTTP_PROXY` / `HTTPS_PROXY`。
3. 新开 PowerShell，仅执行：

```powershell
$env:PUB_HOSTED_URL = "https://pub.dev"
dart pub login
```

授权后尽快在浏览器点允许，避免 CLI 先超时。

## 依赖写法（发布后）

```yaml
dependencies:
  skywalking_flutter: ^0.1.0
```
