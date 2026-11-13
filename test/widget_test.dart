// WedGo smoke test: the app boots to the splash screen and, with no
// backend configured (no --dart-define values, no saved setup), routes
// to the first-launch Backend Setup screen.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wedgo/app.dart';

void main() {
  testWidgets('WedGo boots to splash then Backend Setup',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WedGoApp()));

    // Splash branding.
    expect(find.text('WedGo'), findsOneWidget);

    // After the splash delay the app routes to Setup (no backend).
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();
    expect(find.text('Backend Setup'), findsOneWidget);
  });
}
