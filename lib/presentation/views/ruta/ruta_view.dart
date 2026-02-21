import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:cobrador_app/config/theme/app_theme.dart';
import 'package:cobrador_app/domain/cliente_model.dart';
import 'package:cobrador_app/domain/cobro_model.dart';
import 'package:cobrador_app/infrastructure/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class RutaView extends StatefulWidget {
  const RutaView({super.key});

  @override
  State<RutaView> createState() => _RutaViewState();
}

class _RutaViewState extends State<RutaView>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String? _recintoSeleccionado;
  bool _mostrarSoloPendientes = true;
  Position? _ubicacionActual;
  bool _cargandoUbicacion = false;
  final MapController _mapController = MapController();
  Cliente? _clienteSeleccionado;
  List<LatLng> _rutaOptimizada = []; // Puntos de parada (clientes)
  List<LatLng> _rutaReal = []; // Ruta real siguiendo calles
  bool _cargandoRuta = false;
  String? _duracionTotal;
  String? _distanciaTotal;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(() {
      if (!_tabController!.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController!.index;
        });
      }
    });
    _obtenerUbicacionActual();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacionActual() async {
    setState(() => _cargandoUbicacion = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _mostrarSnackBar('Los servicios de ubicación están deshabilitados');
        setState(() => _cargandoUbicacion = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _mostrarSnackBar('Permisos de ubicación denegados');
          setState(() => _cargandoUbicacion = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _mostrarSnackBar('Permisos de ubicación permanentemente denegados');
        setState(() => _cargandoUbicacion = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _ubicacionActual = position;
        _cargandoUbicacion = false;
      });

      _calcularRutaOptimizada();
    } catch (e) {
      setState(() => _cargandoUbicacion = false);
      _mostrarSnackBar('Error al obtener ubicación: $e');
    }
  }

  void _mostrarSnackBar(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  Future<void> _calcularRutaOptimizada() async {
    final datos = _obtenerDatosClientes();
    final pendientes = datos.where((d) => d['visitado'] == false).toList();
    final clientesConUbicacion = pendientes
        .where((d) => (d['cliente'] as Cliente).tieneUbicacion)
        .toList();

    if (clientesConUbicacion.isEmpty || _ubicacionActual == null) {
      setState(() {
        _rutaOptimizada = [];
        _rutaReal = [];
        _duracionTotal = null;
        _distanciaTotal = null;
      });
      return;
    }

    setState(() => _cargandoRuta = true);

    // Preparar puntos: ubicación actual + todos los clientes
    List<LatLng> puntos = [
      LatLng(_ubicacionActual!.latitude, _ubicacionActual!.longitude),
    ];

    for (final dato in clientesConUbicacion) {
      final cliente = dato['cliente'] as Cliente;
      puntos.add(LatLng(cliente.latitud!, cliente.longitud!));
    }

    // Usar OSRM Trip API para optimizar el orden de visitas (TSP)
    await _obtenerRutaOptimizadaOSRM(puntos);
  }

  /// Usa OSRM Trip API para resolver el problema del viajante (TSP)
  /// y obtener la ruta más óptima con los mejores atajos
  Future<void> _obtenerRutaOptimizadaOSRM(List<LatLng> puntos) async {
    if (puntos.length < 2) {
      setState(() {
        _rutaOptimizada = [];
        _rutaReal = [];
        _cargandoRuta = false;
      });
      return;
    }

    try {
      // Construir coordenadas para OSRM (formato: lng,lat;lng,lat;...)
      final coordenadas = puntos
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      // Usar el endpoint /trip para optimización TSP
      // source=first: empezar desde el primer punto (ubicación actual)
      // roundtrip=false: no volver al inicio
      // geometries=geojson: formato de respuesta
      final url = Uri.parse(
        'https://router.project-osrm.org/trip/v1/driving/$coordenadas'
        '?source=first&roundtrip=false&geometries=geojson&overview=full&steps=true',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw Exception('Tiempo de espera agotado');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' &&
            data['trips'] != null &&
            data['trips'].isNotEmpty) {
          final trip = data['trips'][0];
          final geometry = trip['geometry'];
          final coordinates = geometry['coordinates'] as List;

          // Convertir coordenadas GeoJSON [lng, lat] a LatLng
          final rutaReal = coordinates.map<LatLng>((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();

          // Extraer waypoints en orden optimizado
          final waypoints = data['waypoints'] as List;
          final puntosOrdenados = <LatLng>[];

          // Ordenar según el índice optimizado por OSRM
          final waypointsOrdenados = List<Map<String, dynamic>>.from(
            waypoints.map((w) => w as Map<String, dynamic>),
          );
          waypointsOrdenados.sort(
            (a, b) => (a['waypoint_index'] as int).compareTo(
              b['waypoint_index'] as int,
            ),
          );

          for (final wp in waypointsOrdenados) {
            final location = wp['location'] as List;
            puntosOrdenados.add(
              LatLng(
                (location[1] as num).toDouble(),
                (location[0] as num).toDouble(),
              ),
            );
          }

          // Extraer duración y distancia
          final duracionSegundos = trip['duration'] as num;
          final distanciaMetros = trip['distance'] as num;

          setState(() {
            _rutaOptimizada = puntosOrdenados;
            _rutaReal = rutaReal;
            _duracionTotal = _formatearDuracion(duracionSegundos.toInt());
            _distanciaTotal = _formatearDistancia(distanciaMetros.toDouble());
          });

          if (mounted && puntos.length > 3) {
            _mostrarSnackBar(
              '✓ Ruta optimizada con ${puntos.length - 1} paradas',
            );
          }
        } else {
          // Fallback: usar algoritmo local del vecino más cercano
          await _calcularRutaFallback(puntos);
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error OSRM Trip: $e');
      // Fallback al algoritmo local
      await _calcularRutaFallback(puntos);
    } finally {
      if (mounted) {
        setState(() => _cargandoRuta = false);
      }
    }
  }

  /// Algoritmo fallback del vecino más cercano cuando OSRM no está disponible
  Future<void> _calcularRutaFallback(List<LatLng> puntos) async {
    if (puntos.isEmpty) return;

    List<LatLng> ruta = [];
    LatLng puntoActual = puntos.first;
    ruta.add(puntoActual);

    List<LatLng> porVisitar = List.from(puntos.skip(1));

    while (porVisitar.isNotEmpty) {
      double distanciaMinima = double.infinity;
      int indiceMasCercano = 0;

      for (int i = 0; i < porVisitar.length; i++) {
        final distancia = _calcularDistancia(puntoActual, porVisitar[i]);
        if (distancia < distanciaMinima) {
          distanciaMinima = distancia;
          indiceMasCercano = i;
        }
      }

      puntoActual = porVisitar[indiceMasCercano];
      ruta.add(puntoActual);
      porVisitar.removeAt(indiceMasCercano);
    }

    setState(() => _rutaOptimizada = ruta);

    // Intentar obtener la ruta real para los puntos ordenados localmente
    await _obtenerRutaRealSimple(ruta);
  }

  /// Obtiene solo la geometría de la ruta sin reordenar
  Future<void> _obtenerRutaRealSimple(List<LatLng> puntos) async {
    if (puntos.length < 2) {
      setState(() => _rutaReal = puntos);
      return;
    }

    try {
      final coordenadas = puntos
          .map((p) => '${p.longitude},${p.latitude}')
          .join(';');

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordenadas'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          final rutaReal = coordinates.map<LatLng>((coord) {
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();

          final duracionSegundos = route['duration'] as num;
          final distanciaMetros = route['distance'] as num;

          setState(() {
            _rutaReal = rutaReal;
            _duracionTotal = _formatearDuracion(duracionSegundos.toInt());
            _distanciaTotal = _formatearDistancia(distanciaMetros.toDouble());
          });
        } else {
          setState(() => _rutaReal = puntos);
        }
      }
    } catch (e) {
      setState(() => _rutaReal = puntos);
      debugPrint('Error al obtener ruta simple: $e');
    }
  }

  String _formatearDuracion(int segundos) {
    if (segundos < 60) {
      return '$segundos seg';
    } else if (segundos < 3600) {
      final minutos = segundos ~/ 60;
      return '$minutos min';
    } else {
      final horas = segundos ~/ 3600;
      final minutos = (segundos % 3600) ~/ 60;
      return '${horas}h ${minutos}m';
    }
  }

  String _formatearDistancia(double metros) {
    if (metros < 1000) {
      return '${metros.toStringAsFixed(0)} m';
    } else {
      final km = metros / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  double _calcularDistancia(LatLng p1, LatLng p2) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, p1, p2);
  }

  /// Obtiene el número de orden de visita para un cliente basado en la ruta optimizada
  /// Retorna 0 si no está en la ruta, o el número de orden (1, 2, 3...)
  int _obtenerOrdenVisita(Cliente cliente) {
    if (!cliente.tieneUbicacion || _rutaOptimizada.isEmpty) return 0;

    final puntoCliente = LatLng(cliente.latitud!, cliente.longitud!);

    // El primer punto es la ubicación actual, así que empezamos desde 1
    for (int i = 1; i < _rutaOptimizada.length; i++) {
      final punto = _rutaOptimizada[i];
      // Comparar con tolerancia pequeña para coordenadas
      if ((punto.latitude - puntoCliente.latitude).abs() < 0.0001 &&
          (punto.longitude - puntoCliente.longitude).abs() < 0.0001) {
        return i; // Retorna posición (1 = primero a visitar)
      }
    }
    return 0;
  }

  /// Ordena la lista de datos de clientes según el orden de la ruta optimizada
  List<Map<String, dynamic>> _ordenarClientesPorRuta(
    List<Map<String, dynamic>> datos,
  ) {
    if (_rutaOptimizada.isEmpty) return datos;

    final datosOrdenados = List<Map<String, dynamic>>.from(datos);
    datosOrdenados.sort((a, b) {
      final clienteA = a['cliente'] as Cliente;
      final clienteB = b['cliente'] as Cliente;
      final ordenA = _obtenerOrdenVisita(clienteA);
      final ordenB = _obtenerOrdenVisita(clienteB);

      // Los que tienen orden van primero, ordenados por número
      if (ordenA == 0 && ordenB == 0) return 0;
      if (ordenA == 0) return 1; // A no tiene orden, va después
      if (ordenB == 0) return -1; // B no tiene orden, va después
      return ordenA.compareTo(ordenB);
    });

    return datosOrdenados;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildCompactAppBar(),
      body: Column(
        children: [
          _buildCompactHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildMapaView(), _buildListaClientes()],
            ),
          ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 0 && _rutaOptimizada.length > 1
          ? _buildNavigationFAB()
          : null,
    );
  }

  PreferredSizeWidget _buildCompactAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppTheme.primary,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.route_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Ruta de Cobranza',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            _mostrarSoloPendientes ? Icons.filter_alt : Icons.filter_alt_off,
            color: Colors.white,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() => _mostrarSoloPendientes = !_mostrarSoloPendientes);
            _calcularRutaOptimizada();
          },
          tooltip: _mostrarSoloPendientes ? 'Pendientes' : 'Todos',
        ),
        IconButton(
          icon: _cargandoUbicacion
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.my_location, color: Colors.white),
          onPressed: _cargandoUbicacion ? null : _obtenerUbicacionActual,
          tooltip: 'Mi ubicación',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildCompactHeader() {
    return ValueListenableBuilder(
      valueListenable: LocalStorageService.cobrosBox.listenable(),
      builder: (context, Box<Cobro> box, _) {
        final datos = _obtenerDatosClientes();
        final totalClientes = datos.length;
        final visitados = datos.where((d) => d['visitado'] == true).length;
        final pendientes = totalClientes - visitados;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Stats compactos
              _buildMiniStat(Icons.groups_rounded, '$totalClientes', 'Total'),
              const SizedBox(width: 12),
              _buildMiniStat(Icons.check_circle_rounded, '$visitados', 'Visitados', 
                  color: AppTheme.success),
              const SizedBox(width: 12),
              _buildMiniStat(Icons.schedule_rounded, '$pendientes', 'Pendientes',
                  color: AppTheme.warning),
              const Spacer(),
              // Info de ruta compacta
              if (_rutaReal.isNotEmpty && !_cargandoRuta)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.darkGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.straighten_rounded, 
                          color: Colors.white.withValues(alpha: 0.8), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _distanciaTotal ?? '-',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 1,
                        height: 12,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Icon(Icons.timer_outlined,
                          color: Colors.white.withValues(alpha: 0.8), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _duracionTotal ?? '-',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_cargandoRuta)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Calculando...',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? AppTheme.accent),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color ?? AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppTheme.accent,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(3),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_rounded, size: 18),
                SizedBox(width: 6),
                Text('Mapa'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_rounded, size: 18),
                SizedBox(width: 6),
                Text('Lista'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        _abrirNavegacion();
      },
      backgroundColor: AppTheme.success,
      icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
      label: const Text(
        'Iniciar ruta',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  

  Widget _buildMapaView() {
    return ValueListenableBuilder(
      valueListenable: LocalStorageService.cobrosBox.listenable(),
      builder: (context, Box<Cobro> box, _) {
        return ValueListenableBuilder(
          valueListenable: LocalStorageService.clientesBox.listenable(),
          builder: (context, Box<Cliente> clientesBox, _) {
            var datos = _obtenerDatosClientes();

            if (_mostrarSoloPendientes) {
              datos = datos.where((d) => d['visitado'] == false).toList();
            }

            final clientesConUbicacion = datos
                .where((d) => (d['cliente'] as Cliente).tieneUbicacion)
                .toList();

            if (clientesConUbicacion.isEmpty && _ubicacionActual == null) {
              return _buildSinUbicaciones();
            }

            // Calcular centro del mapa
            LatLng centro;
            if (_ubicacionActual != null) {
              centro = LatLng(
                _ubicacionActual!.latitude,
                _ubicacionActual!.longitude,
              );
            } else if (clientesConUbicacion.isNotEmpty) {
              final primerCliente =
                  clientesConUbicacion.first['cliente'] as Cliente;
              centro = LatLng(primerCliente.latitud!, primerCliente.longitud!);
            } else {
              centro = const LatLng(
                19.4326,
                -99.1332,
              ); // Ciudad de México por defecto
            }

            return Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: centro,
                    initialZoom: 14,
                    onTap: (_, __) {
                      setState(() => _clienteSeleccionado = null);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.cobrador_app',
                    ),
                    // Línea de ruta real (siguiendo calles)
                    if (_rutaReal.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _rutaReal,
                            strokeWidth: 5,
                            color: AppTheme.accent,
                            borderStrokeWidth: 2,
                            borderColor: Colors.white,
                          ),
                        ],
                      ),
                    // Marcadores
                    MarkerLayer(
                      markers: [
                        // Marcador de ubicación actual
                        if (_ubicacionActual != null)
                          Marker(
                            point: LatLng(
                              _ubicacionActual!.latitude,
                              _ubicacionActual!.longitude,
                            ),
                            width: 60,
                            height: 60,
                            child: _buildCurrentLocationMarker(),
                          ),
                        // Marcadores de clientes
                        ...clientesConUbicacion.map((dato) {
                          final cliente = dato['cliente'] as Cliente;
                          final visitado = dato['visitado'] as bool;
                          final ordenVisita = _obtenerOrdenVisita(cliente);
                          final esPrimero = ordenVisita == 1 && !visitado;

                          return Marker(
                            point: LatLng(cliente.latitud!, cliente.longitud!),
                            width: esPrimero ? 60 : 50,
                            height: esPrimero ? 70 : 60,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _clienteSeleccionado = cliente);
                              },
                              child: _buildClienteMarker(
                                ordenVisita: ordenVisita,
                                visitado: visitado,
                                esPrimero: esPrimero,
                                isSelected: _clienteSeleccionado?.id == cliente.id,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
                // Panel de información del cliente seleccionado
                if (_clienteSeleccionado != null)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: _buildClienteInfoPanel(),
                  ),
                // Botones de control compactos
                Positioned(
                  right: 12,
                  top: 12,
                  child: Column(
                    children: [
                      _buildMiniMapButton(
                        Icons.center_focus_strong_rounded,
                        () {
                          if (_ubicacionActual != null) {
                            _mapController.move(
                              LatLng(
                                _ubicacionActual!.latitude,
                                _ubicacionActual!.longitude,
                              ),
                              15,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 6),
                      _buildMiniMapButton(
                        Icons.zoom_out_map_rounded,
                        _ajustarZoomParaTodos,
                      ),
                      const SizedBox(height: 6),
                      _buildMiniMapButton(Icons.refresh_rounded, () {
                        _obtenerUbicacionActual();
                      }),
                    ],
                  ),
                ),
                // Leyenda compacta
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMiniLeyenda(AppTheme.accent, 'Tú'),
                        _buildMiniLeyenda(AppTheme.error, 'Pend.'),
                        _buildMiniLeyenda(AppTheme.success, 'Visit.'),
                        _buildMiniLeyenda(AppTheme.warning, 'Sig.'),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCurrentLocationMarker() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const Center(
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildClienteMarker({
    required int ordenVisita,
    required bool visitado,
    required bool esPrimero,
    required bool isSelected,
  }) {
    final Color baseColor = visitado
        ? AppTheme.success
        : (esPrimero
            ? AppTheme.warning
            : (isSelected ? AppTheme.accent : AppTheme.error));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(12),
            border: esPrimero
                ? Border.all(color: Colors.white, width: 3)
                : Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
            boxShadow: [
              BoxShadow(
                color: baseColor.withValues(alpha: 0.5),
                blurRadius: esPrimero ? 12 : 6,
                spreadRadius: esPrimero ? 2 : 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            width: esPrimero ? 32 : 26,
            height: esPrimero ? 32 : 26,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: ordenVisita > 0
                  ? Text(
                      '$ordenVisita',
                      style: TextStyle(
                        color: baseColor,
                        fontWeight: FontWeight.bold,
                        fontSize: esPrimero ? 16 : 13,
                      ),
                    )
                  : Icon(
                      visitado ? Icons.check : Icons.store,
                      size: esPrimero ? 18 : 14,
                      color: baseColor,
                    ),
            ),
          ),
        ),
        CustomPaint(
          size: const Size(12, 8),
          painter: _TrianglePainter(color: baseColor),
        ),
      ],
    );
  }

  Widget _buildMiniLeyenda(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinUbicaciones() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.accent.withValues(alpha: 0.05),
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.shade100,
                      Colors.grey.shade50,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.location_off_rounded,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Sin ubicaciones GPS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Agrega coordenadas GPS a tus clientes\npara visualizarlos en el mapa y\noptimizar tu ruta de cobranza.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _obtenerUbicacionActual,
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.my_location, color: Colors.white, size: 22),
                          SizedBox(width: 12),
                          Text(
                            'Obtener mi ubicación',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMapButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          borderRadius: BorderRadius.circular(10),
          child: Icon(icon, color: AppTheme.accent, size: 20),
        ),
      ),
    );
  }


  Widget _buildClienteInfoPanel() {
    final datos = _obtenerDatosClientes();
    final dato = datos.firstWhere(
      (d) => (d['cliente'] as Cliente).id == _clienteSeleccionado!.id,
      orElse: () => {
        'cliente': _clienteSeleccionado!,
        'visitado': false,
        'ultimoCobro': null,
        'recintoNombre': '',
      },
    );
    final visitado = dato['visitado'] as bool;
    final ultimoCobro = dato['ultimoCobro'] as Cobro?;
    final ordenVisita = _obtenerOrdenVisita(_clienteSeleccionado!);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header compacto
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: visitado
                        ? AppTheme.successGradient
                        : AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: visitado
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                        : ordenVisita > 0
                            ? Text(
                                '$ordenVisita',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : Text(
                                _clienteSeleccionado!.nombre.isNotEmpty
                                    ? _clienteSeleccionado!.nombre[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _clienteSeleccionado!.nombre,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_clienteSeleccionado!.direccion != null)
                        Text(
                          _clienteSeleccionado!.direccion!,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _clienteSeleccionado = null),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
            // Botones de acción o estado
            if (visitado && ultimoCobro != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, 
                          color: AppTheme.success, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Visitado • Abono: \$${ultimoCobro.abono.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildCompactActionButton(
                        icon: Icons.directions_rounded,
                        label: 'Ir',
                        color: AppTheme.accent,
                        onTap: () => _navegarACliente(_clienteSeleccionado!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildCompactActionButton(
                        icon: Icons.phone_rounded,
                        label: 'Llamar',
                        color: AppTheme.success,
                        onTap: () => _llamarCliente(_clienteSeleccionado!),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _ajustarZoomParaTodos() {
    final datos = _obtenerDatosClientes();
    final clientesConUbicacion = datos
        .where((d) => (d['cliente'] as Cliente).tieneUbicacion)
        .toList();

    if (clientesConUbicacion.isEmpty) return;

    List<LatLng> puntos = [];

    if (_ubicacionActual != null) {
      puntos.add(
        LatLng(_ubicacionActual!.latitude, _ubicacionActual!.longitude),
      );
    }

    for (var dato in clientesConUbicacion) {
      final cliente = dato['cliente'] as Cliente;
      puntos.add(LatLng(cliente.latitud!, cliente.longitud!));
    }

    if (puntos.length == 1) {
      _mapController.move(puntos.first, 15);
      return;
    }

    // Calcular bounds
    double minLat = puntos.map((p) => p.latitude).reduce(min);
    double maxLat = puntos.map((p) => p.latitude).reduce(max);
    double minLng = puntos.map((p) => p.longitude).reduce(min);
    double maxLng = puntos.map((p) => p.longitude).reduce(max);

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));

    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  Future<void> _navegarACliente(Cliente cliente) async {
    if (!cliente.tieneUbicacion) {
      _mostrarSnackBar('El cliente no tiene ubicación GPS configurada');
      return;
    }

    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${cliente.latitud},${cliente.longitud}&travelmode=driving',
    );

    final geoUrl = Uri.parse(
      'geo:${cliente.latitud},${cliente.longitud}?q=${cliente.latitud},${cliente.longitud}(${Uri.encodeComponent(cliente.nombre)})',
    );

    try {
      final launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        final geoLaunched = await launchUrl(
          geoUrl,
          mode: LaunchMode.externalApplication,
        );
        
        if (!geoLaunched) {
          _mostrarSnackBar('Instala Google Maps para usar la navegación');
        }
      }
    } catch (e) {
      debugPrint('Error al navegar: $e');
      try {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } catch (_) {
        _mostrarSnackBar('No se pudo abrir la navegación');
      }
    }
  }

  Future<void> _llamarCliente(Cliente cliente) async {
    if (cliente.referencia == null || cliente.referencia!.isEmpty) {
      _mostrarSnackBar('El cliente no tiene número de teléfono registrado');
      return;
    }

    final url = Uri.parse('tel:${cliente.referencia}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _mostrarSnackBar('No se pudo realizar la llamada');
    }
  }

  Future<void> _abrirNavegacion() async {
    if (_rutaOptimizada.length < 2) {
      _mostrarSnackBar('No hay ruta disponible para navegar');
      return;
    }

    // Abrir navegación al primer punto de la ruta (después de la ubicación actual)
    final destino = _rutaOptimizada[1];
    
    // Construir waypoints si hay más de un destino
    String waypointsParam = '';
    if (_rutaOptimizada.length > 2) {
      // Tomar hasta 10 waypoints intermedios (límite de Google Maps)
      final waypoints = _rutaOptimizada
          .skip(1)
          .take(min(10, _rutaOptimizada.length - 1))
          .map((p) => '${p.latitude},${p.longitude}')
          .join('|');
      waypointsParam = '&waypoints=$waypoints';
    }

    // Intentar con Google Maps URL
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${destino.latitude},${destino.longitude}'
      '&travelmode=driving'
      '$waypointsParam',
    );

    // Intentar con geo: URI (funciona con cualquier app de mapas)
    final geoUrl = Uri.parse(
      'geo:${destino.latitude},${destino.longitude}?q=${destino.latitude},${destino.longitude}',
    );

    try {
      // Primero intentar con la URL de Google Maps
      final launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        // Si falla, intentar con geo:
        final geoLaunched = await launchUrl(
          geoUrl,
          mode: LaunchMode.externalApplication,
        );
        
        if (!geoLaunched) {
          _mostrarSnackBar('Instala Google Maps para usar la navegación');
        }
      }
    } catch (e) {
      debugPrint('Error al abrir navegación: $e');
      // Último intento con geo:
      try {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } catch (_) {
        _mostrarSnackBar('No se pudo abrir la navegación');
      }
    }
  }

  Widget _buildListaClientes() {
    return ValueListenableBuilder(
      valueListenable: LocalStorageService.cobrosBox.listenable(),
      builder: (context, Box<Cobro> box, _) {
        return ValueListenableBuilder(
          valueListenable: LocalStorageService.clientesBox.listenable(),
          builder: (context, Box<Cliente> clientesBox, _) {
            var datos = _obtenerDatosClientes();

            if (_mostrarSoloPendientes) {
              datos = datos.where((d) => d['visitado'] == false).toList();
            }

            if (datos.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: _mostrarSoloPendientes
                              ? AppTheme.successGradient
                              : LinearGradient(
                                  colors: [
                                    Colors.grey.shade100,
                                    Colors.grey.shade50,
                                  ],
                                ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _mostrarSoloPendientes
                                  ? AppTheme.success.withValues(alpha: 0.3)
                                  : Colors.grey.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          _mostrarSoloPendientes
                              ? Icons.celebration_rounded
                              : Icons.people_outline_rounded,
                          size: 56,
                          color: _mostrarSoloPendientes
                              ? Colors.white
                              : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        _mostrarSoloPendientes
                            ? '¡Felicidades!'
                            : 'Sin clientes',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _mostrarSoloPendientes
                              ? AppTheme.success
                              : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _mostrarSoloPendientes
                            ? 'Todos los clientes han sido visitados hoy'
                            : 'No hay clientes registrados',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade500,
                          height: 1.4,
                        ),
                      ),
                      if (_mostrarSoloPendientes) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, 
                                  color: AppTheme.success, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '100% completado',
                                style: TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            // Ordenar según ruta optimizada si existe
            final datosOrdenados = _ordenarClientesPorRuta(datos);

            // Agrupar por recinto
            final clientesPorRecinto = <String, List<Map<String, dynamic>>>{};
            for (var dato in datosOrdenados) {
              final recintoNombre = dato['recintoNombre'] as String;
              clientesPorRecinto.putIfAbsent(recintoNombre, () => []);
              clientesPorRecinto[recintoNombre]!.add(dato);
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: clientesPorRecinto.length,
              itemBuilder: (context, index) {
                final recintoNombre = clientesPorRecinto.keys.elementAt(index);
                final clientes = clientesPorRecinto[recintoNombre]!;
                final visitadosEnRecinto = clientes.where((d) => d['visitado'] == true).length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 12, top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accent.withValues(alpha: 0.08),
                            AppTheme.primaryLight.withValues(alpha: 0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recintoNombre,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$visitadosEnRecinto de ${clientes.length} visitados',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: visitadosEnRecinto == clientes.length
                                  ? AppTheme.success.withValues(alpha: 0.15)
                                  : AppTheme.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${clientes.length}',
                              style: TextStyle(
                                fontSize: 13,
                                color: visitadosEnRecinto == clientes.length
                                    ? AppTheme.success
                                    : AppTheme.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...clientes.map((dato) => _buildClienteCard(dato)),
                    const SizedBox(height: 8),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildClienteCard(Map<String, dynamic> dato) {
    final cliente = dato['cliente'] as Cliente;
    final visitado = dato['visitado'] as bool;
    final ultimoCobro = dato['ultimoCobro'] as Cobro?;
    final ordenVisita = _obtenerOrdenVisita(cliente);
    final esPrimero = ordenVisita == 1 && !visitado;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: esPrimero
            ? Border.all(color: AppTheme.warning, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: esPrimero
                ? AppTheme.warning.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: esPrimero ? 12 : 8,
            offset: const Offset(0, 4),
            spreadRadius: esPrimero ? 2 : 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            if (cliente.tieneUbicacion) {
              _tabController?.animateTo(0);
              setState(() => _clienteSeleccionado = cliente);
              Future.delayed(const Duration(milliseconds: 300), () {
                _mapController.move(
                  LatLng(cliente.latitud!, cliente.longitud!),
                  16,
                );
              });
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Número de orden
                    if (ordenVisita > 0 && !visitado)
                      Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          gradient: esPrimero
                              ? AppTheme.warningGradient
                              : AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: (esPrimero ? AppTheme.warning : AppTheme.accent)
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$ordenVisita',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: visitado
                            ? AppTheme.successGradient
                            : LinearGradient(
                                colors: [
                                  AppTheme.accent.withValues(alpha: 0.15),
                                  AppTheme.primaryLight.withValues(alpha: 0.15),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: visitado
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                                : Text(
                                    cliente.nombre.isNotEmpty
                                        ? cliente.nombre[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Color(0xFF667eea),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                          ),
                          if (cliente.tieneUbicacion)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  Icons.gps_fixed_rounded,
                                  size: 10,
                                  color: AppTheme.success,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  cliente.nombre,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    decoration: visitado ? TextDecoration.lineThrough : null,
                                    color: visitado ? Colors.grey.shade500 : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (esPrimero)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.warningGradient,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.warning.withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.navigate_next_rounded, 
                                          color: Colors.white, size: 14),
                                      SizedBox(width: 2),
                                      Text(
                                        'SIGUIENTE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (cliente.direccion != null && cliente.direccion!.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, 
                                    size: 13, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    cliente.direccion!,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          if (cliente.referencia != null && cliente.referencia!.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.info_outline, 
                                    size: 13, color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    cliente.referencia!,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Acciones
                    if (!visitado && cliente.tieneUbicacion)
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: ShaderMask(
                            shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                            child: const Icon(Icons.directions_rounded, color: Colors.white),
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _navegarACliente(cliente);
                          },
                          tooltip: 'Cómo llegar',
                        ),
                      )
                    else if (visitado)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_circle_rounded, 
                            color: AppTheme.success, size: 22),
                      )
                    else
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey.shade300,
                      ),
                  ],
                ),
                // Abono info
                if (visitado && ultimoCobro != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.success.withValues(alpha: 0.08),
                          AppTheme.success.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.payments_rounded, 
                            color: AppTheme.success, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Abono: ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '\$${ultimoCobro.abono.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ultimoCobro.metodoPago,
                            style: TextStyle(
                              color: AppTheme.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _obtenerDatosClientes() {
    List<Cliente> clientes;
    if (_recintoSeleccionado != null) {
      clientes = LocalStorageService.obtenerClientesActivosPorRecinto(
        _recintoSeleccionado!,
      );
    } else {
      clientes = LocalStorageService.obtenerClientesActivos();
    }

    final cobrosHoy = LocalStorageService.obtenerCobrosDeHoy();
    final List<Map<String, dynamic>> datos = [];

    for (var cliente in clientes) {
      final cobroHoy = cobrosHoy.cast<Cobro?>().firstWhere(
        (cobro) => cobro!.cliente.toLowerCase() == cliente.nombre.toLowerCase(),
        orElse: () => null,
      );

      final recinto = LocalStorageService.obtenerRecintoPorId(
        cliente.recintoId,
      );

      datos.add({
        'cliente': cliente,
        'visitado': cobroHoy != null,
        'ultimoCobro': cobroHoy,
        'recintoNombre': recinto?.nombre ?? 'Sin recinto',
      });
    }

    // Ordenar por distancia si hay ubicación actual
    if (_ubicacionActual != null) {
      datos.sort((a, b) {
        if (a['visitado'] != b['visitado']) {
          return a['visitado'] ? 1 : -1;
        }

        final clienteA = a['cliente'] as Cliente;
        final clienteB = b['cliente'] as Cliente;

        if (!clienteA.tieneUbicacion && !clienteB.tieneUbicacion) {
          return clienteA.nombre.compareTo(clienteB.nombre);
        }
        if (!clienteA.tieneUbicacion) return 1;
        if (!clienteB.tieneUbicacion) return -1;

        final distanciaA = _calcularDistancia(
          LatLng(_ubicacionActual!.latitude, _ubicacionActual!.longitude),
          LatLng(clienteA.latitud!, clienteA.longitud!),
        );
        final distanciaB = _calcularDistancia(
          LatLng(_ubicacionActual!.latitude, _ubicacionActual!.longitude),
          LatLng(clienteB.latitud!, clienteB.longitud!),
        );

        return distanciaA.compareTo(distanciaB);
      });
    } else {
      datos.sort((a, b) {
        if (a['visitado'] != b['visitado']) {
          return a['visitado'] ? 1 : -1;
        }
        return (a['cliente'] as Cliente).nombre.compareTo(
          (b['cliente'] as Cliente).nombre,
        );
      });
    }

    return datos;
  }
}

// Painter para el triángulo del marcador
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
