import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aegis/main.dart';

void main() {
  testWidgets('AegisApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AegisApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
