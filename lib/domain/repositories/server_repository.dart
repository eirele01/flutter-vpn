import 'package:bagani_vpn/domain/entities/vpn_server.dart';

abstract class ServerRepository {
  Future<List<VpnServer>> getServers({bool forceRefresh = false});
  Future<List<VpnServer>> getLastCachedServers();
  Future<void> saveServers(List<VpnServer> servers);
}
