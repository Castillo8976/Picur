import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const prealertKey = 'picur.prealert';
  static const alertKey = 'picur.alert';
  static const dryKey = 'picur.dry';
  static const wetKey = 'picur.wet';

  Future<(double, double)> thresholds() async {
    final p = await SharedPreferences.getInstance();
    return (p.getDouble(prealertKey) ?? 60, p.getDouble(alertKey) ?? 75);
  }

  Future<void> saveThresholds(double prealert, double alert) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(prealertKey, prealert);
    await p.setDouble(alertKey, alert);
  }

  Future<(int?, int?)> calibration() async {
    final p = await SharedPreferences.getInstance();
    return (p.getInt(dryKey), p.getInt(wetKey));
  }

  Future<void> saveCalibration(int dry, int wet) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(dryKey, dry);
    await p.setInt(wetKey, wet);
  }
}
