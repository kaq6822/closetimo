// #48 FR-029 — 저장소 읽기의 최초 로딩·정상 빈 상태·읽기 실패를 구분한다.
//
// 스트림 오류를 `snap.data ?? const []`처럼 빈 값으로 대체하면 "옷이 없다"로
// 오해된다. 화면은 [StreamStateBuilder]로 로딩·실패를 먼저 분기하고, 빈 목록
// 판단은 데이터가 실제로 도착한 뒤 builder 안에서만 한다.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// 최초 로딩 표시.
class AsyncLoadingView extends StatelessWidget {
  const AsyncLoadingView({
    this.padding = const EdgeInsets.symmetric(
      vertical: ClosetimoSpacing.space40,
    ),
    super.key,
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: const Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}

/// 읽기 실패 안내와 "다시 시도" 버튼.
class AsyncErrorView extends StatelessWidget {
  const AsyncErrorView({
    required this.message,
    required this.onRetry,
    this.padding = const EdgeInsets.symmetric(
      vertical: ClosetimoSpacing.space40,
      horizontal: ClosetimoSpacing.lg,
    ),
    super.key,
  });

  /// 무엇을 읽지 못했는지(예: "옷장을 불러오지 못했어요").
  final String message;
  final VoidCallback onRetry;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: ClosetimoColors.error),
          const SizedBox(height: ClosetimoSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ClosetimoColors.ink,
            ),
          ),
          const SizedBox(height: ClosetimoSpacing.xs),
          const Text(
            '저장된 데이터는 그대로예요. 다시 시도해 주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              color: ClosetimoColors.muted,
            ),
          ),
          const SizedBox(height: ClosetimoSpacing.sm),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

/// 스트림을 구독해 로딩·실패·데이터를 나눠 그린다.
///
/// - 데이터가 오기 전: [loading] (기본 [AsyncLoadingView])
/// - 오류 이벤트: [AsyncErrorView]. "다시 시도"는 [stream]을 다시 호출해 재구독한다.
/// - 데이터: [builder]. 빈 상태 판단은 여기서 한다.
///
/// [stream]은 [streamKey]가 바뀔 때만 다시 만든다(필터 변경 등). 부모가 다시
/// 그려져도 같은 구독을 유지한다. 로딩·실패 뷰를 sliver 문맥에 넣으려면
/// [wrapState]로 `SliverToBoxAdapter` 등을 씌운다.
class StreamStateBuilder<T> extends StatefulWidget {
  const StreamStateBuilder({
    required this.stream,
    required this.errorMessage,
    required this.builder,
    this.streamKey,
    this.loading,
    this.wrapState,
    super.key,
  });

  final Stream<T> Function() stream;
  final Object? streamKey;
  final String errorMessage;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loading;
  final Widget Function(Widget child)? wrapState;

  @override
  State<StreamStateBuilder<T>> createState() => _StreamStateBuilderState<T>();
}

class _StreamStateBuilderState<T> extends State<StreamStateBuilder<T>> {
  late Stream<T> _stream = _subscribe();

  /// 다시 시도 횟수. StreamBuilder가 이전 오류 스냅샷을 들고 있지 않도록 새로 만든다.
  int _attempt = 0;

  /// 오류를 그대로 흘려보내되 한 번 로그로 남긴다.
  Stream<T> _subscribe() => widget.stream().transform(
    StreamTransformer<T, T>.fromHandlers(
      handleError: (error, stackTrace, sink) {
        debugPrint('Stream read failed (${widget.errorMessage}): $error');
        sink.addError(error, stackTrace);
      },
    ),
  );

  @override
  void didUpdateWidget(StreamStateBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.streamKey != oldWidget.streamKey) _stream = _subscribe();
  }

  void _retry() => setState(() {
    _attempt++;
    _stream = _subscribe();
  });

  @override
  Widget build(BuildContext context) {
    final wrap = widget.wrapState ?? (Widget child) => child;
    return StreamBuilder<T>(
      key: ValueKey(_attempt),
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return wrap(
            AsyncErrorView(message: widget.errorMessage, onRetry: _retry),
          );
        }
        if (snap.hasData) return widget.builder(context, snap.requireData);
        return wrap(widget.loading ?? const AsyncLoadingView());
      },
    );
  }
}
