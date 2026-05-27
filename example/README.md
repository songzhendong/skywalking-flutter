# skywalking_flutter 示例 App

<div align="right">

[![English](https://img.shields.io/badge/lang-English-blue?style=flat-square)](../README.md)
[![简体中文](https://img.shields.io/badge/lang-简体中文-red?style=flat-square)](../doc/USAGE.md)

</div>

演示 [OtlpFlutter.init](https://github.com/songzhendong/skywalking-flutter/blob/main/lib/src/otlp_flutter.dart)、Trace、Metrics 与按钮触发上报。
## 前置条件

- 已安装 Flutter SDK（`>=3.10.0`）
- 本机或可达网络上有 **SkyWalking OAP**，并启用 OTLP（REST **12800**）

OAP 配置片段见主仓库 [README](../README.md#oap-configuration)。

## 运行

```bash
cd example
flutter pub get
flutter run
```

点击 **Send sample trace + metric**，在 Horizon → **OTel & Zipkin Traces** 中查询 Service **`flutter-otlp-demo`**。

UI 效果参考主仓库截图：[Trace 列表](../doc/images/horizon-zipkin-traces-list.png) · [Span 详情](../doc/images/horizon-zipkin-trace-detail.png)（亦见 [doc/USAGE.md §9.2](../doc/USAGE.md#92-ui-查看)）。

## OTLP 地址

| 环境 | `--dart-define` |
|------|-----------------|
| 本机 / iOS 模拟器 | 默认 `http://127.0.0.1:12800` |
| Android 模拟器 | `OTEL_EXPORTER_OTLP_ENDPOINT=http://10.0.2.2:12800` |
| 真机（电脑局域网） | `OTEL_EXPORTER_OTLP_ENDPOINT=http://<电脑IP>:12800` |

```bash
flutter run --dart-define=OTEL_EXPORTER_OTLP_ENDPOINT=http://10.0.2.2:12800
```

## 关闭 Agent

```bash
flutter run --dart-define=SKYWALKING_ENABLED=false
```
