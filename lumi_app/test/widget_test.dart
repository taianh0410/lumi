import 'package:flutter_test/flutter_test.dart';

import 'package:lumi_app/main.dart';

void main() {
  testWidgets('renders the app shell', (WidgetTester tester) async {
    await tester.pumpWidget(const LumiApp());

    expect(find.text('LUMI AI'), findsWidgets);
  });
}
