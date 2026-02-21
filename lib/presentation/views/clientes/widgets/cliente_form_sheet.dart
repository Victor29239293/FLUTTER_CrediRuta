import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../../domain/cliente_model.dart';
import '../../../../infrastructure/local_storage_service.dart';

/// BottomSheet para crear o editar un cliente
class ClienteFormSheet extends StatefulWidget {
  final String recintoId;
  final Cliente? clienteEditar;

  const ClienteFormSheet({
    super.key,
    required this.recintoId,
    this.clienteEditar,
  });

  @override
  State<ClienteFormSheet> createState() => _ClienteFormSheetState();
}

class _ClienteFormSheetState extends State<ClienteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _direccionController = TextEditingController();
  bool _guardando = false;
  bool _obteniendoUbicacion = false;
  double? _latitud;
  double? _longitud;
  final MapController _mapController = MapController();

  bool get _esEdicion => widget.clienteEditar != null;
  bool get _tieneUbicacion => _latitud != null && _longitud != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreController.text = widget.clienteEditar!.nombre;
      _referenciaController.text = widget.clienteEditar!.referencia ?? '';
      _direccionController.text = widget.clienteEditar!.direccion ?? '';
      _latitud = widget.clienteEditar!.latitud;
      _longitud = widget.clienteEditar!.longitud;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _referenciaController.dispose();
    _direccionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHandle(),
              _buildHeader(),
              _buildForm(),
              _buildActions(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.textMuted.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_add_outlined,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _esEdicion ? 'Editar Cliente' : 'Nuevo Cliente',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // Campo nombre
            TextFormField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Nombre del cliente *',
                hintText: 'Ej: Juan Pérez',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Campo referencia (opcional)
            TextFormField(
              controller: _referenciaController,
              decoration: InputDecoration(
                labelText: 'Referencia (opcional)',
                hintText: 'Teléfono, cédula, etc.',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Campo dirección
            TextFormField(
              controller: _direccionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Dirección (opcional)',
                hintText: 'Ej: Calle 10 #20-30, Local 5',
                prefixIcon: const Icon(Icons.home_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.surfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Sección de ubicación GPS
            _buildUbicacionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUbicacionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _tieneUbicacion
              ? AppTheme.success.withValues(alpha: 0.5)
              : AppTheme.textMuted.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: _tieneUbicacion ? AppTheme.success : AppTheme.textMuted,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ubicación GPS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _tieneUbicacion
                      ? AppTheme.success
                      : AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              if (_tieneUbicacion)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '✓ Configurada',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Mini mapa si hay ubicación
          if (_tieneUbicacion) ...[
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.textMuted.withValues(alpha: 0.2),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(_latitud!, _longitud!),
                  initialZoom: 16,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.cobrador_app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_latitud!, _longitud!),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lat: ${_latitud!.toStringAsFixed(6)}, Lng: ${_longitud!.toStringAsFixed(6)}',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _obteniendoUbicacion
                      ? null
                      : _obtenerUbicacionActual,
                  icon: _obteniendoUbicacion
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(
                    _obteniendoUbicacion ? 'Obteniendo...' : 'Mi ubicación',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _seleccionarEnMapa,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text(
                    'Seleccionar',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (_tieneUbicacion) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _eliminarUbicacion,
                  icon: const Icon(Icons.delete_outline),
                  color: AppTheme.error,
                  tooltip: 'Eliminar ubicación',
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.error.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _obtenerUbicacionActual() async {
    setState(() => _obteniendoUbicacion = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _mostrarError('Los servicios de ubicación están deshabilitados');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _mostrarError('Permisos de ubicación denegados');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _mostrarError(
          'Permisos de ubicación permanentemente denegados. Por favor habilítalos en configuración.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _latitud = position.latitude;
        _longitud = position.longitude;
      });

      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación obtenida correctamente'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _mostrarError('Error al obtener ubicación: $e');
    } finally {
      if (mounted) setState(() => _obteniendoUbicacion = false);
    }
  }

  void _eliminarUbicacion() {
    setState(() {
      _latitud = null;
      _longitud = null;
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _seleccionarEnMapa() async {
    // Obtener ubicación inicial para el mapa
    LatLng? ubicacionInicial;

    if (_tieneUbicacion) {
      ubicacionInicial = LatLng(_latitud!, _longitud!);
    } else {
      // Intentar obtener ubicación actual como punto de partida
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            final position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
              ),
            ).timeout(const Duration(seconds: 5));
            ubicacionInicial = LatLng(position.latitude, position.longitude);
          }
        }
      } catch (_) {
        // Usar ubicación por defecto (Bogotá)
      }
    }

    // Ubicación por defecto si no se pudo obtener
    ubicacionInicial ??= const LatLng(4.6097, -74.0817);

    if (!mounted) return;

    final resultado = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _MapaSeleccionView(ubicacionInicial: ubicacionInicial!),
      ),
    );

    if (resultado != null && mounted) {
      setState(() {
        _latitud = resultado.latitude;
        _longitud = resultado.longitude;
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación seleccionada correctamente'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: AppTheme.textMuted.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _guardando ? null : _guardarCliente,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _esEdicion ? 'Guardar cambios' : 'Crear cliente',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    HapticFeedback.mediumImpact();

    try {
      if (_esEdicion) {
        // Actualizar cliente existente
        final clienteActualizado = widget.clienteEditar!.copyWith(
          nombre: _nombreController.text.trim(),
          referencia: _referenciaController.text.trim().isNotEmpty
              ? _referenciaController.text.trim()
              : null,
          direccion: _direccionController.text.trim().isNotEmpty
              ? _direccionController.text.trim()
              : null,
          latitud: _latitud,
          longitud: _longitud,
        );
        await LocalStorageService.actualizarCliente(clienteActualizado);
      } else {
        // Crear nuevo cliente
        final nuevoCliente = Cliente(
          id: LocalStorageService.generateId(),
          nombre: _nombreController.text.trim(),
          referencia: _referenciaController.text.trim().isNotEmpty
              ? _referenciaController.text.trim()
              : null,
          direccion: _direccionController.text.trim().isNotEmpty
              ? _direccionController.text.trim()
              : null,
          recintoId: widget.recintoId,
          fechaCreacion: DateTime.now(),
          activo: true,
          latitud: _latitud,
          longitud: _longitud,
        );
        await LocalStorageService.guardarCliente(nuevoCliente);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _esEdicion ? 'Cliente actualizado' : 'Cliente creado',
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
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

/// Vista de mapa para seleccionar ubicación manualmente
class _MapaSeleccionView extends StatefulWidget {
  final LatLng ubicacionInicial;

  const _MapaSeleccionView({required this.ubicacionInicial});

  @override
  State<_MapaSeleccionView> createState() => _MapaSeleccionViewState();
}

class _MapaSeleccionViewState extends State<_MapaSeleccionView> {
  late LatLng _ubicacionSeleccionada;
  final MapController _mapController = MapController();
  bool _obteniendoUbicacion = false;

  @override
  void initState() {
    super.initState();
    _ubicacionSeleccionada = widget.ubicacionInicial;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Seleccionar ubicación',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, _ubicacionSeleccionada),
            icon: const Icon(Icons.check, color: AppTheme.success),
            label: const Text(
              'Confirmar',
              style: TextStyle(
                color: AppTheme.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa interactivo
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _ubicacionSeleccionada,
              initialZoom: 16,
              onTap: (tapPosition, point) {
                setState(() {
                  _ubicacionSeleccionada = point;
                });
                HapticFeedback.selectionClick();
              },
              onLongPress: (tapPosition, point) {
                setState(() {
                  _ubicacionSeleccionada = point;
                });
                HapticFeedback.mediumImpact();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.cobrador_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _ubicacionSeleccionada,
                    width: 50,
                    height: 50,
                    child: const _AnimatedMarker(),
                  ),
                ],
              ),
            ],
          ),

          // Instrucciones
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Toca el mapa para seleccionar la ubicación del cliente',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Coordenadas seleccionadas
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: AppTheme.success,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Ubicación seleccionada',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lat: ${_ubicacionSeleccionada.latitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          'Lng: ${_ubicacionSeleccionada.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botón de mi ubicación
          Positioned(
            bottom: 180,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'my_location',
              mini: true,
              backgroundColor: AppTheme.surface,
              onPressed: _obteniendoUbicacion ? null : _irAMiUbicacion,
              child: _obteniendoUbicacion
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : const Icon(Icons.my_location, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _irAMiUbicacion() async {
    setState(() => _obteniendoUbicacion = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _mostrarError('Los servicios de ubicación están deshabilitados');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _mostrarError('Permisos de ubicación denegados');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _mostrarError('Permisos denegados permanentemente');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final nuevaUbicacion = LatLng(position.latitude, position.longitude);

      setState(() {
        _ubicacionSeleccionada = nuevaUbicacion;
      });

      _mapController.move(nuevaUbicacion, 17);
      HapticFeedback.mediumImpact();
    } catch (e) {
      _mostrarError('Error al obtener ubicación');
    } finally {
      if (mounted) setState(() => _obteniendoUbicacion = false);
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// Marcador animado para indicar la ubicación seleccionada
class _AnimatedMarker extends StatefulWidget {
  const _AnimatedMarker();

  @override
  State<_AnimatedMarker> createState() => _AnimatedMarkerState();
}

class _AnimatedMarkerState extends State<_AnimatedMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.location_on, color: Colors.white, size: 24),
          ),
          Container(
            width: 4,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
