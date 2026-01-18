import 'package:bagani_vpn/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:bagani_vpn/core/utils/ad_helper.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  BannerAd? _bannerAd;
  int _bannerRetryCount = 0;
  final int _maxBannerRetries = 3;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    if (_bannerAd != null) return;

    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          debugPrint('Settings BannerAd loaded successfully');
          _bannerRetryCount = 0;
          if (mounted) setState(() {});
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Settings BannerAd failed to load: $error');
          ad.dispose();
          _bannerAd = null;

          if (_bannerRetryCount < _maxBannerRetries) {
            _bannerRetryCount++;
            Future.delayed(Duration(seconds: _bannerRetryCount * 5), () {
              if (mounted) _loadBannerAd();
            });
          }
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
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: Container(
        width: double.infinity,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection(context, "Appearance", [
                    ListTile(
                      leading: Icon(
                        _getThemeIcon(settings.themeMode),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text("Theme"),
                      subtitle: Text(_getThemeName(settings.themeMode)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => notifier.toggleTheme(),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection(context, "VPN Settings", [
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.blueAccent,
                      ),
                      title: const Text("Auto-Refresh Servers"),
                      subtitle: const Text("Always keep the list up to date"),
                      value: settings.isAutoRefreshEnabled,
                      onChanged: (val) => notifier.toggleAutoRefresh(val),
                    ),
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.security_rounded,
                        color: Colors.greenAccent,
                      ),
                      title: const Text("Kill Switch"),
                      subtitle: const Text("Block internet when VPN drops"),
                      value: settings.isKillSwitchEnabled,
                      onChanged: (val) => notifier.toggleKillSwitch(val),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSection(context, "About", [
                    const ListTile(
                      leading: Icon(
                        Icons.info_outline_rounded,
                        color: Colors.grey,
                      ),
                      title: Text("Version"),
                      subtitle: Text("1.0.0"),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.code_rounded,
                        color: Colors.grey,
                      ),
                      title: const Text("OSS Licenses"),
                      onTap: () {
                        showLicensePage(context: context);
                      },
                    ),
                  ]),
                ],
              ),
            ),
            if (_bannerAd != null)
              Container(
                alignment: Alignment.center,
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.wb_sunny_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        return Icons.brightness_auto_rounded;
    }
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return "Light";
      case ThemeMode.dark:
        return "Dark";
      case ThemeMode.system:
        return "System Default";
    }
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.primary.withAlpha(180),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          color: Theme.of(context).cardTheme.color,
          child: Column(children: children),
        ),
      ],
    );
  }
}
