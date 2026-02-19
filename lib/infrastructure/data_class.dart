// ============================================================
// DATA CLASS
// ============================================================
import '../domain/cobro_model.dart';
import 'local_storage_service.dart';

class CobrosData {
  final List<Cobro> cobros;
  final double total;
  final double totalEfectivo;
  final double totalTransferencia;
  final DateTime fecha;

  CobrosData({
    required this.cobros,
    required this.total,
    required this.totalEfectivo,
    required this.totalTransferencia,
    required this.fecha,
  });

  factory CobrosData.fromDate(DateTime fecha) {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);

    final cobros = LocalStorageService.obtenerCobrosPorFecha(inicio, fin);

    return CobrosData(
      cobros: cobros,
      total: cobros.fold(0.0, (sum, c) => sum + c.abono),
      totalEfectivo: cobros
          .where((c) => c.metodoPago == 'Efectivo')
          .fold(0.0, (sum, c) => sum + c.abono),
      totalTransferencia: cobros
          .where((c) => c.metodoPago == 'Transferencia')
          .fold(0.0, (sum, c) => sum + c.abono),
      fecha: fecha,
    );
  }

  int get cantidadCobros => cobros.length;
  bool get isEmpty => cobros.isEmpty;

  Map<String, List<Cobro>> get cobrosPorRecinto {
    final Map<String, List<Cobro>> agrupados = {};
    final cobrosOrdenados = List<Cobro>.from(cobros)
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    for (final cobro in cobrosOrdenados) {
      agrupados.putIfAbsent(cobro.recinto, () => []).add(cobro);
    }
    return agrupados;
  }

  double totalPorRecinto(String recinto) {
    return cobrosPorRecinto[recinto]?.fold<double>(
          0.0,
          (sum, cobro) => sum + cobro.abono,
        ) ??
        0.0;
  }

  List<String> get recintosOrdenados => cobrosPorRecinto.keys.toList();

  CobrosData filtrarPorBusqueda(String termino) {
    if (termino.isEmpty) return this;

    final terminoLower = termino.toLowerCase();
    final cobrosFiltrados = cobros.where((cobro) {
      return cobro.cliente.toLowerCase().contains(terminoLower) ||
          cobro.recinto.toLowerCase().contains(terminoLower);
    }).toList();

    return CobrosData(
      cobros: cobrosFiltrados,
      total: cobrosFiltrados.fold(0.0, (sum, c) => sum + c.abono),
      totalEfectivo: cobrosFiltrados
          .where((c) => c.metodoPago == 'Efectivo')
          .fold(0.0, (sum, c) => sum + c.abono),
      totalTransferencia: cobrosFiltrados
          .where((c) => c.metodoPago == 'Transferencia')
          .fold(0.0, (sum, c) => sum + c.abono),
      fecha: fecha,
    );
  }
}
