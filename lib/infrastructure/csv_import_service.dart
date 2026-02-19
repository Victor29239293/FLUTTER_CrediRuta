import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../domain/cliente_model.dart';
import '../domain/recinto_model.dart';
import 'local_storage_service.dart';

/// Resultado de la importación de clientes desde CSV/Excel
class ImportResult {
  final int clientesImportados;
  final int recintosCreados;
  final int filasIgnoradas;
  final List<String> errores;

  ImportResult({
    required this.clientesImportados,
    required this.recintosCreados,
    required this.filasIgnoradas,
    this.errores = const [],
  });

  bool get tieneErrores => errores.isNotEmpty;

  String get resumen {
    final buffer = StringBuffer();
    buffer.write('Se importaron $clientesImportados clientes');
    if (recintosCreados > 0) {
      buffer.write(' en $recintosCreados recintos nuevos');
    }
    if (filasIgnoradas > 0) {
      buffer.write(' ($filasIgnoradas filas ignoradas)');
    }
    return buffer.toString();
  }
}

/// Servicio para importar clientes desde archivos CSV o Excel (.xlsx).
///
/// Formato esperado:
/// - Primera fila: cabecera con columnas: recinto, nombre, referencia
/// - Filas siguientes: datos de clientes
///
/// Ejemplo:
/// ```
/// recinto,nombre,referencia
/// Centro Comercial,Juan Pérez,555-1234
/// Centro Comercial,María López,
/// Plaza Norte,Carlos García,555-5678
/// ```
class CsvImportService {
  /// Abre el selector de archivos y permite seleccionar un CSV o Excel
  static Future<File?> seleccionarArchivoCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt', 'xlsx', 'xls'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  /// Importa clientes desde un archivo CSV o Excel.
  ///
  /// Detecta automáticamente el tipo de archivo por su extensión.
  static Future<ImportResult> importarDesdeArchivo(File archivo) async {
    final extension = archivo.path.toLowerCase().split('.').last;

    if (extension == 'xlsx' || extension == 'xls') {
      return _importarDesdeExcel(archivo);
    } else {
      return _importarDesdeCsv(archivo);
    }
  }

  /// Importa clientes desde un archivo Excel (.xlsx/.xls)
  static Future<ImportResult> _importarDesdeExcel(File archivo) async {
    int clientesImportados = 0;
    int recintosCreados = 0;
    int filasIgnoradas = 0;
    List<String> errores = [];

    try {
      final bytes = await archivo.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // Usar la primera hoja del archivo
      if (excel.tables.isEmpty) {
        return ImportResult(
          clientesImportados: 0,
          recintosCreados: 0,
          filasIgnoradas: 0,
          errores: ['El archivo Excel está vacío'],
        );
      }

      final nombreHoja = excel.tables.keys.first;
      final hoja = excel.tables[nombreHoja]!;

      if (hoja.rows.isEmpty) {
        return ImportResult(
          clientesImportados: 0,
          recintosCreados: 0,
          filasIgnoradas: 0,
          errores: ['La hoja de cálculo está vacía'],
        );
      }

      // Obtener cabecera (primera fila)
      final cabecera = hoja.rows.first
          .map((cell) => cell?.value?.toString() ?? '')
          .toList();

      if (!_validarCabecera(cabecera)) {
        return ImportResult(
          clientesImportados: 0,
          recintosCreados: 0,
          filasIgnoradas: 0,
          errores: [
            'Formato de cabecera inválido. Se esperan columnas: recinto, nombre, referencia',
          ],
        );
      }

      // Encontrar índices de columnas
      final indiceRecinto = _encontrarIndice(cabecera, [
        'recinto',
        'lugar',
        'ubicacion',
      ]);
      final indiceNombre = _encontrarIndice(cabecera, [
        'nombre',
        'cliente',
        'name',
      ]);
      final indiceReferencia = _encontrarIndice(cabecera, [
        'referencia',
        'telefono',
        'cedula',
        'ref',
      ]);

      if (indiceRecinto == -1 || indiceNombre == -1) {
        return ImportResult(
          clientesImportados: 0,
          recintosCreados: 0,
          filasIgnoradas: 0,
          errores: [
            'No se encontraron las columnas requeridas (recinto, nombre)',
          ],
        );
      }

      // Cache de recintos
      final Map<String, String> cacheRecintos = {};

      // Procesar filas (empezando desde la segunda)
      for (int i = 1; i < hoja.rows.length; i++) {
        final fila = hoja.rows[i];

        try {
          // Obtener valores de las celdas
          final campos = fila
              .map((cell) => cell?.value?.toString() ?? '')
              .toList();

          if (campos.length <= indiceRecinto || campos.length <= indiceNombre) {
            filasIgnoradas++;
            continue;
          }

          final nombreRecinto = campos[indiceRecinto].trim();
          final nombreCliente = campos[indiceNombre].trim();
          final referencia =
              indiceReferencia != -1 && campos.length > indiceReferencia
              ? campos[indiceReferencia].trim()
              : null;

          if (nombreRecinto.isEmpty || nombreCliente.isEmpty) {
            filasIgnoradas++;
            continue;
          }

          // Buscar o crear recinto
          String recintoId;
          if (cacheRecintos.containsKey(nombreRecinto.toLowerCase())) {
            recintoId = cacheRecintos[nombreRecinto.toLowerCase()]!;
          } else {
            final recintoExistente =
                LocalStorageService.obtenerRecintoPorNombre(nombreRecinto);
            if (recintoExistente != null) {
              recintoId = recintoExistente.id;
            } else {
              final nuevoRecinto = Recinto(
                id: LocalStorageService.generateId(),
                nombre: nombreRecinto,
                fechaCreacion: DateTime.now(),
                activo: true,
              );
              await LocalStorageService.guardarRecinto(nuevoRecinto);
              recintoId = nuevoRecinto.id;
              recintosCreados++;
            }
            cacheRecintos[nombreRecinto.toLowerCase()] = recintoId;
          }

          // Crear cliente
          final nuevoCliente = Cliente(
            id: LocalStorageService.generateId(),
            nombre: nombreCliente,
            referencia: referencia?.isNotEmpty == true ? referencia : null,
            recintoId: recintoId,
            fechaCreacion: DateTime.now(),
            activo: true,
          );
          await LocalStorageService.guardarCliente(nuevoCliente);
          clientesImportados++;
        } catch (e) {
          filasIgnoradas++;
          errores.add('Error en fila ${i + 1}: $e');
        }
      }

      return ImportResult(
        clientesImportados: clientesImportados,
        recintosCreados: recintosCreados,
        filasIgnoradas: filasIgnoradas,
        errores: errores,
      );
    } catch (e) {
      return ImportResult(
        clientesImportados: clientesImportados,
        recintosCreados: recintosCreados,
        filasIgnoradas: filasIgnoradas,
        errores: ['Error al leer el archivo Excel: $e'],
      );
    }
  }

  /// Importa clientes desde un archivo CSV
  static Future<ImportResult> _importarDesdeCsv(File archivo) async {
    int clientesImportados = 0;
    int recintosCreados = 0;
    int filasIgnoradas = 0;
    List<String> errores = [];

    try {
      // Leer el contenido del archivo
      final contenido = await archivo.readAsString();
      final lineas = contenido.split('\n');

      if (lineas.isEmpty) {
        return ImportResult(
          clientesImportados: 0,
          recintosCreados: 0,
          filasIgnoradas: 0,
          errores: ['El archivo está vacío'],
        );
      }

      // Validar cabecera
      final cabecera = _parsearLinea(lineas.first.trim());
      if (!_validarCabecera(cabecera)) {
        return ImportResult(
          clientesImportados: 0,
          recintosCreados: 0,
          filasIgnoradas: 0,
          errores: [
            'Formato de cabecera inválido. Se esperan columnas: recinto, nombre, referencia',
          ],
        );
      }

      // Encontrar índices de columnas
      final indiceRecinto = _encontrarIndice(cabecera, [
        'recinto',
        'lugar',
        'ubicacion',
      ]);
      final indiceNombre = _encontrarIndice(cabecera, [
        'nombre',
        'cliente',
        'name',
      ]);
      final indiceReferencia = _encontrarIndice(cabecera, [
        'referencia',
        'telefono',
        'cedula',
        'ref',
      ]);

      if (indiceRecinto == -1 || indiceNombre == -1) {
        return ImportResult(
          clientesImportados: 0,
          recintosCreados: 0,
          filasIgnoradas: 0,
          errores: [
            'No se encontraron las columnas requeridas (recinto, nombre)',
          ],
        );
      }

      // Cache de recintos para evitar múltiples búsquedas
      final Map<String, String> cacheRecintos = {};

      // Procesar cada fila de datos (empezando desde la segunda)
      for (int i = 1; i < lineas.length; i++) {
        final linea = lineas[i].trim();
        if (linea.isEmpty) continue;

        try {
          final campos = _parsearLinea(linea);

          // Validar que tenga suficientes campos
          if (campos.length <= indiceRecinto || campos.length <= indiceNombre) {
            filasIgnoradas++;
            continue;
          }

          final nombreRecinto = campos[indiceRecinto].trim();
          final nombreCliente = campos[indiceNombre].trim();
          final referencia =
              indiceReferencia != -1 && campos.length > indiceReferencia
              ? campos[indiceReferencia].trim()
              : null;

          // Validar datos obligatorios
          if (nombreRecinto.isEmpty || nombreCliente.isEmpty) {
            filasIgnoradas++;
            continue;
          }

          // Buscar o crear recinto
          String recintoId;
          if (cacheRecintos.containsKey(nombreRecinto.toLowerCase())) {
            recintoId = cacheRecintos[nombreRecinto.toLowerCase()]!;
          } else {
            final recintoExistente =
                LocalStorageService.obtenerRecintoPorNombre(nombreRecinto);
            if (recintoExistente != null) {
              recintoId = recintoExistente.id;
            } else {
              // Crear nuevo recinto
              final nuevoRecinto = Recinto(
                id: LocalStorageService.generateId(),
                nombre: nombreRecinto,
                fechaCreacion: DateTime.now(),
                activo: true,
              );
              await LocalStorageService.guardarRecinto(nuevoRecinto);
              recintoId = nuevoRecinto.id;
              recintosCreados++;
            }
            cacheRecintos[nombreRecinto.toLowerCase()] = recintoId;
          }

          // Crear cliente
          final nuevoCliente = Cliente(
            id: LocalStorageService.generateId(),
            nombre: nombreCliente,
            referencia: referencia?.isNotEmpty == true ? referencia : null,
            recintoId: recintoId,
            fechaCreacion: DateTime.now(),
            activo: true,
          );
          await LocalStorageService.guardarCliente(nuevoCliente);
          clientesImportados++;
        } catch (e) {
          filasIgnoradas++;
          errores.add('Error en línea ${i + 1}: $e');
        }
      }

      return ImportResult(
        clientesImportados: clientesImportados,
        recintosCreados: recintosCreados,
        filasIgnoradas: filasIgnoradas,
        errores: errores,
      );
    } catch (e) {
      return ImportResult(
        clientesImportados: clientesImportados,
        recintosCreados: recintosCreados,
        filasIgnoradas: filasIgnoradas,
        errores: ['Error al leer el archivo: $e'],
      );
    }
  }

  /// Parsea una línea CSV considerando comas dentro de comillas
  static List<String> _parsearLinea(String linea) {
    final List<String> campos = [];
    final buffer = StringBuffer();
    bool dentroComillas = false;

    for (int i = 0; i < linea.length; i++) {
      final char = linea[i];

      if (char == '"') {
        dentroComillas = !dentroComillas;
      } else if (char == ',' && !dentroComillas) {
        campos.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    campos.add(buffer.toString());

    return campos;
  }

  /// Valida que la cabecera tenga las columnas mínimas requeridas
  static bool _validarCabecera(List<String> cabecera) {
    if (cabecera.length < 2) return false;

    final cabeceraLower = cabecera.map((c) => c.toLowerCase().trim()).toList();

    final tieneRecinto = cabeceraLower.any(
      (c) => c == 'recinto' || c == 'lugar' || c == 'ubicacion',
    );
    final tieneNombre = cabeceraLower.any(
      (c) => c == 'nombre' || c == 'cliente' || c == 'name',
    );

    return tieneRecinto && tieneNombre;
  }

  /// Encuentra el índice de una columna buscando por posibles nombres
  static int _encontrarIndice(
    List<String> cabecera,
    List<String> posiblesNombres,
  ) {
    for (int i = 0; i < cabecera.length; i++) {
      final campo = cabecera[i].toLowerCase().trim();
      if (posiblesNombres.contains(campo)) {
        return i;
      }
    }
    return -1;
  }
}
