// US5 T074 — 설정 탭.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/utils/clock.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/providers/app_providers.dart';
import 'backup/backup_flow.dart';
import 'widgets/preference_row.dart';
import 'widgets/profile_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(preferencesStreamProvider);
    final clock = ref.watch(clockProvider);
    final repo = ref.read(preferencesRepositoryProvider);

    return prefsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator.adaptive()),
      error: (e, _) => Center(child: Text('설정을 불러오지 못했어요\n$e')),
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
                    const _Section(
                      title: '기타',
                      rows: [
                        PreferenceRow(label: '개인정보 처리방침', textValue: '준비 중'),
                        PreferenceRow(label: '앱 정보', textValue: 'v1.0.0'),
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
