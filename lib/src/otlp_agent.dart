import 'package:http/http.dart' as http;

import 'config.dart';
import 'instrumented_client.dart';
import 'meter.dart';
import 'otlp_metrics_exporter.dart';
import 'otlp_span.dart';
import 'otlp_trace_exporter.dart';
import 'tracer.dart';

/// OpenTelemetry OTLP agent for Dart / Flutter (traces + metrics over HTTP JSON).
class OtlpAgent {
  OtlpAgent._(this.config, this._traces, this._metrics);

  static OtlpAgent? _instance;

  final OtlpExporterConfig config;
  final OtlpTraceExporter? _traces;
  final OtlpMetricsExporter? _metrics;
  OtlpTracer? _tracer;
  OtlpMeter? _meter;

  /// Initialize the global agent.
  static OtlpAgent init(OtlpExporterConfig config, {http.Client? httpClient}) {
    if (_instance != null) {
      return _instance!;
    }
    OtlpTraceExporter? traces;
    OtlpMetricsExporter? metrics;
    if (config.tracesEnabled) {
      traces = OtlpTraceExporter(config, httpClient: httpClient);
      traces.start();
    }
    if (config.metricsEnabled) {
      metrics = OtlpMetricsExporter(config, httpClient: httpClient);
      metrics.start();
    }
    if (traces == null && metrics == null) {
      throw ArgumentError(
        'At least one of tracesEnabled or metricsEnabled must be true',
      );
    }
    _instance = OtlpAgent._(config, traces, metrics);
    return _instance!;
  }

  static OtlpAgent initFromEnvironment({
    Map<String, String> dartDefines = const {},
    String defaultEndpoint = 'http://127.0.0.1:12800',
    String defaultServiceName = 'unknown_service',
    http.Client? httpClient,
  }) =>
      init(
        OtlpExporterConfig.fromEnvironment(
          dartDefines: dartDefines,
          defaultEndpoint: defaultEndpoint,
          defaultServiceName: defaultServiceName,
        ),
        httpClient: httpClient,
      );

  static OtlpAgent get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('Call OtlpAgent.init() before using the agent.');
    }
    return i;
  }

  static bool get isInitialized => _instance != null;

  OtlpTracer get tracer {
    final t = _traces;
    if (t == null) {
      throw StateError('Traces export is disabled in config');
    }
    return _tracer ??= OtlpTracer(t);
  }

  OtlpMeter get meter {
    final m = _metrics;
    if (m == null) {
      throw StateError('Metrics export is disabled in config');
    }
    return _meter ??= OtlpMeter(m);
  }

  OtlpTraceExporter get traceExporter {
    final t = _traces;
    if (t == null) {
      throw StateError('Traces export is disabled in config');
    }
    return t;
  }

  OtlpMetricsExporter? get metricsExporter => _metrics;

  @Deprecated('Use traceExporter')
  OtlpTraceExporter get exporter => traceExporter;

  InstrumentedClient httpClient({http.Client? inner}) {
    return InstrumentedClient(
      exporter: traceExporter,
      meter: _metrics != null ? meter : null,
      inner: inner ?? http.Client(),
    );
  }

  @Deprecated('Use tracer.recordEvent')
  void trackEvent({
    required String name,
    required Duration duration,
    Map<String, String> attributes = const {},
    OtlpStatusCode status = OtlpStatusCode.ok,
    OtlpSpanKind kind = OtlpSpanKind.internal,
  }) {
    tracer.recordSpan(
      name: name,
      duration: duration,
      kind: kind,
      attributes: attributes,
      status: status,
    );
  }

  @Deprecated('Use tracer.withSpan')
  Future<T> trace<T>(
    String name,
    Future<T> Function() action, {
    Map<String, String> attributes = const {},
  }) =>
      tracer.withSpan(name, (_) => action(), attributes: attributes);

  @Deprecated('Use meter.addCounter')
  void addCounter(
    String name, {
    int delta = 1,
    Map<String, String> attributes = const {},
  }) =>
      meter.addCounter(name, delta: delta, attributes: attributes);

  @Deprecated('Use meter.recordDuration')
  void recordHistogramMs(
    String name,
    double milliseconds, {
    Map<String, String> attributes = const {},
  }) =>
      meter.recordHistogramMs(name, milliseconds, attributes: attributes);

  Future<void> flush() async {
    await _traces?.flush();
    await _metrics?.flush();
  }

  Future<void> shutdown() async {
    await _traces?.close();
    await _metrics?.close();
    _instance = null;
  }
}
