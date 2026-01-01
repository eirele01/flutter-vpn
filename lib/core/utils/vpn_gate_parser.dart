import 'package:csv/csv.dart';
import 'package:bagani_vpn/domain/entities/vpn_server.dart';

class VpnGateParser {
  static List<VpnServer> parse(String csvResponse) {
    if (csvResponse.isEmpty) {
      return [];
    }

    // The file contains lines starting with '*' or '#' which are comments/metadata
    // The data starts after "*vpn_servers" line, with the header "#HostName,..."
    // We should look for the header line to know where data begins.

    final lines = csvResponse.split('\n');
    final cleanCsvLines = <String>[];

    bool headerFound = false;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) {
        continue;
      }
      if (line.startsWith('*')) {
        continue; // Skip *vpn_servers and * at end
      }

      if (line.startsWith('#HostName')) {
        headerFound = true;
        // Clean the header line of the leading '#' for easier parsing if needed,
        // or just let the CSV parser handle it if we treat it manually.
        // We will remove '#' so the CSV converter treats it as a key if we utilize map conversion,
        // but here we just need the rows.
        cleanCsvLines.add(line.substring(1)); // Remove '#'
        continue;
      }

      if (headerFound) {
        cleanCsvLines.add(line);
      }
    }

    if (cleanCsvLines.isEmpty) {
      return [];
    }

    // Use standard CSV parser
    try {
      final csvConverter = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ); // We handle nums manually to be safe
      // Join back to string to pass to converter, or use convert on string
      final csvString = cleanCsvLines.join('\n');
      final rows = csvConverter.convert(csvString);

      // Map rows to entities
      // Check indices from header:
      // HostName(0), IP(1), Score(2), Ping(3), Speed(4), CountryLong(5), CountryShort(6),
      // NumVpnSessions(7), Uptime(8), TotalUsers(9), TotalTraffic(10), LogType(11),
      // Operator(12), Message(13), OpenVPN_ConfigData_Base64(14)

      final servers = <VpnServer>[];

      // Row 0 is header
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 15) {
          continue; // Invalid row
        }

        try {
          servers.add(
            VpnServer(
              hostName: row[0].toString(),
              ip: row[1].toString(),
              score: int.tryParse(row[2].toString()) ?? 0,
              ping: int.tryParse(row[3].toString()) ?? 0,
              speed: int.tryParse(row[4].toString()) ?? 0,
              countryLong: row[5].toString(),
              countryShort: row[6].toString(),
              numVpnSessions: int.tryParse(row[7].toString()) ?? 0,
              uptime: int.tryParse(row[8].toString()) ?? 0,
              totalUsers: int.tryParse(row[9].toString()) ?? 0,
              totalTraffic: int.tryParse(row[10].toString()) ?? 0,
              logType: row[11].toString(),
              operator: row[12].toString(),
              message: row[13].toString(),
              openVpnConfigData: row[14].toString(), // Base64
            ),
          );
        } catch (e) {
          // Skip malformed row
          // print('Error parsing row $i: $e');
        }
      }
      return servers;
    } catch (e) {
      // print('CSV Parsing error: $e');
      return [];
    }
  }
}
