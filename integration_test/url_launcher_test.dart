// Feature #5 — Open external URL (url_launcher).
// Platform-specific: canLaunchUrl reaches a platform channel and resolves
// without actually opening anything. We assert the call completes (the plugin
// is registered on this platform) rather than a specific truthiness, since
// Android gates results behind manifest <queries>. Runs on ALL platforms.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('canLaunchUrl resolves for an https URL', (tester) async {
    final result = await canLaunchUrl(Uri.parse('https://example.com'));
    expect(result, isA<bool>(),
        reason: 'url_launcher platform channel should respond');
  });
}
