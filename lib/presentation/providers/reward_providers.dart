import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bagani_vpn/core/constants/app_constants.dart';

class RewardState {
  final int remainingSeconds;
  final int adsWatchedToday;
  final DateTime? lastAdWatchedAt;
  final DateTime lastResetDate;

  RewardState({
    required this.remainingSeconds,
    required this.adsWatchedToday,
    this.lastAdWatchedAt,
    required this.lastResetDate,
  });

  bool get isOnCooldown {
    if (lastAdWatchedAt == null) return false;
    return DateTime.now().difference(lastAdWatchedAt!).inMinutes < 15;
  }

  int get cooldownMinutesRemaining {
    if (lastAdWatchedAt == null) return 0;
    final diff = 15 - DateTime.now().difference(lastAdWatchedAt!).inMinutes;
    return diff > 0 ? diff : 0;
  }

  bool get canWatchAd {
    if (adsWatchedToday >= 6) return false;
    if (isOnCooldown) return false;
    // Max 12 hours = 12 * 3600 = 43200 seconds
    if (remainingSeconds >= 43200) return false;
    return true;
  }

  RewardState copyWith({
    int? remainingSeconds,
    int? adsWatchedToday,
    DateTime? lastAdWatchedAt,
    DateTime? lastResetDate,
  }) {
    return RewardState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      adsWatchedToday: adsWatchedToday ?? this.adsWatchedToday,
      lastAdWatchedAt: lastAdWatchedAt ?? this.lastAdWatchedAt,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }
}

class RewardController extends StateNotifier<RewardState> {
  Timer? _timer;

  RewardController()
    : super(
        RewardState(
          remainingSeconds: 0,
          adsWatchedToday: 0,
          lastResetDate: DateTime.now(),
        ),
      ) {
    _loadState();
    _startMidnightCheck();
  }

  void _loadState() {
    final box = Hive.box(AppConstants.hiveBoxName);
    final remaining =
        box.get('reward_remaining_seconds', defaultValue: 0) as int;
    final watched = box.get('reward_ads_today', defaultValue: 0) as int;
    final lastAd = box.get('reward_last_ad_at') as DateTime?;
    final lastResetStr = box.get('reward_last_reset_date');

    DateTime lastReset =
        lastResetStr != null ? DateTime.parse(lastResetStr) : DateTime.now();

    state = RewardState(
      remainingSeconds: remaining,
      adsWatchedToday: watched,
      lastAdWatchedAt: lastAd,
      lastResetDate: lastReset,
    );

    _checkMidnightReset();
  }

  void _saveState() {
    final box = Hive.box(AppConstants.hiveBoxName);
    box.put('reward_remaining_seconds', state.remainingSeconds);
    box.put('reward_ads_today', state.adsWatchedToday);
    box.put('reward_last_ad_at', state.lastAdWatchedAt);
    box.put('reward_last_reset_date', state.lastResetDate.toIso8601String());
  }

  void _checkMidnightReset() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastReset = DateTime(
      state.lastResetDate.year,
      state.lastResetDate.month,
      state.lastResetDate.day,
    );

    if (today.isAfter(lastReset)) {
      state = state.copyWith(adsWatchedToday: 0, lastResetDate: now);
      _saveState();
    }
  }

  void _startMidnightCheck() {
    // Check every hour
    _timer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkMidnightReset();
    });
  }

  void addReward() {
    // 2 hours = 7200 seconds
    state = state.copyWith(
      remainingSeconds: state.remainingSeconds + 7200,
      adsWatchedToday: state.adsWatchedToday + 1,
      lastAdWatchedAt: DateTime.now(),
    );
    _saveState();
  }

  void useOneSecond() {
    if (state.remainingSeconds > 0) {
      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      // We don't save every second to Hive to avoid performance issues,
      // but we should save periodically or on disconnect.
      if (state.remainingSeconds % 30 == 0) {
        _saveState();
      }
    }
  }

  void saveCurrentTime() {
    _saveState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final rewardProvider = StateNotifierProvider<RewardController, RewardState>((
  ref,
) {
  return RewardController();
});

final pulseRewardProvider = StateProvider<int>((ref) => 0);
