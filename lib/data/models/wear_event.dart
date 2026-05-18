// data-model.md §2 WearEvent 컬렉션. FR-013·020 타임라인 백본.

import 'package:isar/isar.dart';

part 'wear_event.g.dart';

@collection
class WearEvent {
  WearEvent({
    required this.itemId,
    required this.kind,
    required this.occurredAt,
    this.note,
  });

  Id id = Isar.autoIncrement;

  @Index()
  late int itemId;

  @enumerated
  late EventKind kind;

  @Index(type: IndexType.value)
  late DateTime occurredAt;

  String? note;
}

enum EventKind { wear, wash }

extension EventKindLabel on EventKind {
  String get label => switch (this) {
        EventKind.wear => '착용',
        EventKind.wash => '세탁',
      };
}
