
abstract class VpnEngine {
  Future<void> initialize();
  Future<void> connect(String config, String name, {String? username, String? password});
  Future<void> disconnect();
  Stream<String> get stageStream; // Connecting, Connected, Disconnected, etc.
  Stream<String?> get statusStream; // Details
  Future<bool> get isConnected;
}
