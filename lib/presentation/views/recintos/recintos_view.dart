import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../config/theme/app_theme.dart';
import '../../../domain/recinto_model.dart';
import '../../../infrastructure/local_storage_service.dart';
import 'widgets/recintos_content.dart';
import 'widgets/recinto_form_sheet.dart';
import 'widgets/nuevo_recinto_fab.dart';

/// Vista principal para gestionar los recintos
///
/// Esta vista implementa un diseño minimalista y permite:
/// - Visualizar todos los recintos
/// - Crear nuevos recintos
/// - Editar recintos existentes
/// - Eliminar recintos
class RecintosView extends StatelessWidget {
  const RecintosView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ValueListenableBuilder<Box<Recinto>>(
        valueListenable: LocalStorageService.recintosBox.listenable(),
        builder: (context, box, _) {
          final recintos = LocalStorageService.obtenerTodosLosRecintos();
          return RecintosContent(recintos: recintos);
        },
      ),
      floatingActionButton: NuevoRecintoFAB(
        onPressed: () => _mostrarFormularioRecinto(context),
      ),
    );
  }

  void _mostrarFormularioRecinto(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RecintoFormSheet(),
    );
  }
}
