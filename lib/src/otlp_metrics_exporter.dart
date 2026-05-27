import 'dart:async';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'otlp_attribute.dart';
import 'otlp_http_sender.dart';

/// Pending OTLP metric sample.
class OtlpMetricSample {
  OtlpMetricSample({
    required this.name,
    required this.kind,
    required this.value,
    this.attributes = const {},
    this.unit = '',
  });

  final String name;
  final OtlpMetricKind kind;
  final double value;
  final Map<String, String> attributes;
  final String unit;
}

enum OtlpMetricKind { counter, histogram }

/// Default histogram buckets for latency in milliseconds (OTel-style explicit bounds).
const List<double> kOtlpDefaultHistogramBoundsMs = [
  0,
  5,
  10,
  25,
  50,
  75,
  100,
  250,
  500,
  750,
  1000,
  2500,
  5000,
  7500,
  10000,
];

/// Exports metrics via OTLP/HTTP JSON (`POST /v1/metrics`).
class OtlpMetricsExporter {
  OtlpMetricsExporter(
    this.config, {
    http.Client? httpClient,
    OtlpHttpSender? sender,
    List<double>? histogramBoundsMs,
  })  : _sender = sender ?? OtlpHttpSender(client: httpClient),
        _histogramBoundsMs = histogramBoundsMs ?? kOtlpDefaultHistogramBoundsMs;

  final OtlpExporterConfig config;
  final OtlpHttpSender _sender;
  final List<double> _histogramBoundsMs;

  final List<OtlpMetricSample> _queue = [];
  Timer? _timer;
  bool _closed = false;

  void start() {
    _timer ??= Timer.periodic(config.flushInterval, (_) => flush());
  }

  void recordCounter(
    String name, {
    int delta = 1,
    Map<String, String> attributes = const {},
    String unit = '1',
  }) {
    if (_closed || delta == 0) return;
    _queue.add(
      OtlpMetricSample(
        name: name,
        kind: OtlpMetricKind.counter,
        value: delta.toDouble(),
        attributes: attributes,
        unit: unit,
      ),
    );
  }

  void recordHistogram(
    String name,
    double value, {
    Map<String, String> attributes = const {},
    String unit = 'ms',
  }) {
    if (_closed) return;
    _queue.add(
      OtlpMetricSample(
        name: name,
        kind: OtlpMetricKind.histogram,
        value: value,
        attributes: attributes,
        unit: unit,
      ),
    );
  }

  @Deprecated('Use recordHistogram')
  void recordHistogramMs(
    String name,
    double milliseconds, {
    Map<String, String> attributes = const {},
  }) =>
      recordHistogram(name, milliseconds, attributes: attributes, unit: 'ms');

  Map<String, Object?> buildExportPayload(List<OtlpMetricSample> samples) {
    final grouped = <String, List<OtlpMetricSample>>{};
    for (final s in samples) {
      grouped.putIfAbsent(s.name, () => []).add(s);
    }

    final metrics = <Map<String, Object?>>[];
    for (final entry in grouped.entries) {
      final first = entry.value.first;
      if (first.kind == OtlpMetricKind.counter) {
        metrics.add(_buildSumMetric(entry.key, entry.value));
      } else {
        metrics.add(_buildHistogramMetric(entry.key, entry.value));
      }
    }

    return {
      'resourceMetrics': [
        {
          'resource': {'attributes': config.resource.toOtlpAttributes()},
          'scopeMetrics': [
            {
              'scope': {
                'name': config.instrumentationScopeName,
                'version': config.instrumentationScopeVersion,
              },
              'metrics': metrics,
            },
          ],
        },
      ],
    };
  }

  Map<String, Object?> _buildSumMetric(String name, List<OtlpMetricSample> samples) {
    final points = <Map<String, Object?>>[];
    final nowNano = DateTime.now().microsecondsSinceEpoch * 1000;
    final unit = samples.first.unit.isEmpty ? '1' : samples.first.unit;
    for (final s in samples) {
      points.add({
        'timeUnixNano': nowNano.toString(),
        'asInt': s.value.round().toString(),
        'attributes': OtlpAttribute.fromMap(s.attributes),
      });
    }
    return {
      'name': name,
      'unit': unit,
      'sum': {
        'aggregationTemporality': 1,
        'isMonotonic': true,
        'dataPoints': points,
      },
    };
  }

  Map<String, Object?> _buildHistogramMetric(
    String name,
    List<OtlpMetricSample> samples,
  ) {
    final points = <Map<String, Object?>>[];
    final nowNano = DateTime.now().microsecondsSinceEpoch * 1000;
    final unit = samples.first.unit.isEmpty ? '1' : samples.first.unit;
    for (final s in samples) {
      points.add({
        'timeUnixNano': nowNano.toString(),
        'count': '1',
        'sum': s.value,
        'explicitBounds': _histogramBoundsMs,
        'bucketCounts': _histogramBuckets(s.value),
        'attributes': OtlpAttribute.fromMap(s.attributes),
      });
    }
    return {
      'name': name,
      'unit': unit,
      'histogram': {
        'aggregationTemporality': 1,
        'dataPoints': points,
      },
    };
  }

  List<int> _histogramBuckets(double value) {
    final counts = List<int>.filled(_histogramBoundsMs.length + 1, 0);
    var idx = _histogramBoundsMs.length;
    for (var i = 0; i < _histogramBoundsMs.length; i++) {
      if (value <= _histogramBoundsMs[i]) {
        idx = i;
        break;
      }
    }
    counts[idx] = 1;
    return counts;
  }

  Future<bool> flush() async {
    if (_closed || _queue.isEmpty) return true;
    final batch = List<OtlpMetricSample>.from(_queue);
    _queue.clear();
    return exportNow(batch);
  }

  Future<bool> exportNow(List<OtlpMetricSample> samples) async {
    if (samples.isEmpty) return true;
    final result = await _sender.postJson(
      config.metricsUrl,
      buildExportPayload(samples),
    );
    return result.success;
  }

  Future<void> close() async {
    _closed = true;
    _timer?.cancel();
    await flush();
    _sender.close();
  }
}
