import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/theme/app_theme.dart';
import '../../../domain/cobro_model.dart';
import '../../../domain/cliente_model.dart';
import '../../../domain/recinto_model.dart';
import '../../../infrastructure/local_storage_service.dart';

/// Pantalla de cobro rápido con recinto y cliente preseleccionados.
///
/// Esta pantalla simplifica el proceso de registro de cobros:
/// - Muestra recinto y cliente en solo lectura
/// - Ofrece botones de montos rápidos (5, 10, 15, 20, 25, 50)
/// - Permite tomar foto de la cartilla
/// - Guarda el cobro en Hive
class NuevoCobroRapidoScreen extends StatefulWidget {
  final Recinto recinto;
  final Cliente cliente;

  const NuevoCobroRapidoScreen({
    super.key,
    required this.recinto,
    required this.cliente,
  });

  @override
  State<NuevoCobroRapidoScreen> createState() => _NuevoCobroRapidoScreenState();
}

class _NuevoCobroRapidoScreenState extends State<NuevoCobroRapidoScreen> {
  // Controlador para el campo de abono personalizado
  final _abonoController = TextEditingController();

  // Método de pago seleccionado (por defecto Efectivo)
  String _metodoPago = 'Efectivo';

  // Monto rápido seleccionado (null si se escribe manualmente)
  double? _montoRapidoSeleccionado;

  // Lista de fotos tomadas
  final List<File> _fotos = [];
  final ImagePicker _picker = ImagePicker();

  // Estado de guardado
  bool _guardando = false;

  // Montos rápidos disponibles
  static const List<double> _montosRapidos = [5, 10, 15, 20, 25, 50];

  @override
  void dispose() {
    _abonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar personalizado
          _buildAppBar(),

          // Contenido principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información del recinto y cliente (solo lectura)
                  _buildInfoSection(),
                  const SizedBox(height: 32),

                  // Botones de montos rápidos
                  _buildMontosRapidosSection(),
                  const SizedBox(height: 24),

                  // Campo de abono personalizado
                  _buildAbonoField(),
                  const SizedBox(height: 24),

                  // Selector de método de pago
                  _buildMetodoPagoSection(),
                  const SizedBox(height: 24),

                  // Sección de fotos
                  _buildFotosSection(),
                  const SizedBox(height: 32),

                  // Botón guardar
                  _buildGuardarButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// AppBar con título y botón de regreso
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primary,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: const Text(
          'Cobro Rápido',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
    );
  }

  /// Sección con información del recinto y cliente (solo lectura)
  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Recinto
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Recinto',
            value: widget.recinto.nombre,
            iconColor: AppTheme.primary,
          ),
          const Divider(height: 24),
          // Cliente
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Cliente',
            value: widget.cliente.nombre,
            subtitle: widget.cliente.referencia,
            iconColor: AppTheme.efectivo,
          ),
        ],
      ),
    );
  }

  /// Sección de botones de montos rápidos
  Widget _buildMontosRapidosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.speed, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Monto rápido',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Grid de botones de montos rápidos
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _montosRapidos.map((monto) {
            final isSelected = _montoRapidoSeleccionado == monto;
            return _MontoRapidoButton(
              monto: monto,
              isSelected: isSelected,
              onTap: () => _seleccionarMontoRapido(monto),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Selecciona un monto rápido y actualiza el campo de texto
  void _seleccionarMontoRapido(double monto) {
    HapticFeedback.lightImpact();
    setState(() {
      _montoRapidoSeleccionado = monto;
      _abonoController.text = monto.toStringAsFixed(0);
    });
  }

  /// Campo de texto para abono personalizado
  Widget _buildAbonoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_money, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Abono',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _abonoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            prefixText: '\$ ',
            prefixStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            hintText: '0',
            hintStyle: TextStyle(
              color: AppTheme.textMuted.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.textMuted.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
          onChanged: (value) {
            // Si el usuario escribe, deseleccionar el monto rápido
            final parsed = double.tryParse(value);
            if (parsed != null && !_montosRapidos.contains(parsed)) {
              setState(() => _montoRapidoSeleccionado = null);
            } else if (parsed != null && _montosRapidos.contains(parsed)) {
              setState(() => _montoRapidoSeleccionado = parsed);
            }
          },
        ),
      ],
    );
  }

  /// Selector de método de pago
  Widget _buildMetodoPagoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.payment, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Método de pago',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetodoPagoChip(
                label: 'Efectivo',
                icon: Icons.payments_outlined,
                isSelected: _metodoPago == 'Efectivo',
                color: AppTheme.efectivo,
                onTap: () => setState(() => _metodoPago = 'Efectivo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetodoPagoChip(
                label: 'Transferencia',
                icon: Icons.account_balance_outlined,
                isSelected: _metodoPago == 'Transferencia',
                color: AppTheme.transferencia,
                onTap: () => setState(() => _metodoPago = 'Transferencia'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Sección de fotos de evidencia
  Widget _buildFotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.camera_alt_outlined, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Foto de cartilla',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${_fotos.length} foto(s)',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Botones para tomar foto o seleccionar de galería
        Row(
          children: [
            // Botón para tomar foto con cámara
            Expanded(
              child: InkWell(
                onTap: _tomarFoto,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.add_a_photo,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Cámara',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Botón para seleccionar de galería
            Expanded(
              child: InkWell(
                onTap: _seleccionarDeGaleria,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.transferencia.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.transferencia.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.photo_library_outlined,
                          color: AppTheme.transferencia,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Galería',
                        style: TextStyle(
                          color: AppTheme.transferencia,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Miniaturas de fotos tomadas
        if (_fotos.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _fotos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < _fotos.length - 1 ? 12 : 0,
                  ),
                  child: _FotoMiniatura(
                    foto: _fotos[index],
                    onEliminar: () => _eliminarFoto(index),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  /// Toma una foto con la cámara
  Future<void> _tomarFoto() async {
    HapticFeedback.lightImpact();
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (imagen != null) {
      setState(() => _fotos.add(File(imagen.path)));
    }
  }

  /// Selecciona una imagen de la galería
  Future<void> _seleccionarDeGaleria() async {
    HapticFeedback.lightImpact();
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (imagen != null) {
      setState(() => _fotos.add(File(imagen.path)));
    }
  }

  /// Elimina una foto de la lista
  void _eliminarFoto(int index) {
    HapticFeedback.lightImpact();
    setState(() => _fotos.removeAt(index));
  }

  /// Botón principal para guardar el cobro
  Widget _buildGuardarButton() {
    final tieneAbono =
        _abonoController.text.isNotEmpty &&
        double.tryParse(_abonoController.text) != null &&
        double.parse(_abonoController.text) > 0;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: tieneAbono && !_guardando ? _guardarCobro : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          disabledBackgroundColor: AppTheme.textMuted.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _guardando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Guardar Cobro',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Guarda el cobro en Hive y regresa a la pantalla anterior
  Future<void> _guardarCobro() async {
    setState(() => _guardando = true);
    HapticFeedback.mediumImpact();

    try {
      // Guardar fotos si hay
      List<String> rutasImagenes = [];
      if (_fotos.isNotEmpty) {
        rutasImagenes = await LocalStorageService.guardarImagenes(_fotos);
      }

      // Crear el objeto Cobro
      final cobro = Cobro(
        id: LocalStorageService.generateId(),
        cliente: widget.cliente.nombre,
        recinto: widget.recinto.nombre,
        abono: double.parse(_abonoController.text),
        metodoPago: _metodoPago,
        imagenesPath: rutasImagenes,
        fecha: DateTime.now(),
      );

      // Guardar en Hive
      await LocalStorageService.guardarCobro(cobro);

      if (mounted) {
        // Mostrar SnackBar de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Cobro de \$${_abonoController.text} registrado'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Volver a la pantalla anterior
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}

// ============================================================
// WIDGETS AUXILIARES
// ============================================================

/// Fila de información (recinto/cliente)
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Botón de monto rápido
class _MontoRapidoButton extends StatelessWidget {
  final double monto;
  final bool isSelected;
  final VoidCallback onTap;

  const _MontoRapidoButton({
    required this.monto,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.textMuted.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          '\$${monto.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Chip de método de pago
class _MetodoPagoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _MetodoPagoChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : AppTheme.textMuted.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppTheme.textMuted,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Miniatura de foto con botón de eliminar
class _FotoMiniatura extends StatelessWidget {
  final File foto;
  final VoidCallback onEliminar;

  const _FotoMiniatura({required this.foto, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(foto, width: 80, height: 80, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onEliminar,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppTheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
