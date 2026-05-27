import 'otlp_attribute.dart';
import 'otlp_span.dart';
import 'otlp_trace_exporter.dart';
import 'semconv.dart';

/// Trace API (OpenTelemetry Tracer-like).
class OtlpTracer {
  OtlpTracer(this._exporter);

  final OtlpTraceExporter _exporter;

  OtlpSpan startSpan(
    String name, {
    OtlpSpanKind kind = OtlpSpanKind.internal,
    String? traceId,
    String? parentSpanId,
    Map<String, String> attributes = const {},
  }) {
    return OtlpSpan(
      name: name,
      traceId: traceId ?? _exporter.idGenerator.traceId(),
      spanId: _exporter.idGenerator.spanId(),
      parentSpanId: parentSpanId,
      kind: kind,
      startTime: DateTime.now(),
      attributes: Map<String, String>.from(attributes),
    );
  }

  void endSpan(OtlpSpan span, {OtlpStatusCode? status}) {
    _exporter.enqueue(span.finish(status: status));
  }

  /// Record a completed span (fire-and-forget).
  void recordSpan({
    required String name,
    required Duration duration,
    OtlpSpanKind kind = OtlpSpanKind.internal,
    Map<String, String> attributes = const {},
    OtlpStatusCode status = OtlpStatusCode.ok,
    String? traceId,
    String? spanId,
    String? parentSpanId,
  }) {
    final end = DateTime.now();
    final start = end.subtract(duration);
    _exporter.enqueue(
      OtlpSpanData(
        name: name,
        startTimeUnixNano: start.microsecondsSinceEpoch * 1000,
        endTimeUnixNano: end.microsecondsSinceEpoch * 1000,
        traceId: traceId ?? _exporter.idGenerator.traceId(),
        spanId: spanId ?? _exporter.idGenerator.spanId(),
        parentSpanId: parentSpanId,
        kind: kind,
        statusCode: status,
        attributes: attributes,
      ),
    );
  }

  Future<T> withSpan<T>(
    String name,
    Future<T> Function(OtlpSpan span) action, {
    OtlpSpanKind kind = OtlpSpanKind.internal,
    Map<String, String> attributes = const {},
    String? parentSpanId,
  }) async {
    final span = startSpan(
      name,
      kind: kind,
      parentSpanId: parentSpanId,
      attributes: attributes,
    );
    try {
      final result = await action(span);
      endSpan(span, status: OtlpStatusCode.ok);
      return result;
    } catch (e, st) {
      span.recordException(e);
      endSpan(span);
      Error.throwWithStackTrace(e, st);
    }
  }

  @Deprecated('Use withSpan')
  Future<T> trace<T>(
    String name,
    Future<T> Function() action, {
    Map<String, String> attributes = const {},
  }) =>
      withSpan(name, (_) => action(), attributes: attributes);

  /// Business / UI event (`event.name` semantic attribute).
  void recordEvent({
    required String name,
    Duration duration = Duration.zero,
    Map<String, String> attributes = const {},
    OtlpStatusCode status = OtlpStatusCode.ok,
  }) {
    recordSpan(
      name: name,
      duration: duration,
      kind: OtlpSpanKind.internal,
      status: status,
      attributes: OtlpAttribute.merge({Semconv.eventName: name}, attributes),
    );
  }
}
