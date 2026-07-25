// Feature #6 — Network access configuration (per-platform permissions).
// These aren't runtime behaviours but build config that gates downloads + audio
// on each platform. A missing entry silently breaks networking on that platform
// (the old macOS -11800 bug), so we assert the config files statically. This is
// a host-side unit test — run with `flutter test test/`.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('network access config', () {
    test('macOS release entitlements allow the network client', () {
      final content =
          File('macos/Runner/Release.entitlements').readAsStringSync();
      expect(content.contains('com.apple.security.network.client'), isTrue,
          reason: 'release macOS build must allow outgoing network');
    });

    test('macOS debug entitlements allow the network client', () {
      final content =
          File('macos/Runner/DebugProfile.entitlements').readAsStringSync();
      expect(content.contains('com.apple.security.network.client'), isTrue,
          reason: 'debug macOS build must allow outgoing network');
    });

    test('Android manifest declares the INTERNET permission', () {
      final content =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(content.contains('android.permission.INTERNET'), isTrue,
          reason: 'Android needs INTERNET for audio + translation downloads');
    });
  });
}
