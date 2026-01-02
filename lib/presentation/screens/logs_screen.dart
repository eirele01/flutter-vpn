import 'package:bagani_vpn/domain/repositories/vpn_engine.dart';
import 'package:bagani_vpn/presentation/providers/vpn_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logHistory = ref.watch(logHistoryProvider);
    final vpnState = ref.watch(vpnControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Logs'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: logHistory.join('\n')));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Logs copied')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              ref.read(logHistoryProvider.notifier).clear();
            },
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child:
            logHistory.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 64,
                        color: Colors.grey.withAlpha(100),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "No logs recorded yet.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
                : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: logHistory.length,
                  itemBuilder: (context, index) {
                    final log = logHistory[index];
                    final isStatus = log.contains('Status ->');

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      color:
                          isStatus
                              ? vpnState.statusColor(context).withAlpha(30)
                              : Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color:
                              isStatus
                                  ? vpnState.statusColor(context).withAlpha(100)
                                  : Colors.grey.withAlpha(30),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.split(': ')[0], // Time
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500,
                                fontFamily: 'Courier',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                log.substring(log.indexOf(': ') + 2), // Message
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      isStatus
                                          ? Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black87
                                          : Colors.grey.shade700,
                                  fontWeight:
                                      isStatus
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
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
  final VpnEngine _engine;

  LogHistoryNotifier(this._engine) : super([]) {
    _engine.statusStream.listen((log) {
      if (log != null) {
        if (log.contains('byte_in:')) return;

        String line = log;
        if (line.startsWith('Engine: ')) {
          line = line.replaceFirst('Engine: ', '');
        }

        if (line.isEmpty || line.contains('noprocess')) return;

        state = [...state, "${_time()}: $line"];
        if (state.length > 200) state = state.sublist(state.length - 200);
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
        return "Identity Protected";
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
