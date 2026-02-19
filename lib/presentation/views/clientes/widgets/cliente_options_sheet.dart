import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../../domain/cliente_model.dart';
import '../../../../infrastructure/local_storage_service.dart';
import '../../../shared/widgets/sheet_handle.dart';
import 'cliente_form_sheet.dart';

/// BottomSheet con opciones para un cliente (editar, activar/desactivar, eliminar)
class ClienteOptionsSheet extends StatelessWidget {
  final Cliente cliente;
  final String recintoNombre;

  const ClienteOptionsSheet({
    super.key,
    required this.cliente,
    required this.recintoNombre,
  });

  // Colores consistentes con ClienteCard
  static const List<Color> _avatarColors = [
    Color(0xFF0F4C75),
    Color(0xFF3282B8),
    Color(0xFF00A8CC),
    Color(0xFF2E7D32),
    Color(0xFF00695C),
    Color(0xFF5D4037),
    Color(0xFF455A64),
    Color(0xFF6A1B9A),
  ];

  Color get _avatarColor {
    final hash = cliente.nombre.hashCode.abs();
    return _avatarColors[hash % _avatarColors.length];
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
                _ClienteHeader(
                  cliente: cliente,
                  recintoNombre: recintoNombre,
                  color: _avatarColor,
                ),
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
    return Column(
      children: [
        // Editar cliente - Opción principal
        _ModernOptionTile(
          icon: Icons.edit_rounded,
          label: 'Editar cliente',
          subtitle: 'Modificar nombre o teléfono',
          color: _avatarColor,
          isPrimary: true,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
            _editarCliente(context);
          },
        ),
        const SizedBox(height: 12),
        // Opciones secundarias
        Row(
          children: [
            Expanded(
              child: _CompactOptionTile(
                icon: cliente.activo
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                label: cliente.activo ? 'Desactivar' : 'Activar',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  _toggleActivoCliente(context);
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

  void _editarCliente(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClienteFormSheet(
        recintoId: cliente.recintoId,
        clienteEditar: cliente,
      ),
    );
  }

  Future<void> _toggleActivoCliente(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final clienteActualizado = cliente.copyWith(activo: !cliente.activo);
    await LocalStorageService.actualizarCliente(clienteActualizado);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cliente.activo ? 'Cliente desactivado' : 'Cliente activado',
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _confirmarEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _DeleteConfirmationDialog(
        clienteNombre: cliente.nombre,
        onConfirm: () async {
          Navigator.pop(ctx);
          await LocalStorageService.eliminarCliente(cliente.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Cliente eliminado'),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

/// Header con información del cliente
class _ClienteHeader extends StatelessWidget {
  final Cliente cliente;
  final String recintoNombre;
  final Color color;

  const _ClienteHeader({
    required this.cliente,
    required this.recintoNombre,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final inicial = cliente.nombre.isNotEmpty
        ? cliente.nombre[0].toUpperCase()
        : '?';

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
              inicial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
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
                cliente.nombre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Recinto
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    recintoNombre,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              // Teléfono si existe
              if (cliente.referencia != null &&
                  cliente.referencia!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      cliente.referencia!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        // Badge de estado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: cliente.activo
                ? AppTheme.success.withValues(alpha: 0.1)
                : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            cliente.activo ? 'Activo' : 'Inactivo',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: cliente.activo ? AppTheme.success : AppTheme.textMuted,
            ),
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
  final String clienteNombre;
  final VoidCallback onConfirm;

  const _DeleteConfirmationDialog({
    required this.clienteNombre,
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
            'Eliminar cliente',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: Text(
        '¿Estás seguro de eliminar a "$clienteNombre"?\nEsta acción no se puede deshacer.',
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
}
