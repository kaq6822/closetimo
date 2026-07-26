/// Isar 3의 Item 한 건을 native 저장소 타입과 분리해 표현한다.
class LegacyItemData {
  const LegacyItemData({
    required this.id,
    required this.name,
    required this.categoryIndex,
    required this.careMethodIndex,
    required this.statusIndex,
    required this.washCycle,
    required this.wearSinceWash,
    required this.totalWears,
    required this.inLaundry,
    required this.fallbackColor,
    required this.createdAt,
    this.brand,
    this.lastWornAt,
    this.lastWashedAt,
    this.purchasedAt,
    this.imagePath,
  });

  final int id;
  final String name;
  final String? brand;
  final int categoryIndex;
  final int careMethodIndex;
  final int statusIndex;
  final int washCycle;
  final int wearSinceWash;
  final int totalWears;
  final DateTime? lastWornAt;
  final DateTime? lastWashedAt;
  final DateTime? purchasedAt;
  final bool inLaundry;
  final String? imagePath;
  final int fallbackColor;
  final DateTime createdAt;
}

/// Isar 3의 WearEvent 한 건을 native 저장소 타입과 분리해 표현한다.
class LegacyWearEventData {
  const LegacyWearEventData({
    required this.id,
    required this.itemId,
    required this.kindIndex,
    required this.occurredAt,
    this.note,
  });

  final int id;
  final int itemId;
  final int kindIndex;
  final DateTime occurredAt;
  final String? note;
}

/// Isar 3의 UserPreferences singleton을 표현한다.
class LegacyPreferencesData {
  const LegacyPreferencesData({
    required this.id,
    required this.notifWash,
    required this.notifWeekly,
    required this.notifUnworn,
    required this.accent,
    this.lastTab,
    this.firstLaunchedAt,
  });

  final int id;
  final bool notifWash;
  final bool notifWeekly;
  final bool notifUnworn;
  final String accent;
  final String? lastTab;
  final DateTime? firstLaunchedAt;
}

/// legacy collection 전체를 한 시점의 값으로 고정한 snapshot이다.
class LegacySnapshot {
  const LegacySnapshot({
    required this.items,
    required this.events,
    this.preferences,
  });

  final List<LegacyItemData> items;
  final List<LegacyWearEventData> events;
  final LegacyPreferencesData? preferences;
}
