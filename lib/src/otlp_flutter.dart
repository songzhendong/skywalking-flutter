import 'package:flutter/foundation.dart';

import 'config.dart';
import 'otlp_agent.dart';

/// Flutter 便捷初始化（读取 `--dart-define` / `OTEL_*`）。
abstract final class OtlpFlutter {
  OtlpFlutter._();

  /// `SKYWALKING_ENABLED=false` 或 `OTEL_SDK_DISABLED=true` 时关闭。
  static const enabled = bool.fromEnvironment(
    'SKYWALKING_ENABLED',
    defaultValue: true,
  );

  static const _sdkDisabled = bool.fromEnvironment(
    'OTEL_SDK_DISABLED',
    defaultValue: false,
  );

  static const _metricsFlag = bool.fromEnvironment(
    'SKYWALKING_METRICS_ENABLED',
    defaultValue: true,
  );

  /// 是否应启动 Agent（仅看编译期开关；endpoint 是否为空由调用方判断）。
  static bool get shouldInitialize => enabled && !_sdkDisabled;

  /// 从 `--dart-define` 构建配置（Flutter 推荐）。
  static OtlpExporterConfig configFromDartDefines({
    String defaultEndpoint = 'http://127.0.0.1:12800',
    String defaultServiceName = 'flutter-app',
    String defaultEnvironment = 'production',
    String defaultServiceVersion = '1.0.0',
    Duration flushInterval = const Duration(seconds: 5),
  }) {
    final endpoint = _pickEndpoint(defaultEndpoint);
    final serviceName = _pick(
      const [
        'OTEL_SERVICE_NAME',
        'SKYWALKING_SERVICE_NAME',
        'SERVICE_NAME',
      ],
      defaultServiceName,
    );
    final serviceVersion = _pick(
      const ['OTEL_SERVICE_VERSION', 'SKYWALKING_SERVICE_VERSION'],
      defaultServiceVersion,
    );
    final deploymentEnvironment = _pick(
      const ['SKYWALKING_ENV', 'DEPLOYMENT_ENVIRONMENT'],
      defaultEnvironment,
    );
    final metricsEnabled = _metricsFlag &&
        !_isFalse(const ['OTEL_METRICS_EXPORTER'], 'none');

    return OtlpExporterConfig(
      serviceName: serviceName,
      otlpEndpoint: endpoint,
      serviceVersion: serviceVersion,
      deploymentEnvironment: deploymentEnvironment,
      flushInterval: flushInterval,
      metricsEnabled: metricsEnabled,
      tracesEnabled: !_isFalse(const ['OTEL_TRACES_EXPORTER'], 'none'),
    );
  }

  /// 初始化全局 [OtlpAgent]；已初始化则返回现有实例；禁用时返回 `null`。
  static OtlpAgent? init({
    String defaultEndpoint = 'http://127.0.0.1:12800',
    String defaultServiceName = 'flutter-app',
    String defaultEnvironment = 'production',
    String defaultServiceVersion = '1.0.0',
    Duration flushInterval = const Duration(seconds: 5),
    bool logConfig = kDebugMode,
  }) {
    if (!shouldInitialize) return null;
    if (OtlpAgent.isInitialized) return OtlpAgent.instance;

    final config = configFromDartDefines(
      defaultEndpoint: defaultEndpoint,
      defaultServiceName: defaultServiceName,
      defaultEnvironment: defaultEnvironment,
      defaultServiceVersion: defaultServiceVersion,
      flushInterval: flushInterval,
    );
    if (config.otlpEndpoint.trim().isEmpty) return null;

    if (logConfig) {
      debugPrint(
        '[skywalking_flutter] endpoint=${config.otlpEndpoint} '
        'service=${config.serviceName} traces=${config.tracesEnabled} '
        'metrics=${config.metricsEnabled}',
      );
    }
    return OtlpAgent.init(config);
  }

  static String _pickEndpoint(String fallback) {
    for (final key in const [
      'OTEL_EXPORTER_OTLP_ENDPOINT',
      'SKYWALKING_OTLP_ENDPOINT',
      'OTLP_ENDPOINT',
    ]) {
      final v = String.fromEnvironment(key);
      if (v.trim().isNotEmpty) return v.trim();
    }
    return fallback;
  }

  static String _pick(List<String> keys, String fallback) {
    for (final key in keys) {
      final v = String.fromEnvironment(key);
      if (v.trim().isNotEmpty) return v.trim();
    }
    return fallback;
  }

  static bool _isFalse(List<String> keys, String offValue) {
    for (final key in keys) {
      final v = String.fromEnvironment(key).toLowerCase();
      if (v == offValue) return true;
    }
    return false;
  }
}
