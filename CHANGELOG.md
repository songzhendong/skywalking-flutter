# Changelog

## 0.1.3

- Add `example/` for pub.dev full score; include example in published package.

## 0.1.2

- Fix pub.dev `repository` URL and LICENSE recognition; document current version in changelog.

## 0.1.1

- Pure Dart OTLP/HTTP agent for traces and metrics (SkyWalking OAP compatible).

## 0.1.0

- Docs: Horizon Metrics inspect and parent-child trace screenshots (`doc/images/`).
- Initial release: OpenTelemetry OTLP/HTTP agent (pure Dart) for traces and metrics.
- Package name `skywalking_flutter` on pub.dev; source https://github.com/songzhendong/skywalking-dart
- Compatible with Apache SkyWalking OAP (`receiver-otel` on port 12800).
- `OtlpAgent`, `OtlpFlutter`, `InstrumentedClient`, and `bin/verify_otlp.dart`.
- Sample OAP MAL rules: `doc/oap/flutter-otlp.yaml`
