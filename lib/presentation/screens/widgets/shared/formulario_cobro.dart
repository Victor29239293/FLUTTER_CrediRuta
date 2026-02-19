import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../domain/cobro_model.dart';
import '../../../../domain/recinto_model.dart';
import '../../../../infrastructure/local_storage_service.dart';

// ============================================================
// THEME
// ============================================================
class _AppTheme {
  static const Color primary = Color(0xFF1A1A2E);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F3F4);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textMuted = Color(0xFFADB5BD);
  static const Color error = Color(0xFFDC3545);
  static const Color success = Color(0xFF28A745);
  static const Color efectivo = Color(0xFF28A745);
  static const Color transferencia = Color(0xFF007BFF);
}

// ============================================================
// FORMULARIO COBRO SCREEN
// ============================================================
class FormularioCobroScreen extends StatefulWidget {
  const FormularioCobroScreen({super.key});

  @override
  State<FormularioCobroScreen> createState() => _FormularioCobroScreenState();
}

class _FormularioCobroScreenState extends State<FormularioCobroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clienteController = TextEditingController();
  final _recintoController = TextEditingController();
  final _abonoController = TextEditingController();
  String _metodoPago = 'Efectivo';
  bool _guardando = false;

  Recinto? _recintoSeleccionado;
  List<Recinto> _recintos = [];

  final List<File> _imagenesEvidencia = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cargarRecintos();
  }

  void _cargarRecintos() {
    setState(() {
      _recintos = LocalStorageService.obtenerRecintosActivos();
    });
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _recintoController.dispose();
    _abonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: _AppTheme.primary,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: const Text(
                'Nuevo Cobro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  color: _AppTheme.primary,
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
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección Cliente
                    _SectionHeader(
                      icon: Icons.person_outline_rounded,
                      title: 'Cliente',
                    ),
                    const SizedBox(height: 16),
                    _InputField(
                      controller: _clienteController,
                      label: 'Nombre del cliente',
                      hint: 'Ej: Juan Pérez',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    _RecintoSelector(
                      recintos: _recintos,
                      recintoSeleccionado: _recintoSeleccionado,
                      recintoController: _recintoController,
                      onRecintoChanged: (recinto) {
                        setState(() {
                          _recintoSeleccionado = recinto;
                          if (recinto != null) {
                            _recintoController.text = recinto.nombre;
                          }
                        });
                      },
                      onTextoChanged: (texto) {
                        if (_recintoSeleccionado != null &&
                            _recintoSeleccionado!.nombre != texto) {
                          setState(() => _recintoSeleccionado = null);
                        }
                      },
                      validator: (v) => v?.isEmpty ?? true ? 'Requerido' : null,
                    ),

                    const SizedBox(height: 32),

                    // Sección Pago
                    _SectionHeader(
                      icon: Icons.payments_outlined,
                      title: 'Pago',
                    ),
                    const SizedBox(height: 16),
                    _InputField(
                      controller: _abonoController,
                      label: 'Monto',
                      hint: '0.00',
                      icon: Icons.attach_money_rounded,
                      keyboardType: TextInputType.number,
                      prefix: '\$ ',
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Requerido';
                        if (double.tryParse(v!) == null)
                          return 'Número inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _MetodoPagoSelector(
                      metodoPago: _metodoPago,
                      onChanged: (m) => setState(() => _metodoPago = m),
                    ),

                    const SizedBox(height: 32),

                    // Sección Evidencia
                    _SectionHeader(
                      icon: Icons.photo_camera_outlined,
                      title: 'Evidencia',
                      subtitle: 'Opcional',
                    ),
                    const SizedBox(height: 16),
                    _EvidenciaSection(
                      imagenes: _imagenesEvidencia,
                      onTomarFoto: _tomarFoto,
                      onSeleccionarGaleria: _seleccionarDeGaleria,
                      onEliminarFoto: _eliminarFoto,
                      onEliminarTodas: _eliminarTodasLasFotos,
                    ),

                    const SizedBox(height: 40),

                    // Botón Guardar
                    _GuardarButton(
                      guardando: _guardando,
                      onPressed: _guardarCobro,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarCobro() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _guardando = true);

      try {
        List<String> rutasImagenes = [];
        if (_imagenesEvidencia.isNotEmpty) {
          rutasImagenes = await LocalStorageService.guardarImagenes(
            _imagenesEvidencia,
          );
        }

        final cobro = Cobro(
          id: LocalStorageService.generateId(),
          cliente: _clienteController.text.trim(),
          recinto: _recintoController.text.trim(),
          abono: double.parse(_abonoController.text),
          metodoPago: _metodoPago,
          imagenesPath: rutasImagenes,
          fecha: DateTime.now(),
        );

        await LocalStorageService.guardarCobro(cobro);

        if (mounted) {
          HapticFeedback.mediumImpact();
          _mostrarExito(context);
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) _mostrarError(context, e.toString());
      } finally {
        if (mounted) setState(() => _guardando = false);
      }
    }
  }

  void _mostrarExito(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Cobro guardado'),
          ],
        ),
        backgroundColor: _AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _mostrarError(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: _AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _tomarFoto() async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (imagen != null) {
      setState(() => _imagenesEvidencia.add(File(imagen.path)));
    }
  }

  Future<void> _seleccionarDeGaleria() async {
    final List<XFile> imagenes = await _picker.pickMultiImage(imageQuality: 80);
    if (imagenes.isNotEmpty) {
      setState(
        () => _imagenesEvidencia.addAll(imagenes.map((img) => File(img.path))),
      );
    }
  }

  void _eliminarFoto(int index) {
    setState(() => _imagenesEvidencia.removeAt(index));
  }

  void _eliminarTodasLasFotos() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: _AppTheme.error),
            SizedBox(width: 12),
            Text('Eliminar fotos'),
          ],
        ),
        content: const Text('¿Eliminar todas las fotos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: _AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _imagenesEvidencia.clear());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION HEADER
// ============================================================
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _AppTheme.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _AppTheme.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// INPUT FIELD
// ============================================================
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final String? prefix;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            color: _AppTheme.textSecondary,
            fontWeight: FontWeight.w400,
          ),
          hintStyle: TextStyle(
            color: _AppTheme.textMuted,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: _AppTheme.primary, size: 22),
          ),
          prefixText: prefix,
          prefixStyle: const TextStyle(
            color: _AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _AppTheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _AppTheme.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _AppTheme.error, width: 2),
          ),
          filled: true,
          fillColor: _AppTheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// METODO PAGO SELECTOR
// ============================================================
class _MetodoPagoSelector extends StatelessWidget {
  final String metodoPago;
  final ValueChanged<String> onChanged;

  const _MetodoPagoSelector({
    required this.metodoPago,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetodoPagoCard(
            icon: Icons.payments_outlined,
            label: 'Efectivo',
            isSelected: metodoPago == 'Efectivo',
            color: _AppTheme.efectivo,
            onTap: () => onChanged('Efectivo'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetodoPagoCard(
            icon: Icons.account_balance_outlined,
            label: 'Transferencia',
            isSelected: metodoPago == 'Transferencia',
            color: _AppTheme.transferencia,
            onTap: () => onChanged('Transferencia'),
          ),
        ),
      ],
    );
  }
}

class _MetodoPagoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _MetodoPagoCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : _AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 12 : 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : _AppTheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? color : _AppTheme.textSecondary,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected ? color : _AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EVIDENCIA SECTION
// ============================================================
class _EvidenciaSection extends StatelessWidget {
  final List<File> imagenes;
  final VoidCallback onTomarFoto;
  final VoidCallback onSeleccionarGaleria;
  final ValueChanged<int> onEliminarFoto;
  final VoidCallback onEliminarTodas;

  const _EvidenciaSection({
    required this.imagenes,
    required this.onTomarFoto,
    required this.onSeleccionarGaleria,
    required this.onEliminarFoto,
    required this.onEliminarTodas,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botones de acción
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.camera_alt_outlined,
                label: 'Cámara',
                onTap: onTomarFoto,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.photo_library_outlined,
                label: 'Galería',
                onTap: onSeleccionarGaleria,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Contenedor de imágenes
        if (imagenes.isNotEmpty)
          _ImagenesContainer(
            imagenes: imagenes,
            onEliminarFoto: onEliminarFoto,
            onEliminarTodas: onEliminarTodas,
          )
        else
          _EmptyEvidencia(),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _AppTheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: _AppTheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagenesContainer extends StatelessWidget {
  final List<File> imagenes;
  final ValueChanged<int> onEliminarFoto;
  final VoidCallback onEliminarTodas;

  const _ImagenesContainer({
    required this.imagenes,
    required this.onEliminarFoto,
    required this.onEliminarTodas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: _AppTheme.success,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${imagenes.length} foto${imagenes.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _AppTheme.success,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onEliminarTodas,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Eliminar',
                    style: TextStyle(
                      color: _AppTheme.error,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: imagenes.length,
              itemBuilder: (context, index) => _ImagenPreview(
                file: imagenes[index],
                onDelete: () => onEliminarFoto(index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagenPreview extends StatelessWidget {
  final File file;
  final VoidCallback onDelete;

  const _ImagenPreview({required this.file, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(file, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: _AppTheme.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEvidencia extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppTheme.surfaceVariant, width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _AppTheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_a_photo_outlined,
              size: 32,
              color: _AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sin evidencia',
            style: TextStyle(
              color: _AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GUARDAR BUTTON
// ============================================================
class _GuardarButton extends StatelessWidget {
  final bool guardando;
  final VoidCallback onPressed;

  const _GuardarButton({required this.guardando, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: guardando ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: guardando
              ? _AppTheme.primary.withOpacity(0.6)
              : _AppTheme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _AppTheme.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: guardando
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 12),
                    Text(
                      'Guardar Cobro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ============================================================
// RECINTO SELECTOR
// ============================================================
class _RecintoSelector extends StatefulWidget {
  final List<Recinto> recintos;
  final Recinto? recintoSeleccionado;
  final TextEditingController recintoController;
  final Function(Recinto?) onRecintoChanged;
  final Function(String) onTextoChanged;
  final String? Function(String?)? validator;

  const _RecintoSelector({
    required this.recintos,
    required this.recintoSeleccionado,
    required this.recintoController,
    required this.onRecintoChanged,
    required this.onTextoChanged,
    this.validator,
  });

  @override
  State<_RecintoSelector> createState() => _RecintoSelectorState();
}

class _RecintoSelectorState extends State<_RecintoSelector> {
  bool _mostrarLista = false;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _focusNode.removeListener(_onFocusChange);
    _overlayEntry?.remove();
    _overlayEntry = null;
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_isDisposed || !mounted) return;
    if (_focusNode.hasFocus && widget.recintos.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    if (_isDisposed || !mounted) return;
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _mostrarLista = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!_isDisposed && mounted) {
      setState(() => _mostrarLista = false);
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 8),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            shadowColor: Colors.black26,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: _AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _AppTheme.surfaceVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: widget.recintos.length,
                  itemBuilder: (context, index) {
                    final recinto = widget.recintos[index];
                    final isSelected =
                        widget.recintoSeleccionado?.id == recinto.id;

                    return InkWell(
                      onTap: () {
                        if (_isDisposed || !mounted) return;
                        widget.onRecintoChanged(recinto);
                        _focusNode.unfocus();
                        _removeOverlay();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _AppTheme.primary.withOpacity(0.08)
                              : null,
                          border: Border(
                            bottom: BorderSide(
                              color: _AppTheme.surfaceVariant,
                              width: index < widget.recintos.length - 1 ? 1 : 0,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _AppTheme.primary.withOpacity(0.1)
                                    : _AppTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.store_outlined,
                                size: 18,
                                color: isSelected
                                    ? _AppTheme.primary
                                    : _AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recinto.nombre,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? _AppTheme.primary
                                          : _AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (recinto.direccion != null &&
                                      recinto.direccion!.isNotEmpty)
                                    Text(
                                      recinto.direccion!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _AppTheme.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: _AppTheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: Container(
            decoration: BoxDecoration(
              color: _AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: widget.recintoController,
              focusNode: _focusNode,
              validator: widget.validator,
              onChanged: widget.onTextoChanged,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Recinto',
                hintText: widget.recintos.isEmpty
                    ? 'Ej: Local 15'
                    : 'Selecciona o escribe',
                labelStyle: const TextStyle(
                  color: _AppTheme.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
                hintStyle: TextStyle(
                  color: _AppTheme.textMuted,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(
                    Icons.store_outlined,
                    color: _AppTheme.primary,
                    size: 22,
                  ),
                ),
                suffixIcon: widget.recintos.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          _mostrarLista
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: _AppTheme.primary,
                        ),
                        onPressed: () {
                          if (_mostrarLista) {
                            _focusNode.unfocus();
                          } else {
                            _focusNode.requestFocus();
                          }
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _AppTheme.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _AppTheme.error,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _AppTheme.error,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: _AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
          ),
        ),

        // Indicador de recinto seleccionado
        if (widget.recintoSeleccionado != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: _AppTheme.success,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.recintoSeleccionado!.nombre,
                  style: const TextStyle(
                    color: _AppTheme.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    widget.onRecintoChanged(null);
                    widget.recintoController.clear();
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    color: _AppTheme.success,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Mensaje si no hay recintos
        if (widget.recintos.isEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _AppTheme.transferencia.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: _AppTheme.transferencia,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Crea recintos en la sección Recintos',
                    style: TextStyle(
                      color: _AppTheme.transferencia,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
