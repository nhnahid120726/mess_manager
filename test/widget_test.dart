import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mas_manegment/main.dart';

void main() {
  testWidgets('MessApp initializes correctly as StatelessWidget', (WidgetTester tester) async {
    const app = MessApp();
    expect(app, isNotNull);
    expect(app, isA<StatelessWidget>());
  });
}
