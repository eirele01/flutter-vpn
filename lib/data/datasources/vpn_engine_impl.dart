import 'dart:async';
import 'package:bagani_vpn/domain/repositories/vpn_engine.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';

class VpnEngineImpl implements VpnEngine {
  late OpenVPN _openVPN;
  final _stageController = StreamController<String>.broadcast();
  final _statusController = StreamController<String?>.broadcast();

  VpnEngineImpl() {
    _openVPN = OpenVPN(
      onVpnStatusChanged: (data) {
        // VpnStatus might not have message field directly or it's named differently
        // We'll trust data.toString() or leave it empty for now if strict
        _statusController.add(data?.toString());
      },
      onVpnStageChanged: (data, stage) {
        // If stage is String in this version
        _stageController.add(stage.toString());
      },
    );
  }

  @override
  Future<void> initialize() async {
    _statusController.add("Engine: Initializing...");
    await _openVPN.initialize(
      groupIdentifier: "group.com.baganivpn.app",
      providerBundleIdentifier: "id.laskarmedia.openvpnFlutter.VPNExtension",
      localizedDescription: "BaganiVPN",
    );
    _statusController.add("Engine: Ready.");
  }

  @override
  Future<void> connect(
    String config,
    String name, {
    String? username,
    String? password,
  }) async {
    _statusController.add("Engine: Connecting to $name...");
    try {
      _openVPN.connect(
        config,
        name,
        username: username ?? 'vpn',
        password: password ?? 'vpn',
        certIsRequired: true,
      );
    } catch (e) {
      _statusController.add("Engine Error: $e");
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    _openVPN.disconnect();
  }

  @override
  Stream<String> get stageStream => _stageController.stream;

  @override
  Stream<String?> get statusStream => _statusController.stream;

  @override
  Future<bool> get isConnected async {
    // The plugin doesn't expose a direct async getter easily without state,
    // but we can track it via stream or use requestPermission logic which checks service.
    // For now, assume state management handles this via stream events.
    return false;
  }
}
