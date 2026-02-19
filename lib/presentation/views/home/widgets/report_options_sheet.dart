import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../infrastructure/report_service.dart';

/// Bottom sheet para opciones de descarga y compartir reportes
class ReportOptionsSheet extends StatefulWidget {
  final DateTime fechaSeleccionada;

  const ReportOptionsSheet({super.key, required this.fechaSeleccionada});

  @override
  State<ReportOptionsSheet> createState() => _ReportOptionsSheetState();
}

class _ReportOptionsSheetState extends State<ReportOptionsSheet> {
  bool _isLoading = false;
  String? _rutaArchivoGenerado;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _usarRangoFechas = false;

  @override
  void initState() {
    super.initState();
    _fechaInicio = widget.fechaSeleccionada;
    _fechaFin = widget.fechaSeleccionada;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          const Divider(height: 1),
          _buildDateRangeToggle(),
          if (_usarRangoFechas) _buildDateRangeSelector(),
          const Divider(height: 1),
          _buildOptions(),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.summarize_rounded,
              color: AppTheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generar Reporte',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Exporta los cobros por recintos',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildDateRangeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _usarRangoFechas
                  ? 'Rango de fechas'
                  : 'Solo: ${_formatDate(_fechaInicio!)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Switch(
            value: _usarRangoFechas,
            activeTrackColor: AppTheme.primary,
            onChanged: (value) {
              setState(() {
                _usarRangoFechas = value;
                if (!value) {
                  _fechaInicio = widget.fechaSeleccionada;
                  _fechaFin = widget.fechaSeleccionada;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _DateButton(
              label: 'Desde',
              date: _fechaInicio!,
              onTap: () => _selectDate(isStart: true),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.arrow_forward, color: AppTheme.textSecondary),
          ),
          Expanded(
            child: _DateButton(
              label: 'Hasta',
              date: _fechaFin!,
              onTap: () => _selectDate(isStart: false),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _fechaInicio! : _fechaFin!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _fechaInicio = picked;
          if (_fechaFin!.isBefore(picked)) {
            _fechaFin = picked;
          }
        } else {
          _fechaFin = picked;
          if (_fechaInicio!.isAfter(picked)) {
            _fechaInicio = picked;
          }
        }
      });
    }
  }

  Widget _buildOptions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _OptionTile(
            icon: Icons.table_chart_rounded,
            iconColor: Colors.green,
            title: 'Descargar Excel',
            subtitle: 'Reporte completo en formato .xlsx',
            onTap: _isLoading ? null : _generarYDescargarExcel,
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.share_rounded,
            iconColor: Colors.blue,
            title: 'Compartir Excel',
            subtitle: 'Enviar archivo por cualquier app',
            onTap: _isLoading ? null : _generarYCompartirExcel,
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.chat_rounded,
            iconColor: const Color(0xFF25D366),
            title: 'Compartir por WhatsApp',
            subtitle: 'Resumen de texto + archivo Excel',
            onTap: _isLoading ? null : _compartirPorWhatsApp,
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.text_snippet_rounded,
            iconColor: Colors.orange,
            title: 'Solo resumen de texto',
            subtitle: 'Compartir resumen rápido',
            onTap: _isLoading ? null : _compartirResumenTexto,
          ),
        ],
      ),
    );
  }

  Future<void> _generarYDescargarExcel() async {
    setState(() => _isLoading = true);

    try {
      final rutaArchivo = await ReportService.generarReporteExcel(
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin!,
      );

      _rutaArchivoGenerado = rutaArchivo;

      await ReportService.abrirArchivo(rutaArchivo);

      if (mounted) {
        HapticFeedback.mediumImpact();
        _showSuccessSnackBar('Reporte generado correctamente');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al generar el reporte: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generarYCompartirExcel() async {
    setState(() => _isLoading = true);

    try {
      final rutaArchivo =
          _rutaArchivoGenerado ??
          await ReportService.generarReporteExcel(
            fechaInicio: _fechaInicio!,
            fechaFin: _fechaFin!,
          );

      _rutaArchivoGenerado = rutaArchivo;

      await ReportService.compartirArchivo(rutaArchivo);

      if (mounted) {
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al compartir: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _compartirPorWhatsApp() async {
    setState(() => _isLoading = true);

    try {
      // Generar el archivo Excel primero
      final rutaArchivo =
          _rutaArchivoGenerado ??
          await ReportService.generarReporteExcel(
            fechaInicio: _fechaInicio!,
            fechaFin: _fechaFin!,
          );

      _rutaArchivoGenerado = rutaArchivo;

      // Compartir el archivo (que abrirá el selector incluyendo WhatsApp)
      await ReportService.compartirPorWhatsApp(rutaArchivo);

      if (mounted) {
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al compartir: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _compartirResumenTexto() async {
    setState(() => _isLoading = true);

    try {
      await ReportService.compartirResumenWhatsApp(
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin!,
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al compartir: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Botón de selección de fecha
class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(date),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Tile de opción individual
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Función helper para mostrar el bottom sheet de reportes
void showReportOptionsSheet(BuildContext context, DateTime fechaSeleccionada) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        ReportOptionsSheet(fechaSeleccionada: fechaSeleccionada),
  );
}
