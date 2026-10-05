import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

/// Where the pipeline publishes its JSON (GitHub Pages).
/// Overridable for tests and forks.
class Endpoints {
  static const base = String.fromEnvironment(
    'BULLINDICATOR_DATA_BASE',
    defaultValue: 'https://bull.koini.io/data',
  );
  static Uri latest() => Uri.parse('$base/latest.json');
  static Uri history() => Uri.parse('$base/history.json');
  static Uri charts() => Uri.parse('$base/charts.json');
}

enum LoadSource { network, cache, none }

class Loaded<T> {
  final T? data;
  final LoadSource source;
  final Object? error;
  const Loaded(this.data, this.source, [this.error]);
  bool get ok => data != null;
}

/// Repository: network-first with persistent cache fallback.
/// The app shows cached data with a stale banner rather than nothing,
/// and never fabricates values.
class Repo {
  final http.Client client;
  Repo({http.Client? client}) : client = client ?? http.Client();

  Future<Loaded<CycleData>> latest() async =>
      _load('latest', Endpoints.latest(), (j) => CycleData.fromJson(j));

  Future<Loaded<List<HistoryRow>>> history() async => _loadList(
      'history', Endpoints.history(), (l) => l.map((e) => HistoryRow.fromJson(e)).toList());

  Future<Loaded<Map<String, dynamic>>> charts() async =>
      _load('charts', Endpoints.charts(), (j) => j);

  Future<Loaded<T>> _load<T>(
      String key, Uri uri, T Function(Map<String, dynamic>) parse) async {
    try {
      final res = await client.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final body = utf8.decode(res.bodyBytes);
      final parsed = parse(jsonDecode(body) as Map<String, dynamic>);
      await _cachePut(key, body);
      return Loaded(parsed, LoadSource.network);
    } catch (e) {
      final cached = await _cacheGet(key);
      if (cached != null) {
        try {
          return Loaded(parse(jsonDecode(cached) as Map<String, dynamic>),
              LoadSource.cache, e);
        } catch (_) {}
      }
      return Loaded(null, LoadSource.none, e);
    }
  }

  Future<Loaded<T>> _loadList<T>(
      String key, Uri uri, T Function(List<Map<String, dynamic>>) parse) async {
    try {
      final res = await client.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final body = utf8.decode(res.bodyBytes);
      final parsed =
          parse((jsonDecode(body) as List).cast<Map<String, dynamic>>());
      await _cachePut(key, body);
      return Loaded(parsed, LoadSource.network);
    } catch (e) {
      final cached = await _cacheGet(key);
      if (cached != null) {
        try {
          return Loaded(
              parse((jsonDecode(cached) as List).cast<Map<String, dynamic>>()),
              LoadSource.cache,
              e);
        } catch (_) {}
      }
      return Loaded(null, LoadSource.none, e);
    }
  }

  Future<void> _cachePut(String key, String body) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('cache_$key', body);
  }

  Future<String?> _cacheGet(String key) async {
    final p = await SharedPreferences.getInstance();
    return p.getString('cache_$key');
  }
}
