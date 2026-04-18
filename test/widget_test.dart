import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sleeping_noise/app.dart';

void main() {
  testWidgets('App loads home shell with SleepingNoise title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SleepingNoiseApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('SleepingNoise'), findsOneWidget);
    expect(find.textContaining('ortam sesleri'), findsOneWidget);
  });
}
