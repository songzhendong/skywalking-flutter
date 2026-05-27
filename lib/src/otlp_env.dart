import 'dart:io';

import 'config.dart';

/// Reads OpenTelemetry-standard environment variables (and legacy aliases).
abstract final class OtlpEnv {
  static const otelSdkDisabled = 'OTEL_SDK_DISABLED';
  static const otelServiceName = 'OTEL_SERVICE_NAME';
  static const otelServiceVersion = 'OTEL_SERVICE_VERSION';
  static const otelResourceAttributes = 'OTEL_RESOURCE_ATTRIBUTES';
  static const otelExporterOtlpEndpoint = 'OTEL_EXPORTER_OTLP_ENDPOINT';
  static const otelExporterOtlpTracesEndpoint = 'OTEL_EXPORTER_OTLP_TRACES_ENDPOINT';
  static const otelExporterOtlpMetricsEndpoint = 'OTEL_EXPORTER_OTLP_METRICS_ENDPOINT';
  static const otelMetricsExporter = 'OTEL_METRICS_EXPORTER';
  static const otelTracesExporter = 'OTEL_TRACES_EXPORTER';

  /// Legacy / project-specific (still supported).
  static const legacyOtlpEndpoint = 'OTLP_ENDPOINT';
  static const legacySkywalkingOtlpEndpoint = 'SKYWALKING_OTLP_ENDPOINT';
  static const legacyServiceName = 'SERVICE_NAME';
  static const legacySkywalkingServiceName = 'SKYWALKING_SERVICE_NAME';

  static bool sdkDisabledFromEnvironment() {
    final v = _env(otelSdkDisabled)?.toLowerCase();
    return v == 'true' || v == '1';
  }

  static Map<String, String> resourceAttributesFromEnvironment() {
    final raw = _env(otelResourceAttributes);
    if (raw == null || raw.isEmpty) return {};
    final out = <String, String>{};
    for (final part in raw.split(',')) {
      final piece = part.trim();
      if (piece.isEmpty) continue;
      final eq = piece.indexOf('=');
      if (eq <= 0) continue;
      out[piece.substring(0, eq).trim()] = piece.substring(eq + 1).trim();
    }
    return out;
  }

  static String? endpointFromEnvironment() {
    for (final key in [
      otelExporterOtlpEndpoint,
      legacyOtlpEndpoint,
      legacySkywalkingOtlpEndpoint,
    ]) {
      final v = _env(key);
      if (v != null && v.isNotEmpty) return _stripTrailingSlash(v);
    }
    return null;
  }

  static String? tracesEndpointFromEnvironment() {
    final v = _env(otelExporterOtlpTracesEndpoint);
    if (v != null && v.isNotEmpty) return v;
    final base = endpointFromEnvironment();
    if (base == null) return null;
    return _joinUrl(base, '/v1/traces');
  }

  static String? metricsEndpointFromEnvironment() {
    final v = _env(otelExporterOtlpMetricsEndpoint);
    if (v != null && v.isNotEmpty) return v;
    final base = endpointFromEnvironment();
    if (base == null) return null;
    return _joinUrl(base, '/v1/metrics');
  }

  static String? serviceNameFromEnvironment({String fallback = 'unknown_service'}) {
    for (final key in [
      otelServiceName,
      legacyServiceName,
      legacySkywalkingServiceName,
    ]) {
      final v = _env(key);
      if (v != null && v.isNotEmpty) return v;
    }
    return fallback;
  }

  static String? serviceVersionFromEnvironment() => _env(otelServiceVersion);

  static bool metricsDisabledFromEnvironment() {
    final exporter = _env(otelMetricsExporter)?.toLowerCase();
    return exporter == 'none';
  }

  static bool tracesDisabledFromEnvironment() {
    final exporter = _env(otelTracesExporter)?.toLowerCase();
    return exporter == 'none';
  }

  /// Build config from environment + optional compile-time [dartDefines] overrides.
  static OtlpExporterConfig resolveConfig({
    Map<String, String> dartDefines = const {},
    String defaultEndpoint = 'http://127.0.0.1:12800',
    String defaultServiceName = 'unknown_service',
    bool defaultMetricsEnabled = true,
  }) {
    String pick(String key, String? fromEnv, String fallback) {
      final d = dartDefines[key]?.trim();
      if (d != null && d.isNotEmpty) return d;
      if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
      return fallback;
    }

    final endpoint = pick(
      legacyOtlpEndpoint,
      endpointFromEnvironment(),
      defaultEndpoint,
    );

    final serviceName = pick(
      otelServiceName,
      serviceNameFromEnvironment(fallback: defaultServiceName),
      defaultServiceName,
    );

    final serviceVersion = pick(
      otelServiceVersion,
      serviceVersionFromEnvironment(),
      'unknown',
    );

    final metricsOff = metricsDisabledFromEnvironment();
    final tracesOff = tracesDisabledFromEnvironment();

    return OtlpExporterConfig(
      serviceName: serviceName,
      otlpEndpoint: endpoint,
      serviceVersion: serviceVersion,
      resourceAttributes: resourceAttributesFromEnvironment(),
      tracesEnabled: !tracesOff,
      metricsEnabled: defaultMetricsEnabled && !metricsOff,
      tracesEndpoint: tracesEndpointFromEnvironment(),
      metricsEndpoint: metricsEndpointFromEnvironment(),
    );
  }

  static String? _env(String key) {
    final v = Platform.environment[key]?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  static String _stripTrailingSlash(String url) =>
      url.replaceAll(RegExp(r'/+$'), '');

  static String _joinUrl(String base, String path) {
    final b = _stripTrailingSlash(base);
    if (path.startsWith('/')) return '$b$path';
    return '$b/$path';
  }
}
