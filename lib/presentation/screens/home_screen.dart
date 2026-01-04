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
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:bagani_vpn/core/utils/ad_helper.dart';
import 'package:bagani_vpn/presentation/providers/reward_providers.dart';
import 'package:bagani_vpn/presentation/widgets/reward_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  BannerAd? _bannerAd;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() {}),
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  void _loadRewardedAd() {
    if (_isRewardedAdLoading) return;
    setState(() => _isRewardedAdLoading = true);

    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          _showRewardedAd();
        },
        onAdFailedToLoad: (error) {
          debugPrint('RewardedAd failed to load: $error');
          _isRewardedAdLoading = false;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ad failed to load. Check console for details."),
            ),
          );
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd == null) return;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        ref.read(rewardProvider.notifier).addReward();
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(vpnEngineProvider).initialize();
      // Reload banner if it was null
      if (_bannerAd == null) _loadBannerAd();
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
        title: const Text('BaganiVPN'),
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
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              // 1. Server Info & Reward Card Area (Top)
              // This section takes its natural space
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
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
                            vertical: 16,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? 40
                                      : 10,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
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
                                Icon(
                                  Icons.public_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 28,
                                ),
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
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    Text(
                                      vpnState.currentServer?.ip ??
                                          "Your real IP is Secured",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color
                                            ?.withAlpha(150),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    RewardCard(
                      onWatchAd: _loadRewardedAd,
                      isAdLoading: _isRewardedAdLoading,
                      isVpnConnected:
                          vpnState.stage == 'connected' ||
                          vpnState.isConnecting,
                    ),
                  ],
                ),
              ),

              // 2. Control & Hero Area (Status + Button + Bottom)
              // Using a single Expanded + LayoutBuilder for precision centering
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      children: [
                        // A. Status Area - Fixed Height (90px)
                        SizedBox(
                          height: 90,
                          child: FadeIn(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  vpnState.displayStage,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: vpnState.statusColor(context),
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                SizedBox(
                                  height: 30,
                                  child:
                                      vpnState.stage == 'connected'
                                          ? Text(
                                            _formatDuration(vpnState.duration),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontFamily: 'Courier',
                                              fontWeight: FontWeight.w500,
                                            ),
                                          )
                                          : null,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // B. Center Button - Takes all remaining Space
                        Expanded(
                          child: Center(
                            child: ZoomIn(
                              child: ConnectButton(
                                state: vpnState.stage,
                                onTap: () {
                                  final rewardSeconds =
                                      ref.read(rewardProvider).remainingSeconds;

                                  if (rewardSeconds <= 0 &&
                                      vpnState.stage == 'disconnected') {
                                    ref
                                        .read(pulseRewardProvider.notifier)
                                        .state++;
                                    return;
                                  }

                                  if (serverListAsync.asData != null) {
                                    if (vpnState.stage == 'connected' ||
                                        vpnState.isConnecting) {
                                      ref
                                          .read(vpnControllerProvider.notifier)
                                          .disconnect();
                                    } else if (vpnState.stage ==
                                            'disconnected' &&
                                        serverListAsync
                                            .asData!
                                            .value
                                            .isNotEmpty) {
                                      ref
                                          .read(vpnControllerProvider.notifier)
                                          .fastConnect(
                                            serverListAsync.asData!.value,
                                          );
                                    } else if (vpnState.stage == 'error') {
                                      ref
                                          .read(vpnControllerProvider.notifier)
                                          .disconnect();
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Fetching servers... Try again.",
                                          ),
                                        ),
                                      );
                                      final _ = ref.refresh(serverListProvider);
                                    }
                                  }
                                },
                              ),
                            ),
                          ),
                        ),

                        // C. Bottom Section Area - Fixed Height (150px)
                        SizedBox(
                          height: 150,
                          child: Container(
                            alignment: Alignment.topCenter,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                if (vpnState.stage == 'connected')
                                  FadeInUp(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        StatusCard(
                                          title: "DOWNLOAD",
                                          value: vpnState.byteInTotal,
                                          icon: Icons.expand_more_rounded,
                                          color: Colors.greenAccent,
                                        ),
                                        StatusCard(
                                          title: "UPLOAD",
                                          value: vpnState.byteOutTotal,
                                          icon: Icons.expand_less_rounded,
                                          color: Colors.orangeAccent,
                                        ),
                                        StatusCard(
                                          title: "PING",
                                          value:
                                              "${vpnState.currentServer?.ping ?? 0} ms",
                                          icon: Icons.bolt_rounded,
                                          color: Colors.blueAccent,
                                        ),
                                      ],
                                    ),
                                  )
                                else if (_bannerAd != null)
                                  FadeIn(
                                    child: Container(
                                      alignment: Alignment.center,
                                      width: _bannerAd!.size.width.toDouble(),
                                      height: _bannerAd!.size.height.toDouble(),
                                      child: AdWidget(ad: _bannerAd!),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
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
}
