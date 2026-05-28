# Example

Minimal Dart program that initializes [skywalking_flutter](../), sends one trace span and one metric, then flushes to OAP.

## Prerequisites

- Dart SDK `>=3.0.0`
- SkyWalking OAP with OTLP on port **12800**

## Run

```bash
cd example
dart pub get
dart run lib/main.dart
```

Override endpoint or service name with environment variables (see [doc/USAGE.md](../doc/USAGE.md)):

```bash
export OTEL_EXPORTER_OTLP_ENDPOINT=http://127.0.0.1:12800
export OTEL_SERVICE_NAME=skywalking-flutter-example
dart run lib/main.dart
```

For a full Flutter UI demo, see the [skywalking-dart](https://github.com/songzhendong/skywalking-dart/tree/main/example) mirror repository.
