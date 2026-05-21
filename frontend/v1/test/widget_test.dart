import 'package:flutter_test/flutter_test.dart';
import 'package:v1/main.dart';

void main() {
  testWidgets('SimSearch home renders', (WidgetTester tester) async {
    await tester.pumpWidget(const SimSearchApp());

    expect(find.text('SimSearch'), findsWidgets);
    expect(find.text('Find Similar Assets'), findsOneWidget);
  });
}
