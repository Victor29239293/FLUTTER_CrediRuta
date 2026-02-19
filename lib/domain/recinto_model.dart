import 'package:hive/hive.dart';

part 'recinto_model.g.dart';

@HiveType(typeId: 1)
class Recinto extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String nombre;

  @HiveField(2)
  final String? direccion;

  @HiveField(3)
  final String? descripcion;

  @HiveField(4)
  final DateTime fechaCreacion;

  @HiveField(5)
  final bool activo;

  @HiveField(6)
  final int orden;

  Recinto({
    required this.id,
    required this.nombre,
    this.direccion,
    this.descripcion,
    required this.fechaCreacion,
    this.activo = true,
    this.orden = 0,
  });

  /// Método para crear una copia con modificaciones
  Recinto copyWith({
    String? id,
    String? nombre,
    String? direccion,
    String? descripcion,
    DateTime? fechaCreacion,
    bool? activo,
    int? orden,
  }) {
    return Recinto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      descripcion: descripcion ?? this.descripcion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      activo: activo ?? this.activo,
      orden: orden ?? this.orden,
    );
  }

  @override
  String toString() => nombre;
}
