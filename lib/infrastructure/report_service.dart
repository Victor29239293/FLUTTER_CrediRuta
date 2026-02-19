import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/cobro_model.dart';
import 'local_storage_service.dart';

/// Servicio para generar reportes de cobros en Excel
class ReportService {
  static String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'es_MX',
      symbol: '\$',
      decimalDigits: 2,
    ).format(value);
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static String _formatFileDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}_${date.hour.toString().padLeft(2, '0')}-${date.minute.toString().padLeft(2, '0')}';
  }

  /// Genera un reporte Excel de cobros por fecha
  /// Retorna la ruta del archivo generado
  static Future<String> generarReporteExcel({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    // Obtener cobros del rango de fechas
    final inicio = DateTime(
      fechaInicio.year,
      fechaInicio.month,
      fechaInicio.day,
    );
    final fin = DateTime(
      fechaFin.year,
      fechaFin.month,
      fechaFin.day,
      23,
      59,
      59,
    );
    final cobros = LocalStorageService.obtenerCobrosPorFecha(inicio, fin);

    // Agrupar cobros por recinto
    final cobrosPorRecinto = _agruparPorRecinto(cobros);

    // Crear el archivo Excel
    final excel = Excel.createExcel();

    // Eliminar la hoja por defecto
    excel.delete('Sheet1');

    // Crear hoja de resumen
    _crearHojaResumen(excel, cobrosPorRecinto, fechaInicio, fechaFin);

    // Crear una hoja por cada recinto
    for (final recinto in cobrosPorRecinto.keys) {
      _crearHojaRecinto(excel, recinto, cobrosPorRecinto[recinto]!);
    }

    // Guardar el archivo
    final directory = await getApplicationDocumentsDirectory();
    final reportesDir = Directory('${directory.path}/reportes');
    if (!await reportesDir.exists()) {
      await reportesDir.create(recursive: true);
    }

    final nombreArchivo =
        'reporte_cobros_${_formatFileDate(DateTime.now())}.xlsx';
    final rutaArchivo = '${reportesDir.path}/$nombreArchivo';

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final file = File(rutaArchivo);
      await file.writeAsBytes(fileBytes);
    }

    return rutaArchivo;
  }

  /// Agrupa los cobros por recinto
  static Map<String, List<Cobro>> _agruparPorRecinto(List<Cobro> cobros) {
    final Map<String, List<Cobro>> agrupados = {};

    // Ordenar por fecha descendente
    final cobrosOrdenados = List<Cobro>.from(cobros)
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    for (final cobro in cobrosOrdenados) {
      agrupados.putIfAbsent(cobro.recinto, () => []).add(cobro);
    }

    return agrupados;
  }

  /// Crea la hoja de resumen general
  static void _crearHojaResumen(
    Excel excel,
    Map<String, List<Cobro>> cobrosPorRecinto,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) {
    final sheet = excel['Resumen General'];

    // Estilos
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 12,
    );

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.fromHexString('#1565C0'),
    );

    final subtotalStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'),
    );

    final totalStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1565C0'),
      fontColorHex: ExcelColor.white,
      fontSize: 12,
    );

    int row = 0;

    // Título del reporte
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue(
      'REPORTE DE COBROS',
    );
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .cellStyle =
        titleStyle;
    row++;

    // Rango de fechas
    final rangoFechas =
        fechaInicio.isAtSameMomentAs(fechaFin) ||
            (fechaInicio.year == fechaFin.year &&
                fechaInicio.month == fechaFin.month &&
                fechaInicio.day == fechaFin.day)
        ? 'Fecha: ${_formatDate(fechaInicio)}'
        : 'Período: ${_formatDate(fechaInicio)} - ${_formatDate(fechaFin)}';
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue(
      rangoFechas,
    );
    row++;

    // Fecha de generación
    final now = DateTime.now();
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue(
      'Generado: ${_formatDate(now)} ${_formatTime(now)}',
    );
    row += 2;

    // Encabezados de la tabla de resumen
    final headers = [
      'Recinto',
      'Cant. Cobros',
      'Total Efectivo',
      'Total Transferencia',
      'Total',
    ];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }
    row++;

    // Variables para totales generales
    double totalGeneralEfectivo = 0;
    double totalGeneralTransferencia = 0;
    double totalGeneral = 0;
    int totalCobros = 0;

    // Datos por recinto
    for (final recinto in cobrosPorRecinto.keys) {
      final cobrosRecinto = cobrosPorRecinto[recinto]!;
      final totalEfectivo = cobrosRecinto
          .where((c) => c.metodoPago == 'Efectivo')
          .fold(0.0, (sum, c) => sum + c.abono);
      final totalTransferencia = cobrosRecinto
          .where((c) => c.metodoPago == 'Transferencia')
          .fold(0.0, (sum, c) => sum + c.abono);
      final total = cobrosRecinto.fold(0.0, (sum, c) => sum + c.abono);

      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(
        recinto,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = IntCellValue(
        cobrosRecinto.length,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(
        _formatCurrency(totalEfectivo),
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(
        _formatCurrency(totalTransferencia),
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = TextCellValue(
        _formatCurrency(total),
      );

      // Aplicar estilo de subtotal
      for (int i = 0; i < 5; i++) {
        sheet
                .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
                .cellStyle =
            subtotalStyle;
      }

      totalGeneralEfectivo += totalEfectivo;
      totalGeneralTransferencia += totalTransferencia;
      totalGeneral += total;
      totalCobros += cobrosRecinto.length;

      row++;
    }

    // Fila de totales generales
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue(
      'TOTAL GENERAL',
    );
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
        .value = IntCellValue(
      totalCobros,
    );
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
        .value = TextCellValue(
      _formatCurrency(totalGeneralEfectivo),
    );
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
        .value = TextCellValue(
      _formatCurrency(totalGeneralTransferencia),
    );
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
        .value = TextCellValue(
      _formatCurrency(totalGeneral),
    );

    // Aplicar estilo de total
    for (int i = 0; i < 5; i++) {
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
              .cellStyle =
          totalStyle;
    }

    // Ajustar ancho de columnas
    sheet.setColumnWidth(0, 25);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 20);
    sheet.setColumnWidth(3, 20);
    sheet.setColumnWidth(4, 20);
  }

  /// Crea una hoja para un recinto específico con todos sus cobros
  static void _crearHojaRecinto(
    Excel excel,
    String nombreRecinto,
    List<Cobro> cobros,
  ) {
    // Limpiar nombre del recinto para usarlo como nombre de hoja
    final nombreHoja = _limpiarNombreHoja(nombreRecinto);
    final sheet = excel[nombreHoja];

    // Estilos
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#4CAF50'),
      fontColorHex: ExcelColor.white,
      horizontalAlign: HorizontalAlign.Center,
    );

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#2E7D32'),
    );

    final totalStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#4CAF50'),
      fontColorHex: ExcelColor.white,
    );

    int row = 0;

    // Título del recinto
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue(
      'RECINTO: $nombreRecinto',
    );
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .cellStyle =
        titleStyle;
    row += 2;

    // Encabezados
    final headers = [
      '#',
      'Fecha',
      'Hora',
      'Cliente',
      'Método de Pago',
      'Abono',
    ];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }
    row++;

    // Datos de cobros
    int numero = 1;
    for (final cobro in cobros) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = IntCellValue(
        numero,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(
        _formatDate(cobro.fecha),
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(
        _formatTime(cobro.fecha),
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(
        cobro.cliente,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = TextCellValue(
        cobro.metodoPago,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = TextCellValue(
        _formatCurrency(cobro.abono),
      );

      numero++;
      row++;
    }

    // Fila vacía antes del total
    row++;

    // Totales por método de pago
    final totalEfectivo = cobros
        .where((c) => c.metodoPago == 'Efectivo')
        .fold(0.0, (sum, c) => sum + c.abono);
    final totalTransferencia = cobros
        .where((c) => c.metodoPago == 'Transferencia')
        .fold(0.0, (sum, c) => sum + c.abono);
    final total = cobros.fold(0.0, (sum, c) => sum + c.abono);

    // Total Efectivo
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
        .value = TextCellValue(
      'Total Efectivo:',
    );
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
        .value = TextCellValue(
      _formatCurrency(totalEfectivo),
    );
    row++;

    // Total Transferencia
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
        .value = TextCellValue(
      'Total Transferencia:',
    );
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
        .value = TextCellValue(
      _formatCurrency(totalTransferencia),
    );
    row++;

    // Total general del recinto
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
        .value = TextCellValue(
      'TOTAL RECINTO:',
    );
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .cellStyle =
        totalStyle;
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
        .value = TextCellValue(
      _formatCurrency(total),
    );
    sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .cellStyle =
        totalStyle;

    // Ajustar ancho de columnas
    sheet.setColumnWidth(0, 8);
    sheet.setColumnWidth(1, 12);
    sheet.setColumnWidth(2, 10);
    sheet.setColumnWidth(3, 30);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 15);
  }

  /// Limpia el nombre del recinto para usarlo como nombre de hoja Excel
  static String _limpiarNombreHoja(String nombre) {
    // Los nombres de hojas en Excel no pueden tener: / \ ? * [ ]
    // y tienen un límite de 31 caracteres
    String nombreLimpio = nombre
        .replaceAll('/', '-')
        .replaceAll('\\', '-')
        .replaceAll('?', '')
        .replaceAll('*', '')
        .replaceAll('[', '(')
        .replaceAll(']', ')');

    if (nombreLimpio.length > 31) {
      nombreLimpio = nombreLimpio.substring(0, 31);
    }

    return nombreLimpio.isEmpty ? 'Sin nombre' : nombreLimpio;
  }

  /// Abre el archivo Excel en la aplicación predeterminada
  static Future<void> abrirArchivo(String rutaArchivo) async {
    await OpenFilex.open(rutaArchivo);
  }

  /// Comparte el archivo Excel
  static Future<void> compartirArchivo(String rutaArchivo) async {
    await Share.shareXFiles(
      [XFile(rutaArchivo)],
      subject: 'Reporte de Cobros',
      text: 'Te comparto el reporte de cobros',
    );
  }

  /// Comparte el archivo por WhatsApp
  static Future<bool> compartirPorWhatsApp(String rutaArchivo) async {
    try {
      // Intentar compartir directamente el archivo
      await Share.shareXFiles(
        [XFile(rutaArchivo)],
        subject: 'Reporte de Cobros',
        text: 'Te comparto el reporte de cobros',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Genera un resumen en texto para compartir por WhatsApp
  static String generarResumenTexto({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) {
    final inicio = DateTime(
      fechaInicio.year,
      fechaInicio.month,
      fechaInicio.day,
    );
    final fin = DateTime(
      fechaFin.year,
      fechaFin.month,
      fechaFin.day,
      23,
      59,
      59,
    );
    final cobros = LocalStorageService.obtenerCobrosPorFecha(inicio, fin);
    final cobrosPorRecinto = _agruparPorRecinto(cobros);

    final buffer = StringBuffer();

    // Encabezado
    buffer.writeln('📊 *REPORTE DE COBROS*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');

    final rangoFechas =
        fechaInicio.isAtSameMomentAs(fechaFin) ||
            (fechaInicio.year == fechaFin.year &&
                fechaInicio.month == fechaFin.month &&
                fechaInicio.day == fechaFin.day)
        ? '📅 Fecha: ${_formatDate(fechaInicio)}'
        : '📅 Período: ${_formatDate(fechaInicio)} - ${_formatDate(fechaFin)}';
    buffer.writeln(rangoFechas);
    buffer.writeln('');

    double totalGeneralEfectivo = 0;
    double totalGeneralTransferencia = 0;
    double totalGeneral = 0;

    // Detalles por recinto
    for (final recinto in cobrosPorRecinto.keys) {
      final cobrosRecinto = cobrosPorRecinto[recinto]!;
      final totalEfectivo = cobrosRecinto
          .where((c) => c.metodoPago == 'Efectivo')
          .fold(0.0, (sum, c) => sum + c.abono);
      final totalTransferencia = cobrosRecinto
          .where((c) => c.metodoPago == 'Transferencia')
          .fold(0.0, (sum, c) => sum + c.abono);
      final total = cobrosRecinto.fold(0.0, (sum, c) => sum + c.abono);

      buffer.writeln('🏢 *$recinto*');
      buffer.writeln('   Cobros: ${cobrosRecinto.length}');

      // Listar clientes
      buffer.writeln('   👥 Clientes:');
      for (final cobro in cobrosRecinto) {
        final icono = cobro.metodoPago == 'Efectivo' ? '💵' : '💳';
        buffer.writeln(
          '      • ${cobro.cliente} - $icono ${_formatCurrency(cobro.abono)}',
        );
      }

      if (totalEfectivo > 0) {
        buffer.writeln('   💵 Efectivo: ${_formatCurrency(totalEfectivo)}');
      }
      if (totalTransferencia > 0) {
        buffer.writeln(
          '   💳 Transferencia: ${_formatCurrency(totalTransferencia)}',
        );
      }
      buffer.writeln('   📌 *Total: ${_formatCurrency(total)}*');
      buffer.writeln('');

      totalGeneralEfectivo += totalEfectivo;
      totalGeneralTransferencia += totalTransferencia;
      totalGeneral += total;
    }

    // Total general
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📊 *TOTAL GENERAL*');
    buffer.writeln('   Total Cobros: ${cobros.length}');
    buffer.writeln('   💵 Efectivo: ${_formatCurrency(totalGeneralEfectivo)}');
    buffer.writeln(
      '   💳 Transferencia: ${_formatCurrency(totalGeneralTransferencia)}',
    );
    buffer.writeln('   💰 *TOTAL: ${_formatCurrency(totalGeneral)}*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━');

    return buffer.toString();
  }

  /// Comparte el resumen por WhatsApp (solo texto)
  static Future<void> compartirResumenWhatsApp({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? numeroTelefono,
  }) async {
    final resumen = generarResumenTexto(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );

    if (numeroTelefono != null && numeroTelefono.isNotEmpty) {
      // Abrir WhatsApp con número específico
      final encodedMessage = Uri.encodeComponent(resumen);
      final whatsappUrl = 'https://wa.me/$numeroTelefono?text=$encodedMessage';
      final uri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback a compartir genérico
        await Share.share(resumen, subject: 'Reporte de Cobros');
      }
    } else {
      // Compartir genérico
      await Share.share(resumen, subject: 'Reporte de Cobros');
    }
  }
}
