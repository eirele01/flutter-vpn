import 'package:bagani_vpn/core/constants/app_constants.dart';
import 'package:bagani_vpn/data/datasources/vpn_gate_api_client.dart';
import 'package:bagani_vpn/domain/entities/vpn_server.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BackgroundFetchService {
  static Future<void> fetchAndCacheServers() async {
    try {
      // 1. Init Hive
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(VpnServerAdapter());
      }

      // 2. Open Box
      final box = await Hive.openBox(AppConstants.hiveBoxName);

      // 3. Fetch from API
      final dio = Dio();
      final apiClient = VpnGateApiClient(dio);
      final servers = await apiClient.fetchServers();

      // 4. Update Cache
      if (servers.isNotEmpty) {
        await box.put(AppConstants.serverCacheKey, servers);
        await box.put(
          '${AppConstants.serverCacheKey}_timestamp',
          DateTime.now().millisecondsSinceEpoch,
        );
      }

      await box.close();
    } catch (e) {
      // Background task should ideally be silent or use debug prints in debug mode
      // print('Background task error: $e');
    }
  }
}
