// US2 T045 — 옷장 탭. 검색·필터·정렬 + 2 컬럼 그리드.
// #43 — '입을 수 있음' 필터, 타일 빠른 동작, 다중 선택 바(FR-005a·008a·008b).
// #39 — 선택 바 '착용 기록'(FR-008c)은 selection/wear_record_action.dart.
// #48 FR-029 — 로딩·읽기 실패를 빈 옷장·검색 무결과와 구분한다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/async_state_view.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/item.dart';
import '../../data/models/item_filter.dart';
import '../../data/providers/app_providers.dart';
import '../../data/repositories/item_repository.dart';
import 'filter_summary.dart';
import 'selection/bulk_tag_action.dart';
import 'selection/item_selection.dart';
import 'selection/selection_action_bar.dart';
import 'selection/wear_record_action.dart';
import 'widgets/filter_result_bar.dart';
import 'widgets/garment_tile.dart';
import 'widgets/wardrobe_filter_bar.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({this.initialFilter = const ItemFilter(), super.key});

  /// 라우트 쿼리에서 온 종류·용도 조건(검색어 제외). 홈 카드 진입 시 카드의
  /// 집계 범위와 같다(#37).
  final ItemFilter initialFilter;

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  /// 종류·용도 조건. 검색어는 [_query]로 따로 관리한다.
  late ItemFilter _scope = widget.initialFilter;
  String _query = '';

  /// '입을 수 있음'(#43). 검색어처럼 URL에 싣지 않는 화면 State다.
  bool _readyToWear = false;
  WardrobeSort _sort = WardrobeSort.statusCleanFirst;

  /// 검색창 텍스트. 홈 카드 진입으로 검색어를 비울 때 화면 표시도 맞춘다(#33).
  final TextEditingController _searchController = TextEditingController();

  /// 마지막으로 그린 목록. 다중 선택의 "모두 선택"·바구니 담기 대상 계산에 쓴다.
  List<Item> _visibleItems = const [];

  /// 그리드가 sliver로 바뀌면 스크롤 위치가 콘텐츠 축소 시 남는다.
  /// 마지막 옷을 삭제하면 그리드가 사라져 화면 높이가 확 줄고, 스크롤이
  /// 되감기지 않으면 "내 옷장" 제목이 화면 위로 밀려난 빈 화면이 보인다.
  /// 옷장이 비면 최상단으로 되돌린다.
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(WardrobeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // indexedStack 셸이 State를 보존하므로, 홈 카테고리 카드가 새 `?category=`로
    // 진입하면 여기서 필터를 맞춘다(FR-019). 칩 선택은 URL에 먼저 반영되므로
    // `_category`와 같으면 건드리지 않는다. 목록이 통째로 바뀌므로 맨 위로 올린다.
    final next = widget.initialFilter;
    if (next != oldWidget.initialFilter && next != _scope) {
      _scope = next;
      // #33 — 이전 검색어·'입을 수 있음'이 남으면 카드 범위와 다른(빈) 목록이
      // 보인다. 카드 집계와 같은 범위가 되도록 함께 초기화한다(FR-006a).
      _query = '';
      _readyToWear = false;
      _searchController.clear();
      // 탭 전환 중 build 단계에서 호출되므로 레이아웃이 끝난 뒤 이동한다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(wardrobeSelectionProvider.notifier).exit();
        if (_scrollController.hasClients) _scrollController.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// 옷장이 비었을 때만 스크롤을 초기화한다.
  ///
  /// build 중 `jumpTo`를 부르면 "setState/build 중 스크롤 위치 변경" 오류가
  /// 나므로 다음 프레임으로 미룬다.
  void _resetScrollIfEmpty(List<Item> items) {
    if (items.isNotEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.offset == 0) return;
      _scrollController.jumpTo(0);
    });
  }

  /// 칩 선택을 `?category=`에도 반영해, 이후 홈 카드가 같은 카테고리로
  /// 다시 진입해도 쿼리 변화로 감지되게 한다.
  void _onScopeChanged(ItemFilter scope) {
    setState(() => _scope = scope);
    context.goNamed(
      Routes.wardrobe,
      queryParameters: wardrobeQueryParameters(scope),
    );
  }

  /// 목록이 바뀌면 보이지 않게 된 옷을 선택에서 뺀다(FR-008b).
  void _syncSelection(List<Item> items) {
    _visibleItems = items;
    if (!ref.read(wardrobeSelectionProvider).active) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(wardrobeSelectionProvider.notifier)
          .retainOnly(_visibleItems.map((i) => i.id));
    });
  }

  /// 선택한 옷 중 바구니에 없는 옷만 담는다(이미 담긴 옷은 토글로 빼지 않는다).
  Future<void> _addSelectedToLaundry(Set<int> ids) async {
    final laundry = ref.read(laundryRepositoryProvider);
    final targets = [
      for (final i in _visibleItems)
        if (ids.contains(i.id) && !i.inLaundry) i.id,
    ];
    for (final id in targets) {
      await laundry.toggle(id);
    }
    if (!mounted) return;
    ref.read(wardrobeSelectionProvider.notifier).exit();
    showClosetimoToast(
      context,
      targets.isEmpty
          ? '이미 모두 세탁 바구니에 있어요'
          : '${targets.length}점을 세탁 바구니에 담았어요',
    );
  }

  /// 검색어·'입을 수 있음'·종류·용도·태그 조건을 모두 지운다(#46 결과 초기화).
  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _readyToWear = false;
    });
    _onScopeChanged(const ItemFilter());
  }

  /// 결과 목록 sliver. 비어 있으면 옷장이 빈 경우와 검색 무결과를 구분한다.
  Widget _buildResults(ItemFilter filter, List<Item> items) {
    if (items.isEmpty) {
      // 검색어·필터 없이 비어 있으면 옷장 자체가 빈 것이므로
      // "검색 무결과"와 구분해 첫 등록을 유도한다.
      final filtered = filter.isActive;
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: ClosetimoSpacing.space60,
          ),
          child: Center(
            child: Text(
              filtered
                  ? '검색 결과가 없습니다.'
                  : '아직 등록된 옷이 없어요.\n오른쪽 위 + 버튼으로 첫 옷을 등록해 보세요.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                color: ClosetimoColors.muted,
                height: 1.5,
              ),
            ),
          ),
        ),
      );
    }
    return SliverPadding(
      // 마지막 타일이 하단 탭바와 겹치지 않도록 그리드 끝에 여백을 둔다.
      // 선택 모드에서는 하단 액션 바(액션 2줄 가능)가 타일을 가리지 않도록 더 비운다.
      padding: EdgeInsets.only(
        left: ClosetimoSpacing.lg,
        right: ClosetimoSpacing.lg,
        bottom: ref.watch(wardrobeSelectionProvider).active
            ? ClosetimoSpacing.space76 + ClosetimoSpacing.space120
            : ClosetimoSpacing.space76,
      ),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: ClosetimoSpacing.space14,
          crossAxisSpacing: ClosetimoSpacing.space14,
          childAspectRatio: 0.66,
        ),
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => GarmentTile(item: items[i]),
          childCount: items.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(itemRepositoryProvider);
    final filter = _scope.copyWith(query: _query, readyToWear: _readyToWear);
    final selection = ref.watch(wardrobeSelectionProvider);
    // 선택 모드에서 시스템 뒤로 가기는 앱을 닫지 않고 선택만 끝낸다.
    return PopScope(
      canPop: !selection.active,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(wardrobeSelectionProvider.notifier).exit();
      },
      child: Column(
        children: [
          TopBar(
            rightSlot: TopBarPlusAction(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                context.pushNamed(Routes.addItem);
              },
            ),
          ),
          Expanded(
            // 전체 화면을 하나의 스크롤 뷰로 두고 그리드는 sliver로 끼운다.
            // 이전 구현은 `SingleChildScrollView` 안에
            // `GridView.builder(shrinkWrap: true, NeverScrollableScrollPhysics)`
            // 를 넣어, 스크롤 여부와 무관하게 100개 타일을 전부 한 번에
            // 레이아웃·페인트했다(T080 측정에서 첫 프레임 build 20ms로 확인).
            // sliver 그리드는 화면에 보이는 타일만 빌드한다.
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    ClosetimoSpacing.lg,
                    ClosetimoSpacing.md,
                    ClosetimoSpacing.lg,
                    0,
                  ),
                  sliver: SliverList.list(
                    children: [
                      Text(
                        '내 옷장',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      // #21 — 헤더를 줄여 첫 줄 타일이 첫 화면에 보이게 한다.
                      const SizedBox(height: ClosetimoSpacing.space4),
                      const Text(
                        '청결도와 착용 빈도에 따라 정리된 컬렉션입니다.',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          color: ClosetimoColors.muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: ClosetimoSpacing.md),
                      WardrobeFilterBar(
                        searchController: _searchController,
                        scope: _scope,
                        readyToWear: _readyToWear,
                        sort: _sort,
                        onQueryChanged: (v) => setState(() => _query = v),
                        onScopeChanged: _onScopeChanged,
                        onReadyToWearChanged: (v) =>
                            setState(() => _readyToWear = v),
                        onSortChanged: (s) => setState(() => _sort = s),
                        tagUsages:
                            ref.watch(tagUsageProvider).valueOrNull ?? const [],
                      ),
                      const SizedBox(height: ClosetimoSpacing.md),
                    ],
                  ),
                ),
                StreamStateBuilder<List<Item>>(
                  stream: () => repo.watchFiltered(filter: filter, sort: _sort),
                  streamKey: (repo, filter, _sort),
                  errorMessage: '옷장을 불러오지 못했어요',
                  wrapState: (child) => SliverToBoxAdapter(child: child),
                  builder: (ctx, items) {
                    _resetScrollIfEmpty(items);
                    _syncSelection(items);
                    final results = _buildResults(filter, items);
                    if (!filter.isActive) return results;
                    // #46 — 조건이 걸려 있으면 결과 수와 초기화를 목록 위에 보인다.
                    return SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                          child: FilterResultBar(
                            count: items.length,
                            onReset: _resetFilters,
                          ),
                        ),
                        results,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          if (selection.active)
            SelectionActionBar(
              count: selection.count,
              filterSummary: describeItemFilter(filter),
              onSelectAll: () => ref
                  .read(wardrobeSelectionProvider.notifier)
                  .selectAll(_visibleItems.map((i) => i.id)),
              onClear: () =>
                  ref.read(wardrobeSelectionProvider.notifier).clear(),
              onExit: () => ref.read(wardrobeSelectionProvider.notifier).exit(),
              actions: [
                SelectionAction(
                  label: '바구니에 담기',
                  icon: Icons.local_laundry_service_outlined,
                  onPressed: () => _addSelectedToLaundry(selection.ids),
                ),
                wearRecordSelectionAction(context, ref, selection.ids),
                // #46 — 여러 옷에 태그 일괄 붙이기·떼기.
                bulkTagAction(
                  context,
                  ref,
                  selected: [
                    for (final i in _visibleItems)
                      if (selection.ids.contains(i.id)) i,
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
