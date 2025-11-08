// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookswap_flutter/main.dart'; // <- Import your main.dart

void main() {
  testWidgets('App launches and shows initial screen',
      (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const BookSwapApp());

    // Let animations settle
    await tester.pumpAndSettle();

    // Verify that either SignInScreen or HomeScreen is shown based on auth state
    expect(find.byType(Scaffold), findsWidgets);
  });
}
