import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../domain/cobro_model.dart';
import '../../../../infrastructure/local_storage_service.dart';
import '../utils/date_formatter.dart';

/// Bottom sheet que muestra el detalle completo de un cobro
class DetalleCobroSheet extends StatelessWidget {
  final Cobro cobro;

  const DetalleCobroSheet({super.key, required this.cobro});

  bool get _isEfectivo => cobro.metodoPago == 'Efectivo';
  Color get _color => _isEfectivo ? AppTheme.efectivo : AppTheme.transferencia;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DragHandle(),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetalleHeader(cobro: cobro, color: _color),
                  const SizedBox(height: 28),
                  _DetalleInfo(
                    cobro: cobro,
                    isEfectivo: _isEfectivo,
                    color: _color,
                  ),
                  if (cobro.imagenesPath.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _ImagenesSection(imagenes: cobro.imagenesPath),
                  ],
                  const SizedBox(height: 32),
                  _EliminarButton(cobro: cobro),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Handle para arrastrar el bottom sheet
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Header del detalle con título, fecha y monto
class _DetalleHeader extends StatelessWidget {
  final Cobro cobro;
  final Color color;

  const _DetalleHeader({required this.cobro, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Detalle del cobro',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormatter.formatearFechaConHora(cobro.fecha),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _MontoChip(monto: cobro.abono, color: color),
      ],
    );
  }
}

/// Chip que muestra el monto
class _MontoChip extends StatelessWidget {
  final double monto;
  final Color color;

  const _MontoChip({required this.monto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '\$${monto.toStringAsFixed(2)}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Información detallada del cobro
class _DetalleInfo extends StatelessWidget {
  final Cobro cobro;
  final bool isEfectivo;
  final Color color;

  const _DetalleInfo({
    required this.cobro,
    required this.isEfectivo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _DetalleItem(
            icon: Icons.person_outline_rounded,
            label: 'Cliente',
            valor: cobro.cliente,
          ),
          Divider(height: 28, color: Colors.grey.shade300),
          _DetalleItem(
            icon: Icons.location_on_outlined,
            label: 'Recinto',
            valor: cobro.recinto,
          ),
          Divider(height: 28, color: Colors.grey.shade300),
          _DetalleItem(
            icon: isEfectivo
                ? Icons.payments_outlined
                : Icons.account_balance_outlined,
            label: 'Método de pago',
            valor: cobro.metodoPago,
            valorColor: color,
          ),
        ],
      ),
    );
  }
}

/// Item individual del detalle
class _DetalleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  final Color? valorColor;

  const _DetalleItem({
    required this.icon,
    required this.label,
    required this.valor,
    this.valorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: valorColor ?? AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sección de imágenes de evidencia
class _ImagenesSection extends StatelessWidget {
  final List<String> imagenes;

  const _ImagenesSection({required this.imagenes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ImagenesSectionHeader(cantidad: imagenes.length),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: imagenes.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < imagenes.length - 1 ? 12 : 0,
                ),
                child: _ImagenThumbnail(
                  imagePath: imagenes[index],
                  onTap: () => _mostrarImagenCompleta(context, imagenes[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _mostrarImagenCompleta(BuildContext context, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImagenCompletaScreen(imagePath: imagePath),
      ),
    );
  }
}

/// Header de la sección de imágenes
class _ImagenesSectionHeader extends StatelessWidget {
  final int cantidad;

  const _ImagenesSectionHeader({required this.cantidad});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.photo_library_outlined,
          size: 20,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          'Evidencia ($cantidad)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Thumbnail de una imagen
class _ImagenThumbnail extends StatelessWidget {
  final String imagePath;
  final VoidCallback onTap;

  const _ImagenThumbnail({required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(imagePath), fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// Pantalla completa para ver una imagen
class _ImagenCompletaScreen extends StatelessWidget {
  final String imagePath;

  const _ImagenCompletaScreen({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(File(imagePath)),
        ),
      ),
    );
  }
}

/// Botón para eliminar el cobro
class _EliminarButton extends StatelessWidget {
  final Cobro cobro;

  const _EliminarButton({required this.cobro});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmarEliminar(context),
        icon: const Icon(Icons.delete_outline_rounded, size: 20),
        label: const Text('Eliminar cobro'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.error,
          side: BorderSide(color: AppTheme.error.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _EliminarDialog(cobro: cobro, parentContext: context),
    );
  }
}

/// Diálogo de confirmación para eliminar
class _EliminarDialog extends StatelessWidget {
  final Cobro cobro;
  final BuildContext parentContext;

  const _EliminarDialog({required this.cobro, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.error),
          SizedBox(width: 12),
          Text('Eliminar cobro'),
        ],
      ),
      content: const Text(
        '¿Está seguro de eliminar este cobro? Esta acción no se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            await LocalStorageService.eliminarCobro(cobro.id);
            if (context.mounted) Navigator.pop(context);
            if (parentContext.mounted) Navigator.pop(parentContext);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}
