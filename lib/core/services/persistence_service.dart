import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final persistenceServiceProvider = Provider<PersistenceService>((ref) {
  return PersistenceService();
});

class PersistenceService {
  static const String _unlockedKey = 'purchased_subjects';

  Future<Set<String>> getUnlockedSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getStringList(_unlockedKey) ?? [];
    return unlocked.toSet();
  }

  Future<void> unlockSubject(String subjectIdentifier) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_unlockedKey) ?? [];
    if (!current.contains(subjectIdentifier)) {
      current.add(subjectIdentifier);
      await prefs.setStringList(_unlockedKey, current);
    }
  }

  Future<void> unlockAllInYear(String yearMarker) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_unlockedKey) ?? [];
    if (!current.contains(yearMarker)) {
      current.add(yearMarker);
      await prefs.setStringList(_unlockedKey, current);
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_unlockedKey);
  }
}
