import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../../domain/recinto_model.dart';
import '../../../../infrastructure/local_storage_service.dart';
import 'recinto_form_sheet.dart';
import '../../../shared/widgets/sheet_handle.dart';
import '../../clientes/clientes_por_recinto_view.dart';

/// Bottom sheet con opciones para un recinto
class RecintoOptionsSheet extends StatelessWidget {
  final Recinto recinto;

  const RecintoOptionsSheet({super.key, required this.recinto});

  // Colores consistentes con RecintoCard
  static const List<Color> _recintoColors = [
    Color(0xFF0F4C75),
    Color(0xFF3282B8),
    Color(0xFF00A8CC),
    Color(0xFF2E7D32),
    Color(0xFF00695C),
    Color(0xFF5D4037),
    Color(0xFF455A64),
    Color(0xFF37474F),
  ];

  Color get _recintoColor {
    final hash = recinto.nombre.hashCode.abs();
    return _recintoColors[hash % _recintoColors.length];
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
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RecintoHeader(recinto: recinto, color: _recintoColor),
                const SizedBox(height: 24),
                _buildOptions(context),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildOptions(BuildContext context) {
    final clientesCount = LocalStorageService.obtenerCantidadClientesEnRecinto(
      recinto.id,
    );

    return Column(
      children: [
        // Ver clientes - Opción principal
        _ModernOptionTile(
          icon: Icons.people_rounded,
          label: 'Ver clientes',
          subtitle: '$clientesCount registrados',
          color: _recintoColor,
          isPrimary: true,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
            _navegarAClientes(context);
          },
        ),
        const SizedBox(height: 12),
        // Opciones secundarias
        Row(
          children: [
            Expanded(
              child: _CompactOptionTile(
                icon: Icons.edit_rounded,
                label: 'Editar',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  _editarRecinto(context);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CompactOptionTile(
                icon: recinto.activo
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                label: recinto.activo ? 'Desactivar' : 'Activar',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  _toggleActivo();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CompactOptionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Eliminar',
                color: AppTheme.error,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  _confirmarEliminar(context);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _navegarAClientes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientesPorRecintoView(recinto: recinto),
      ),
    );
  }

  void _editarRecinto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecintoFormSheet(recinto: recinto),
    );
  }

  void _toggleActivo() async {
    final actualizado = recinto.copyWith(activo: !recinto.activo);
    await LocalStorageService.actualizarRecinto(actualizado);
  }

  void _confirmarEliminar(BuildContext context) {
    final clientesCount = LocalStorageService.obtenerCantidadClientesEnRecinto(
      recinto.id,
    );

    showDialog(
      context: context,
      builder: (ctx) => _DeleteConfirmationDialog(
        clientesCount: clientesCount,
        onConfirm: () async {
          await LocalStorageService.eliminarRecinto(recinto.id);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }
}

/// Header con información del recinto
class _RecintoHeader extends StatelessWidget {
  final Recinto recinto;
  final Color color;

  const _RecintoHeader({required this.recinto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              recinto.nombre.isNotEmpty ? recinto.nombre[0].toUpperCase() : 'R',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recinto.nombre,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              if (recinto.direccion != null && recinto.direccion!.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        recinto.direccion!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: recinto.activo
                            ? AppTheme.success.withValues(alpha: 0.1)
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        recinto.activo ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: recinto.activo
                              ? AppTheme.success
                              : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tile de opción moderna (principal)
class _ModernOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ModernOptionTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.8)],
                  )
                : null,
            color: isPrimary ? null : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: isPrimary
                ? null
                : Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? Colors.white : color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isPrimary ? Colors.white : AppTheme.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isPrimary
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppTheme.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isPrimary
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppTheme.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tile de opción compacta
class _CompactOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _CompactOptionTile({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? AppTheme.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: displayColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: displayColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: displayColor, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: displayColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Diálogo de confirmación para eliminar
class _DeleteConfirmationDialog extends StatelessWidget {
  final int clientesCount;
  final VoidCallback onConfirm;

  const _DeleteConfirmationDialog({
    required this.clientesCount,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Eliminar recinto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: Text(
        _getMessage(),
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Eliminar',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _getMessage() {
    return clientesCount > 0
        ? 'Este recinto tiene $clientesCount clientes asociados. ¿Está seguro de eliminarlo?'
        : '¿Está seguro de eliminar este recinto?';
  }
}
