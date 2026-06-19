import 'package:flutter_test/flutter_test.dart';

import 'package:auto_monpoto/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AutoMonpotoApp());
    expect(find.text('Auto Monpoto'), findsWidgets);
  });
}
