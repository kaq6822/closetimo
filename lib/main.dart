// 옷장이모(Closetimo) entry point — Phase 2 T029 본격 부트스트랩.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme/app_theme.dart';
import 'core/persistence/isar_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: _ClosetimoBootstrap()));
}

/// Isar 초기화가 끝날 때까지 잠깐 스플래시를 보여주는 부트스트랩 위젯.
class _ClosetimoBootstrap extends ConsumerWidget {
  const _ClosetimoBootstrap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isar = ref.watch(isarProvider);
    return MaterialApp(
      title: '옷장이모',
      debugShowCheckedModeBanner: false,
      theme: buildClosetimoTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      home: isar.when(
        loading: () => const _SplashScreen(),
        error: (e, st) => _ErrorScreen(error: e),
        data: (_) => const _ClosetimoApp(),
      ),
    );
  }
}

class _ClosetimoApp extends ConsumerWidget {
  const _ClosetimoApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return Builder(
      builder: (ctx) => MaterialApp.router(
        title: '옷장이모',
        debugShowCheckedModeBanner: false,
        theme: buildClosetimoTheme(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ko', 'KR')],
        routerConfig: router,
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            '앱 초기화에 실패했어요.\n$error',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
