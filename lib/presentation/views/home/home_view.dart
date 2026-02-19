import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../config/theme/app_theme.dart';
import '../../../domain/cobro_model.dart';
import '../../../infrastructure/data_class.dart';
import '../../../infrastructure/local_storage_service.dart';
import 'home_content.dart';


/// Vista principal del Home con selector de fecha
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  DateTime _fechaSeleccionada = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _buildBody(),
      // floatingActionButton: NuevoCobroFAB(
      //   onPressed: () => _navegarAFormulario(context),
      // ),
    );
  }

  Widget _buildBody() {
    return ValueListenableBuilder<Box<Cobro>>(
      valueListenable: LocalStorageService.cobrosBox.listenable(),
      builder: (context, box, _) {
        final cobrosData = CobrosData.fromDate(_fechaSeleccionada);
        return HomeContent(
          cobrosData: cobrosData,
          fechaSeleccionada: _fechaSeleccionada,
          onFechaChanged: _onFechaChanged,
        );
      },
    );
  }

  void _onFechaChanged(DateTime fecha) {
    setState(() => _fechaSeleccionada = fecha);
  }

 
}
