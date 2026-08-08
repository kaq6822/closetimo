// 착용 히스토리 타임라인 클리핑 회귀 테스트.
//
// 세로선(left: -27)과 이벤트 아이콘(left: -42)은 타임라인 바깥 Stack의
// 음수 좌표에 그려진다. Stack 기본값(Clip.hardEdge)이 유지되면 아이콘과
// 세로선이 모두 잘려 화면에서 사라지므로(iOS 시뮬레이터 검증에서 발견),
// 바깥 Stack의 clipBehavior가 Clip.none으로 유지되는지를 고정한다.
// 클리핑은 페인트 단계에만 작용해 위젯 존재·좌표 어서션으로는 잡을 수
// 없다 — 픽셀 단위 검증이 필요해지면 골든 테스트로 승격한다.

import 'package:closetimo/app/theme/app_theme.dart';
import 'package:closetimo/data/models/wear_event.dart';
import 'package:closetimo/data/providers/app_providers.dart';
import 'package:closetimo/data/repositories/event_repository.dart';
import 'package:closetimo/features/item_detail/widgets/history_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEventRepository implements EventRepository {
  _FakeEventRepository(this.events);

  final List<WearEvent> events;

  @override
  Stream<List<WearEvent>> watchForItem(int itemId) => Stream.value(events);

  @override
  Future<void> recordWear(int itemId, {String? note}) async {}

  @override
  Future<void> updateEventNote(int eventId, String? note) async {}

  @override
  Future<void> deleteWearEvent(int eventId) async {}
}

void main() {
  Widget harness(EventRepository repo) {
    return ProviderScope(
      overrides: [eventRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: buildClosetimoTheme(),
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: HistoryTimeline(itemId: 1),
          ),
        ),
      ),
    );
  }

  testWidgets('타임라인 아이콘·세로선이 클리핑되지 않는다 (회귀)', (tester) async {
    final repo = _FakeEventRepository([
      WearEvent(
        itemId: 1,
        kind: EventKind.wear,
        occurredAt: DateTime(2026, 8, 8),
        note: '오피스 미팅',
      )..id = 1,
      WearEvent(
        itemId: 1,
        kind: EventKind.wash,
        occurredAt: DateTime(2026, 8, 1),
      )..id = 2,
    ]);
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    // 이벤트 2건이 타임라인에 노출된다.
    expect(find.text('착용 기록'), findsOneWidget);
    expect(find.text('세탁 완료'), findsOneWidget);

    // 타임라인 바깥(최상위) Stack은 음수 좌표 자식을 자르지 않아야 한다.
    // 하위의 다른 Stack까지 강제하면 정당한 클리핑 추가에도 깨지므로
    // 최상위 Stack 하나로 한정한다.
    final outerStack = tester.widget<Stack>(
      find
          .descendant(
            of: find.byType(HistoryTimeline),
            matching: find.byType(Stack),
          )
          .first,
    );
    expect(
      outerStack.clipBehavior,
      Clip.none,
      reason: '타임라인 바깥 Stack이 음수 좌표의 아이콘·세로선을 잘라내면 안 된다',
    );

    // 이벤트 종류별 아이콘이 트리에 존재한다.
    expect(find.byIcon(Icons.checkroom_rounded), findsOneWidget);
    expect(find.byIcon(Icons.opacity_rounded), findsOneWidget);
  });
}
