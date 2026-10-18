// 설정 > 개인정보 처리방침 행이 스토어에 제출된 영구 URL을 연다.

import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/core/utils/clock.dart';
import 'package:closetimo/data/models/user_preferences.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/preferences_repository.dart';
import 'package:closetimo/features/settings/link_opener.dart';
import 'package:closetimo/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 18, 9, 30);

class _FixedClock implements Clock {
  @override
  DateTime now() => _now;
}

class _FakePrefsRepo implements PreferencesRepository {
  @override
  Stream<UserPreferences> watch() =>
      Stream.value(UserPreferences.defaults()..firstLaunchedAt = _now);
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class _FakeOpener implements LinkOpener {
  _FakeOpener({this.result = true});
  final bool result;
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return result;
  }
}

Future<void> _pump(WidgetTester tester, LinkOpener opener) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesRepositoryProvider.overrideWithValue(_FakePrefsRepo()),
        clockProvider.overrideWithValue(_FixedClock()),
        linkOpenerProvider.overrideWithValue(opener),
      ],
      child: MaterialApp(
        theme: buildClosetimoTheme(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko', 'KR')],
        home: const Scaffold(body: SettingsScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapPolicy(WidgetTester tester) async {
  await tester.ensureVisible(find.text('개인정보 처리방침'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('개인정보 처리방침'));
  await tester.pumpAndSettle();
}

void main() {
  test('방침 URL은 스토어에 제출된 영구 경로다', () {
    expect(
      privacyPolicyUri.toString(),
      'https://kaq6822.github.io/smulsmul/apps/closetimo/privacy/',
    );
  });

  testWidgets('행을 누르면 방침 URL을 연다', (tester) async {
    final opener = _FakeOpener();
    await _pump(tester, opener);

    expect(find.text('준비 중'), findsNothing);
    await _tapPolicy(tester);

    expect(opener.opened, [privacyPolicyUri]);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('열지 못하면 안내 스낵바를 보인다', (tester) async {
    final opener = _FakeOpener(result: false);
    await _pump(tester, opener);

    await _tapPolicy(tester);

    expect(opener.opened, [privacyPolicyUri]);
    expect(find.textContaining('개인정보처리방침을 열 수 없어요'), findsOneWidget);
  });
}
