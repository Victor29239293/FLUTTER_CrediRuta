/// Utilidades para formatear fechas en español
class DateFormatter {
  DateFormatter._();

  static const List<String> _diasSemana = [
    'Dom',
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
  ];

  static const List<String> _meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// Retorna el día de la semana abreviado (Dom, Lun, etc.)
  static String formatearDiaSemana(DateTime fecha) {
    return _diasSemana[fecha.weekday % 7];
  }

  /// Retorna la fecha en formato "15 de enero de 2024"
  static String formatearFechaCompleta(DateTime fecha) {
    return '${fecha.day} de ${_meses[fecha.month - 1]} de ${fecha.year}';
  }

  /// Retorna la fecha con hora en formato "15 de enero • 14:30"
  static String formatearFechaConHora(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '${fecha.day} de ${_meses[fecha.month - 1]} • $hora:$minuto';
  }

  /// Verifica si la fecha es hoy
  static bool esHoy(DateTime fecha) {
    final now = DateTime.now();
    return fecha.year == now.year &&
        fecha.month == now.month &&
        fecha.day == now.day;
  }
}
