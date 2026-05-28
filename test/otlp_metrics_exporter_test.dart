import 'package:skywalking_flutter/skywalking_flutter.dart';
import 'package:test/test.dart';

void main() {
  test('buildExportPayload includes counter and histogram', () {
    final exporter = OtlpMetricsExporter(
      const OtlpExporterConfig(serviceName: 'test-app'),
    );
    final payload = exporter.buildExportPayload([
      OtlpMetricSample(
        name: 'http.client.duration',
        kind: OtlpMetricKind.counter,
        value: 1,
        attributes: {'http.response.status_code': '200'},
      ),
      OtlpMetricSample(
        name: 'app.startup.duration',
        kind: OtlpMetricKind.histogram,
        value: 120.5,
        unit: 'ms',
      ),
    ]);

    final resourceMetrics = payload['resourceMetrics']! as List;
    final scopeMetrics =
        ((resourceMetrics.first as Map)['scopeMetrics'] as List).first as Map;
    final metrics = scopeMetrics['metrics']! as List;
    expect(metrics.length, 2);

    final counter = metrics.first as Map;
    expect(counter['name'], 'http.client.duration');
    expect(counter['sum'], isNotNull);

    final histogram = metrics.last as Map;
    expect(histogram['name'], 'app.startup.duration');
    expect(histogram['histogram'], isNotNull);
  });
}
