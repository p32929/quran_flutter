// Feature #2 — Settings persistence (pref / SharedPreferences).
// Platform-specific: SharedPreferences is backed by a different native store on
// each platform (NSUserDefaults, SharedPreferences, localStorage on web, etc.).
// Runs on ALL platforms.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pref/pref.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pref service stores and updates a value', (tester) async {
    final pref = await PrefServiceShared.init(defaults: {
      'integration_test_key': 'initial',
    });

    // Default applied
    expect(pref.get<String>('integration_test_key'), 'initial');

    // Write + read back through the real platform store
    await pref.set('integration_test_key', 'updated');
    expect(pref.get<String>('integration_test_key'), 'updated');

    // A fresh service instance sees the persisted value (no default override)
    final pref2 = await PrefServiceShared.init();
    expect(pref2.get<String>('integration_test_key'), 'updated',
        reason: 'value should persist across service instances');
  });
}
