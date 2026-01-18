# BaganiVPN Implementation Plan

This document outlines the roadmap to evolve BaganiVPN from its current prototype state into a production-ready, robust Android/iOS VPN application.

## Phase 1: Native Core & Connectivity Verification (Critical)

**Objective**: Ensure the VPN engine reliably connects, disconnects, and reports status on physical devices.

- [ ] **Native Configuration Verification**
  - [ ] **Android**: Verify `AndroidManifest.xml` permissions (`FOREGROUND_SERVICE`, `BIND_VPN_SERVICE`).
  - [ ] **iOS**: Verify `Info.plist` and `NetworkExtension` entitlement checks (Must match Bundle ID).
- [ ] **VPN Engine Harness**
  - [ ] Add detailed logging to `VpnEngineImpl` streams to diagnose connection phases.
  - [ ] Verify `OpenVPN` config sanitation logic (handling of `block-outside-dns`, `route-method`, etc., often needed for mobile).
- [ ] **Connection Testing**
  - [ ] Test connection to a known working VPNGate server.
  - [ ] Verify disconnection cleans up resources.

## Phase 2: Settings & Persistence State

**Objective**: Make the `SettingsScreen` functional and persist user preferences.

- [ ] **Preference Storage**
  - [ ] Create `SettingsRepository` using `Hive` or `shared_preferences`.
  - [ ] Define keys: `theme_mode`, `kill_switch_enabled`, `auto_refresh_enabled`.
- [ ] **Settings Logic Integration**
  - [ ] Create `SettingsNotifier`/`Provider` (Riverpod).
  - [ ] Connect `SettingsScreen` UI toggles to the Provider.
  - [ ] Implement live Theme switching.
- [ ] **Feature Implementation**
  - [ ] **Kill Switch**: Implement logic to detect VPN drop and block network (requires platform channel or Android native code often, or simple "Auto-Reconnect" policy).
  - [ ] **Auto-Refresh**: Wire up `Workmanager` constraints to this setting.

## Phase 3: Data Layer Robustness

**Objective**: Ensure server list availability even when the primary API is flaky.

- [ ] **API Resilience**
  - [ ] Improve `VpnGateParser` to handle malformed CSV lines without crashing entire batch.
  - [ ] implement a fallback mirror if the primary VPNGate URL is blocked.
- [ ] **Advanced Caching**
  - [ ] Optimize `BackgroundFetchService` to only notify user if _new_ faster servers are found.
  - [ ] Implement "Favorite Servers" feature (Bookmark server ID).

## Phase 4: UI/UX Polish (Modern Aesthetics)

**Objective**: "Wow" the user as per the design guidelines.

- [ ] **Visual Overhaul**
  - [ ] Replace standard `Card` with Glassmorphism containers.
  - [ ] Add Lottie animations for "Connecting" and "Connected" states.
  - [ ] Improve flag icons caching/loading.
- [ ] **User Feedback**
  - [ ] Add a connection duration timer.
  - [ ] Add a real-time graph for download/upload speed using the simple text stats we have.

## Executing This Plan

We will start with **Phase 2 (Settings & Persistence)** as it is purely Dart/Flutter and establishes the app's structure, while you (User) verify the **Phase 1 (Native)** requirements on your local emulator/device side.
