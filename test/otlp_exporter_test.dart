import 'package:skywalking_flutter/skywalking_flutter.dart';
import 'package:test/test.dart';

void main() {
  test('buildExportPayload includes service.name and hex ids', () {
    final exporter = OtlpTraceExporter(
      const OtlpExporterConfig(serviceName: 'test-app'),
    );
    final payload = exporter.buildExportPayload([
      OtlpSpanData(
        name: 'unit.test',
        traceId: '5b8efff798038103d269b633813fc60c',
        spanId: '00f067aa0ba902b7',
        startTimeUnixNano: 1000,
        endTimeUnixNano: 2000,
        kind: OtlpSpanKind.server,
      ),
    ]);

    final resourceSpans = payload['resourceSpans']! as List;
    final resource = (resourceSpans.first as Map)['resource'] as Map;
    final attrs = (resource['attributes'] as List)
        .cast<Map>()
        .map((a) => a['key'] as String)
        .toList();
    expect(attrs, contains(Semconv.serviceName));

    final scopeSpans =
        (resourceSpans.first as Map)['scopeSpans'] as List;
    final spans =
        ((scopeSpans.first as Map)['spans'] as List);
    final span = spans.first as Map;
    expect(span['traceId'], '5b8efff798038103d269b633813fc60c');
    expect(span['spanId'], '00f067aa0ba902b7');
    expect(span['kind'], 2);
  });

  test('tracesUrl and metricsUrl normalize trailing slash', () {
    const cfg = OtlpExporterConfig(
      serviceName: 'x',
      otlpEndpoint: 'http://127.0.0.1:12800/',
    );
    expect(cfg.tracesUrl, 'http://127.0.0.1:12800/v1/traces');
    expect(cfg.metricsUrl, 'http://127.0.0.1:12800/v1/metrics');
  });

  test('Semconv.httpSpanName follows METHOD path pattern', () {
    expect(Semconv.httpSpanName('get', '/xt/video/list'), 'GET /xt/video/list');
  });
}
