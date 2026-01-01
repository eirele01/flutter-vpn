import 'package:bagani_vpn/core/constants/app_constants.dart';
import 'package:bagani_vpn/data/datasources/vpn_gate_api_client.dart';
import 'package:bagani_vpn/domain/entities/vpn_server.dart';
import 'package:bagani_vpn/domain/repositories/server_repository.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ServerRepositoryImpl implements ServerRepository {
  final VpnGateApiClient _apiClient;
  final Box _box;

  ServerRepositoryImpl(this._apiClient) : _box = Hive.box(AppConstants.hiveBoxName);

  @override
  Future<List<VpnServer>> getServers({bool forceRefresh = false}) async {
    // Check if we have cached data
    final hasCache = _box.containsKey(AppConstants.serverCacheKey);
    
    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    final isOffline = connectivityResult.contains(ConnectivityResult.none);

    if (isOffline) {
      if (hasCache) {
        return getLastCachedServers();
      } else {
        throw Exception('No internet and no cached servers.');
      }
    }

    if (!forceRefresh && hasCache) {
      // Check if cache is fresh enough (e.g., < 15 mins)
      final lastUpdated = _box.get('${AppConstants.serverCacheKey}_timestamp') as int?;
      if (lastUpdated != null) {
        final diff = DateTime.now().millisecondsSinceEpoch - lastUpdated;
        if (diff < 15 * 60 * 1000) { // 15 minutes
          return getLastCachedServers();
        }
      }
    }

    // Fetch from network
    try {
      final servers = await _apiClient.fetchServers();
      if (servers.isNotEmpty) {
        await saveServers(servers);
      }
      return servers;
    } catch (e) {
      // If fetch fails, fallback to cache if available
      if (hasCache) {
        return getLastCachedServers();
      }
      rethrow;
    }
  }

  @override
  Future<List<VpnServer>> getLastCachedServers() async {
    final dynamic data = _box.get(AppConstants.serverCacheKey);
    if (data != null && data is List) {
       // Hive stores lists as dynamic usually, dependent on adapter
       // We cast to List<dynamic> then map to VpnServer if needed, 
       // but since we registered a TypeAdapter, it should return List<VpnServer> or List<dynamic> containing VpnServers
       return data.cast<VpnServer>();
    }
    return [];
  }

  @override
  Future<void> saveServers(List<VpnServer> servers) async {
    await _box.put(AppConstants.serverCacheKey, servers);
    await _box.put('${AppConstants.serverCacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }
}
