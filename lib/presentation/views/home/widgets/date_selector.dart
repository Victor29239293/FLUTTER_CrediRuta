import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_theme.dart';
import '../utils/date_formatter.dart';

/// Selector de fecha con diseño moderno tipo card
class DateSelector extends StatelessWidget {
  final DateTime fechaSeleccionada;
  final ValueChanged<DateTime> onFechaChanged;

  const DateSelector({
    super.key,
    required this.fechaSeleccionada,
    required this.onFechaChanged,
  });

  bool get _isToday {
    final now = DateTime.now();
    return fechaSeleccionada.year == now.year &&
        fechaSeleccionada.month == now.month &&
        fechaSeleccionada.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _DateNavButton(
            icon: Icons.chevron_left_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              onFechaChanged(
                fechaSeleccionada.subtract(const Duration(days: 1)),
              );
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _mostrarDatePicker(context),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isToday
                              ? 'Hoy'
                              : DateFormatter.formatearDiaSemana(
                                  fechaSeleccionada,
                                ),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          DateFormatter.formatearFechaCompleta(
                            fechaSeleccionada,
                          ),
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          _DateNavButton(
            icon: Icons.chevron_right_rounded,
            onTap: _isToday
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onFechaChanged(
                      fechaSeleccionada.add(const Duration(days: 1)),
                    );
                  },
            disabled: _isToday,
          ),
        ],
      ),
    );
  }

  void _mostrarDatePicker(BuildContext context) async {
    HapticFeedback.selectionClick();
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
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

    if (fecha != null) {
      onFechaChanged(fecha);
    }
  }
}

/// Botón de navegación moderno
class _DateNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  const _DateNavButton({required this.icon, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 50,
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: disabled
              ? AppTheme.textMuted.withValues(alpha: 0.3)
              : AppTheme.primary,
          size: 26,
        ),
      ),
    );
  }
}
