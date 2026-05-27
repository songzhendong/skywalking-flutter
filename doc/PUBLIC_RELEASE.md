# 公开仓库与 pub.dev 发布清单

## 1. GitHub 改为 Public

1. 打开 https://github.com/songzhendong/skywalking-flutter/settings  
2. **Danger Zone → Change visibility → Public**

公开后，他人无需 Token 即可：

```yaml
skywalking_flutter:
  git:
    url: https://github.com/songzhendong/skywalking-flutter.git
    ref: main
```

## 2. 发布前检查

- [ ] `README.md` / `doc/USAGE.md` 链接可访问  
- [ ] `flutter test` 通过（Flutter 插件需用 `flutter test`，不要用纯 `dart test`）  
- [ ] `dart pub publish --dry-run` 无 error  
- [ ] `example` 可 `flutter run`  
- [ ] OAP 已启用 `receiver-otel`（`otlp-traces,otlp-metrics`）  
- [ ] 仓库 Description 与 License（Apache-2.0）正确  
- [ ] pub.dev 发布账号与维护者一致（当前：**songzhendong**，xiaodong12315@qq.com）

## 3. 发布到 pub.dev

1. 登录：https://pub.dev（使用 Google 账号绑定邮箱 **xiaodong12315@qq.com**）  
2. 本地校验：

```bash
cd skywalking-flutter
dart pub publish --dry-run
```

3. 正式发布（需交互确认 `y`）：

```bash
# 若使用国内镜像，请临时指向官方源
$env:PUB_HOSTED_URL = "https://pub.dev"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.googleapis.com"
dart pub publish
```

4. 发布后 `pubspec.yaml` 中依赖写法：

```yaml
dependencies:
  skywalking_flutter: ^0.1.0
```

## 4. 与 Apache 官方关系

README 中已说明：**社区维护，非 Apache SkyWalking 官方发行版**。  
若未来捐赠 ASF，可迁移至 `apache/skywalking-flutter` 并更新 `repository` URL。
