import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:bagani_vpn/core/utils/ad_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  BannerAd? _bannerAd;

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
        onAdLoaded: (_) => setState(() {}),
        onAdFailedToLoad: (ad, error) {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: Container(
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
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection(context, "Appearance", [
                    ListTile(
                      leading: const Icon(
                        Icons.brightness_6_rounded,
                        color: Colors.redAccent,
                      ),
                      title: const Text("Theme"),
                      subtitle: const Text("System Default"),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {},
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
                      value: true,
                      onChanged: (val) {},
                    ),
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.security_rounded,
                        color: Colors.greenAccent,
                      ),
                      title: const Text("Kill Switch"),
                      subtitle: const Text("Block internet when VPN drops"),
                      value: false,
                      onChanged: (val) {},
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent.withAlpha(200),
              letterSpacing: 1.1,
            ),
          ),
        ),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Theme.of(context).cardColor.withAlpha(200),
          child: Column(children: children),
        ),
      ],
    );
  }
}
