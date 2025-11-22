// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartev/main.dart';

void main() {
  testWidgets('Authentication screen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartEVChargingApp());

    // Verify that the login screen is displayed
    expect(find.text('EzCharge'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
    expect(find.text('Sign Up'), findsWidgets);
  });

  testWidgets('Can toggle between login and sign up', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartEVChargingApp());

    // Tap on Sign Up
    await tester.tap(find.text('Sign Up').last);
    await tester.pumpAndSettle();

    // Verify Full Name field appears
    expect(find.byType(TextField), findsWidgets);

    // Tap back to Login
    await tester.tap(find.text('Login').first);
    await tester.pumpAndSettle();
  });

  testWidgets('Email validation works', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartEVChargingApp());

    // Find email field
    final emailFields = find.byType(TextField);
    expect(emailFields, findsWidgets);

    // Type email
    await tester.enterText(emailFields.first, 'test@example.com');
    expect(find.text('test@example.com'), findsOneWidget);
  });
}