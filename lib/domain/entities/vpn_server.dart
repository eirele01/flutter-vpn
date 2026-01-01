import 'package:hive/hive.dart';

part 'vpn_server.g.dart';

@HiveType(typeId: 0)
class VpnServer {
  @HiveField(0)
  final String hostName;
  @HiveField(1)
  final String ip;
  @HiveField(2)
  final int score;
  @HiveField(3)
  final int ping;
  @HiveField(4)
  final int speed; // in bps
  @HiveField(5)
  final String countryLong;
  @HiveField(6)
  final String countryShort;
  @HiveField(7)
  final int numVpnSessions;
  @HiveField(8)
  final int uptime; // in ms? No, usually distinct format in CSV, need to check. API says "Uptime" (likely milliseconds or seconds). CSV often has a formatted string or raw number. We'll store as int (seconds usually)
  @HiveField(9)
  final int totalUsers;
  @HiveField(10)
  final int totalTraffic;
  @HiveField(11)
  final String logType;
  @HiveField(12)
  final String operator;
  @HiveField(13)
  final String message;
  @HiveField(14)
  final String openVpnConfigData; // Base64 encoded

  VpnServer({
    required this.hostName,
    required this.ip,
    required this.score,
    required this.ping,
    required this.speed,
    required this.countryLong,
    required this.countryShort,
    required this.numVpnSessions,
    required this.uptime,
    required this.totalUsers,
    required this.totalTraffic,
    required this.logType,
    required this.operator,
    required this.message,
    required this.openVpnConfigData,
  });

  // Calculate a quality score
  double get qualityScore {
    // Higher speed is better. Lower ping is better.
    // Speed is in bps. Ping is in ms.
    if (speed == 0) return 0;
    double speedFactor = speed / 1000000; // Mbps approx
    double pingFactor = (ping <= 0 ? 999 : ping).toDouble();
    double sessionsFactor = numVpnSessions > 50 ? 0.5 : 1.0; // Penalty for crowds
    
    // Sort logic: High Speed / Ping
    return (speedFactor / pingFactor) * sessionsFactor;
  }
}
