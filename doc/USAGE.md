# skywalking_flutter 使用文档

<div align="right">

[![English](https://img.shields.io/badge/lang-English-blue?style=flat-square)](../README.md)
[![简体中文](https://img.shields.io/badge/lang-简体中文-red?style=flat-square)](USAGE.md)

</div>

通用 **OpenTelemetry OTLP/HTTP** Dart/Flutter Agent，向 **SkyWalking OAP**（或任意兼容 OTLP/HTTP JSON 的后端）上报 **分布式链路（Traces）** 与 **指标（Metrics）**。

| 项目 | 说明 |
|------|------|
| 包名 | `skywalking_flutter` |
| 版本 | 0.1.1 |
| 作者 | songzhendong (xiaodong12315@qq.com) |
| 仓库 | https://github.com/songzhendong/skywalking-dart |
| 协议 | OTLP over HTTP JSON |
| Trace 端点 | `POST {base}/v1/traces` |
| Metrics 端点 | `POST {base}/v1/metrics` |
| 默认 OAP 端口 | `12800`（与 Java Agent 的 gRPC `11800` 不同） |

---

## 目录

1. [适用场景](#1-适用场景)
2. [安装](#2-安装)
3. [后端准备（SkyWalking OAP）](#3-后端准备skywalking-oap)
4. [快速开始](#4-快速开始)
5. [配置说明](#5-配置说明)
6. [API 使用指南](#6-api-使用指南)
7. [Flutter 集成建议](#7-flutter-集成建议)
8. [业务封装示例](#8-业务封装示例)
9. [验证与排错](#9-验证与排错)
10. [限制说明](#10-限制说明)
11. [与 Java SkyWalking Agent 对比](#11-与-java-skywalking-agent-对比)

---

## 1. 适用场景

- Flutter / Dart 移动应用、桌面应用需要接入 SkyWalking 可观测性
- 希望使用 **标准 OTLP** 协议，而非 SkyWalking 私有 gRPC Agent 协议
- 需要同时上报 **Trace + Metrics**（Counter、Histogram）
- 需要为 `package:http` 请求自动产生 **HTTP CLIENT** Span 与标准 HTTP 指标

**不适合：**

- 需要全自动字节码/无侵入埋点（请用 Java Agent）
- 需要 OTLP gRPC、Protobuf 编码（本包仅 HTTP JSON）
- 需要 Logs 导出（OAP 可接收 logs，本包尚未实现）
- 需要 Gauge、UpDownCounter、Exemplar、W3C TraceContext 自动传播（见[限制说明](#10-限制说明)）

---

## 2. 安装

在 `pubspec.yaml` 中添加 `skywalking_flutter` 依赖。

### 2.1 pub.dev（推荐）

```yaml
dependencies:
  skywalking_flutter: ^0.1.1
```

### 2.2 Git（源码仓库）

```yaml
dependencies:
  skywalking_flutter:
    git:
      url: https://github.com/songzhendong/skywalking-dart.git
      ref: main
```

### 2.3 路径依赖

```yaml
dependencies:
  skywalking_flutter:
    path: ../skywalking-dart
```

然后执行：

```bash
dart pub get
# Flutter 应用亦可：
flutter pub get
```

### 2.4 导入

```dart
import 'package:skywalking_flutter/skywalking_flutter.dart';
```

---

## 3. 后端准备（SkyWalking OAP）

OAP 需启用 OTLP 接收器（`application.yml`）：

```yaml
receiver-otel:
  selector: ${SW_OTEL_RECEIVER:default}
  default:
    enabledHandlers: ${SW_OTEL_RECEIVER_ENABLED_HANDLERS:"otlp-traces,otlp-metrics,otlp-logs"}
```

若要在 Horizon UI 的 Zipkin 视图查看 Trace，还需：

```yaml
receiver-zipkin:
  selector: default
query-zipkin:
  selector: default
```

修改配置后 **完整重启 OAP**。

本地自检：

```powershell
# Zipkin 查询 API（UI 依赖）
Invoke-WebRequest http://127.0.0.1:9412/zipkin/api/v2/services -UseBasicParsing

# OTLP 写入冒烟
cd skywalking-dart
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:12800"
$env:OTEL_SERVICE_NAME = "flutter-otlp-verify"
dart run bin/verify_otlp.dart
```

输出应包含 `traces=.../v1/traces, metrics=.../v1/metrics` 且最后一行为 `OK`。

---

## 4. 快速开始

### 4.1 Flutter 推荐：`OtlpFlutter.init`

读取 `--dart-define`，Debug 下打印 endpoint；禁用时不初始化。

```dart
import 'package:flutter/material.dart';
import 'package:skywalking_flutter/skywalking_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  OtlpFlutter.init(
    defaultServiceName: 'my-flutter-app',
    defaultEndpoint: 'http://127.0.0.1:12800',
    defaultEnvironment: 'dev',
    flushInterval: const Duration(seconds: 3),
  );

  runApp(const MyApp());
}
```

```bash
flutter run \
  --dart-define=OTEL_SERVICE_NAME=my-flutter-app \
  --dart-define=OTEL_EXPORTER_OTLP_ENDPOINT=http://10.0.2.2:12800
```

| `--dart-define` | 说明 |
|-----------------|------|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP 根地址 |
| `OTEL_SERVICE_NAME` | 服务名 |
| `SKYWALKING_OTLP_ENDPOINT` | endpoint 别名 |
| `SKYWALKING_ENABLED=false` | 关闭 Agent |
| `OTEL_SDK_DISABLED=true` | 关闭 Agent |
| `SKYWALKING_METRICS_ENABLED=false` | 仅 Trace |

### 4.2 手动：`OtlpExporterConfig`

```dart
import 'package:skywalking_flutter/skywalking_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final agent = OtlpAgent.init(
    const OtlpExporterConfig(
      serviceName: 'my-flutter-app',
      otlpEndpoint: 'http://127.0.0.1:12800',
      deploymentEnvironment: 'dev',
      flushInterval: Duration(seconds: 3),
    ),
  );

  await agent.tracer.withSpan('app.startup', (_) async {
    // 业务逻辑
  });

  agent.meter.addCounter('app.launches', attributes: {'platform': 'flutter'});
  agent.meter.recordDuration('app.startup.duration', const Duration(milliseconds: 120));

  await agent.flush();
  runApp(const MyApp());
}
```

### 4.3 从进程环境变量初始化（CLI / 桌面）

```dart
if (OtlpEnv.sdkDisabledFromEnvironment()) return;

final agent = OtlpAgent.initFromEnvironment(
  defaultEndpoint: 'http://127.0.0.1:12800',
  defaultServiceName: 'my-flutter-app',
);
```

PowerShell 示例：

```powershell
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:12800"
$env:OTEL_SERVICE_NAME = "my-flutter-app"
dart run your_app.dart
```

### 4.4 带 HTTP 自动埋点

```dart
final client = OtlpAgent.instance.httpClient();
final resp = await client.get(Uri.parse('http://127.0.0.1:8080/api/health'));
```

每次请求会自动：

- 产生 Trace Span，名称为 `GET /api/health`（`METHOD path` 格式）
- 若启用了 Metrics，累加 `http.client.requests` 并记录 `http.client.request.duration`

### 4.5 应用退出时关闭

```dart
await OtlpAgent.instance.shutdown();
```

---

## 5. 配置说明

### 5.1 `OtlpExporterConfig` 字段

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `serviceName` | `String` | （必填） | Resource 属性 `service.name` |
| `otlpEndpoint` | `String` | `http://127.0.0.1:12800` | OTLP 根地址，**不含** `/v1/traces` |
| `serviceVersion` | `String` | `unknown` | `service.version` |
| `deploymentEnvironment` | `String` | `production` | `deployment.environment` |
| `serviceInstanceId` | `String?` | `null` | `service.instance.id`，为空则由 SDK 生成 |
| `resourceAttributes` | `Map` | `{}` | 额外 Resource 属性 |
| `instrumentationScopeName` | `String` | `io.opentelemetry.flutter` | Scope 名 |
| `flushInterval` | `Duration` | `5s` | 批量 flush 周期 |
| `maxBatchSize` | `int` | `32` | 单批最大条数 |
| `tracesEnabled` | `bool` | `true` | 是否导出 Trace |
| `metricsEnabled` | `bool` | `true` | 是否导出 Metrics |
| `tracesEndpoint` | `String?` | `null` | 完整 Trace URL 覆盖 |
| `metricsEndpoint` | `String?` | `null` | 完整 Metrics URL 覆盖 |

计算后的 URL：

- Traces：`{otlpEndpoint}/v1/traces`（或 `tracesEndpoint`）
- Metrics：`{otlpEndpoint}/v1/metrics`（或 `metricsEndpoint`）

### 5.2 标准环境变量（OpenTelemetry）

| 环境变量 | 说明 |
|----------|------|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP 根地址（优先） |
| `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` | 完整 Traces URL |
| `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT` | 完整 Metrics URL |
| `OTEL_SERVICE_NAME` | 服务名 |
| `OTEL_SERVICE_VERSION` | 服务版本 |
| `OTEL_RESOURCE_ATTRIBUTES` | 如 `team=mobile,region=cn` |
| `OTEL_SDK_DISABLED=true` | 禁用 SDK |
| `OTEL_METRICS_EXPORTER=none` | 仅关闭 Metrics |
| `OTEL_TRACES_EXPORTER=none` | 仅关闭 Traces |

### 5.3 兼容的旧变量名

| 旧变量 | 映射到 |
|--------|--------|
| `OTLP_ENDPOINT` | OTLP 根地址 |
| `SKYWALKING_OTLP_ENDPOINT` | OTLP 根地址 |
| `SERVICE_NAME` | 服务名 |
| `SKYWALKING_SERVICE_NAME` | 服务名 |

### 5.4 Flutter `--dart-define`

`dart run` / `flutter run` **不会**自动把 `--dart-define` 写入进程环境变量。推荐在 App 内用编译期常量：

```dart
const _otlpEndpoint = String.fromEnvironment(
  'OTEL_EXPORTER_OTLP_ENDPOINT',
  defaultValue: String.fromEnvironment(
    'SKYWALKING_OTLP_ENDPOINT',
    defaultValue: 'http://127.0.0.1:12800',
  ),
);

const _serviceName = String.fromEnvironment(
  'OTEL_SERVICE_NAME',
  defaultValue: 'my-flutter-app',
);

OtlpAgent.init(
  OtlpExporterConfig(
    serviceName: _serviceName,
    otlpEndpoint: _otlpEndpoint,
    metricsEnabled: const bool.fromEnvironment('SKYWALKING_METRICS_ENABLED', defaultValue: true),
  ),
);
```

运行：

```bash
flutter run \
  --dart-define=OTEL_EXPORTER_OTLP_ENDPOINT=https://your-oap.example.com \
  --dart-define=OTEL_SERVICE_NAME=my-flutter-app
```

也可把 define 传给 `OtlpExporterConfig.fromEnvironment(dartDefines: {...})`，由 `dartDefines` 覆盖环境变量。

### 5.5 网络拓扑注意（真机 + 内网穿透）

常见错误：业务 API 与 OTLP 共用同一个 `http://` 域名，导致 Trace 打到业务后端（如 8082）并报 `No static resource v1/traces`。

| 用途 | 示例 |
|------|------|
| 业务 API | `http://xxx.vicp.fun` → 8082 |
| OTLP | `https://xxx.vicp.fun` → 12800 |

**API 用 HTTP，OTLP 用 HTTPS（或独立 host:12800）**，不要把 `/v1/traces` 发到业务网关。

---

## 6. API 使用指南

### 6.1 `OtlpFlutter`（Flutter 便捷入口）

| 成员 | 说明 |
|------|------|
| `OtlpFlutter.shouldInitialize` | 是否启用（`SKYWALKING_ENABLED` / `OTEL_SDK_DISABLED`） |
| `OtlpFlutter.configFromDartDefines(...)` | 从 `--dart-define` 生成 `OtlpExporterConfig` |
| `OtlpFlutter.init(...)` | 初始化 Agent；禁用时返回 `null` |

### 6.2 `OtlpAgent`（入口）

| 方法 | 说明 |
|------|------|
| `OtlpAgent.init(config)` | 初始化全局单例 |
| `OtlpAgent.initFromEnvironment(...)` | 从环境变量构建 config 并 init |
| `OtlpAgent.instance` | 获取单例（未 init 抛错） |
| `OtlpAgent.isInitialized` | 是否已初始化 |
| `agent.tracer` | Trace API |
| `agent.meter` | Metrics API（需 `metricsEnabled: true`） |
| `agent.httpClient({inner})` | 返回带埋点的 `http.Client` |
| `agent.flush()` | 立即 flush Trace + Metrics |
| `agent.shutdown()` | 停止定时器并关闭 HTTP 客户端 |

### 6.3 `OtlpTracer`（链路）

#### 异步包裹（推荐）

```dart
await OtlpAgent.instance.tracer.withSpan(
  'order.checkout',
  (span) async {
    span.setAttribute('order.id', orderId);
    return await checkout();
  },
  attributes: {'channel': 'app'},
);
```

异常会自动记录 `exception.type` / `exception.message`，Span 状态为 `ERROR`。

#### 记录已完成的 Span

```dart
OtlpAgent.instance.tracer.recordSpan(
  name: 'cache.warmup',
  duration: const Duration(milliseconds: 42),
  attributes: {'cache.keys': '128'},
);
```

#### 业务 / UI 事件

```dart
OtlpAgent.instance.tracer.recordEvent(
  name: 'screen.home',
  duration: Duration.zero,
  attributes: {Semconv.screenName: 'home'},
);
```

#### 手动 Span

```dart
final span = OtlpAgent.instance.tracer.startSpan('manual.work');
try {
  // ...
  OtlpAgent.instance.tracer.endSpan(span, status: OtlpStatusCode.ok);
} catch (e) {
  span.recordException(e);
  OtlpAgent.instance.tracer.endSpan(span);
  rethrow;
}
```

#### Span 种类 `OtlpSpanKind`

| 值 | 用途 |
|----|------|
| `internal` | 默认，应用内部逻辑 |
| `client` | 对外部服务调用（HTTP Client 自动使用） |
| `server` | 处理入站请求（本包不自动创建） |
| `producer` / `consumer` | 消息队列（按需手动使用） |

### 6.4 `OtlpMeter`（指标）

需 `OtlpExporterConfig.metricsEnabled: true`。样本先入队，按 `flushInterval` 批量 `POST /v1/metrics` 到 OAP。

#### 三种 API：用法与作用

| 方法 | 指标类型 | 作用 | 典型场景 |
|------|----------|------|----------|
| `addCounter(任意名, …)` | **Counter**（只增计数） | 记录「发生了多少次」 | 登录次数、按钮点击、HTTP 请求数、异常次数 |
| `recordDuration(任意名, …)` | **Histogram**（单位 ms） | 记录「耗时分布」 | 接口耗时、冷启动、发布/搜索耗时 |
| `recordHistogram(任意名, value, …)` | **Histogram**（自定义单位） | 记录「数值分布」 | 包体大小（`By`）、队列深度、自定义分数 |

- **`name`**：指标名，由业务自定（点分小写，如 `app.auth.login`）；Agent **不预置**除 HTTP 自动埋点外的固定业务名。
- **`attributes`**：维度标签（如 `result: ok/fail`、`search.tab: video`），用于在 OAP 按维度聚合；勿放用户 ID、完整 URL 等高基数字段。
- **`delta`**（Counter）：本次累加值，默认 `1`。
- Counter 与 Histogram 在 OTLP 导出时分别对应 **Sum（Cumulative）** 与 **Histogram**；Histogram 使用内置毫秒分桶（见 `kOtlpDefaultHistogramBoundsMs`）。

#### Counter

```dart
OtlpAgent.instance.meter.addCounter(
  'orders.created',
  delta: 1,
  attributes: {'payment': 'wechat'},
);
```

#### Histogram（数值）

```dart
OtlpAgent.instance.meter.recordHistogram(
  'payload.size',
  1024.0,
  unit: 'By',
);
```

#### Histogram（耗时，单位 ms）

```dart
OtlpAgent.instance.meter.recordDuration(
  'checkout.duration',
  const Duration(milliseconds: 350),
  attributes: {'result': 'ok'},
);
```

`recordDuration` 等价于 `recordHistogram(..., unit: 'ms')`，内部把 `Duration` 转为毫秒浮点值。

#### 指标命名建议

- 使用 **点分** 小写：`{domain}.{entity}.{measure}`
- 示例：`app.auth.login`、`http.client.requests`
- 属性（attributes）用于维度拆分，避免把高基数数据（用户 ID、完整 URL 带 query）放进指标标签

### 6.5 `InstrumentedClient`（HTTP）

```dart
final client = OtlpAgent.instance.httpClient(
  inner: http.Client(), // 可选，默认新建
);

await client.get(Uri.parse('https://api.example.com/v1/users'));
await client.post(
  Uri.parse('https://api.example.com/v1/login'),
  headers: {'Content-Type': 'application/json'},
  body: '{"user":"demo"}',
);
```

**Trace 属性（节选）：** `http.request.method`、`url.full`、`url.path`、`http.response.status_code` 等（见 `Semconv.httpClientAttributes`）。

**自动 Metrics（当 `metricsEnabled` 时）：**

| 指标名 | 类型 |
|--------|------|
| `http.client.requests` | Counter |
| `http.client.request.duration` | Histogram（ms） |

> `InstrumentedClient` 会缓冲响应 body 以计算大小与状态码，超大流式下载请注意内存占用。

### 6.6 `Semconv`（语义约定常量）

提供 OpenTelemetry 常用属性键，避免手写字符串：

```dart
import 'package:skywalking_flutter/skywalking_flutter.dart';

Semconv.serviceName;           // service.name
Semconv.httpRequestMethod;     // http.request.method
Semconv.exceptionType;         // exception.type
Semconv.metricHttpClientRequests;
Semconv.httpSpanName('GET', '/api/foo'); // => "GET /api/foo"
```

完整列表见 `lib/src/semconv.dart`。

### 6.7 兼容别名（Deprecated）

| 旧名称 | 新名称 |
|--------|--------|
| `Skywalking` | `OtlpAgent` |
| `SkywalkingConfig` | `OtlpExporterConfig` |
| `agent.trackEvent` | `agent.tracer.recordSpan` / `recordEvent` |
| `agent.trace(...)` | `agent.tracer.withSpan` |

---

## 7. Flutter 集成建议

### 7.1 初始化时机

在 `main()` 中 **`WidgetsFlutterBinding.ensureInitialized()` 之后**、`runApp()` 之前：

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Monitoring.init(); // 内部调用 OtlpAgent.init
  runApp(const MyApp());
}
```

### 7.2 全局 HTTP 客户端

在业务层封装单例，统一走 `OtlpAgent.instance.httpClient()`，避免部分请求绕过埋点。

### 7.3 路由 / 页面浏览

使用 `NavigatorObserver` 在 `didPush` 时上报 `screen.<name>` Span 与 Counter（如 `app.screen.views`）。

### 7.4 全局异常

```dart
FlutterError.onError = (details) {
  OtlpAgent.instance.tracer.recordSpan(
    name: 'exception',
    duration: Duration.zero,
    status: OtlpStatusCode.error,
    attributes: {
      Semconv.exceptionType: details.exception.runtimeType.toString(),
      Semconv.exceptionMessage: details.exception.toString(),
    },
  );
  OtlpAgent.instance.meter.addCounter(
    Semconv.metricExceptions,
    attributes: {'exception.context': 'flutter.error'},
  );
};
```

### 7.5 生命周期

在 `WidgetsBindingObserver.didChangeAppLifecycleState` 中上报前后台切换。

### 7.6 关闭

`dispose` 或 App 退出时调用 `shutdown()`，避免丢失最后一批数据。

---

## 8. 业务封装示例

建议在业务仓库单独建 `lib/monitoring/`，对 Agent 做薄封装，**业务代码只依赖封装层**：

```dart
// monitoring.dart
class AppMonitoring {
  static Future<void> init() async {
    if (!_enabled) return;
    OtlpAgent.init(OtlpExporterConfig(
      serviceName: 'my-app',
      otlpEndpoint: _endpoint,
      metricsEnabled: true,
      flushInterval: const Duration(seconds: 3),
    ));
    _installErrorHandlers();
  }

  static http.Client get http => OtlpAgent.instance.httpClient();

  static void trackLogin({required bool success}) {
    final t = OtlpAgent.instance.tracer;
    final m = OtlpAgent.instance.meter;
    t.recordSpan(name: 'auth.login', duration: Duration.zero, status: success ? OtlpStatusCode.ok : OtlpStatusCode.error);
    m.addCounter('app.auth.login', attributes: {'result': success ? 'ok' : 'fail'});
  }
}
```

建议在业务 App 中增加 `lib/monitoring/` 薄封装（`init`、`sharedHttpClient`、业务 `trackXxx`），业务代码只依赖封装层，不直接散落 `OtlpAgent` 调用。

---

## 9. 验证与排错

### 9.1 命令行冒烟

```powershell
cd skywalking-dart
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:12800"
$env:OTEL_SERVICE_NAME = "flutter-otlp-verify"
dart run bin/verify_otlp.dart
```

### 9.2 UI 查看

| 数据类型 | 查看位置 |
|----------|----------|
| Trace | Horizon → **OTel & Zipkin Traces**，Service 选你的 `serviceName` |
| Metrics | Horizon → **OPERATE → Metrics inspect**（**不在 Zipkin 页面**） |

#### 示例截图（两排缩略图，点击放大）

**点击下方缩略图可在新页面查看原图。**

<table>
  <tr>
    <td align="center" width="50%">
      <a href="images/horizon-metrics-inspect.png">
        <img src="images/horizon-metrics-inspect.png" width="420" alt="Metrics inspect"/>
      </a>
      <br/>
      <b>① Metrics inspect（指标）</b><br/>
      <sub>OPERATE → Metrics inspect · 添加 MAL-OTEL / <code>flutter-otlp</code> · 如 <code>meter_flutter_http_requests_rpm</code></sub>
    </td>
    <td align="center" width="50%">
      <a href="images/horizon-trace-parent-child.png">
        <img src="images/horizon-trace-parent-child.png" width="420" alt="Trace parent-child"/>
      </a>
      <br/>
      <b>② Trace 父子链路</b><br/>
      <sub>根 Span <code>app.cold_start</code> · 子 Span <code>feed.prefetch</code> 等 · 右侧 <b>Parent Id</b></sub>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <a href="images/horizon-zipkin-traces-list.png">
        <img src="images/horizon-zipkin-traces-list.png" width="420" alt="Trace list"/>
      </a>
      <br/>
      <b>③ Trace 列表</b><br/>
      <sub>OTel &amp; Zipkin Traces · 按 <code>OTEL_SERVICE_NAME</code> 过滤</sub>
    </td>
    <td align="center" width="50%">
      <a href="images/horizon-zipkin-trace-detail.png">
        <img src="images/horizon-zipkin-trace-detail.png" width="420" alt="Span detail"/>
      </a>
      <br/>
      <b>④ Span 详情</b><br/>
      <sub>Tags：<code>telemetry.sdk.name=skywalking-flutter</code>、<code>telemetry.sdk.language=dart</code></sub>
    </td>
  </tr>
</table>

#### Metrics（指标）说明

OAP 加载 `flutter-otlp` 规则并重启后，在 **Metrics inspect** 中通过 **+ add metric** 选择 **MAL-OTEL → flutter-otlp**，实体选 `xt-open-app`（或你的 `OTEL_SERVICE_NAME`）。常见指标：

- `meter_flutter_verify_events_total` — 冒烟/校验事件计数  
- `meter_flutter_http_requests_rpm` — HTTP 请求每分钟速率  
- `meter_flutter_http_requests_total` — HTTP 请求累计  

> Inspect 横轴为时间桶（分钟级）；无数据时先跑 `dart run bin/verify_otlp.dart` 或真实 App 产生 OTLP，并确认 OAP 已启用 `receiver-otel` 与 `flutter-otlp` 规则。

#### Trace（链路，含父子 Span）说明

在 **OTel & Zipkin Traces** 中按 Service 过滤（如 `xt-open-app`）。列表中每条 Trace 对应一次调用链；点开一条后，中间时间轴展示 **父子层级**（见上图 ②）：

- **父 Span**：例如 `app.cold_start`（冷启动根节点）  
- **子 Span**：同一 `traceId` 下，如 `app.bootstrap.config`、`feed.prefetch`、`screen.home`  
- **Parent Id**：右侧面板指向父 Span 的 id；根 Span 无父 id  

由 `tracer.withSpan` 嵌套或业务封装（如 `SkywalkingMonitoring.trackColdStart`）形成 **一棵树**；单个 HTTP 请求多为一条扁平 Trace，无父子关系。

### 9.3 常见问题

| 现象 | 可能原因 | 处理 |
|------|----------|------|
| `FAIL: OTLP export failed` | OAP 未启动或未开 `receiver-otel` | 检查 12800、重启 OAP |
| Zipkin 0 traces | `query-zipkin` 未启用 | 改 `application.yml` 并重启 |
| 业务后端报 `No static resource v1/traces` | OTLP 发到了 API 网关 | 改用独立 OTLP 地址（HTTPS→12800） |
| 看不到 Metrics | 仅查了 Zipkin | 到 Metrics 功能或 OAP 日志确认 |
| `Call OtlpAgent.init() before...` | 未初始化就调 API | 在 `main` 中先 `init` |
| `Traces export is disabled` | `tracesEnabled: false` | 检查配置 |
| 真机连不上 127.0.0.1 | 模拟器/真机网络隔离 | 使用电脑局域网 IP 或穿透域名 |

### 9.4 调试日志

在封装层 `init` 时打印 endpoint 便于确认：

```dart
debugPrint('[OTLP] endpoint=${config.otlpEndpoint} service=${config.serviceName}');
```

---

## 10. 限制说明

当前版本 **尚未实现** 或仅部分支持：

| 能力 | 状态 |
|------|------|
| OTLP HTTP JSON Traces | ✅ |
| OTLP HTTP JSON Metrics（Counter、Histogram） | ✅ |
| OTLP gRPC / Protobuf | ❌ |
| Logs 导出 | ❌ |
| Gauge / UpDownCounter | ❌ |
| W3C `traceparent` 自动注入与跨服务关联 | ❌ |
| 自动 Widget / 路由无侵入埋点 | ❌（需业务 Observer） |
| 与 Java Agent 直连同一 gRPC 端口 | ❌（协议不同） |

数据以 **批量异步** 方式 flush；进程强杀可能丢失最后一小批数据，关键路径可手动 `flush()`。

---

## 11. 与 Java SkyWalking Agent 对比

| 对比项 | Java SkyWalking Agent | skywalking_flutter |
|--------|----------------------|-------------------|
| 协议 | SkyWalking 私有（gRPC 11800） | **OTLP HTTP JSON（12800）** |
| 埋点方式 | 字节码增强、插件自动 | 手动 / HTTP Client 包装 |
| Trace 查看 | OAP Native / Zipkin | Zipkin（OTLP 转入）+ OAP |
| Metrics | 通过 OAP 多种接收器 | OTLP Metrics |
| 配置 | `agent.config` | `OtlpExporterConfig` + `OTEL_*` |

两者可在同一 OAP 中共存：Java 服务走 Agent，Flutter 走 OTLP，在 UI 中按 **Service 名称** 区分。

---

## 附录：模块结构

```
skywalking-dart/
├── lib/
│   ├── skywalking_flutter.dart   # 公开导出
│   └── src/
│       ├── otlp_agent.dart            # 入口
│       ├── config.dart                # OtlpExporterConfig
│       ├── otlp_env.dart              # 环境变量解析
│       ├── tracer.dart / meter.dart   # 对外 API
│       ├── otlp_trace_exporter.dart   # Trace 批量导出
│       ├── otlp_metrics_exporter.dart # Metrics 批量导出
│       ├── instrumented_client.dart   # HTTP 埋点
│       └── semconv.dart               # 语义约定常量
├── bin/verify_otlp.dart               # 冒烟脚本
├── test/                              # 单元测试
└── doc/USAGE.md                       # 本文档
```

---

**维护：** 如有问题或需求，请在仓库内提 Issue，或联系可观测性负责人。
