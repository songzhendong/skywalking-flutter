import 'package:flutter/material.dart';
import 'package:skywalking_flutter/skywalking_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  OtlpFlutter.init(
    defaultServiceName: 'flutter-otlp-demo',
    defaultEndpoint: 'http://127.0.0.1:12800',
    defaultEnvironment: 'dev',
  );

  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OTLP Agent Demo',
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  String _status = 'Ready';

  Future<void> _sendSample() async {
    if (!OtlpAgent.isInitialized) {
      setState(() => _status = 'Agent disabled (check SKYWALKING_ENABLED / endpoint)');
      return;
    }
    setState(() => _status = 'Sending...');
    try {
      final agent = OtlpAgent.instance;
      await agent.tracer.withSpan('demo.button_tap', (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        agent.tracer.recordEvent(
          name: 'demo.screen_view',
          attributes: {Semconv.screenName: 'home'},
        );
      });
      agent.meter.addCounter('demo.button.clicks');
      await agent.flush();
      setState(() => _status = 'Sent. Check Zipkin for flutter-otlp-demo');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTLP Agent')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'OTLP/HTTP → ${OtlpAgent.isInitialized ? OtlpAgent.instance.config.otlpEndpoint : "(disabled)"}',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _sendSample,
              child: const Text('Send sample trace + metric'),
            ),
            const SizedBox(height: 16),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
