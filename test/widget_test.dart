import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pathao_agent/main.dart';

void main() {
  testWidgets('Smoke test widget load', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: PathaoAgentApp(),
      ),
    );

    // Verify that the login title or button is present
    expect(find.text('Agent Login'), findsOneWidget);
  });
}
