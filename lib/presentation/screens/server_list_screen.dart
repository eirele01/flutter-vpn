import 'package:bagani_vpn/domain/entities/vpn_server.dart';
import 'package:bagani_vpn/presentation/providers/vpn_providers.dart';
import 'package:country_flags/country_flags.dart';
import 'package:bagani_vpn/core/utils/ad_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ServerListScreen extends ConsumerStatefulWidget {
  const ServerListScreen({super.key});

  @override
  ConsumerState<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends ConsumerState<ServerListScreen> {
  String _sortBy = 'All'; // All, Best Match, Speed, Ping
  String _searchQuery = '';
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('ServerList Banner loaded');
          if (mounted) setState(() => _isBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('ServerList Banner failed: $error');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serverListAsync = ref.watch(serverListProvider);
    final vpnState = ref.watch(vpnControllerProvider);

    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF000000)
              : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('BaganiVPN'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(serverForceRefreshProvider.notifier).state = true;
              ref.invalidate(serverListProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final horizontalPadding =
                maxWidth > 600 ? (maxWidth - 560) / 2 : 16.0;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Servers',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: CupertinoSearchTextField(
                      placeholder: 'Search country',
                      style: TextStyle(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: CupertinoSlidingSegmentedControl<String>(
                        groupValue: _sortBy,
                        children: const {
                          'All': Text('All', style: TextStyle(fontSize: 12)),
                          'Best Match': Text(
                            'Best',
                            style: TextStyle(fontSize: 12),
                          ),
                          'Speed': Text(
                            'Speed',
                            style: TextStyle(fontSize: 12),
                          ),
                          'Ping': Text('Ping', style: TextStyle(fontSize: 12)),
                        },
                        onValueChanged: (v) {
                          if (v != null) setState(() => _sortBy = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: serverListAsync.when(
                      data: (servers) {
                        final filtered = _applyFilterAndSort(servers);

                        return ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            if (vpnState.stage == 'connected' &&
                                vpnState.currentServer != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                                child: _ConnectedPill(vpnState: vpnState),
                              ),

                            _InsetGroupedSection(
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filtered.length,
                                separatorBuilder:
                                    (_, __) => Divider(
                                      height: 1,
                                      thickness: 0.5,
                                      indent: 64,
                                      color: Theme.of(
                                        context,
                                      ).dividerColor.withAlpha(100),
                                    ),
                                itemBuilder:
                                    (context, i) => _ServerRow(
                                      server: filtered[i],
                                      onTap: () {
                                        _connectToServer(filtered[i], servers);
                                      },
                                    ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading:
                          () => const Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar:
          _isBannerLoaded && _bannerAd != null
              ? SafeArea(
                child: Container(
                  alignment: Alignment.center,
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              )
              : null,
    );
  }

  List<VpnServer> _applyFilterAndSort(List<VpnServer> servers) {
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
        int cmp = a.countryLong.compareTo(b.countryLong);
        if (cmp != 0) return cmp;
        return b.qualityScore.compareTo(a.qualityScore);
      });
    } else {
      // Best Match
      filtered.sort((a, b) => b.qualityScore.compareTo(a.qualityScore));
    }
    return filtered;
  }

  void _connectToServer(VpnServer server, List<VpnServer> alternatives) {
    ref
        .read(vpnControllerProvider.notifier)
        .connect(server, alternatives: alternatives);
    Navigator.pop(context);
  }
}

class _ConnectedPill extends StatelessWidget {
  final VpnState vpnState;
  const _ConnectedPill({required this.vpnState});

  @override
  Widget build(BuildContext context) {
    final color = vpnState.statusColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 28,
              height: 20,
              child: CountryFlag.fromCountryCode(
                vpnState.currentServer!.countryShort,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Identity Protected: ${vpnState.currentServer!.countryLong}",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(200),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              "SECURED",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsetGroupedSection extends StatelessWidget {
  final Widget child;
  const _InsetGroupedSection({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1C1C1E)
                : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _ServerRow extends StatelessWidget {
  final VpnServer server;
  final VoidCallback onTap;

  const _ServerRow({required this.server, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final speedMbps = (server.speed / 1000000).toStringAsFixed(1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 36,
                  height: 26,
                  child: CountryFlag.fromCountryCode(server.countryShort),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.countryLong,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      "${server.ip} • $speedMbps Mbps",
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withAlpha(150),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _PingBadge(ping: server.ping),
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: Colors.grey.withAlpha(100),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PingBadge extends StatelessWidget {
  final int ping;
  const _PingBadge({required this.ping});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.green;
    if (ping > 100) color = Colors.orange;
    if (ping > 200) color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "$ping ms",
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
