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
  String _sortBy = 'All'; // All, Best Match, Speed, Ping
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final serverListAsync = ref.watch(serverListProvider);
    final vpnState = ref.watch(vpnControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VPN Servers'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(serverListProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with search
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search Country...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: Theme.of(context).cardColor.withAlpha(150),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Best Match'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Speed'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Ping'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Active Connection Status
          if (vpnState.stage == 'connected' && vpnState.currentServer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildConnectedStatus(vpnState),
            ),

          Expanded(
            child: serverListAsync.when(
              data: (servers) {
                var filtered =
                    servers.where((s) {
                      final q = _searchQuery.toLowerCase();
                      return s.countryLong.toLowerCase().contains(q) ||
                          s.operator.toLowerCase().contains(q);
                    }).toList();

                if (_sortBy == 'Speed') {
                  filtered.sort((a, b) => b.speed.compareTo(a.speed));
                } else if (_sortBy == 'Ping') {
                  filtered.sort((a, b) => a.ping.compareTo(b.ping));
                } else if (_sortBy == 'All') {
                  filtered.sort((a, b) {
                    // Primary: Country Name (Alphabetical)
                    int cmp = a.countryLong.compareTo(b.countryLong);
                    if (cmp != 0) return cmp;
                    // Secondary: Quality Score
                    return b.qualityScore.compareTo(a.qualityScore);
                  });
                } else {
                  filtered.sort(
                    (a, b) => b.qualityScore.compareTo(a.qualityScore),
                  );
                }

                if (filtered.isEmpty) {
                  return const Center(child: Text("No servers found"));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  itemBuilder:
                      (context, index) => _buildServerCard(filtered[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _sortBy == label;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.redAccent : Colors.grey.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedStatus(VpnState vpnState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: vpnState.statusColor.withAlpha(40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vpnState.statusColor.withAlpha(100)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 32,
              height: 22,
              child: CountryFlag.fromCountryCode(
                vpnState.currentServer!.countryShort,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CURRENTLY CONNECTED",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  vpnState.currentServer!.countryLong,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: vpnState.statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "ACTIVE",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(VpnServer server) {
    final speedMbps = (server.speed / 1000000).toStringAsFixed(1);
    final isCrowded = server.numVpnSessions > 100;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
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
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "${server.ip} • $speedMbps Mbps",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 14,
                  color: server.ping < 50 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text("${server.ping} ms", style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
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
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }

  void _connectToServer(VpnServer server) {
    ref.read(vpnControllerProvider.notifier).connect(server);
    Navigator.pop(context);
  }
}
