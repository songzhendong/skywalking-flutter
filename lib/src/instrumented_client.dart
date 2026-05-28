import 'package:http/http.dart' as http;

import 'meter.dart';
import 'otlp_span.dart';
import 'otlp_trace_exporter.dart';
import 'semconv.dart';

/// [http.Client] that exports OTLP CLIENT spans per request (HTTP semantic conventions).
class InstrumentedClient extends http.BaseClient {
  /// Wraps [inner] and records one CLIENT span per HTTP call via [exporter].
  InstrumentedClient({
    required this.exporter,
    required http.Client inner,
    this.meter,
  }) : _inner = inner;

  /// Trace exporter used to build and enqueue spans for each request.
  final OtlpTraceExporter exporter;
  final http.Client _inner;
  final OtlpMeter? meter;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final traceId = exporter.idGenerator.traceId();
    final spanId = exporter.idGenerator.spanId();
    final start = DateTime.now();
    final path = request.url.path.isEmpty ? '/' : request.url.path;
    final spanName = Semconv.httpSpanName(request.method, path);

    try {
      final streamed = await _inner.send(request);
      final bytes = await streamed.stream.toBytes();
      final response = http.Response.bytes(
        bytes,
        streamed.statusCode,
        headers: streamed.headers,
        request: streamed.request,
        isRedirect: streamed.isRedirect,
        persistentConnection: streamed.persistentConnection,
        reasonPhrase: streamed.reasonPhrase,
      );
      final elapsed = DateTime.now().difference(start);
      _record(
        name: spanName,
        request: request,
        traceId: traceId,
        spanId: spanId,
        start: start,
        end: DateTime.now(),
        statusCode: response.statusCode,
      );
      _recordHttpMetrics(request, response.statusCode, elapsed);
      return http.StreamedResponse(
        Stream.value(bytes),
        response.statusCode,
        headers: response.headers,
        request: response.request,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e) {
      final elapsed = DateTime.now().difference(start);
      _record(
        name: spanName,
        request: request,
        traceId: traceId,
        spanId: spanId,
        start: start,
        end: DateTime.now(),
        statusCode: 0,
        error: e,
      );
      _recordHttpMetrics(request, 0, elapsed, error: true);
      rethrow;
    }
  }

  void _recordHttpMetrics(
    http.BaseRequest request,
    int statusCode,
    Duration elapsed, {
    bool error = false,
  }) {
    final m = meter;
    if (m == null) return;
    final path = request.url.path.isEmpty ? '/' : request.url.path;
    final status = error ? 'error' : (statusCode >= 500
        ? '5xx'
        : statusCode >= 400
            ? '4xx'
            : 'ok');
    final attrs = <String, String>{
      Semconv.httpRequestMethod: request.method.toUpperCase(),
      Semconv.urlPath: path,
      Semconv.httpResponseStatusCode: statusCode.toString(),
      'http.response.status_class': status,
    };
    m.addCounter(Semconv.metricHttpClientRequests, attributes: attrs);
    m.recordDuration(
      Semconv.metricHttpClientRequestDuration,
      elapsed,
      attributes: attrs,
    );
  }

  void _record({
    required String name,
    required http.BaseRequest request,
    required String traceId,
    required String spanId,
    required DateTime start,
    required DateTime end,
    required int statusCode,
    Object? error,
  }) {
    final attrs = Semconv.httpClientAttributes(
      method: request.method,
      url: request.url,
      statusCode: statusCode,
    );
    if (error != null) {
      attrs[Semconv.exceptionType] = error.runtimeType.toString();
      attrs[Semconv.exceptionMessage] = error.toString();
    }
    exporter.enqueue(
      OtlpSpanData(
        name: name,
        traceId: traceId,
        spanId: spanId,
        startTimeUnixNano: start.microsecondsSinceEpoch * 1000,
        endTimeUnixNano: end.microsecondsSinceEpoch * 1000,
        kind: OtlpSpanKind.client,
        statusCode: error != null || statusCode >= 500
            ? OtlpStatusCode.error
            : OtlpStatusCode.ok,
        attributes: attrs,
      ),
    );
  }

  @override
  void close() {
    _inner.close();
  }
}
