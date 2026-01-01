// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vpn_server.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VpnServerAdapter extends TypeAdapter<VpnServer> {
  @override
  final int typeId = 0;

  @override
  VpnServer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VpnServer(
      hostName: fields[0] as String,
      ip: fields[1] as String,
      score: fields[2] as int,
      ping: fields[3] as int,
      speed: fields[4] as int,
      countryLong: fields[5] as String,
      countryShort: fields[6] as String,
      numVpnSessions: fields[7] as int,
      uptime: fields[8] as int,
      totalUsers: fields[9] as int,
      totalTraffic: fields[10] as int,
      logType: fields[11] as String,
      operator: fields[12] as String,
      message: fields[13] as String,
      openVpnConfigData: fields[14] as String,
    );
  }

  @override
  void write(BinaryWriter writer, VpnServer obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.hostName)
      ..writeByte(1)
      ..write(obj.ip)
      ..writeByte(2)
      ..write(obj.score)
      ..writeByte(3)
      ..write(obj.ping)
      ..writeByte(4)
      ..write(obj.speed)
      ..writeByte(5)
      ..write(obj.countryLong)
      ..writeByte(6)
      ..write(obj.countryShort)
      ..writeByte(7)
      ..write(obj.numVpnSessions)
      ..writeByte(8)
      ..write(obj.uptime)
      ..writeByte(9)
      ..write(obj.totalUsers)
      ..writeByte(10)
      ..write(obj.totalTraffic)
      ..writeByte(11)
      ..write(obj.logType)
      ..writeByte(12)
      ..write(obj.operator)
      ..writeByte(13)
      ..write(obj.message)
      ..writeByte(14)
      ..write(obj.openVpnConfigData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VpnServerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
