import 'package:flutter_test/flutter_test.dart';
import 'package:kisaan_ml/main.dart';

void main() {
  testWidgets('app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KisaanMLApp());
    await tester.pump();
  });
}
