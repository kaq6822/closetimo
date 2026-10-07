// T077 — 공용 디자인 시스템 위젯 라이트 모드 골든 테스트.
//
// 헌법 II 회귀 가드. 공용 위젯의 색상·간격·라운딩·타이포가 바뀌면
// 기준 이미지와 달라져 테스트가 실패한다.
//
// 실행:
//   flutter test test/widget/design_system_golden_test.dart            # 비교
//   flutter test test/widget/design_system_golden_test.dart --update-goldens
//
// 변경 후에는 반드시 육안으로 기준 이미지를 확인한다.

import 'package:closetimo/core/widgets/chip_filter.dart';
import 'package:closetimo/core/widgets/primary_button.dart';
import 'package:closetimo/core/widgets/progress_bar.dart';
import 'package:closetimo/core/widgets/soft_button.dart';
import 'package:closetimo/core/widgets/status_label.dart';
import 'package:closetimo/core/widgets/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

void main() {
  setUpAll(loadGoldenFonts);

  group('PrimaryButton', () {
    testWidgets('기본 상태', (tester) async {
      await pumpGoldenHost(
        tester,
        const SizedBox(
          width: 260,
          child: PrimaryButton(label: '등록하기', onPressed: _noop),
        ),
      );
      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button.png'),
      );
    });

    testWidgets('비활성 상태는 흐리게 처리된다', (tester) async {
      await pumpGoldenHost(
        tester,
        const SizedBox(
          width: 260,
          child: PrimaryButton(label: '등록하기', onPressed: null),
        ),
      );
      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button_disabled.png'),
      );
    });

    testWidgets('앞뒤 아이콘 슬롯', (tester) async {
      await pumpGoldenHost(
        tester,
        const SizedBox(
          width: 300,
          child: PrimaryButton(
            label: '기록',
            leading: Icon(Icons.add_rounded),
            trailing: Icon(Icons.check_rounded),
            onPressed: _noop,
          ),
        ),
      );
      await expectLater(
        find.byType(PrimaryButton),
        matchesGoldenFile('goldens/primary_button_icons.png'),
      );
    });
  });

  group('SoftButton', () {
    testWidgets('기본 상태', (tester) async {
      await pumpGoldenHost(
        tester,
        const SizedBox(
          width: 260,
          child: SoftButton(label: '세탁 바구니', onPressed: _noop),
        ),
      );
      await expectLater(
        find.byType(SoftButton),
        matchesGoldenFile('goldens/soft_button.png'),
      );
    });

    testWidgets('앞 아이콘 슬롯', (tester) async {
      await pumpGoldenHost(
        tester,
        const SizedBox(
          width: 260,
          child: SoftButton(
            label: '세탁 바구니',
            leading: Icon(Icons.local_laundry_service_rounded),
            onPressed: _noop,
          ),
        ),
      );
      await expectLater(
        find.byType(SoftButton),
        matchesGoldenFile('goldens/soft_button_leading.png'),
      );
    });
  });

  group('ChipFilter', () {
    // 상태별로 별도 화면에 렌더링한다. 두 칩을 한 Row에 함께 두면
    // golden 캡처 범위가 둘을 모두 포함해 두 기준 이미지가 동일해진다.
    testWidgets('활성 상태는 primary 배경', (tester) async {
      await pumpGoldenHost(
        tester,
        const ChipFilter(label: '전체', active: true, onTap: _noop),
      );
      await expectLater(
        find.byType(ChipFilter),
        matchesGoldenFile('goldens/chip_filter_active.png'),
      );
    });

    testWidgets('비활성 상태는 secondary-container 배경', (tester) async {
      await pumpGoldenHost(
        tester,
        const ChipFilter(label: '아우터', active: false, onTap: _noop),
      );
      await expectLater(
        find.byType(ChipFilter),
        matchesGoldenFile('goldens/chip_filter_inactive.png'),
      );
    });
  });

  group('StatusLabel', () {
    testWidgets('깨끗함 라벨 (FR-008)', (tester) async {
      await pumpGoldenHost(
        tester,
        const StatusLabel(variant: StatusLabelVariant.clean),
      );
      await expectLater(
        find.byType(StatusLabel),
        matchesGoldenFile('goldens/status_label_clean.png'),
      );
    });

    testWidgets('세탁 필요 라벨 (FR-008)', (tester) async {
      await pumpGoldenHost(
        tester,
        const StatusLabel(variant: StatusLabelVariant.dirty),
      );
      await expectLater(
        find.byType(StatusLabel),
        matchesGoldenFile('goldens/status_label_dirty.png'),
      );
    });
  });

  group('ProgressBar', () {
    // 값은 프랙션으로 보이므로 캡처 범위가 잘리지 않도록 각 값을
    // 별도 화면에서 비교한다.
    testWidgets('일반 variant — 중간 값', (tester) async {
      await pumpGoldenHost(
        tester,
        const SizedBox(width: 240, child: ProgressBar(value: 0.6)),
      );
      await expectLater(
        find.byType(ProgressBar),
        matchesGoldenFile('goldens/progress_bar_normal.png'),
      );
    });

    testWidgets('일반 variant — 만차', (tester) async {
      await pumpGoldenHost(
        tester,
        const SizedBox(width: 240, child: ProgressBar(value: 1)),
      );
      await expectLater(
        find.byType(ProgressBar),
        matchesGoldenFile('goldens/progress_bar_full.png'),
      );
    });

    testWidgets('alert variant는 tertiary 톤을 쓴다 (FR-021)', (tester) async {
      await pumpGoldenHost(
        tester,
        const SizedBox(
          width: 240,
          child: ProgressBar(value: 0.6, variant: ProgressBarVariant.alert),
        ),
      );
      await expectLater(
        find.byType(ProgressBar),
        matchesGoldenFile('goldens/progress_bar_alert.png'),
      );
    });
  });

  group('TopBar', () {
    testWidgets('타이틀만 있는 상태', (tester) async {
      await pumpGoldenHost(
        tester,
        const SizedBox(width: 400, child: TopBar(title: '옷장이모')),
      );
      await expectLater(
        find.byType(TopBar),
        matchesGoldenFile('goldens/top_bar_title.png'),
      );
    });

    testWidgets('뒤로가기 + 서브타이틀 + 우측 액션', (tester) async {
      await pumpGoldenHost(
        tester,
        const SizedBox(
          width: 400,
          child: TopBar(
            subtitle: '신규 옷 등록',
            onBack: _noop,
            rightSlot: Text('저장'),
          ),
        ),
      );
      await expectLater(
        find.byType(TopBar),
        matchesGoldenFile('goldens/top_bar_subtitle.png'),
      );
    });
  });
}

void _noop() {}
