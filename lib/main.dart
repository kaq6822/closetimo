// 옷장이모(Closetimo) entry point — Phase 2 T029 본격 부트스트랩.
// 단일 MaterialApp.router로 평탄화하고, Isar 초기화 게이팅은 router의
// builder 내부에서 처리한다(중첩 MaterialApp 금지).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme/app_theme.dart';
import 'core/persistence/isar_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ClosetimoApp()));
}

class ClosetimoApp extends ConsumerWidget {
  const ClosetimoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
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
      builder: (context, child) {
        // Isar 초기화가 끝날 때까지 스플래시. 완료 후 child(라우터) 렌더.
        final isar = ref.watch(isarProvider);
        return isar.when(
          loading: () => const _SplashScreen(),
          error: (e, _) => _ErrorScreen(error: e),
          data: (_) => child ?? const SizedBox.shrink(),
        );
      },
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
