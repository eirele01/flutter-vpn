import 'package:bagani_vpn/presentation/providers/vpn_providers.dart';
import 'package:bagani_vpn/presentation/screens/logs_screen.dart';
import 'package:bagani_vpn/presentation/screens/server_list_screen.dart';
import 'package:bagani_vpn/presentation/screens/settings_screen.dart';
import 'package:bagani_vpn/presentation/widgets/connect_button.dart';
import 'package:bagani_vpn/presentation/widgets/status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:country_flags/country_flags.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When coming back from background, re-init the engine
      // to trigger stage/status streams to emit current status.
      ref.read(vpnEngineProvider).initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vpnState = ref.watch(vpnControllerProvider);
    final serverListAsync = ref.watch(serverListProvider);
    // duration timer is now handled inside VpnController state

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'BaganiVPN',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          if (vpnState.stage != 'disconnected')
            IconButton(
              icon: const Icon(Icons.terminal_rounded),
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LogsScreen()));
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                Theme.of(context).brightness == Brightness.dark
                    ? [const Color(0xFF2D1B1B), const Color(0xFF1A1212)]
                    : [const Color(0xFFFFF5F5), const Color(0xFFFFEBEE)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Server Selection & IP Area
              FadeInDown(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ServerListScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withAlpha(20),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        if (vpnState.currentServer != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              width: 32,
                              height: 24,
                              child: CountryFlag.fromCountryCode(
                                vpnState.currentServer!.countryShort,
                              ),
                            ),
                          )
                        else
                          const Icon(Icons.public_rounded, color: Colors.grey),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                vpnState.currentServer?.countryLong ??
                                    "Select Best Location",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                vpnState.currentServer?.ip ??
                                    "Your real IP is hidden",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color?.withAlpha(180),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.swap_vert_rounded,
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Status Text
              FadeInDown(
                child: Column(
                  children: [
                    Text(
                      _getDisplayStatus(vpnState.stage),
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(vpnState.stage),
                      ),
                    ),
                    if (vpnState.stage == 'connected')
                      Text(
                        _formatDuration(vpnState.duration),
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),

              const Spacer(),

              // Big Connect Button
              ZoomIn(
                child: ConnectButton(
                  state: vpnState.stage,
                  onTap: () {
                    if (vpnState.stage == 'connected' ||
                        vpnState.stage == 'connecting') {
                      ref.read(vpnControllerProvider.notifier).disconnect();
                    } else {
                      if (serverListAsync.asData?.value != null &&
                          serverListAsync.asData!.value.isNotEmpty) {
                        ref
                            .read(vpnControllerProvider.notifier)
                            .fastConnect(serverListAsync.asData!.value);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Fetching servers... Try again."),
                          ),
                        );
                        final _ = ref.refresh(serverListProvider);
                      }
                    }
                  },
                ),
              ),

              const Spacer(),

              const SizedBox(height: 20),

              // Stats Row
              if (vpnState.stage == 'connected')
                FadeInUp(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        StatusCard(
                          title: "DOWNLOAD",
                          value: vpnState.byteInTotal,
                          icon: Icons.arrow_downward_rounded,
                          color: _getStatusColor('connected'),
                        ),
                        StatusCard(
                          title: "UPLOAD",
                          value: vpnState.byteOutTotal,
                          icon: Icons.arrow_upward_rounded,
                          color: Colors.orangeAccent,
                        ),
                        StatusCard(
                          title: "PING",
                          value: "${vpnState.currentServer?.ping ?? 0} ms",
                          icon: Icons.bolt_rounded,
                          color: Colors.blueAccent,
                        ),
                      ],
                    ),
                  ),
                ),
              if (vpnState.stage != 'connected') const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(d.inHours);
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  String _getDisplayStatus(String stage) {
    switch (stage) {
      case 'connected':
        return "Connected";
      case 'disconnected':
        return "Disconnected";
      case 'connecting':
      case 'wait_connection':
      case 'tcp_connect':
      case 'authenticating':
      case 'get_config':
        return "Connecting";
      case 'error':
        return "Failed";
      default:
        return "Disconnected";
    }
  }

  Color _getStatusColor(String stage) {
    switch (stage) {
      case 'connected':
        return const Color(0xFF7ED9A7); // Soft Pastel Red
      case 'connecting':
      case 'wait_connection':
      case 'tcp_connect':
      case 'authenticating':
      case 'get_config':
        return const Color(0xFF8ECDF4);
      case 'error':
        return const Color(0xFFF28B82);
      default:
        return const Color(0xFFE6E8EB);
    }
  }
}
