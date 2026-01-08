import 'package:flutter_test/flutter_test.dart';
import 'package:interval_reminders/main.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Timer smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TimerService()),
        ],
        child: const IntervalApp(),
      ),
    );

    // Verify that the title is present
    expect(find.text('Interval Reminders'), findsOneWidget);

    // Verify initial timer state (45:00)
    expect(find.text('45:00'), findsOneWidget);
  });
}
