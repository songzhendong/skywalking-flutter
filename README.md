# skywalking_flutter

<div align="right">

[![English](https://img.shields.io/badge/lang-English-blue?style=flat-square)](README.md)
[![简体中文](https://img.shields.io/badge/lang-简体中文-red?style=flat-square)](doc/USAGE.md)

</div>

[![GitHub](https://img.shields.io/badge/GitHub-songzhendong%2Fskywalking--flutter-blue)](https://github.com/songzhendong/skywalking-flutter)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

OpenTelemetry **OTLP/HTTP** Flutter plugin for **traces** and **metrics**, compatible with [Apache SkyWalking OAP](https://skywalking.apache.org/) (`receiver-otel` on port **12800**).

> **Community-maintained** — not an official Apache SkyWalking release.  
> Repository: https://github.com/songzhendong/skywalking-flutter

| Item | Value |
|------|--------|
| Plugin | Flutter (empty Android/iOS shell; logic in Dart) |
| Protocol | `POST /v1/traces`, `POST /v1/metrics` (HTTP JSON) |
| Version | 0.1.0 |
| Author | songzhendong |
| SDK | Dart `>=3.0.0`, Flutter `>=3.10.0` |

## Features

- Standard OTLP over HTTP JSON (OpenTelemetry-aligned env vars)
- `OtlpAgent` → `tracer` / `meter` / `httpClient()`
- HTTP client spans + `http.client.requests` / `http.client.request.duration`
- `OtlpFlutter.init()` reads `--dart-define` (Flutter-friendly)
- Optional CLI smoke test: `bin/verify_otlp.dart`

## Screenshots (Horizon UI)

Trace list (filter by your `OTEL_SERVICE_NAME`):

![OTel & Zipkin Traces list](doc/images/horizon-zipkin-traces-list.png)

Span detail (Flutter OTLP client; check `telemetry.sdk.name=skywalking-flutter` in tags):

![Trace span detail](doc/images/horizon-zipkin-trace-detail.png)

See [doc/USAGE.md](doc/USAGE.md) for the full Chinese guide and troubleshooting.

## Documentation

| Doc | Description |
|-----|-------------|
| [doc/USAGE.md](doc/USAGE.md) | Full guide in **简体中文** (install, OAP, API, troubleshooting) |
| [doc/PUBLIC_RELEASE.md](doc/PUBLIC_RELEASE.md) | Make repo public / pub.dev checklist |
| [example/README.md](example/README.md) | Runnable demo app |
| [CHANGELOG.md](CHANGELOG.md) | Version history |

## Install

**pub.dev** (recommended):

```yaml
dependencies:
  skywalking_flutter: ^0.1.0
```

**Git**:

```yaml
dependencies:
  skywalking_flutter:
    git:
      url: https://github.com/songzhendong/skywalking-flutter.git
      ref: main
```

```bash
flutter pub get
```

> Git dependency: if the repo is **private**, configure Git credentials (see [doc/PUBLIC_RELEASE.md](doc/PUBLIC_RELEASE.md)).

## Quick start (Flutter)

```dart
import 'package:flutter/material.dart';
import 'package:skywalking_flutter/skywalking_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  OtlpFlutter.init(
    defaultServiceName: 'my-flutter-app',
    defaultEndpoint: 'http://127.0.0.1:12800',
  );

  runApp(const MyApp());
}
```

HTTP with auto instrumentation:

```dart
final client = OtlpAgent.instance.httpClient();
await client.get(Uri.parse('https://api.example.com/health'));
```

Custom span + metric:

```dart
await OtlpAgent.instance.tracer.withSpan('checkout', (_) async {
  // business logic
});
OtlpAgent.instance.meter.addCounter('orders.created');
```

## `--dart-define` (recommended)

```bash
flutter run \
  --dart-define=OTEL_SERVICE_NAME=my-flutter-app \
  --dart-define=OTEL_EXPORTER_OTLP_ENDPOINT=http://10.0.2.2:12800
```

| Define | Purpose |
|--------|---------|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP base URL (no `/v1/traces` suffix) |
| `OTEL_SERVICE_NAME` | Service name in UI |
| `SKYWALKING_OTLP_ENDPOINT` | Alias for endpoint |
| `SKYWALKING_ENABLED=false` | Disable agent |
| `SKYWALKING_METRICS_ENABLED=false` | Traces only |

## OAP configuration

```yaml
receiver-otel:
  default:
    enabledHandlers: otlp-traces,otlp-metrics,otlp-logs
query-zipkin:
  selector: default   # Zipkin UI for traces
```

Restart OAP after changes. View traces: Horizon → **OTel & Zipkin Traces** (service name from `OTEL_SERVICE_NAME`).

## Network pitfall (API vs OTLP)

| Traffic | Example | Port |
|---------|---------|------|
| Business API | `http://your-domain` | 8082 |
| OTLP | `https://your-domain` or `http://host:12800` | 12800 |

Do **not** send `/v1/traces` to the business HTTP port.

## Verify

```powershell
cd path/to/skywalking-flutter
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:12800"
$env:OTEL_SERVICE_NAME = "flutter-otlp-verify"
dart run bin/verify_otlp.dart
```

## Example app

```bash
cd example
flutter pub get
flutter run
# Android emulator → host OAP:
flutter run --dart-define=OTEL_EXPORTER_OTLP_ENDPOINT=http://10.0.2.2:12800
```

Service name in demo: **`flutter-otlp-demo`**.

## Push updates to GitHub

```powershell
cd path/to/skywalking-flutter
.\scripts\push_to_github.ps1 -Message "your commit message"
```

## License

Apache License 2.0 — see [LICENSE](LICENSE).
