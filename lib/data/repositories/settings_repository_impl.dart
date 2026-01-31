import 'package:bagani_vpn/domain/repositories/settings_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final Box _box;

  static const String _kThemeMode = 'theme_mode';
  static const String _kKillSwitch = 'kill_switch';
  static const String _kAutoRefresh = 'auto_refresh';

  SettingsRepositoryImpl(this._box);

  @override
  String getThemeMode() {
    return _box.get(_kThemeMode, defaultValue: 'system');
  }

  @override
  Future<void> setThemeMode(String mode) async {
    await _box.put(_kThemeMode, mode);
  }

  @override
  bool isKillSwitchEnabled() {
    return _box.get(_kKillSwitch, defaultValue: false);
  }

  @override
  Future<void> setKillSwitch(bool enabled) async {
    await _box.put(_kKillSwitch, enabled);
  }

  @override
  bool isAutoRefreshEnabled() {
    // Default to true for auto-refresh
    return _box.get(_kAutoRefresh, defaultValue: true);
  }

  @override
  Future<void> setAutoRefresh(bool enabled) async {
    await _box.put(_kAutoRefresh, enabled);
  }
}
