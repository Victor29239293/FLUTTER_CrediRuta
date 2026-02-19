import 'package:flutter/material.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../../domain/recinto_model.dart';
import '../../../../infrastructure/local_storage_service.dart';
import '../../../shared/widgets/sheet_handle.dart';
import '../../../shared/widgets/custom_form_field.dart';

/// Bottom sheet con formulario para crear/editar un recinto
class RecintoFormSheet extends StatefulWidget {
  final Recinto? recinto;

  const RecintoFormSheet({super.key, this.recinto});

  @override
  State<RecintoFormSheet> createState() => _RecintoFormSheetState();
}

class _RecintoFormSheetState extends State<RecintoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _direccionController;
  late final TextEditingController _descripcionController;

  bool get _isEditing => widget.recinto != null;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _nombreController = TextEditingController(
      text: widget.recinto?.nombre ?? '',
    );
    _direccionController = TextEditingController(
      text: widget.recinto?.direccion ?? '',
    );
    _descripcionController = TextEditingController(
      text: widget.recinto?.descripcion ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

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
          const SheetHandle(),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: _buildForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormHeader(isEditing: _isEditing),
          const SizedBox(height: 28),
          _buildFormFields(),
          const SizedBox(height: 32),
          _SubmitButton(isEditing: _isEditing, onPressed: _guardar),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        CustomFormField(
          controller: _nombreController,
          label: 'Nombre del recinto',
          hint: 'Ej: Plaza Central',
          icon: Icons.business_outlined,
          validator: _validarNombre,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        CustomFormField(
          controller: _direccionController,
          label: 'Dirección (opcional)',
          hint: 'Ej: Calle 5 #123',
          icon: Icons.place_outlined,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        CustomFormField(
          controller: _descripcionController,
          label: 'Descripción (opcional)',
          hint: 'Notas adicionales',
          icon: Icons.notes_outlined,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  String? _validarNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }

    final nombreCambiado =
        !_isEditing || widget.recinto!.nombre != value.trim();
    if (nombreCambiado && LocalStorageService.existeRecinto(value.trim())) {
      return 'Ya existe un recinto con este nombre';
    }

    return null;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreController.text.trim();
    final direccion = _direccionController.text.trim();
    final descripcion = _descripcionController.text.trim();

    if (_isEditing) {
      await _actualizarRecinto(nombre, direccion, descripcion);
    } else {
      await _crearRecinto(nombre, direccion, descripcion);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _actualizarRecinto(
    String nombre,
    String direccion,
    String descripcion,
  ) async {
    final actualizado = widget.recinto!.copyWith(
      nombre: nombre,
      direccion: direccion.isEmpty ? null : direccion,
      descripcion: descripcion.isEmpty ? null : descripcion,
    );
    await LocalStorageService.actualizarRecinto(actualizado);
  }

  Future<void> _crearRecinto(
    String nombre,
    String direccion,
    String descripcion,
  ) async {
    final nuevo = Recinto(
      id: LocalStorageService.generateId(),
      nombre: nombre,
      direccion: direccion.isEmpty ? null : direccion,
      descripcion: descripcion.isEmpty ? null : descripcion,
      fechaCreacion: DateTime.now(),
      orden: LocalStorageService.obtenerSiguienteOrden(),
    );
    await LocalStorageService.guardarRecinto(nuevo);
  }
}

/// Header del formulario
class _FormHeader extends StatelessWidget {
  final bool isEditing;

  const _FormHeader({required this.isEditing});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditing ? 'Editar recinto' : 'Nuevo recinto',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isEditing
              ? 'Modifica los datos del recinto'
              : 'Agrega un nuevo lugar de cobro',
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

/// Botón de enviar formulario
class _SubmitButton extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onPressed;

  const _SubmitButton({required this.isEditing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isEditing ? Icons.check : Icons.add, size: 20),
            const SizedBox(width: 8),
            Text(
              isEditing ? 'Guardar cambios' : 'Crear recinto',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
