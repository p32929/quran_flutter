// E2E: the app can open web links (the About sheet's Source code and
// Portfolio links). Asks the platform whether a browser link can be opened.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:url_launcher/url_launcher.dart';
import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('web links can be opened', (tester) async {
    await bootApp(tester);
    final ok =
        await canLaunchUrl(Uri.parse('https://github.com/p32929/quran_flutter'));
    expect(ok, isTrue, reason: 'a browser should be available for links');
  });
}
