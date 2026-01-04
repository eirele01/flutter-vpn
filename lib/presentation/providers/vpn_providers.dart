import 'dart:async';
import 'dart:convert';
import 'package:bagani_vpn/presentation/providers/reward_providers.dart';
import 'package:flutter/material.dart';

import 'package:bagani_vpn/data/datasources/vpn_engine_impl.dart';
import 'package:bagani_vpn/data/datasources/vpn_gate_api_client.dart';
import 'package:bagani_vpn/data/repositories/server_repository_impl.dart';
import 'package:bagani_vpn/domain/entities/vpn_server.dart';
import 'package:bagani_vpn/domain/repositories/server_repository.dart';
import 'package:bagani_vpn/domain/repositories/vpn_engine.dart';
import 'package:bagani_vpn/core/constants/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Service Dependencies
final dioProvider = Provider((ref) => Dio());

final apiClientProvider = Provider((ref) {
  return VpnGateApiClient(ref.watch(dioProvider));
});

final serverRepositoryProvider = Provider<ServerRepository>((ref) {
  return ServerRepositoryImpl(ref.watch(apiClientProvider));
});

final vpnEngineProvider = Provider<VpnEngine>((ref) {
  return VpnEngineImpl();
});

// Logic Providers

// 1. Server List State
final serverForceRefreshProvider = StateProvider((ref) => false);

final serverListProvider = FutureProvider<List<VpnServer>>((ref) async {
  final repo = ref.watch(serverRepositoryProvider);
  final forceRefresh = ref.watch(serverForceRefreshProvider);
  final servers = await repo.getServers(forceRefresh: forceRefresh);

  // Reset force refresh after use
  if (forceRefresh) {
    Future.microtask(
      () => ref.read(serverForceRefreshProvider.notifier).state = false,
    );
  }

  return servers;
});

// 2. Refresh Controller
class ServerListNotifier extends StateNotifier<AsyncValue<List<VpnServer>>> {
  final ServerRepository _repo;
  ServerListNotifier(this._repo) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final servers = await _repo.getServers(forceRefresh: true);
      state = AsyncValue.data(servers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// 3. Connection State
class VpnState {
  final String stage; // disconnected, connecting, connected, error
  final String? status;
  final VpnServer? currentServer;
  final DateTime? connectedSince;
  final String? log;
  final String byteIn;
  final String byteOut;
  final String byteInTotal;
  final String byteOutTotal;

  final Duration duration;

  VpnState({
    required this.stage,
    this.status,
    this.currentServer,
    this.connectedSince,
    this.log,
    this.byteIn = "0.0 B",
    this.byteOut = "0.0 B",
    this.byteInTotal = "0.0 B",
    this.byteOutTotal = "0.0 B",
    this.duration = Duration.zero,
  });

  VpnState copyWith({
    String? stage,
    String? status,
    VpnServer? currentServer,
    DateTime? connectedSince,
    String? log,
    String? byteIn,
    String? byteOut,
    String? byteInTotal,
    String? byteOutTotal,
    Duration? duration,
  }) {
    return VpnState(
      stage: stage ?? this.stage,
      status: status ?? this.status,
      currentServer: currentServer ?? this.currentServer,
      connectedSince: connectedSince ?? this.connectedSince,
      log: log ?? this.log,
      byteIn: byteIn ?? this.byteIn,
      byteOut: byteOut ?? this.byteOut,
      byteInTotal: byteInTotal ?? this.byteInTotal,
      byteOutTotal: byteOutTotal ?? this.byteOutTotal,
      duration: duration ?? this.duration,
    );
  }

  // --- UI Helpers ---

  bool get isConnecting =>
      stage == 'connecting' ||
      stage == 'wait_connection' ||
      stage == 'tcp_connect' ||
      stage == 'authenticating' ||
      stage == 'get_config' ||
      stage == 'vpn_generate_config';

  String get displayStage {
    if (stage == 'connected') return "Protected";
    if (isConnecting) return "Securing...";
    if (stage == 'error') return "Failed to Secure";
    return "Not Protected";
  }

  // Soft Pastel Palette
  Color statusColor(BuildContext context) {
    if (stage == 'connected') return const Color(0xFF7ED9A7); // Pastel Green
    if (isConnecting) return const Color(0xFF8ECDF4); // Pastel Blue
    if (stage == 'error') return const Color(0xFFFF6B6B); // Primary Pastel Red
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white24
        : Colors.grey.shade400;
  }
}

class VpnController extends StateNotifier<VpnState> {
  final VpnEngine _engine;
  final RewardController _rewardController;
  Timer? _timer;

  VpnController(this._engine, this._rewardController)
    : super(VpnState(stage: 'disconnected')) {
    _loadState().then((_) => _init());
  }

  Future<void> _loadState() async {
    final box = Hive.box(AppConstants.hiveBoxName);
    final stage = box.get('vpn_stage', defaultValue: 'disconnected');
    final server = box.get('vpn_server') as VpnServer?;
    final since = box.get('vpn_since') as DateTime?;

    state = state.copyWith(
      stage: stage,
      currentServer: server,
      connectedSince: since,
    );

    // Only resume timer if we were connected AND the since date is reasonable (not null)
    if (stage == 'connected' && since != null) {
      _startTimer();
    }
  }

  Future<void> _saveState() async {
    try {
      final box = Hive.box(AppConstants.hiveBoxName);
      await box.put('vpn_stage', state.stage);
      await box.put('vpn_server', state.currentServer);
      await box.put('vpn_since', state.connectedSince);
    } catch (_) {
      // Ignore hive errors during save
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _init() async {
    // Initialize the engine first
    await _engine.initialize();

    _engine.stageStream.listen((stage) {
      // Map stage to lower case or enum
      final s = stage.toLowerCase();

      if (s == 'connected') {
        final now = DateTime.now();
        state = state.copyWith(
          stage: 'connected',
          connectedSince: state.connectedSince ?? now,
          duration:
              state.connectedSince != null
                  ? DateTime.now().difference(state.connectedSince!)
                  : Duration.zero,
        );
        _startTimer();
      } else if (s == 'disconnected') {
        _stopTimer();
        state = state.copyWith(
          stage: 'disconnected',
          currentServer: null,
          connectedSince: null,
          duration: Duration.zero,
        );
      } else {
        state = state.copyWith(stage: s); // connecting, etc.
      }
      _saveState();
    });

    _engine.statusStream.listen((status) {
      if (status == null) {
        return;
      }

      // Check if it's a stats message: {connected_on: ..., byte_in: ..., ...}
      if (status.contains('byte_in:')) {
        try {
          final byteInMatch = RegExp(r'byte_in: (\d+)').firstMatch(status);
          final byteOutMatch = RegExp(r'byte_out: (\d+)').firstMatch(status);

          if (byteInMatch != null && byteOutMatch != null) {
            final bIn = byteInMatch.group(1);
            final bOut = byteOutMatch.group(1);

            state = state.copyWith(
              byteInTotal: _formatBytes(bIn),
              byteOutTotal: _formatBytes(bOut),
              // Optional: if the plugin gives speed, we could map it to byteIn/byteOut
            );
          }
        } catch (_) {}
      } else {
        // Regular status message
        state = state.copyWith(status: status);
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Defensive: Stop timer if we are no longer in connected stage
      if (state.stage != 'connected' || state.connectedSince == null) {
        timer.cancel();
        _timer = null;
        return;
      }

      state = state.copyWith(
        duration: DateTime.now().difference(state.connectedSince!),
      );

      // Drain rewarded time
      _rewardController.useOneSecond();

      // Check if time is out
      if (_rewardController.state.remainingSeconds <= 0) {
        disconnect();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatBytes(String? bytesStr) {
    if (bytesStr == null) {
      return "0.0 B";
    }
    double bytes = double.tryParse(bytesStr) ?? 0;
    if (bytes < 1024) {
      return "${bytes.toStringAsFixed(1)} B";
    }
    if (bytes < 1024 * 1024) {
      return "${(bytes / 1024).toStringAsFixed(1)} KB";
    }
    if (bytes < 1024 * 1024 * 1024) {
      return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    }
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB";
  }

  Future<void> connect(VpnServer server) async {
    // Reward check
    if (_rewardController.state.remainingSeconds <= 0) {
      return;
    }

    // If same server and already connected, do nothing.
    if (state.stage == 'connected' && state.currentServer?.ip == server.ip) {
      return;
    }

    // If connected to a DIFFERENT server or currently connecting, disconnect first
    if (state.stage == 'connected' || state.isConnecting) {
      try {
        await _engine.disconnect();
      } catch (_) {
        // Plugin might throw if service isn't active yet
      }
      // Wait for the engine to signal disconnection or just a short safety delay
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    state = state.copyWith(
      stage: 'connecting',
      currentServer: server,
      status: "Starting VPN engine...",
      connectedSince: null, // Reset since we are connecting now
      duration: Duration.zero,
    );
    _saveState();

    // Make sure we wait for initialization if it's still running
    await _engine.initialize();

    state = state.copyWith(status: "Decoding config...");
    String config = "";
    try {
      config = _sanitizeConfig(_decodeConfig(server.openVpnConfigData));
    } catch (e) {
      state = state.copyWith(stage: 'error', status: 'Failed to decode config');
      return;
    }

    try {
      await _engine.connect(config, server.countryLong);
    } catch (e) {
      state = state.copyWith(stage: 'error', status: e.toString());
    }
  }

  Future<void> fastConnect(List<VpnServer> servers) async {
    if (_rewardController.state.remainingSeconds <= 0) {
      return;
    }

    if (state.isConnecting || state.stage == 'connected') {
      return;
    }
    if (servers.isEmpty) {
      state = state.copyWith(stage: 'error', status: 'No servers available');
      return;
    }

    state = state.copyWith(
      stage: 'connecting',
      connectedSince: null,
      duration: Duration.zero,
    ); // Indicates generic connecting

    // Sort servers by quality
    final candidates = List<VpnServer>.from(servers)
      ..sort((a, b) => b.qualityScore.compareTo(a.qualityScore));

    // Take top 5
    final topCandidates = candidates.take(5).toList();

    for (final server in topCandidates) {
      if (state.status == 'User Cancelled') {
        break; // User cancelled
      }

      // Try connecting
      state = state.copyWith(
        stage: 'connecting',
        currentServer: server,
        status: "Trying ${server.countryShort}...",
        connectedSince: null,
        duration: Duration.zero,
      );
      _saveState();

      String config;
      try {
        config = _sanitizeConfig(_decodeConfig(server.openVpnConfigData));
      } catch (e) {
        continue;
      }

      await _engine.connect(config, server.countryLong);

      // Wait for result with timeout
      final success = await _waitForConnection(
        timeout: const Duration(seconds: 40),
      );
      if (success) {
        state = state.copyWith(status: "Successfully connected!");
        return; // Connected!
      } else {
        state = state.copyWith(
          status: "${server.countryShort} timed out. Trying next...",
        );
        // Failed, disconnect and try next
        await _engine.disconnect();
        // Allow a small delay for cleanup
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    // If we get here, all failed
    state = state.copyWith(
      stage: 'error',
      status: 'Timed out. Please try a different country.',
      currentServer: null,
    );
  }

  String _sanitizeConfig(String config) {
    if (config.isEmpty) {
      return config;
    }

    final lines = config.split('\n');
    final result = <String>[];
    bool hasAuthUserPass = false;
    bool inBlock = false;

    for (var line in lines) {
      final l = line.trim();

      // Handle XML blocks like <ca>, <cert>, <key>
      if (l.startsWith('<') && l.endsWith('>')) {
        inBlock = !l.startsWith('</');
        result.add(l);
        continue;
      }
      if (inBlock) {
        result.add(l);
        continue;
      }

      // Skip comments and empty lines
      if (l.isEmpty || l.startsWith('#') || l.startsWith(';')) {
        continue;
      }

      // Force TUN mode
      if (l.startsWith('dev ')) {
        result.add('dev tun');
        continue;
      }

      if (l.startsWith('auth-user-pass')) {
        hasAuthUserPass = true;
      }

      // Remove problematic commands
      if (l.startsWith('route-method') ||
          l.startsWith('route-delay') ||
          l.startsWith('ip-win32') ||
          l.startsWith('block-outside-dns') ||
          l.startsWith('dhcp-option DNS') ||
          l.startsWith('register-dns') ||
          l.startsWith('resolv-retry') ||
          l.startsWith('persist-') ||
          l.startsWith('route-gateway')) {
        continue;
      }

      result.add(l);
    }

    // Modern compatibility flags
    if (!hasAuthUserPass) {
      result.add('auth-user-pass');
    }

    // Optimization for VPNGate / SoftEther
    result.add('client');
    result.add('nobind');
    result.add('float');
    result.add('mssfix 1200'); // Higher stability on mobile
    result.add('hand-window 30');
    result.add('reneg-sec 0');
    result.add('data-ciphers AES-128-CBC:AES-256-CBC:AES-256-GCM:BF-CBC');
    result.add('setenv CLIENT_CERT 0');

    return result.join('\n');
  }

  Future<bool> _waitForConnection({required Duration timeout}) async {
    try {
      // Use the stream to wait for 'connected' or 'error'/'disconnected'
      // We need to listen to the *stream* which is already being listened to in _init.
      // But we can peek at the state or add a one-off listener.
      // Since _init updates state, we can poll state or use a Completer linked to the stream.
      // Easier: polling loop for simplicity in this context without complex stream merging.
      final end = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(end)) {
        if (state.stage == 'connected') {
          return true;
        }
        if (state.stage == 'error') {
          return false;
        }
        if (state.stage == 'disconnected' && state.currentServer != null) {
          // It disconnected while we were trying? Likely failed.
          // Note: connecting -> disconnected transition usually means failure or timeout
          // But we set stage to connecting before calling this.
          // If the engine updates it to disconnected, it failed.
          return false;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
      return false; // Timeout
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() async {
    // Stop timer immediately
    _stopTimer();

    // Clear state before engine call for instant UI response
    state = state.copyWith(
      stage: 'disconnected',
      status: state.isConnecting ? 'User Cancelled' : 'Disconnected',
      connectedSince: null,
      duration: Duration.zero,
    );

    // Explicitly await save to ensure it's written before app might close
    await _saveState();

    try {
      await _engine.disconnect();
    } catch (_) {}
  }

  String _decodeConfig(String base64Str) {
    return utf8.decode(base64Decode(base64Str));
  }
}

final vpnControllerProvider = StateNotifierProvider<VpnController, VpnState>((
  ref,
) {
  final engine = ref.watch(vpnEngineProvider);
  final reward = ref.watch(rewardProvider.notifier);
  return VpnController(engine, reward);
});
