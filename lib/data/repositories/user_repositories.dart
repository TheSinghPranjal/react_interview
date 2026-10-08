import '../../core/services/storage_service.dart';
import '../models/app_settings.dart';
import '../models/bookmark.dart';
import '../models/user_progress.dart';

class ProgressRepository {
  ProgressRepository(this._store);

  static const String key = 'user_progress';
  final KeyValueStore _store;

  UserProgress load() {
    final json = _store.readJson(key);
    if (json == null) return const UserProgress();
    try {
      return UserProgress.fromJson(json);
    } catch (_) {
      return const UserProgress();
    }
  }

  Future<bool> save(UserProgress progress) =>
      _store.writeJson(key, progress.toJson());

  Future<void> reset() => _store.delete(key);
}

class BookmarkRepository {
  BookmarkRepository(this._store);

  static const String key = 'bookmarks';
  final KeyValueStore _store;

  List<Bookmark> load() {
    final list = _store.readJsonList(key);
    if (list == null) return const [];
    final seen = <String>{};
    return [
      for (final e in list)
        if (e is Map)
          if (Bookmark.tryParse(e.cast<String, Object?>()) case final b?)
            if (seen.add(b.key)) b,
    ];
  }

  Future<bool> save(List<Bookmark> bookmarks) =>
      _store.writeJson(key, bookmarks.map((b) => b.toJson()).toList());

  Future<void> reset() => _store.delete(key);
}

class SettingsRepository {
  SettingsRepository(this._store);

  static const String key = 'settings';
  final KeyValueStore _store;

  AppSettings load() {
    final json = _store.readJson(key);
    return json == null ? const AppSettings() : AppSettings.fromJson(json);
  }

  Future<bool> save(AppSettings settings) =>
      _store.writeJson(key, settings.toJson());
}
