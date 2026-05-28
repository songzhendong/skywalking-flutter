import 'package:skywalking_flutter/skywalking_flutter.dart';

/// Minimal CLI demo: one span + counter, then flush to OAP (default 127.0.0.1:12800).
Future<void> main() async {
  final agent = OtlpAgent.init(
    const OtlpExporterConfig(
      serviceName: 'skywalking-flutter-example',
      otlpEndpoint: 'http://127.0.0.1:12800',
      deploymentEnvironment: 'dev',
      flushInterval: Duration(seconds: 1),
    ),
  );

  await agent.tracer.withSpan('example.run', (_) async {
    agent.meter.addCounter('example.runs');
  });
  await agent.flush();
  await agent.shutdown();

  // ignore: avoid_print
  print('OK — check OAP Zipkin for service skywalking-flutter-example');
}
