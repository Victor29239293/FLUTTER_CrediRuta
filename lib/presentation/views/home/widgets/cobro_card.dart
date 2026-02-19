import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../domain/cobro_model.dart';
import '../detalle/detalle_cobro_sheet.dart';

/// Tarjeta individual para mostrar un cobro con diseño moderno
class CobroCard extends StatelessWidget {
  final Cobro cobro;

  const CobroCard({super.key, required this.cobro});

  bool get _isEfectivo => cobro.metodoPago == 'Efectivo';
  Color get _color => _isEfectivo ? AppTheme.efectivo : AppTheme.transferencia;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _mostrarDetalle(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _CobroAvatar(cobro: cobro, color: _color),
                const SizedBox(width: 14),
                Expanded(
                  child: _CobroInfo(cobro: cobro, color: _color),
                ),
                _CobroMonto(monto: cobro.abono, color: _color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetalle(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DetalleCobroSheet(cobro: cobro),
    );
  }
}

/// Avatar del cobro con diseño mejorado
class _CobroAvatar extends StatelessWidget {
  final Cobro cobro;
  final Color color;

  const _CobroAvatar({required this.cobro, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: cobro.imagenesPath.isEmpty
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
              )
            : null,
        color: cobro.imagenesPath.isNotEmpty ? AppTheme.surfaceVariant : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: cobro.imagenesPath.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.file(
                File(cobro.imagenesPath.first),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitial(),
              ),
            )
          : _buildInitial(),
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Text(
        cobro.cliente.isNotEmpty ? cobro.cliente[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Información del cobro mejorada
class _CobroInfo extends StatelessWidget {
  final Cobro cobro;
  final Color color;

  const _CobroInfo({required this.cobro, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cobro.cliente,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppTheme.textPrimary,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _MetodoPagoChip(metodoPago: cobro.metodoPago, color: color),
            const SizedBox(width: 8),
            _HoraIndicator(fecha: cobro.fecha),
            if (cobro.imagenesPath.isNotEmpty) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.photo_camera_rounded,
                size: 14,
                color: AppTheme.textMuted,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Chip del método de pago
class _MetodoPagoChip extends StatelessWidget {
  final String metodoPago;
  final Color color;

  const _MetodoPagoChip({required this.metodoPago, required this.color});

  @override
  Widget build(BuildContext context) {
    final isEfectivo = metodoPago == 'Efectivo';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEfectivo ? Icons.payments_rounded : Icons.swap_horiz_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isEfectivo ? 'Efectivo' : 'Transfer',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicador de la hora del cobro
class _HoraIndicator extends StatelessWidget {
  final DateTime fecha;

  const _HoraIndicator({required this.fecha});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 12, color: AppTheme.textMuted),
        const SizedBox(width: 3),
        Text(
          '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Monto del cobro con diseño destacado
class _CobroMonto extends StatelessWidget {
  final double monto;
  final Color color;

  const _CobroMonto({required this.monto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '\$${monto.toStringAsFixed(0)}',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: AppTheme.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
