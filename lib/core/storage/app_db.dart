import 'package:hive_flutter/hive_flutter.dart';

/// Provides the application's single lazily initialized Hive key-value store.
///
/// Call [init] during application startup before accessing any values. All
/// reads go through [_store], which fails fast when initialization was skipped.
class AppDb {
  AppDb._();

  static final AppDb instance = AppDb._();
  static const String _boxName = 'emailkick_store';

  Box<dynamic>? _box;

  /// Initializes Hive for Flutter and opens the box shared by the application.
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  /// Returns the open store or reports an application lifecycle error.
  Box<dynamic> get _store {
    final Box<dynamic>? box = _box;
    if (box == null) {
      throw StateError(
        'AppDb not initialized. Call AppDb.instance.init() first.',
      );
    }
    return box;
  }

  bool get isEmpty => _store.isEmpty;

  /// Reads [key] only when its persisted value has the expected string type.
  String? getString(String key) {
    final dynamic value = _store.get(key);
    if (value is String) {
      return value;
    }
    return null;
  }

  /// Reads a string list while discarding entries of unexpected types.
  List<String>? getStringList(String key) {
    final dynamic value = _store.get(key);
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return null;
  }

  /// Persists one string value under [key].
  Future<void> setString(String key, String value) async {
    await _store.put(key, value);
  }

  /// Persists a list of strings under [key].
  Future<void> setStringList(String key, List<String> values) async {
    await _store.put(key, values);
  }

  /// Deletes [key], leaving other stored application state untouched.
  Future<void> remove(String key) async {
    await _store.delete(key);
  }
}
