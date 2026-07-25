// Shared E2E helpers: boot the REAL app and drive its REAL UI.
// Not a *_test.dart file, so the test runner won't execute it directly.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran/main.dart' as app;

/// just_audio only has backends on these platforms.
bool get audioSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

/// Pumps frames (real time) until [finder] matches something or we time out.
/// The app boots asynchronously (Sembast import on first run), so we can't use
/// pumpAndSettle — a loading spinner would make it hang.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 90),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 120));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure(
      'Timed out after ${timeout.inSeconds}s waiting for ${reason ?? finder.description}');
}

/// Polls [condition] (real time) until true or timeout. Returns whether it hit.
Future<bool> pumpUntilTrue(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 40),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 150));
    if (condition()) return true;
  }
  return false;
}

/// Launches the real app and waits until the surah list is on screen.
Future<void> bootApp(WidgetTester tester) async {
  app.main();
  await pumpUntilFound(
    tester,
    find.byKey(const ValueKey('surah_tile_1')),
    reason: 'surah list (tile for Surah 1) to appear after boot',
  );
}

/// Opens Surah [number] from the list and waits for its ayahs to render.
Future<void> openSurah(WidgetTester tester, int number) async {
  await tester.tap(find.byKey(ValueKey('surah_tile_$number')));
  await pumpUntilFound(
    tester,
    find.byTooltip('Play Ayah'),
    reason: 'ayah play buttons in Surah $number',
  );
}
