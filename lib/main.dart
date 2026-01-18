import 'package:bagani_vpn/core/constants/app_constants.dart';
import 'package:bagani_vpn/core/theme/app_theme.dart';
import 'package:bagani_vpn/domain/entities/vpn_server.dart';
import 'package:bagani_vpn/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'package:bagani_vpn/core/utils/ad_helper.dart';
import 'package:bagani_vpn/core/utils/app_open_ad_manager.dart';
import 'package:bagani_vpn/core/services/background_fetch_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await BackgroundFetchService.fetchAndCacheServers();
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Hive
  await Hive.initFlutter();
  Hive.registerAdapter(VpnServerAdapter());
  await Hive.openBox(AppConstants.hiveBoxName);

  // Init AdMob with UMP Consent
  await AdHelper.initialize();

  // Init Workmanager
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().registerPeriodicTask(
    "bagani_refresh_servers",
    "fetchServersTask",
    frequency: const Duration(hours: 3),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  runApp(const ProviderScope(child: BaganiVpnApp()));
}

class BaganiVpnApp extends StatefulWidget {
  const BaganiVpnApp({super.key});

  @override
  State<BaganiVpnApp> createState() => _BaganiVpnAppState();
}

class _BaganiVpnAppState extends State<BaganiVpnApp>
    with WidgetsBindingObserver {
  late AppOpenAdManager _appOpenAdManager;

  @override
  void initState() {
    super.initState();
    _appOpenAdManager = AppOpenAdManager()..loadAd();
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
      _appOpenAdManager.showAdIfAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BaganiVPN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
