import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/connection_profile.dart';
import '../models/metric_config.dart';

class PreferencesRepository {
  static const profilesKey = 'picur.connection_profiles';
  static const metricsKey = 'picur.metrics';
  static const activeKey = 'picur.active_connection';
  static const themeKey = 'picur.dark_theme';
  static const intervalKey = 'picur.no_signal_seconds';

  Future<List<ConnectionProfile>> profiles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(profilesKey);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((item) => ConnectionProfile.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveProfiles(List<ConnectionProfile> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(profilesKey, jsonEncode(profiles.map((p) => p.toJson()).toList()));
  }

  Future<String?> activeConnection() async =>
      (await SharedPreferences.getInstance()).getString(activeKey);

  Future<void> setActiveConnection(String id) async =>
      (await SharedPreferences.getInstance()).setString(activeKey, id);

  Future<List<MetricConfig>> metrics() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(metricsKey);
    if (raw == null) return defaultMetrics;
    try {
      return (jsonDecode(raw) as List)
          .map((item) => MetricConfig.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return defaultMetrics;
    }
  }

  Future<void> saveMetrics(List<MetricConfig> metrics) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(metricsKey, jsonEncode(metrics.map((m) => m.toJson()).toList()));
  }

  Future<bool> darkTheme() async =>
      (await SharedPreferences.getInstance()).getBool(themeKey) ?? false;

  Future<void> setDarkTheme(bool value) async =>
      (await SharedPreferences.getInstance()).setBool(themeKey, value);

  Future<int> noSignalSeconds() async =>
      (await SharedPreferences.getInstance()).getInt(intervalKey) ?? 30;
}
