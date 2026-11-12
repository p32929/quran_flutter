// E2E: the Share button on an ayah hands the text to the system share
// feature without crashing. Where a platform has no share feature the app
// copies the text instead and says so; the test prints which one happened.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('sharing an ayah works', (tester) async {
    await bootApp(tester);
    await openSurah(tester, 1);

    await tester.tap(find.byTooltip('Share').first);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }

    expect(tester.takeException(), isNull,
        reason: 'sharing must not crash the app');
    final copiedInstead =
        find.textContaining('Sharing not supported').evaluate().isNotEmpty;
    // ignore: avoid_print
    print('SHARE RESULT: ${copiedInstead ? 'copied to clipboard instead' : 'system share opened'}');
    expect(copiedInstead, isFalse,
        reason: 'the system share feature should open, not the clipboard fallback');
  });
}
