// Feature #4 — Share (share_plus) fallback path.
// Share.share opens the OS share sheet, which can't be driven headlessly, so we
// test ShareUtils' documented fallback: copy to the system clipboard. The
// clipboard is a platform channel (pasteboard on Apple, ClipboardManager on
// Android, etc.). Web clipboard *reads* require a user gesture, so the read-back
// assertion is skipped on web (the write still runs).
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('clipboard write/read round-trip (share fallback)',
      (tester) async {
    const text = 'Bismillah — integration test';
    await Clipboard.setData(const ClipboardData(text: text));

    if (kIsWeb) {
      // Reading the clipboard in headless Chrome needs a user gesture; the
      // write above completing without throwing is the meaningful check here.
      return;
    }

    final data = await Clipboard.getData(Clipboard.kTextPlain);
    expect(data?.text, text);
  });
}
