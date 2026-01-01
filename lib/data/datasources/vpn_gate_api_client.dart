import 'package:dio/dio.dart';
import 'package:bagani_vpn/core/constants/app_constants.dart';
import 'package:bagani_vpn/core/utils/vpn_gate_parser.dart';
import 'package:bagani_vpn/domain/entities/vpn_server.dart';

class VpnGateApiClient {
  final Dio _dio;

  VpnGateApiClient(this._dio);

  Future<List<VpnServer>> fetchServers() async {
    try {
      final response = await _dio.get(
        AppConstants.vpnGateApiUrl,
        options: Options(
          responseType: ResponseType.plain, // Important: we want raw string
        ),
      );

      if (response.statusCode == 200) {
        return VpnGateParser.parse(response.data as String);
      } else {
        throw Exception('Failed to load servers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
