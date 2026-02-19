import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../../domain/recinto_model.dart';
import '../../../../infrastructure/local_storage_service.dart';
import 'recinto_options_sheet.dart';

/// Card moderna que muestra la información de un recinto
class RecintoCard extends StatelessWidget {
  final Recinto recinto;

  const RecintoCard({super.key, required this.recinto});

  // Lista de colores para los recintos
  static const List<Color> _recintoColors = [
    Color(0xFF0F4C75), // Azul oscuro
    Color(0xFF3282B8), // Azul
    Color(0xFF00A8CC), // Cyan
    Color(0xFF2E7D32), // Verde
    Color(0xFF00695C), // Teal
    Color(0xFF5D4037), // Marrón
    Color(0xFF455A64), // Gris azulado
    Color(0xFF37474F), // Gris oscuro
  ];

  Color get _recintoColor {
    final hash = recinto.nombre.hashCode.abs();
    return _recintoColors[hash % _recintoColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final clientesCount = LocalStorageService.obtenerCantidadClientesEnRecinto(
      recinto.id,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: recinto.activo
              ? _recintoColor.withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _mostrarOpciones(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _RecintoAvatar(
                  activo: recinto.activo,
                  color: _recintoColor,
                  inicial: recinto.nombre.isNotEmpty
                      ? recinto.nombre[0].toUpperCase()
                      : 'R',
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _RecintoInfo(
                    recinto: recinto,
                    clientesCount: clientesCount,
                    accentColor: _recintoColor,
                  ),
                ),
                _ActionIndicator(activo: recinto.activo),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarOpciones(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => RecintoOptionsSheet(recinto: recinto),
    );
  }
}

/// Avatar/Icono del recinto con inicial
class _RecintoAvatar extends StatelessWidget {
  final bool activo;
  final Color color;
  final String inicial;

  const _RecintoAvatar({
    required this.activo,
    required this.color,
    required this.inicial,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: activo
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)],
              )
            : null,
        color: activo ? null : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        boxShadow: activo
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          inicial,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: activo ? Colors.white : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Información del recinto (nombre, estado, clientes, dirección)
class _RecintoInfo extends StatelessWidget {
  final Recinto recinto;
  final int clientesCount;
  final Color accentColor;

  const _RecintoInfo({
    required this.recinto,
    required this.clientesCount,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildHeader(), const SizedBox(height: 8), _buildDetails()],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            recinto.nombre,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: recinto.activo ? AppTheme.textPrimary : AppTheme.textMuted,
            ),
          ),
        ),
        if (!recinto.activo) const _InactiveBadge(),
      ],
    );
  }

  Widget _buildDetails() {
    return Row(
      children: [
        // Badge de clientes
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline_rounded, size: 14, color: accentColor),
              const SizedBox(width: 5),
              Text(
                '$clientesCount clientes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
        if (_hasAddress) ...[
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Icon(Icons.place_outlined, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    recinto.direccion!,
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  bool get _hasAddress =>
      recinto.direccion != null && recinto.direccion!.isNotEmpty;
}

/// Badge de estado inactivo
class _InactiveBadge extends StatelessWidget {
  const _InactiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Inactivo',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppTheme.textMuted,
        ),
      ),
    );
  }
}

/// Indicador de acción (chevron)
class _ActionIndicator extends StatelessWidget {
  final bool activo;

  const _ActionIndicator({required this.activo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.chevron_right_rounded,
        color: activo ? AppTheme.textSecondary : AppTheme.textMuted,
        size: 20,
      ),
    );
  }
}
