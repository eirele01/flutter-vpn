import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagani_vpn/presentation/providers/reward_providers.dart';

import 'dart:async';

class RewardCard extends ConsumerStatefulWidget {
  final VoidCallback onWatchAd;
  final bool isAdLoading;
  final bool isVpnConnected;

  const RewardCard({
    super.key,
    required this.onWatchAd,
    required this.isAdLoading,
    required this.isVpnConnected,
  });

  @override
  ConsumerState<RewardCard> createState() => _RewardCardState();
}

class _RewardCardState extends ConsumerState<RewardCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rewardState = ref.watch(rewardProvider);
    final pulseCount = ref.watch(pulseRewardProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                color: Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "Remaining Time",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Text(
                _formatSeconds(rewardState.remainingSeconds),
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Limit: ${rewardState.adsWatchedToday}/6",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (rewardState.isOnCooldown)
                      Text(
                        "Cooldown: ${rewardState.cooldownMinutesRemaining}m remaining",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                        ),
                      ),
                  ],
                ),
              ),
              TweenAnimationBuilder<double>(
                key: ValueKey('pulse_$pulseCount'),
                duration: const Duration(milliseconds: 500),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  // value goes from 0.0 to 1.0
                  // we want scale to go from 1.0 to 1.06 and back to 1.0
                  // This formula creates a triangle wave for the scale: 1.0 -> 1.06 -> 1.0
                  final t =
                      pulseCount > 0 ? (1.0 - (2 * (value - 0.5)).abs()) : 0.0;
                  final scale = 1.0 + (0.06 * t);
                  return Transform.scale(scale: scale, child: child);
                },
                child: ElevatedButton.icon(
                  onPressed:
                      (rewardState.canWatchAd &&
                              !widget.isAdLoading &&
                              !widget.isVpnConnected)
                          ? widget.onWatchAd
                          : null,
                  icon:
                      widget.isAdLoading
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.play_circle_fill, size: 18),
                  label: Text(
                    widget.isVpnConnected
                        ? "Disconnect first"
                        : rewardState.adsWatchedToday >= 6
                        ? "Daily Limit"
                        : "Get 2 Hours",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withAlpha(20)
                            : Colors.grey.shade300,
                    disabledForegroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withAlpha(50)
                            : Colors.grey.shade600,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSeconds(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
}
