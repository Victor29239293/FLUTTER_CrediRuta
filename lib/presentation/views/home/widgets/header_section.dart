import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../infrastructure/data_class.dart';
import 'date_selector.dart';
import 'report_options_sheet.dart';

/// Sección del header con diseño moderno y limpio
class HeaderSection extends StatelessWidget {
  final CobrosData cobrosData;
  final DateTime fechaSeleccionada;
  final ValueChanged<DateTime> onFechaChanged;

  const HeaderSection({
    super.key,
    required this.cobrosData,
    required this.fechaSeleccionada,
    required this.onFechaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de fecha y botón de reporte
          Row(
            children: [
              Expanded(
                child: DateSelector(
                  fechaSeleccionada: fechaSeleccionada,
                  onFechaChanged: onFechaChanged,
                ),
              ),
              const SizedBox(width: 12),
              _ReportButton(
                onPressed: () =>
                    showReportOptionsSheet(context, fechaSeleccionada),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tarjeta de totales moderna
          _ModernTotalCard(cobrosData: cobrosData),
        ],
      ),
    );
  }
}

/// Botón de reporte moderno
class _ReportButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ReportButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
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
          child: const Icon(
            Icons.download_rounded,
            color: AppTheme.primary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de totales con diseño moderno
class _ModernTotalCard extends StatelessWidget {
  final CobrosData cobrosData;

  const _ModernTotalCard({required this.cobrosData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F4C75), Color(0xFF1B262C)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4C75).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Total principal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Total del día',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '\$',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        cobrosData.total.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.5,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Cantidad de cobros
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${cobrosData.cantidadCobros}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Desglose por método de pago
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MetodoPagoChip(
                    icon: Icons.payments_rounded,
                    label: 'Efectivo',
                    monto: cobrosData.totalEfectivo,
                    color: AppTheme.efectivo,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _MetodoPagoChip(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Transferencia',
                    monto: cobrosData.totalTransferencia,
                    color: AppTheme.transferencia,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de método de pago
class _MetodoPagoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double monto;
  final Color color;

  const _MetodoPagoChip({
    required this.icon,
    required this.label,
    required this.monto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '\$${monto.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
