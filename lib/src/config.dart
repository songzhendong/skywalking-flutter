import 'otlp_env.dart';
import 'otlp_resource.dart';

/// OTLP/HTTP exporter configuration (OpenTelemetry-aligned).
class OtlpExporterConfig {
  const OtlpExporterConfig({
    required this.serviceName,
    String otlpEndpoint = 'http://127.0.0.1:12800',
    @Deprecated('Use otlpEndpoint') String? otlpHttpEndpoint,
    this.serviceVersion = 'unknown',
    this.deploymentEnvironment = 'production',
    this.serviceInstanceId,
    this.resourceAttributes = const {},
    this.instrumentationScopeName = 'io.opentelemetry.flutter',
    this.instrumentationScopeVersion = '0.2.0',
    this.flushInterval = const Duration(seconds: 5),
    this.maxBatchSize = 32,
    this.tracesEnabled = true,
    this.metricsEnabled = true,
    this.tracesEndpoint,
    this.metricsEndpoint,
    this.sdkName = 'skywalking-flutter',
    this.sdkVersion = '0.2.0',
  }) : otlpEndpoint = otlpHttpEndpoint ?? otlpEndpoint;

  /// `service.name` resource attribute (required).
  final String serviceName;

  /// OTLP/HTTP base URL without path (`OTEL_EXPORTER_OTLP_ENDPOINT`).
  final String otlpEndpoint;

  @Deprecated('Use otlpEndpoint')
  String get otlpHttpEndpoint => otlpEndpoint;

  final String serviceVersion;
  final String deploymentEnvironment;
  final String? serviceInstanceId;

  /// Merged into resource (e.g. from `OTEL_RESOURCE_ATTRIBUTES`).
  final Map<String, String> resourceAttributes;

  /// `scope.name` on exported spans and metrics.
  final String instrumentationScopeName;
  final String instrumentationScopeVersion;

  final Duration flushInterval;
  final int maxBatchSize;
  final bool tracesEnabled;
  final bool metricsEnabled;

  /// Full URL override (`OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`).
  final String? tracesEndpoint;

  /// Full URL override (`OTEL_EXPORTER_OTLP_METRICS_ENDPOINT`).
  final String? metricsEndpoint;

  final String sdkName;
  final String sdkVersion;

  factory OtlpExporterConfig.fromEnvironment({
    Map<String, String> dartDefines = const {},
    String defaultEndpoint = 'http://127.0.0.1:12800',
    String defaultServiceName = 'unknown_service',
    bool defaultMetricsEnabled = true,
  }) =>
      OtlpEnv.resolveConfig(
        dartDefines: dartDefines,
        defaultEndpoint: defaultEndpoint,
        defaultServiceName: defaultServiceName,
        defaultMetricsEnabled: defaultMetricsEnabled,
      );

  OtlpResource get resource => OtlpResource(
        serviceName: serviceName,
        serviceVersion: serviceVersion,
        deploymentEnvironment: deploymentEnvironment,
        serviceInstanceId: serviceInstanceId,
        sdkName: sdkName,
        sdkVersion: sdkVersion,
        attributes: resourceAttributes,
      );

  String get tracesUrl {
    if (tracesEndpoint != null && tracesEndpoint!.isNotEmpty) {
      return tracesEndpoint!;
    }
    return '${_baseUrl}/v1/traces';
  }

  String get metricsUrl {
    if (metricsEndpoint != null && metricsEndpoint!.isNotEmpty) {
      return metricsEndpoint!;
    }
    return '${_baseUrl}/v1/metrics';
  }

  String get _baseUrl {
    final base = otlpEndpoint.endsWith('/')
        ? otlpEndpoint.substring(0, otlpEndpoint.length - 1)
        : otlpEndpoint;
    return base;
  }

  OtlpExporterConfig copyWith({
    String? serviceName,
    String? otlpEndpoint,
    String? serviceVersion,
    String? deploymentEnvironment,
    String? serviceInstanceId,
    Map<String, String>? resourceAttributes,
    String? instrumentationScopeName,
    String? instrumentationScopeVersion,
    Duration? flushInterval,
    int? maxBatchSize,
    bool? tracesEnabled,
    bool? metricsEnabled,
    String? tracesEndpoint,
    String? metricsEndpoint,
    String? sdkName,
    String? sdkVersion,
  }) =>
      OtlpExporterConfig(
        serviceName: serviceName ?? this.serviceName,
        otlpEndpoint: otlpEndpoint ?? this.otlpEndpoint,
        serviceVersion: serviceVersion ?? this.serviceVersion,
        deploymentEnvironment:
            deploymentEnvironment ?? this.deploymentEnvironment,
        serviceInstanceId: serviceInstanceId ?? this.serviceInstanceId,
        resourceAttributes: resourceAttributes ?? this.resourceAttributes,
        instrumentationScopeName:
            instrumentationScopeName ?? this.instrumentationScopeName,
        instrumentationScopeVersion:
            instrumentationScopeVersion ?? this.instrumentationScopeVersion,
        flushInterval: flushInterval ?? this.flushInterval,
        maxBatchSize: maxBatchSize ?? this.maxBatchSize,
        tracesEnabled: tracesEnabled ?? this.tracesEnabled,
        metricsEnabled: metricsEnabled ?? this.metricsEnabled,
        tracesEndpoint: tracesEndpoint ?? this.tracesEndpoint,
        metricsEndpoint: metricsEndpoint ?? this.metricsEndpoint,
        sdkName: sdkName ?? this.sdkName,
        sdkVersion: sdkVersion ?? this.sdkVersion,
      );
}

/// Backward-compatible alias.
typedef SkywalkingConfig = OtlpExporterConfig;
