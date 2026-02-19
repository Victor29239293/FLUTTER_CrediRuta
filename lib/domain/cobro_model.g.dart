// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cobro_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CobroAdapter extends TypeAdapter<Cobro> {
  @override
  final int typeId = 0;

  @override
  Cobro read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Cobro(
      id: fields[0] as String,
      cliente: fields[1] as String,
      recinto: fields[2] as String,
      abono: fields[3] as double,
      metodoPago: fields[4] as String,
      imagenesPath: (fields[5] as List).cast<String>(),
      fecha: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Cobro obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cliente)
      ..writeByte(2)
      ..write(obj.recinto)
      ..writeByte(3)
      ..write(obj.abono)
      ..writeByte(4)
      ..write(obj.metodoPago)
      ..writeByte(5)
      ..write(obj.imagenesPath)
      ..writeByte(6)
      ..write(obj.fecha);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CobroAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
