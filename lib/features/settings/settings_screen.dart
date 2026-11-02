// US5 T074 — 설정 탭.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/utils/clock.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/vision/native_vision.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/providers/app_providers.dart';
import 'backup/backup_flow.dart';
import 'link_opener.dart';
import 'widgets/preference_row.dart';
import 'widgets/profile_card.dart';

/// 개인정보처리방침을 OS 브라우저로 연다. 열지 못하면(오프라인·브라우저 없음 등)
/// 스낵바로 알린다.
Future<void> _openPrivacyPolicy(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final opened = await ref.read(linkOpenerProvider).open(privacyPolicyUri);
  if (!opened) {
    messenger.showSnackBar(
      const SnackBar(content: Text('브라우저를 열 수 없어요. 잠시 후 다시 시도해 주세요.')),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(preferencesStreamProvider);
    final clock = ref.watch(clockProvider);
    final repo = ref.read(preferencesRepositoryProvider);

    return prefsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      // #48 FR-029 — 실패 원인 대신 복구 경로(다시 시도)를 보인다.
      error: (e, _) {
        debugPrint('Failed to load preferences: $e');
        return Center(
          child: AsyncErrorView(
            message: '설정을 불러오지 못했어요',
            onRetry: () => ref.invalidate(preferencesStreamProvider),
          ),
        );
      },
      data: (prefs) {
        final months = _monthsBetween(
          prefs.firstLaunchedAt ?? clock.now(),
          clock.now(),
        );
        return Column(
          children: [
            const TopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.lg,
                  ClosetimoSpacing.space76,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '설정',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: ClosetimoColors.ink,
                      ),
                    ),
                    const SizedBox(height: ClosetimoSpacing.xs),
                    const Text(
                      '앱 환경을 취향에 맞게 조정하세요.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        color: ClosetimoColors.muted,
                      ),
                    ),
                    const SizedBox(height: ClosetimoSpacing.space28),
                    ProfileCard(monthsTogether: months),
                    const SizedBox(height: ClosetimoSpacing.space28),
                    _Section(
                      title: '알림',
                      caption: '알림 발송은 준비 중이에요. 설정만 먼저 저장돼요.',
                      rows: [
                        PreferenceRow(
                          label: '세탁 알림',
                          toggleValue: prefs.notifWash,
                          onToggle: repo.setNotifWash,
                        ),
                        PreferenceRow(
                          label: '주간 옷장 리포트',
                          toggleValue: prefs.notifWeekly,
                          onToggle: repo.setNotifWeekly,
                        ),
                        PreferenceRow(
                          label: '오래 입지 않은 옷',
                          toggleValue: prefs.notifUnworn,
                          onToggle: repo.setNotifUnworn,
                        ),
                      ],
                    ),
                    const SizedBox(height: ClosetimoSpacing.space28),
                    // #44 — 보관한 옷 확인·복원 진입점. #46 — 태그 관리.
                    _Section(
                      title: '옷 관리',
                      rows: [
                        PreferenceRow(
                          label: '보관함',
                          onTap: () => context.pushNamed(Routes.archive),
                        ),
                        // #46 — 태그 이름 변경·병합·삭제.
                        PreferenceRow(
                          label: '태그 관리',
                          onTap: () => context.pushNamed(Routes.tags),
                        ),
                      ],
                    ),
                    const SizedBox(height: ClosetimoSpacing.space28),
                    // 005 FR-513·515 — 기기 안에서만 하는 사진 분석 설정.
                    const _PhotoAnalysisSection(),
                    const SizedBox(height: ClosetimoSpacing.space28),
                    // #40 — 사용자 실행형 백업·복원. 저장 위치는 OS 공유 시트·
                    // 문서 선택기에서 사용자가 고른다.
                    _Section(
                      title: '데이터',
                      caption:
                          '백업 파일은 직접 고른 위치(파일 앱, iCloud Drive, '
                          'Google Drive 등)에만 저장돼요. 옷 사진과 기록이 들어 있어요.',
                      rows: [
                        PreferenceRow(
                          label: '데이터 백업',
                          onTap: () => runBackup(context, ref),
                        ),
                        PreferenceRow(
                          label: '백업에서 복원',
                          onTap: () => runRestore(context, ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: ClosetimoSpacing.space28),
                    _Section(
                      title: '기타',
                      rows: [
                        PreferenceRow(
                          label: '개인정보 처리방침',
                          onTap: () => _openPrivacyPolicy(context, ref),
                        ),
                        const PreferenceRow(label: '앱 정보', textValue: 'v1.0.0'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static int _monthsBetween(DateTime start, DateTime now) {
    return (now.year - start.year) * 12 + (now.month - start.month);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows, this.caption});

  final String title;
  final String? caption;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).extension<ClosetimoSurfaces>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: ClosetimoSpacing.space4,
            bottom: ClosetimoSpacing.space12,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ClosetimoColors.muted,
              letterSpacing: 1,
            ),
          ),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(
              left: ClosetimoSpacing.space4,
              bottom: ClosetimoSpacing.space12,
            ),
            child: Text(
              caption!,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                color: ClosetimoColors.muted,
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(ClosetimoSpacing.xs),
          decoration: BoxDecoration(
            color: surfaces.containerLow,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                rows[i],
                if (i < rows.length - 1)
                  const SizedBox(height: ClosetimoSpacing.xs),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 005 — 사진 분석 설정. 이 기기가 지원하는 기능만 보인다(미지원 플랫폼은 색상 추천 안내만).
class _PhotoAnalysisSection extends ConsumerWidget {
  const _PhotoAnalysisSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caps =
        ref.watch(visionCapabilitiesProvider).valueOrNull ??
        VisionCapabilities.none;
    final prefs = ref.watch(preferencesStreamProvider).valueOrNull;
    final repo = ref.read(preferencesRepositoryProvider);
    if (prefs == null) return const SizedBox.shrink();
    // 005 — 기기 내 AI를 켜면 모델을 미리 깨우고, 준비 중이면 내려받기를 시작한다.
    Future<void> setAi(bool on) async {
      await repo.setOnDeviceAi(on);
      if (on) {
        await ref.read(attributeSuggesterProvider).prewarm(useOnDeviceAi: true);
      }
    }

    // Android ML Kit은 기능 진단 정보를 Google에 보낸다(헌법 III 예외, 사용자 승인 2026-11-02).
    final android = defaultTargetPlatform == TargetPlatform.android;
    return _Section(
      title: '사진 분석',
      caption: android
          ? '사진은 이 기기 안에서만 분석하고 밖으로 보내지 않아요. 다만 Google ML Kit가 '
                '기능 진단 정보(기기 모델·성능 지표 등)를 Google에 보낼 수 있어요. '
                '분석 결과는 제안일 뿐이라 언제든 바꿀 수 있어요.'
          : '사진은 이 기기 안에서만 분석하고 어디에도 보내지 않아요. '
                '분석 결과는 제안일 뿐이라 언제든 바꿀 수 있어요.',
      rows: [
        const PreferenceRow(label: '사진 색상 추천', textValue: '항상 켜짐'),
        if (caps.backgroundRemoval)
          PreferenceRow(
            label: '사진 배경 자동 제거',
            toggleValue: prefs.removeBackground,
            onToggle: repo.setRemoveBackground,
          ),
        switch (caps.onDeviceAi) {
          OnDeviceAiStatus.available => PreferenceRow(
            label: '기기 내 AI로 자세히 분석',
            toggleValue: prefs.onDeviceAi,
            onToggle: setAi,
          ),
          // 모델을 내려받는 중이거나 받을 수 있다. 켜 두면 준비되는 대로 쓴다.
          OnDeviceAiStatus.notReady => PreferenceRow(
            label: '기기 내 AI로 자세히 분석 (모델 준비 중)',
            toggleValue: prefs.onDeviceAi,
            onToggle: setAi,
          ),
          OnDeviceAiStatus.notEnabled => const PreferenceRow(
            label: '기기 내 AI로 자세히 분석',
            textValue: 'Apple Intelligence를 켜면 쓸 수 있어요',
          ),
          OnDeviceAiStatus.unsupported => null,
        },
      ].nonNulls.toList(),
    );
  }
}
