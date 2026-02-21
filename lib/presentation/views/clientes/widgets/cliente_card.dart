import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../../domain/cliente_model.dart';
import 'cliente_options_sheet.dart';

/// Card moderna que muestra la información de un cliente
class ClienteCard extends StatelessWidget {
  final Cliente cliente;
  final String recintoNombre;

  const ClienteCard({
    super.key,
    required this.cliente,
    required this.recintoNombre,
  });

  // Colores para avatares de clientes
  static const List<Color> _avatarColors = [
    Color(0xFF0F4C75), // Azul oscuro
    Color(0xFF3282B8), // Azul
    Color(0xFF00A8CC), // Cyan
    Color(0xFF2E7D32), // Verde
    Color(0xFF00695C), // Teal
    Color(0xFF5D4037), // Marrón
    Color(0xFF455A64), // Gris azulado
    Color(0xFF6A1B9A), // Púrpura
  ];

  Color get _avatarColor {
    final hash = cliente.nombre.hashCode.abs();
    return _avatarColors[hash % _avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cliente.activo
              ? _avatarColor.withValues(alpha: 0.12)
              : Colors.grey.withValues(alpha: 0.1),
        ),
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
          onTap: () => _mostrarOpciones(context),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _ClienteAvatar(
                  nombre: cliente.nombre,
                  activo: cliente.activo,
                  color: _avatarColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ClienteInfo(
                    cliente: cliente,
                    accentColor: _avatarColor,
                  ),
                ),
                _ActionIndicator(activo: cliente.activo),
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
      builder: (context) =>
          ClienteOptionsSheet(cliente: cliente, recintoNombre: recintoNombre),
    );
  }
}

/// Avatar con inicial del cliente
class _ClienteAvatar extends StatelessWidget {
  final String nombre;
  final bool activo;
  final Color color;

  const _ClienteAvatar({
    required this.nombre,
    required this.activo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: activo
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)],
              )
            : null,
        color: activo ? null : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        boxShadow: activo
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          inicial,
          style: TextStyle(
            color: activo ? Colors.white : AppTheme.textMuted,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Información del cliente (nombre y referencia)
class _ClienteInfo extends StatelessWidget {
  final Cliente cliente;
  final Color accentColor;

  const _ClienteInfo({required this.cliente, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre y badge de inactivo
        Row(
          children: [
            Expanded(
              child: Text(
                cliente.nombre,
                style: TextStyle(
                  color: cliente.activo
                      ? AppTheme.textPrimary
                      : AppTheme.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!cliente.activo)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Inactivo',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        // Referencia y GPS
        Row(
          children: [
            if (cliente.referencia != null && cliente.referencia!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_outlined, size: 12, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      cliente.referencia!,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                'Sin teléfono',
                style: TextStyle(
                  color: AppTheme.textMuted.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            const SizedBox(width: 8),
            // Indicador de GPS
            if (cliente.tieneUbicacion)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gps_fixed, size: 11, color: AppTheme.success),
                    const SizedBox(width: 3),
                    Text(
                      'GPS',
                      style: TextStyle(
                        color: AppTheme.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.chevron_right_rounded,
        color: activo ? AppTheme.textSecondary : AppTheme.textMuted,
        size: 18,
      ),
    );
  }
}
