// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recinto_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecintoAdapter extends TypeAdapter<Recinto> {
  @override
  final int typeId = 1;

  @override
  Recinto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Recinto(
      id: fields[0] as String,
      nombre: fields[1] as String,
      direccion: fields[2] as String?,
      descripcion: fields[3] as String?,
      fechaCreacion: fields[4] as DateTime,
      activo: fields[5] as bool,
      orden: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Recinto obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.direccion)
      ..writeByte(3)
      ..write(obj.descripcion)
      ..writeByte(4)
      ..write(obj.fechaCreacion)
      ..writeByte(5)
      ..write(obj.activo)
      ..writeByte(6)
      ..write(obj.orden);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecintoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
