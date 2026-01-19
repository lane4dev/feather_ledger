import 'package:shared_preferences/shared_preferences.dart';

/// Mock SharedPreferences for testing purposes
class MockSharedPreferences implements SharedPreferences {
  final Map<String, Object> _storage = {};

  @override
  String? getString(String key) {
    return _storage[key] as String?;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Object? get(String key) {
    return _storage[key];
  }

  @override
  bool? getBool(String key) {
    return _storage[key] as bool?;
  }

  @override
  double? getDouble(String key) {
    return _storage[key] as double?;
  }

  @override
  int? getInt(String key) {
    return _storage[key] as int?;
  }

  @override
  List<String>? getStringList(String key) {
    return _storage[key] as List<String>?;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _storage.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _storage.clear();
    return true;
  }

  @override
  Set<String> getKeys() {
    return _storage.keys.toSet();
  }

  @override
  bool containsKey(String key) {
    return _storage.containsKey(key);
  }

  @override
  Future<void> reload() async {
    // No-op for mock
  }

  @override
  Future<bool> commit() async {
    return true;
  }

  // Helper method for testing
  void setMockString(String key, String value) {
    _storage[key] = value;
  }

  void reset() {
    _storage.clear();
  }
}
