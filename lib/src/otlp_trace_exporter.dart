import 'dart:async';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'id_generator.dart';
import 'otlp_attribute.dart';
import 'otlp_http_sender.dart';
import 'otlp_span.dart';

/// Exports spans via OTLP/HTTP JSON (`POST /v1/traces`).
class OtlpTraceExporter {
  OtlpTraceExporter(
    this.config, {
    http.Client? httpClient,
    IdGenerator? idGenerator,
    OtlpHttpSender? sender,
  })  : _ids = idGenerator ?? IdGenerator(),
        _sender = sender ?? OtlpHttpSender(client: httpClient);

  final OtlpExporterConfig config;
  final IdGenerator _ids;
  final OtlpHttpSender _sender;

  final List<OtlpSpanData> _queue = [];
  Timer? _timer;
  bool _closed = false;

  IdGenerator get idGenerator => _ids;

  void start() {
    _timer ??= Timer.periodic(config.flushInterval, (_) => flush());
  }

  void enqueue(OtlpSpanData span) {
    if (_closed) return;
    _queue.add(span);
    if (_queue.length >= config.maxBatchSize) {
      unawaited(flush());
    }
  }

  Map<String, Object?> buildExportPayload(List<OtlpSpanData> spans) {
    return {
      'resourceSpans': [
        {
          'resource': {'attributes': config.resource.toOtlpAttributes()},
          'scopeSpans': [
            {
              'scope': {
                'name': config.instrumentationScopeName,
                'version': config.instrumentationScopeVersion,
              },
              'spans': spans.map(_spanToJson).toList(),
            },
          ],
        },
      ],
    };
  }

  Future<bool> flush() async {
    if (_closed || _queue.isEmpty) return true;
    final batch = List<OtlpSpanData>.from(_queue);
    _queue.clear();
    return exportNow(batch);
  }

  Future<bool> exportNow(List<OtlpSpanData> spans) async {
    if (spans.isEmpty) return true;
    final result = await _sender.postJson(
      config.tracesUrl,
      buildExportPayload(spans),
    );
    return result.success;
  }

  Future<void> close() async {
    _closed = true;
    _timer?.cancel();
    await flush();
    _sender.close();
  }

  Map<String, Object?> _spanToJson(OtlpSpanData span) {
    final json = <String, Object?>{
      'traceId': span.traceId,
      'spanId': span.spanId,
      'name': span.name,
      'kind': span.kind.value,
      'startTimeUnixNano': span.startTimeUnixNano.toString(),
      'endTimeUnixNano': span.endTimeUnixNano.toString(),
      'status': {'code': span.statusCode.value},
      'attributes': OtlpAttribute.fromMap(span.attributes),
    };
    if (span.parentSpanId != null && span.parentSpanId!.isNotEmpty) {
      json['parentSpanId'] = span.parentSpanId;
    }
    return json;
  }

  @Deprecated('Use OtlpAttribute.string')
  static Map<String, Object?> attr(String key, String value) =>
      OtlpAttribute.string(key, value);
}
