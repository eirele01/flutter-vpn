abstract class SettingsRepository {
  /// Save the user's preferred theme mode
  Future<void> setThemeMode(String mode);

  /// Get the saved theme mode (light, dark, system)
  String getThemeMode();

  /// Save the Kill Switch preference
  Future<void> setKillSwitch(bool enabled);

  /// Get the Kill Switch preference
  bool isKillSwitchEnabled();

  /// Save the Auto Refresh preference
  Future<void> setAutoRefresh(bool enabled);

  /// Get the Auto Refresh preference
  bool isAutoRefreshEnabled();
}
