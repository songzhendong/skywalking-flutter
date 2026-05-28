import 'semconv.dart';

/// OTLP span kinds (OpenTelemetry SpanKind enum values).
enum OtlpSpanKind {
  internal(1),
  server(2),
  client(3),
  producer(4),
  consumer(5);

  const OtlpSpanKind(this.value);
  final int value;
}

/// OTLP status codes (StatusCode enum values).
enum OtlpStatusCode {
  unset(0),
  ok(1),
  error(2);

  const OtlpStatusCode(this.value);
  final int value;
}

/// Span payload before export.
class OtlpSpanData {
  OtlpSpanData({
    required this.name,
    required this.startTimeUnixNano,
    required this.endTimeUnixNano,
    required this.traceId,
    required this.spanId,
    this.parentSpanId,
    this.kind = OtlpSpanKind.internal,
    this.statusCode = OtlpStatusCode.unset,
    this.attributes = const {},
  });

  final String name;
  final int startTimeUnixNano;
  final int endTimeUnixNano;
  final String traceId;
  final String spanId;
  final String? parentSpanId;
  final OtlpSpanKind kind;
  final OtlpStatusCode statusCode;
  final Map<String, String> attributes;
}

/// Active span handle (manual instrumentation).
class OtlpSpan {
  OtlpSpan({
    required this.name,
    required this.traceId,
    required this.spanId,
    required this.kind,
    required this.startTime,
    this.parentSpanId,
    Map<String, String>? attributes,
  }) : attributes = attributes ?? {};

  final String name;
  final String traceId;
  final String spanId;
  final String? parentSpanId;
  final OtlpSpanKind kind;
  final DateTime startTime;
  final Map<String, String> attributes;

  OtlpStatusCode _status = OtlpStatusCode.unset;

  void setAttribute(String key, String value) => attributes[key] = value;

  void setStatus(OtlpStatusCode status) => _status = status;

  void recordException(Object error) {
    attributes[Semconv.exceptionType] = error.runtimeType.toString();
    attributes[Semconv.exceptionMessage] = error.toString();
    _status = OtlpStatusCode.error;
  }

  /// Finalize status (defaults unset → ok) and return export payload.
  OtlpSpanData finish({DateTime? endTime, OtlpStatusCode? status}) {
    if (status != null) {
      _status = status;
    } else if (_status == OtlpStatusCode.unset) {
      _status = OtlpStatusCode.ok;
    }
    return toData(endTime: endTime);
  }

  OtlpSpanData toData({DateTime? endTime}) {
    final end = endTime ?? DateTime.now();
    return OtlpSpanData(
      name: name,
      traceId: traceId,
      spanId: spanId,
      parentSpanId: parentSpanId,
      kind: kind,
      statusCode: _status,
      startTimeUnixNano: startTime.microsecondsSinceEpoch * 1000,
      endTimeUnixNano: end.microsecondsSinceEpoch * 1000,
      attributes: Map<String, String>.from(attributes),
    );
  }
}
