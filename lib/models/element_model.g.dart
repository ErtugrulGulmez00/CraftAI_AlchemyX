// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'element_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameElementAdapter extends TypeAdapter<GameElement> {
  @override
  final int typeId = 0;

  @override
  GameElement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameElement(
      name: fields[0] as String,
      emoji: fields[1] as String,
      isFirstDiscovery: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, GameElement obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.emoji)
      ..writeByte(2)
      ..write(obj.isFirstDiscovery);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameElementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
