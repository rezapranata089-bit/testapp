// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:workout_rumah/main.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WorkoutRumahApp());
    await tester.pump();

    // Cukup pastikan splash/home shell berhasil ter-render tanpa error,
    // karena app ini bukan counter app bawaan Flutter.
    expect(find.byType(WorkoutRumahApp), findsOneWidget);
  });
}
