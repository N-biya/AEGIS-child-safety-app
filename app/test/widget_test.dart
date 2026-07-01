import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aegis/main.dart';

void main() {
  testWidgets('AegisApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AegisApp());
    expect(find.byType(MaterialApp), findsOneWidget);

    // The splash screen schedules a delayed navigation timer in initState.
    // Tear the tree down so that timer is cancelled in dispose(), otherwise
    // the test framework flags it as a still-pending timer. This also avoids
    // the navigation callback firing, which would touch Firebase (not
    // initialised in this widget-only test).
    await tester.pumpWidget(const SizedBox());
  });
}
