import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skywalking_flutter_example/main.dart';

void main() {
  testWidgets('demo home shows send button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DemoHomePage()),
    );

    expect(find.text('Send sample trace + metric'), findsOneWidget);
    expect(find.textContaining('OTLP/HTTP'), findsOneWidget);
  });
}
