import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../../infrastructure/csv_import_service.dart';

/// BottomSheet para importar clientes desde un archivo CSV
///
/// Muestra instrucciones del formato esperado y permite
/// seleccionar un archivo para importar.
class ImportarClientesSheet extends StatefulWidget {
  const ImportarClientesSheet({super.key});

  @override
  State<ImportarClientesSheet> createState() => _ImportarClientesSheetState();
}

class _ImportarClientesSheetState extends State<ImportarClientesSheet> {
  bool _importando = false;
  ImportResult? _resultado;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHandle(),
            _buildHeader(),
            if (_resultado != null)
              _buildResultado()
            else ...[
              _buildInstrucciones(),
              _buildFormatoEsperado(),
              _buildAcciones(),
            ],
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
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
            child: const Icon(Icons.upload_file, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Importar Clientes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Carga masiva desde CSV o Excel',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstrucciones() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Instrucciones',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstruccionItem(
              '1',
              'Prepara un archivo CSV o Excel (.xlsx) con tus clientes',
            ),
            _buildInstruccionItem('2', 'La primera fila debe ser la cabecera'),
            _buildInstruccionItem(
              '3',
              'Los recintos nuevos se crearán automáticamente',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruccionItem(String numero, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                numero,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatoEsperado() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Formato esperado (CSV o Excel):',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'recinto,nombre,referencia',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Centro Comercial,Juan Pérez,555-1234\nCentro Comercial,María López,\nPlaza Norte,Carlos García,555-5678',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '* La columna "referencia" es opcional',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcciones() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _importando ? null : _seleccionarEImportar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: _importando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.folder_open, color: Colors.white),
          label: Text(
            _importando ? 'Importando...' : 'Seleccionar archivo',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultado() {
    final resultado = _resultado!;
    final esExitoso = resultado.clientesImportados > 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Icono de resultado
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: (esExitoso ? AppTheme.success : AppTheme.error).withValues(
                alpha: 0.1,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              esExitoso ? Icons.check_circle : Icons.error_outline,
              size: 40,
              color: esExitoso ? AppTheme.success : AppTheme.error,
            ),
          ),
          const SizedBox(height: 24),

          // Título
          Text(
            esExitoso ? '¡Importación exitosa!' : 'Error en la importación',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: esExitoso ? AppTheme.success : AppTheme.error,
            ),
          ),
          const SizedBox(height: 12),

          // Resumen
          Text(
            resultado.resumen,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),

          // Errores si hay
          if (resultado.tieneErrores) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Errores:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.error,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...resultado.errores
                      .take(3)
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $e',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.error.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                  if (resultado.errores.length > 3)
                    Text(
                      '... y ${resultado.errores.length - 3} más',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.error.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Botón cerrar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cerrar',
                style: TextStyle(
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

  Future<void> _seleccionarEImportar() async {
    HapticFeedback.mediumImpact();
    setState(() => _importando = true);

    try {
      final archivo = await CsvImportService.seleccionarArchivoCsv();

      if (archivo == null) {
        setState(() => _importando = false);
        return;
      }

      final resultado = await CsvImportService.importarDesdeArchivo(archivo);

      setState(() {
        _resultado = resultado;
        _importando = false;
      });
    } catch (e) {
      setState(() => _importando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
