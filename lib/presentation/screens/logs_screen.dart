import 'package:bagani_vpn/presentation/providers/vpn_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Realtime logs accumulated from the VPN engine stream.
    final logHistory = ref.watch(logHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: logHistory.join('\n')));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Logs copied')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              ref.read(logHistoryProvider.notifier).clear();
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(8),
        child: ListView.builder(
          itemCount: logHistory.length,
          itemBuilder: (context, index) {
            return Text(
              logHistory[index],
              style: const TextStyle(
                color: Colors.greenAccent,
                fontFamily: 'Courier',
                fontSize: 12,
              ),
            );
          },
        ),
      ),
    );
  }
}

// Simple log accumulator
final logHistoryProvider =
    StateNotifierProvider<LogHistoryNotifier, List<String>>((ref) {
      final engine = ref.watch(vpnEngineProvider);
      return LogHistoryNotifier(engine);
    });

class LogHistoryNotifier extends StateNotifier<List<String>> {
  final dynamic _engine; // VpnEngine

  LogHistoryNotifier(this._engine) : super([]) {
    _engine.statusStream.listen((log) {
      if (log != null) {
        // Skip technical statistics (JSON strings)
        if (log.contains('byte_in:')) return;

        String line = log;
        // Strip "Engine: " prefix if present for a cleaner look
        if (line.startsWith('Engine: ')) {
          line = line.replaceFirst('Engine: ', '');
        }

        // Skip internal/empty messages
        if (line.isEmpty || line.contains('noprocess')) return;

        state = [...state, "${_time()}: $line"];
      }
    });

    _engine.stageStream.listen((stage) {
      final friendly = _getFriendlyStage(stage.toLowerCase());
      state = [...state, "${_time()}: Status -> $friendly"];
    });
  }

  String _time() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
  }

  String _getFriendlyStage(String stage) {
    switch (stage) {
      case 'connected':
        return "Secure Connection Established";
      case 'disconnected':
        return "Disconnected";
      case 'wait_connection':
        return "Waiting for server response...";
      case 'authenticating':
        return "Authenticating credentials...";
      case 'get_config':
        return "Downloading configuration...";
      case 'tcp_connect':
        return "Initiating secure handshake...";
      case 'vpn_generate_config':
        return "Optimizing connection settings...";
      case 'connecting':
        return "Connecting...";
      default:
        return stage.toUpperCase();
    }
  }

  void clear() => state = [];
}
