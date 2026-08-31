import 'package:flutter_test/flutter_test.dart';
import 'package:proofly/main.dart';

void main() {
  testWidgets('Proofly app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProoflyApp());
    expect(find.text('Digital credentials\nyou can prove'), findsOneWidget);
  });
}
