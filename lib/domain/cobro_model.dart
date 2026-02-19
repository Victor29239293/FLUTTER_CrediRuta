import 'package:hive/hive.dart';

part 'cobro_model.g.dart';

@HiveType(typeId: 0)
class Cobro extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String cliente;

  @HiveField(2)
  final String recinto;

  @HiveField(3)
  final double abono;

  @HiveField(4)
  final String metodoPago;

  @HiveField(5)
  final List<String> imagenesPath;

  @HiveField(6)
  final DateTime fecha;

  Cobro({
    required this.id,
    required this.cliente,
    required this.recinto,
    required this.abono,
    required this.metodoPago,
    required this.imagenesPath,
    required this.fecha,
  });

  // Método para crear una copia con modificaciones
  Cobro copyWith({
    String? id,
    String? cliente,
    String? recinto,
    double? abono,
    String? metodoPago,
    List<String>? imagenesPath,
    DateTime? fecha,
  }) {
    return Cobro(
      id: id ?? this.id,
      cliente: cliente ?? this.cliente,
      recinto: recinto ?? this.recinto,
      abono: abono ?? this.abono,
      metodoPago: metodoPago ?? this.metodoPago,
      imagenesPath: imagenesPath ?? this.imagenesPath,
      fecha: fecha ?? this.fecha,
    );
  }
}
