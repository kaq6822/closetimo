import 'package:isar/isar.dart';

import '../models/user_preferences.dart';
import 'preferences_repository.dart';

class IsarPreferencesRepository implements PreferencesRepository {
  IsarPreferencesRepository({required Isar isar}) : _isar = isar;

  final Isar _isar;

  @override
  Stream<UserPreferences> watch() async* {
    final initial = await _isar.userPreferences.get(UserPreferences.singletonId);
    yield initial ?? UserPreferences.defaults();
    await for (final _ in _isar.userPreferences.watchLazy()) {
      final p = await _isar.userPreferences.get(UserPreferences.singletonId);
      yield p ?? UserPreferences.defaults();
    }
  }

  Future<void> _mutate(void Function(UserPreferences) edit) async {
    await _isar.writeTxn(() async {
      final cur =
          await _isar.userPreferences.get(UserPreferences.singletonId) ??
              UserPreferences.defaults();
      edit(cur);
      await _isar.userPreferences.put(cur);
    });
  }

  @override
  Future<void> setNotifWash(bool v) => _mutate((p) => p.notifWash = v);

  @override
  Future<void> setNotifWeekly(bool v) => _mutate((p) => p.notifWeekly = v);

  @override
  Future<void> setNotifUnworn(bool v) => _mutate((p) => p.notifUnworn = v);

  @override
  Future<void> setAccent(String accentKey) =>
      _mutate((p) => p.accent = accentKey);

  @override
  Future<void> setLastTab(String tab) => _mutate((p) => p.lastTab = tab);
}
