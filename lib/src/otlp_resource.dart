import 'otlp_attribute.dart';
import 'semconv.dart';

/// OTLP resource attributes attached to all telemetry from this process.
class OtlpResource {
  const OtlpResource({
    required this.serviceName,
    this.serviceVersion = 'unknown',
    this.deploymentEnvironment = 'production',
    this.serviceInstanceId,
    this.sdkName = 'skywalking-flutter',
    this.sdkVersion = '0.1.2',
    this.sdkLanguage = 'dart',
    this.attributes = const {},
  });

  final String serviceName;
  final String serviceVersion;
  final String deploymentEnvironment;
  final String? serviceInstanceId;
  final String sdkName;
  final String sdkVersion;
  final String sdkLanguage;

  /// Extra resource attributes (`OTEL_RESOURCE_ATTRIBUTES` / custom).
  final Map<String, String> attributes;

  List<Map<String, Object?>> toOtlpAttributes() {
    final merged = <String, String>{
      Semconv.serviceName: serviceName,
      Semconv.serviceVersion: serviceVersion,
      Semconv.deploymentEnvironment: deploymentEnvironment,
      Semconv.telemetrySdkName: sdkName,
      Semconv.telemetrySdkLanguage: sdkLanguage,
      Semconv.telemetrySdkVersion: sdkVersion,
      if (serviceInstanceId != null && serviceInstanceId!.isNotEmpty)
        Semconv.serviceInstanceId: serviceInstanceId!,
      ...attributes,
    };
    return OtlpAttribute.fromMap(merged);
  }
}
