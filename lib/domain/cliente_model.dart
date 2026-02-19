import 'package:hive/hive.dart';

part 'cliente_model.g.dart';

/// Modelo Cliente para almacenar información de clientes por recinto.
///
/// Cada cliente está asociado a un [Recinto] mediante [recintoId].
/// Esto permite organizar clientes por ubicación y facilitar
/// la selección al momento de registrar cobros.
@HiveType(typeId: 2)
class Cliente extends HiveObject {
  /// Identificador único del cliente (UUID)
  @HiveField(0)
  final String id;

  /// Nombre completo del cliente
  @HiveField(1)
  final String nombre;

  /// Referencia opcional (teléfono, cédula, etc.)
  @HiveField(2)
  final String? referencia;

  /// ID del recinto al que pertenece este cliente (FK a Recinto.id)
  @HiveField(3)
  final String recintoId;

  /// Fecha de creación del registro
  @HiveField(4)
  final DateTime fechaCreacion;

  /// Estado del cliente (soft delete)
  @HiveField(5)
  final bool activo;

  Cliente({
    required this.id,
    required this.nombre,
    this.referencia,
    required this.recintoId,
    required this.fechaCreacion,
    this.activo = true,
  });

  /// Crea una copia del cliente con campos modificados
  Cliente copyWith({
    String? id,
    String? nombre,
    String? referencia,
    String? recintoId,
    DateTime? fechaCreacion,
    bool? activo,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      referencia: referencia ?? this.referencia,
      recintoId: recintoId ?? this.recintoId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      activo: activo ?? this.activo,
    );
  }

  @override
  String toString() => nombre;
}
