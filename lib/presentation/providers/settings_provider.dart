import 'package:bagani_vpn/core/constants/app_constants.dart';
import 'package:bagani_vpn/data/repositories/settings_repository_impl.dart';
import 'package:bagani_vpn/domain/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// --- State Class ---
class SettingsState {
  final ThemeMode themeMode;
  final bool isKillSwitchEnabled;
  final bool isAutoRefreshEnabled;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.isKillSwitchEnabled = false,
    this.isAutoRefreshEnabled = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? isKillSwitchEnabled,
    bool? isAutoRefreshEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      isKillSwitchEnabled: isKillSwitchEnabled ?? this.isKillSwitchEnabled,
      isAutoRefreshEnabled: isAutoRefreshEnabled ?? this.isAutoRefreshEnabled,
    );
  }
}

// --- Repository Provider ---
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final box = Hive.box(AppConstants.hiveBoxName);
  return SettingsRepositoryImpl(box);
});

// --- Controller ---
class SettingsController extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;

  SettingsController(this._repository) : super(const SettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final themeStr = _repository.getThemeMode();
    final killSwitch = _repository.isKillSwitchEnabled();
    final autoRefresh = _repository.isAutoRefreshEnabled();

    state = SettingsState(
      themeMode: _parseThemeMode(themeStr),
      isKillSwitchEnabled: killSwitch,
      isAutoRefreshEnabled: autoRefresh,
    );
  }

  Future<void> toggleTheme() async {
    final nextIndex = (state.themeMode.index + 1) % ThemeMode.values.length;
    final newMode = ThemeMode.values[nextIndex];

    // Save as string
    await _repository.setThemeMode(_themeModeToString(newMode));

    // Update state
    state = state.copyWith(themeMode: newMode);
  }

  Future<void> toggleKillSwitch(bool value) async {
    await _repository.setKillSwitch(value);
    state = state.copyWith(isKillSwitchEnabled: value);
  }

  Future<void> toggleAutoRefresh(bool value) async {
    await _repository.setAutoRefresh(value);
    state = state.copyWith(isAutoRefreshEnabled: value);
  }

  // Helpers
  ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    return mode.toString().split('.').last;
  }
}

// --- Provider ---
final settingsProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
      final repo = ref.watch(settingsRepositoryProvider);
      return SettingsController(repo);
    });
