import 'package:flutter_test/flutter_test.dart';
import 'package:mida/main.dart';

void main() {
  testWidgets('App loads with bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const MidaApp());
    expect(find.text('ICD-10'), findsOneWidget);
  });
}
