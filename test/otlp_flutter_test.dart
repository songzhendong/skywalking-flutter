import 'package:flutter_test/flutter_test.dart';
import 'package:skywalking_flutter/skywalking_flutter.dart';

void main() {
  test('configFromDartDefines uses defaults when defines absent', () {
    final config = OtlpFlutter.configFromDartDefines(
      defaultEndpoint: 'http://127.0.0.1:12800',
      defaultServiceName: 'test-app',
    );
    expect(config.serviceName, 'test-app');
    expect(config.otlpEndpoint, 'http://127.0.0.1:12800');
    expect(config.tracesUrl, endsWith('/v1/traces'));
    expect(config.metricsUrl, endsWith('/v1/metrics'));
  });
}
