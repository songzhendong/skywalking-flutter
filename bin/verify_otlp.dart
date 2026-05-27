import 'dart:io';

import 'package:skywalking_flutter/skywalking_flutter.dart';

/// Smoke test (OTel-standard env vars preferred):
/// ```
/// $env:OTEL_EXPORTER_OTLP_ENDPOINT="http://127.0.0.1:12800"
/// $env:OTEL_SERVICE_NAME="flutter-otlp-verify"
/// dart run bin/verify_otlp.dart
/// ```

Future<void> main(List<String> args) async {
  if (OtlpEnv.sdkDisabledFromEnvironment()) {
    // ignore: avoid_print
    print('SKIP: OTEL_SDK_DISABLED is set');
    return;
  }

  final config = OtlpExporterConfig.fromEnvironment(
    defaultEndpoint: 'http://127.0.0.1:12800',
    defaultServiceName: 'flutter-otlp-verify',
  );

  final agent = OtlpAgent.init(
    config.copyWith(flushInterval: const Duration(seconds: 1)),
  );

  // ignore: avoid_print
  print(
    'Sending OTLP to ${config.otlpEndpoint} '
    '(traces=${config.tracesUrl}, metrics=${config.metricsUrl}) '
    'as ${config.serviceName} ...',
  );

  await agent.tracer.withSpan('verify.bootstrap', (_) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });

  agent.tracer.recordEvent(
    name: 'verify.custom_event',
    duration: const Duration(milliseconds: 10),
    attributes: {'source': 'verify_otlp.dart'},
  );

  agent.meter.addCounter('verify.events_total', attributes: {'event': 'custom'});
  agent.meter.recordDuration('verify.bootstrap.duration', const Duration(milliseconds: 50));

  final ok = await agent.traceExporter.exportNow([
    OtlpSpanData(
      name: 'verify.immediate',
      traceId: agent.traceExporter.idGenerator.traceId(),
      spanId: agent.traceExporter.idGenerator.spanId(),
      startTimeUnixNano:
          DateTime.now()
                  .subtract(const Duration(milliseconds: 5))
                  .microsecondsSinceEpoch *
              1000,
      endTimeUnixNano: DateTime.now().microsecondsSinceEpoch * 1000,
      kind: OtlpSpanKind.server,
      attributes: {'test': 'immediate'},
    ),
  ]);

  await agent.flush();
  await agent.shutdown();

  if (ok) {
    // ignore: avoid_print
    print('OK: OTLP export returned success.');
  } else {
    // ignore: avoid_print
    print('FAIL: OTLP export failed. Is OAP listening on ${config.otlpEndpoint}?');
    exitCode = 1;
  }
}
