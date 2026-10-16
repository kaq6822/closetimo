// US2 T045 — 옷장 탭. 검색·필터·정렬 + 2 컬럼 그리드.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/top_bar.dart';
import '../../data/models/item.dart';
import '../../data/models/item_filter.dart';
import '../../data/providers/app_providers.dart';
import '../../data/repositories/item_repository.dart';
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
  WardrobeSort _sort = WardrobeSort.statusCleanFirst;

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
      // 탭 전환 중 build 단계에서 호출되므로 레이아웃이 끝난 뒤 이동한다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(itemRepositoryProvider);
    final stream = repo.watchFiltered(
      filter: _scope.copyWith(query: _query),
      sort: _sort,
    );
    return Column(
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
                    const SizedBox(height: ClosetimoSpacing.sm),
                    const Text(
                      '당신만을 위해 큐레이션된 에센셜 컬렉션입니다.\n'
                      '청결도와 착용 빈도에 따라 정리되어 있습니다.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        color: ClosetimoColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: ClosetimoSpacing.xl),
                    WardrobeFilterBar(
                      query: _query,
                      scope: _scope,
                      sort: _sort,
                      onQueryChanged: (v) => setState(() => _query = v),
                      onScopeChanged: _onScopeChanged,
                      onSortChanged: (s) => setState(() => _sort = s),
                    ),
                    const SizedBox(height: ClosetimoSpacing.xl),
                  ],
                ),
              ),
              StreamBuilder<List<Item>>(
                stream: stream,
                builder: (ctx, snap) {
                  final items = snap.data ?? const [];
                  _resetScrollIfEmpty(items);
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: ClosetimoSpacing.space40,
                        ),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  if (items.isEmpty) {
                    // 검색어·필터 없이 비어 있으면 옷장 자체가 빈 것이므로
                    // "검색 무결과"와 구분해 첫 등록을 유도한다.
                    final filtered =
                        _query.trim().isNotEmpty || _scope.hasScope;
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
                    padding: const EdgeInsets.only(
                      left: ClosetimoSpacing.lg,
                      right: ClosetimoSpacing.lg,
                      bottom: ClosetimoSpacing.space76,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
