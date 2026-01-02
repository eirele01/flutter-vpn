import 'package:bagani_vpn/core/constants/app_constants.dart';
import 'package:bagani_vpn/core/theme/app_theme.dart';
import 'package:bagani_vpn/domain/entities/vpn_server.dart';
import 'package:bagani_vpn/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
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

  // Init AdMob
  await MobileAds.instance.initialize();

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

class BaganiVpnApp extends StatelessWidget {
  const BaganiVpnApp({super.key});

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
