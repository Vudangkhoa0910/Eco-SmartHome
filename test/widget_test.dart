// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:smart_home/provider/getit.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:smart_home/main.dart';

void main() {
  testWidgets('My test', (WidgetTester tester) async {
    setupLocator();
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
  });
}
