# Phase 2: Settings & Persistence Implementation Guide

## Objective

Implement a robust settings management system that persists user preferences (Theme, Kill Switch, Auto-connect) and reacts to changes in real-time.

## 1. Domain Layer: Define the Contract

**File**: `lib/domain/repositories/settings_repository.dart`

- Create an abstract class `SettingsRepository`.
- Define methods:
  - `Future<void> setThemeMode(ThemeMode mode)`
  - `ThemeMode getThemeMode()`
  - `Future<void> setKillSwitch(bool enabled)`
  - `bool isKillSwitchEnabled()`
  - `Future<void> setAutoRefresh(bool enabled)`
  - `bool isAutoRefreshEnabled()`

## 2. Data Layer: Implementation with Hive

**File**: `lib/data/repositories/settings_repository_impl.dart`

- Implement `SettingsRepository`.
- Use a dedicated Hive box (e.g., `'settings_box'`).
- Map `ThemeMode` enum to/from String/Int for storage.

## 3. Presentation Layer: State Management

**File**: `lib/presentation/providers/settings_provider.dart`

- Create a `SettingsState` class (immutable data class) holding:
  - `ThemeMode themeMode`
  - `bool isKillSwitch`
  - `bool isAutoRefresh`
- Create a `SettingsNotifier` extending `StateNotifier<SettingsState>`.
- Use `riverpod` to expose `settingsProvider`.
  - On init: Load values from Repository -> update state.
  - On change: Update Repository -> update state.

## 4. UI Integration

**File**: `lib/presentation/screens/settings_screen.dart`

- Watch `settingsProvider` in the `build` method.
- Replace dummy `true`/`false` values in `SwitchListTile` with `ref.watch(settingsProvider).property`.
- Replace dummy `onChanged` callbacks with `ref.read(settingsProvider.notifier).method()`.
- **Theme Logic**: Update `helpers/app_theme.dart` or `main.dart` to watch the `settingsProvider` for the actual `themeMode` property so the app switches instantly.

## 5. Feature Wiring

- **Kill Switch**: Consumed by `VpnController` (in `vpn_providers.dart`) to determine behavior on disconnect.
- **Auto Refresh**: Consumed by `main.dart` or `BackgroundFetchService` to determine if `Workmanager` tasks should run or skip.
