import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gal/gal.dart';
import '../domain/cobro_model.dart';
import '../domain/recinto_model.dart';
import '../domain/cliente_model.dart';

class LocalStorageService {
  static const String _cobrosBoxName = 'cobros';
  static const String _recintosBoxName = 'recintos';
  static const String _clientesBoxName = 'clientes';
  static const String _configBoxName = 'config';
  static const String _carpetaFotosKey = 'carpeta_fotos';

  static late Box<Cobro> _cobrosBox;
  static late Box<Recinto> _recintosBox;
  static late Box<Cliente> _clientesBox;
  static late Box<String> _configBox;
  static final Uuid _uuid = const Uuid();

  /// Inicializa Hive y abre las cajas necesarias
  static Future<void> init() async {
    await Hive.initFlutter();

    // Registrar adaptadores
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CobroAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(RecintoAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ClienteAdapter());
    }

    // Abrir caja de cobros
    _cobrosBox = await Hive.openBox<Cobro>(_cobrosBoxName);

    // Abrir caja de recintos
    _recintosBox = await Hive.openBox<Recinto>(_recintosBoxName);

    // Abrir caja de clientes
    _clientesBox = await Hive.openBox<Cliente>(_clientesBoxName);

    // Abrir caja de configuración
    _configBox = await Hive.openBox<String>(_configBoxName);
  }

  /// Genera un ID único
  static String generateId() => _uuid.v4();

  /// Obtiene la carpeta de fotos configurada o la predeterminada
  static Future<String> obtenerCarpetaFotos() async {
    final carpetaGuardada = _configBox.get(_carpetaFotosKey);
    if (carpetaGuardada != null && await Directory(carpetaGuardada).exists()) {
      return carpetaGuardada;
    }
    // Carpeta predeterminada
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/evidencias';
  }

  /// Permite al usuario seleccionar una carpeta para guardar fotos
  static Future<String?> seleccionarCarpetaFotos() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Seleccionar carpeta para fotos',
    );

    if (selectedDirectory != null) {
      await _configBox.put(_carpetaFotosKey, selectedDirectory);
      return selectedDirectory;
    }
    return null;
  }

  /// Guarda las imágenes en almacenamiento local y retorna las rutas
  /// También las guarda en la galería del dispositivo para que sean visibles
  static Future<List<String>> guardarImagenes(List<File> imagenes) async {
    final carpetaFotos = await obtenerCarpetaFotos();
    final imagenesDir = Directory(carpetaFotos);

    if (!await imagenesDir.exists()) {
      await imagenesDir.create(recursive: true);
    }

    List<String> rutas = [];
    for (var imagen in imagenes) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final nombreArchivo =
          'cobro_${timestamp}_${_uuid.v4().substring(0, 8)}.jpg';
      final nuevaRuta = '${imagenesDir.path}/$nombreArchivo';
      await imagen.copy(nuevaRuta);
      rutas.add(nuevaRuta);

      // Guardar en la galería del dispositivo para que aparezca visible
      try {
        await Gal.putImage(nuevaRuta, album: 'Cobrador App');
      } catch (e) {
        // Si falla guardar en galería, continuar (ya está guardada localmente)
        print('No se pudo guardar en galería: $e');
      }
    }

    return rutas;
  }

  /// Guarda un nuevo cobro
  static Future<void> guardarCobro(Cobro cobro) async {
    await _cobrosBox.put(cobro.id, cobro);
  }

  /// Obtiene todos los cobros
  static List<Cobro> obtenerTodosLosCobros() {
    return _cobrosBox.values.toList();
  }

  /// Obtiene los cobros de hoy
  static List<Cobro> obtenerCobrosDeHoy() {
    final hoy = DateTime.now();
    return _cobrosBox.values.where((cobro) {
      return cobro.fecha.year == hoy.year &&
          cobro.fecha.month == hoy.month &&
          cobro.fecha.day == hoy.day;
    }).toList();
  }

  /// Obtiene cobros por rango de fechas
  static List<Cobro> obtenerCobrosPorFecha(DateTime inicio, DateTime fin) {
    return _cobrosBox.values.where((cobro) {
      return (cobro.fecha.isAfter(inicio) ||
              cobro.fecha.isAtSameMomentAs(inicio)) &&
          (cobro.fecha.isBefore(fin) || cobro.fecha.isAtSameMomentAs(fin));
    }).toList();
  }

  /// Obtiene un cobro por ID
  static Cobro? obtenerCobroPorId(String id) {
    return _cobrosBox.get(id);
  }

  /// Elimina un cobro
  static Future<void> eliminarCobro(String id) async {
    final cobro = _cobrosBox.get(id);
    if (cobro != null) {
      // Eliminar imágenes asociadas
      for (var imagenPath in cobro.imagenesPath) {
        final archivo = File(imagenPath);
        if (await archivo.exists()) {
          await archivo.delete();
        }
      }
      await _cobrosBox.delete(id);
    }
  }

  /// Actualiza un cobro existente
  static Future<void> actualizarCobro(Cobro cobro) async {
    await _cobrosBox.put(cobro.id, cobro);
  }

  /// Obtiene el total de cobros de hoy
  static double obtenerTotalHoy() {
    return obtenerCobrosDeHoy().fold(0, (sum, cobro) => sum + cobro.abono);
  }

  /// Obtiene el total en efectivo de hoy
  static double obtenerTotalEfectivoHoy() {
    return obtenerCobrosDeHoy()
        .where((cobro) => cobro.metodoPago == 'Efectivo')
        .fold(0, (sum, cobro) => sum + cobro.abono);
  }

  /// Obtiene el total en transferencia de hoy
  static double obtenerTotalTransferenciaHoy() {
    return obtenerCobrosDeHoy()
        .where((cobro) => cobro.metodoPago == 'Transferencia')
        .fold(0, (sum, cobro) => sum + cobro.abono);
  }

  /// Obtiene el total general
  static double obtenerTotalGeneral() {
    return _cobrosBox.values.fold(0, (sum, cobro) => sum + cobro.abono);
  }

  /// Escucha cambios en la caja de cobros (para actualizar UI)
  static Box<Cobro> get cobrosBox => _cobrosBox;

  // ============================================================
  // MÉTODOS PARA RECINTOS
  // ============================================================

  /// Guarda un nuevo recinto
  static Future<void> guardarRecinto(Recinto recinto) async {
    await _recintosBox.put(recinto.id, recinto);
  }

  /// Obtiene todos los recintos
  static List<Recinto> obtenerTodosLosRecintos() {
    return _recintosBox.values.toList();
  }

  /// Obtiene solo los recintos activos ordenados por el campo orden
  static List<Recinto> obtenerRecintosActivos() {
    final recintos = _recintosBox.values
        .where((recinto) => recinto.activo)
        .toList();
    recintos.sort((a, b) => a.orden.compareTo(b.orden));
    return recintos;
  }

  /// Obtiene un recinto por ID
  static Recinto? obtenerRecintoPorId(String id) {
    return _recintosBox.get(id);
  }

  /// Obtiene un recinto por nombre
  static Recinto? obtenerRecintoPorNombre(String nombre) {
    try {
      return _recintosBox.values.firstWhere(
        (recinto) => recinto.nombre.toLowerCase() == nombre.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Actualiza un recinto existente
  static Future<void> actualizarRecinto(Recinto recinto) async {
    await _recintosBox.put(recinto.id, recinto);
  }

  /// Elimina un recinto (soft delete - lo marca como inactivo)
  static Future<void> desactivarRecinto(String id) async {
    final recinto = _recintosBox.get(id);
    if (recinto != null) {
      await _recintosBox.put(id, recinto.copyWith(activo: false));
    }
  }

  /// Elimina un recinto permanentemente
  static Future<void> eliminarRecinto(String id) async {
    await _recintosBox.delete(id);
  }

  /// Verifica si existe un recinto con el nombre dado
  static bool existeRecinto(String nombre) {
    return _recintosBox.values.any(
      (recinto) => recinto.nombre.toLowerCase() == nombre.toLowerCase(),
    );
  }

  /// Actualiza el orden de múltiples recintos
  static Future<void> actualizarOrdenRecintos(
    List<Recinto> recintosOrdenados,
  ) async {
    for (int i = 0; i < recintosOrdenados.length; i++) {
      final recinto = recintosOrdenados[i];
      final recintoActualizado = recinto.copyWith(orden: i);
      await _recintosBox.put(recinto.id, recintoActualizado);
    }
  }

  /// Obtiene el próximo número de orden disponible
  static int obtenerSiguienteOrden() {
    if (_recintosBox.isEmpty) return 0;
    final maxOrden = _recintosBox.values
        .map((r) => r.orden)
        .reduce((a, b) => a > b ? a : b);
    return maxOrden + 1;
  }

  /// Obtiene el número de cobros realizados en un recinto
  static int obtenerCobrosEnRecinto(String nombreRecinto) {
    return _cobrosBox.values
        .where((cobro) => cobro.recinto == nombreRecinto)
        .length;
  }

  /// Escucha cambios en la caja de recintos (para actualizar UI)
  static Box<Recinto> get recintosBox => _recintosBox;

  // ============================================================
  // MÉTODOS PARA CLIENTES
  // ============================================================

  /// Guarda un nuevo cliente
  static Future<void> guardarCliente(Cliente cliente) async {
    await _clientesBox.put(cliente.id, cliente);
  }

  /// Obtiene todos los clientes
  static List<Cliente> obtenerTodosLosClientes() {
    return _clientesBox.values.toList();
  }

  /// Obtiene solo los clientes activos
  static List<Cliente> obtenerClientesActivos() {
    return _clientesBox.values.where((cliente) => cliente.activo).toList();
  }

  /// Obtiene los clientes de un recinto específico por recintoId
  static List<Cliente> obtenerClientesPorRecinto(String recintoId) {
    return _clientesBox.values
        .where((cliente) => cliente.recintoId == recintoId)
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  /// Obtiene los clientes activos de un recinto específico
  static List<Cliente> obtenerClientesActivosPorRecinto(String recintoId) {
    return _clientesBox.values
        .where((cliente) => cliente.recintoId == recintoId && cliente.activo)
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  /// Obtiene un cliente por ID
  static Cliente? obtenerClientePorId(String id) {
    return _clientesBox.get(id);
  }

  /// Busca clientes por nombre (búsqueda parcial)
  static List<Cliente> buscarClientesPorNombre(String termino) {
    final terminoLower = termino.toLowerCase();
    return _clientesBox.values
        .where(
          (cliente) =>
              cliente.activo &&
              cliente.nombre.toLowerCase().contains(terminoLower),
        )
        .toList();
  }

  /// Actualiza un cliente existente
  static Future<void> actualizarCliente(Cliente cliente) async {
    await _clientesBox.put(cliente.id, cliente);
  }

  /// Desactiva un cliente (soft delete)
  static Future<void> desactivarCliente(String id) async {
    final cliente = _clientesBox.get(id);
    if (cliente != null) {
      await _clientesBox.put(id, cliente.copyWith(activo: false));
    }
  }

  /// Activa un cliente previamente desactivado
  static Future<void> activarCliente(String id) async {
    final cliente = _clientesBox.get(id);
    if (cliente != null) {
      await _clientesBox.put(id, cliente.copyWith(activo: true));
    }
  }

  /// Elimina un cliente permanentemente
  static Future<void> eliminarCliente(String id) async {
    await _clientesBox.delete(id);
  }

  /// Obtiene el número de clientes en un recinto
  static int obtenerCantidadClientesEnRecinto(String recintoId) {
    return _clientesBox.values
        .where((cliente) => cliente.recintoId == recintoId && cliente.activo)
        .length;
  }

  /// Escucha cambios en la caja de clientes (para actualizar UI)
  static Box<Cliente> get clientesBox => _clientesBox;
}
