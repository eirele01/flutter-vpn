import 'package:bagani_vpn/domain/entities/vpn_server.dart';
import 'package:bagani_vpn/presentation/providers/vpn_providers.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ServerListScreen extends ConsumerStatefulWidget {
  const ServerListScreen({super.key});

  @override
  ConsumerState<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends ConsumerState<ServerListScreen> {
  // Filters
  String _sortBy = 'Best Match'; // Best Match, Speed, Ping, Country
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final serverListAsync = ref.watch(serverListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(serverListProvider);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Country or Operator...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
        ),
      ),
      body: serverListAsync.when(
        data: (servers) {
          // Filter and Sort
          var filtered =
              servers.where((s) {
                final q = _searchQuery.toLowerCase();
                return s.countryLong.toLowerCase().contains(q) ||
                    s.operator.toLowerCase().contains(q) ||
                    s.message.toLowerCase().contains(q);
              }).toList();

          // Sort
          if (_sortBy == 'Speed') {
            filtered.sort((a, b) => b.speed.compareTo(a.speed));
          } else if (_sortBy == 'Ping') {
            filtered.sort((a, b) => a.ping.compareTo(b.ping));
          } else if (_sortBy == 'Sessions') {
            filtered.sort(
              (a, b) => a.numVpnSessions.compareTo(b.numVpnSessions),
            );
          } else {
            // Best Match (Quality Score)
            filtered.sort((a, b) => b.qualityScore.compareTo(a.qualityScore));
          }

          if (filtered.isEmpty) {
            return const Center(child: Text("No servers found"));
          }

          return ListView.builder(
            itemCount: filtered.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final server = filtered[index];
              return _buildServerCard(server);
            },
          );
        },
        error:
            (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Failed to load servers.\n$err",
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(serverListProvider),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showSortOptions();
        },
        icon: const Icon(Icons.sort),
        label: const Text("Sort"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sortOption('Best Match'),
            _sortOption('Speed'),
            _sortOption('Ping'),
            _sortOption('Sessions'),
          ],
        );
      },
    );
  }

  Widget _sortOption(String title) {
    return ListTile(
      title: Text(title),
      trailing:
          _sortBy == title
              ? const Icon(Icons.check, color: Colors.green)
              : null,
      onTap: () {
        setState(() {
          _sortBy = title;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildServerCard(VpnServer server) {
    // Estimations
    final speedMbps = (server.speed / 1000000).toStringAsFixed(1);
    final isCrowded = server.numVpnSessions > 100; // Arbitrary threshold

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () => _connectToServer(server),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            width: 44,
            height: 30,
            child: CountryFlag.fromCountryCode(server.countryShort),
          ),
        ),
        title: Text(
          server.countryLong,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "${server.ip} • $speedMbps Mbps",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 14,
                  color: server.ping < 50 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  "${server.ping} ms",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.people_alt_rounded,
                  size: 14,
                  color: isCrowded ? Colors.redAccent : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  "${server.numVpnSessions}",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Colors.grey.withAlpha(100),
        ),
      ),
    );
  }

  void _connectToServer(VpnServer server) {
    ref.read(vpnControllerProvider.notifier).connect(server);
    Navigator.pop(context);
  }
}
