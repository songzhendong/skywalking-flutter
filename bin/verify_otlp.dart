import 'dart:io';
import 'dart:math';

import 'package:skywalking_flutter/skywalking_flutter.dart';

/// OTLP 全量冒烟：多类 Metrics + 多类 Trace，默认连续约 12 分钟（跨多个 MINUTE 桶）。
///
/// ```powershell
/// $env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:12800"
/// $env:OTEL_SERVICE_NAME = "xt-open-app"
/// dart run bin/verify_otlp.dart
/// ```

final _rng = Random();

const _httpPaths = <String>[
  '/xt/app/feed/list',
  '/xt/app/user/profile',
  '/xt/app/video/detail',
  '/xt/auth/sms/send',
  '/xt/app/search/query',
];

const _screens = <String>['home', 'feed', 'search', 'me', 'publish'];

/// Inspect 可添加的 `meter_flutter_*`（OAP 须加载 `flutter-otlp` 规则并重启）。
const _inspectMetrics = <String>[
  'meter_flutter_verify_events_total',
  'meter_flutter_http_requests_rpm',
  'meter_flutter_http_latency_avg_ms',
  'meter_flutter_screen_views_total',
  'meter_flutter_lifecycle_events_total',
  'meter_flutter_session_start_total',
  'meter_flutter_auth_login_total',
  'meter_flutter_feed_prefetch_total',
  'meter_flutter_feed_prefetch_duration_avg_ms',
  'meter_flutter_video_play_total',
  'meter_flutter_video_duration_avg_ms',
  'meter_flutter_search_total',
  'meter_flutter_search_duration_avg_ms',
  'meter_flutter_cold_start_duration_avg_ms',
  'meter_flutter_exception_count_total',
];

Future<void> main(List<String> args) async {
  if (OtlpEnv.sdkDisabledFromEnvironment()) {
    // ignore: avoid_print
    print('SKIP: OTEL_SDK_DISABLED is set');
    return;
  }

  final opts = _VerifyOptions.parse(args);
  final config = OtlpExporterConfig.fromEnvironment(
    defaultEndpoint: 'http://127.0.0.1:12800',
    defaultServiceName: 'flutter-otlp-verify',
  );

  final agent = OtlpAgent.init(
    config.copyWith(flushInterval: const Duration(seconds: 1)),
  );

  final estMin = ((opts.rounds - 1) * opts.intervalSec / 60).ceil() + 1;
  // ignore: avoid_print
  print(
    'OTLP ${config.otlpEndpoint} service=${config.serviceName} '
    'mode=${opts.quick ? "quick" : "continuous"} '
    'rounds=${opts.rounds} interval=${opts.intervalSec}s burst=${opts.burst} '
    '(~${estMin}min) ...',
  );

  var traceOk = true;
  if (opts.quick) {
    await _emitRound(agent, roundIndex: 0, burst: 1, fullSuite: true);
    traceOk = await _exportImmediateSpan(agent);
  } else {
    for (var i = 0; i < opts.rounds; i++) {
      await _emitRound(agent, roundIndex: i, burst: opts.burst, fullSuite: true);
      if ((i + 1) % 3 == 0) {
        final ok = await _exportImmediateSpan(agent, tag: 'round-${i + 1}');
        traceOk = traceOk && ok;
      }
      // ignore: avoid_print
      print('  round ${i + 1}/${opts.rounds} ok (traces+metrics flushed)');
      if (i < opts.rounds - 1) {
        await Future<void>.delayed(Duration(seconds: opts.intervalSec));
      }
    }
  }

  await agent.flush();
  await agent.shutdown();

  if (traceOk) {
    // ignore: avoid_print
    print('OK: OTLP export finished.');
    // ignore: avoid_print
    print('Metrics inspect (MAL-OTEL → flutter-otlp):');
    for (final m in _inspectMetrics) {
      // ignore: avoid_print
      print('  - $m');
    }
    // ignore: avoid_print
    print(
      'Zipkin: verify.*, app.cold_start tree, screen.*, auth.sms_send, '
      'GET/POST /xt/..., video.play',
    );
  } else {
    // ignore: avoid_print
    print('FAIL: trace export failed. Is OAP on ${config.otlpEndpoint}?');
    exitCode = 1;
  }
}

Future<void> _emitRound(
  OtlpAgent agent, {
  required int roundIndex,
  required int burst,
  required bool fullSuite,
}) async {
  final tracer = agent.tracer;
  final meter = agent.meter;

  final bootstrapMs = 50 + _rng.nextInt(180);
  await tracer.withSpan(
    'verify.bootstrap',
    (_) async {
      await Future<void>.delayed(Duration(milliseconds: bootstrapMs ~/ 5));
    },
    attributes: {'verify.round': '$roundIndex'},
  );

  if (fullSuite) {
    final treeTraceId = _emitColdStartTraceTree(tracer, roundIndex);
    // ignore: avoid_print
    print('    trace tree: $treeTraceId (4 spans, root=app.cold_start)');
    _emitScreenAndAuthTraces(tracer, roundIndex);
  }

  for (var b = 0; b < burst; b++) {
    tracer.recordEvent(
      name: 'verify.custom_event',
      duration: Duration(milliseconds: 6 + _rng.nextInt(30)),
      attributes: {
        'source': 'verify_otlp.dart',
        'verify.round': '$roundIndex',
        'verify.burst': '$b',
      },
    );
    meter.addCounter(
      'verify.events_total',
      delta: 1 + _rng.nextInt(2),
      attributes: {'event': 'custom', 'round': '$roundIndex'},
    );
  }
  meter.recordDuration(
    'verify.bootstrap.duration',
    Duration(milliseconds: bootstrapMs),
    attributes: {'verify.round': '$roundIndex'},
  );

  if (!fullSuite) {
    await agent.flush();
    return;
  }

  meter.addCounter(
    'app.lifecycle.events',
    attributes: {'event': roundIndex.isEven ? 'foreground' : 'background'},
  );
  meter.addCounter(
    'app.screen.views',
    attributes: {Semconv.screenName: _screens[roundIndex % _screens.length]},
  );
  if (roundIndex == 0 || roundIndex % 4 == 0) {
    meter.addCounter('app.session.start');
    meter.recordDuration(
      'app.cold_start.duration',
      Duration(milliseconds: 800 + _rng.nextInt(1200)),
    );
  }

  meter.addCounter('app.auth.login', attributes: {'result': 'ok'});
  meter.addCounter('app.feed.prefetch', attributes: {'channel': 'home'});
  meter.recordDuration(
    'app.feed.prefetch.duration',
    Duration(milliseconds: 120 + _rng.nextInt(400)),
  );
  meter.addCounter('app.video.play', attributes: {'source': 'feed'});
  meter.recordDuration(
    'app.video.duration',
    Duration(milliseconds: 2000 + _rng.nextInt(8000)),
  );
  meter.addCounter('app.search', attributes: {'tab': 'all'});
  meter.recordDuration(
    'app.search.duration',
    Duration(milliseconds: 80 + _rng.nextInt(350)),
  );

  if (_rng.nextDouble() < 0.15) {
    meter.addCounter(Semconv.metricExceptions, attributes: {'type': 'smoke'});
    tracer.recordEvent(
      name: 'exception',
      duration: const Duration(milliseconds: 2),
      status: OtlpStatusCode.error,
      attributes: {
        Semconv.exceptionType: 'SmokeException',
        Semconv.exceptionMessage: 'intentional smoke round=$roundIndex',
      },
    );
  }

  final httpCalls = 2 + _rng.nextInt(2);
  for (var h = 0; h < httpCalls; h++) {
    final path = _httpPaths[(roundIndex + h) % _httpPaths.length];
    final method = h.isEven ? 'GET' : 'POST';
    await _emitHttpClient(
      tracer,
      meter,
      method: method,
      path: path,
      roundIndex: roundIndex,
    );
  }

  await agent.flush();
}

String _emitColdStartTraceTree(OtlpTracer tracer, int roundIndex) {
  final root = tracer.startSpan('app.cold_start', kind: OtlpSpanKind.server);
  final traceId = root.traceId;
  final rootId = root.spanId;

  tracer.recordSpan(
    name: 'app.bootstrap.config',
    duration: Duration(milliseconds: 30 + _rng.nextInt(80)),
    traceId: traceId,
    parentSpanId: rootId,
    attributes: {'verify.round': '$roundIndex'},
  );
  tracer.recordSpan(
    name: 'screen.home',
    duration: Duration(milliseconds: 20 + _rng.nextInt(50)),
    traceId: traceId,
    parentSpanId: rootId,
    attributes: {Semconv.screenName: 'home'},
  );
  tracer.recordSpan(
    name: 'feed.prefetch',
    duration: Duration(milliseconds: 15 + _rng.nextInt(40)),
    traceId: traceId,
    parentSpanId: rootId,
    kind: OtlpSpanKind.internal,
    attributes: {'channel': 'cold_start'},
  );
  tracer.endSpan(root);
  return traceId;
}

void _emitScreenAndAuthTraces(OtlpTracer tracer, int roundIndex) {
  final screen = _screens[(roundIndex + 1) % _screens.length];
  tracer.recordSpan(
    name: 'screen.$screen',
    duration: Duration(milliseconds: 40 + _rng.nextInt(120)),
    kind: OtlpSpanKind.internal,
    attributes: {Semconv.screenName: screen},
  );
  tracer.recordSpan(
    name: 'auth.sms_send',
    duration: Duration(milliseconds: 25 + _rng.nextInt(60)),
    attributes: {'verify.round': '$roundIndex'},
  );
  tracer.recordSpan(
    name: 'video.play',
    duration: Duration(milliseconds: 100 + _rng.nextInt(300)),
    attributes: {'video_id': 'smoke-$roundIndex'},
  );
}

Future<void> _emitHttpClient(
  OtlpTracer tracer,
  OtlpMeter meter, {
  required String method,
  required String path,
  required int roundIndex,
}) async {
  final latency = Duration(milliseconds: 35 + _rng.nextInt(280));
  final status = _rng.nextDouble() < 0.9 ? 200 : 503;
  final statusClass = status >= 500 ? '5xx' : 'ok';
  final attrs = <String, String>{
    Semconv.httpRequestMethod: method,
    Semconv.urlPath: path,
    Semconv.httpResponseStatusCode: '$status',
    'http.response.status_class': statusClass,
  };

  meter.addCounter(Semconv.metricHttpClientRequests, attributes: attrs);
  meter.recordDuration(
    Semconv.metricHttpClientRequestDuration,
    latency,
    attributes: attrs,
  );

  await tracer.withSpan(
    Semconv.httpSpanName(method, path),
    (_) async {
      await Future<void>.delayed(Duration(milliseconds: latency.inMilliseconds ~/ 6));
    },
    kind: OtlpSpanKind.client,
    attributes: {
      ...attrs,
      Semconv.urlScheme: 'https',
      Semconv.serverAddress: 'api.smoke.local',
      'verify.round': '$roundIndex',
    },
  );
}

Future<bool> _exportImmediateSpan(OtlpAgent agent, {String tag = 'final'}) {
  return agent.traceExporter.exportNow([
    OtlpSpanData(
      name: 'verify.immediate',
      traceId: agent.traceExporter.idGenerator.traceId(),
      spanId: agent.traceExporter.idGenerator.spanId(),
      startTimeUnixNano:
          DateTime.now()
                  .subtract(const Duration(milliseconds: 5))
                  .microsecondsSinceEpoch *
              1000,
      endTimeUnixNano: DateTime.now().microsecondsSinceEpoch * 1000,
      kind: OtlpSpanKind.server,
      attributes: {'test': 'immediate', 'verify.tag': tag},
    ),
  ]);
}

final class _VerifyOptions {
  const _VerifyOptions({
    required this.quick,
    required this.rounds,
    required this.intervalSec,
    required this.burst,
  });

  final bool quick;
  final int rounds;
  final int intervalSec;
  final int burst;

  static const _defaultRounds = 12;
  static const _defaultIntervalSec = 60;
  static const _defaultBurst = 3;

  static _VerifyOptions parse(List<String> args) {
    var quick = false;
    var rounds = _defaultRounds;
    var intervalSec = _defaultIntervalSec;
    var burst = _defaultBurst;
    var durationMin = 0;

    for (final arg in args) {
      if (arg == '--quick' || arg == '-q') {
        quick = true;
      } else if (arg.startsWith('--rounds=')) {
        rounds = int.tryParse(arg.split('=').last) ?? rounds;
      } else if (arg.startsWith('--interval-sec=')) {
        intervalSec = int.tryParse(arg.split('=').last) ?? intervalSec;
      } else if (arg.startsWith('--burst=')) {
        burst = int.tryParse(arg.split('=').last) ?? burst;
      } else if (arg.startsWith('--duration-min=')) {
        durationMin = int.tryParse(arg.split('=').last) ?? durationMin;
      } else if (arg == '--help' || arg == '-h') {
        // ignore: avoid_print
        print(_usage);
        exit(0);
      }
    }

    if (durationMin > 0 && !quick) {
      rounds = ((durationMin * 60) / intervalSec).ceil().clamp(1, 120);
    }

    return _VerifyOptions(
      quick: quick,
      rounds: rounds.clamp(1, 120),
      intervalSec: intervalSec.clamp(1, 600),
      burst: burst.clamp(1, 20),
    );
  }
}

const _usage = '''
verify_otlp.dart — continuous OTLP smoke (metrics + traces)

  dart run bin/verify_otlp.dart
  dart run bin/verify_otlp.dart --duration-min=15 --interval-sec=60
  dart run bin/verify_otlp.dart --quick

Options:
  --quick                 Single round
  --rounds=N              Default 12
  --interval-sec=N        Default 60
  --burst=N               Default 3
  --duration-min=N        rounds = ceil(N*60/interval)

Env: OTEL_EXPORTER_OTLP_ENDPOINT, OTEL_SERVICE_NAME
''';
