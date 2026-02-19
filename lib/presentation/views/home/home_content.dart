import 'package:flutter/material.dart';
import '../../../infrastructure/data_class.dart';
import 'widgets/widgets.dart';

/// Contenido principal del Home con búsqueda y lista de cobros
class HomeContent extends StatefulWidget {
  final CobrosData cobrosData;
  final DateTime fechaSeleccionada;
  final ValueChanged<DateTime> onFechaChanged;

  const HomeContent({
    super.key,
    required this.cobrosData,
    required this.fechaSeleccionada,
    required this.onFechaChanged,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cobrosDataFiltrados = widget.cobrosData.filtrarPorBusqueda(
      _searchTerm,
    );

    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        // Header con fecha y totales
        SliverToBoxAdapter(
          child: HeaderSection(
            cobrosData: widget.cobrosData,
            fechaSeleccionada: widget.fechaSeleccionada,
            onFechaChanged: widget.onFechaChanged,
          ),
        ),

        // Barra de búsqueda
        SliverToBoxAdapter(
          child: SearchBarWidget(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onClear: _onSearchClear,
          ),
        ),

        // Contenido dinámico según el estado
        ..._buildContent(cobrosDataFiltrados),

        // Espacio inferior para el FAB
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  void _onSearchChanged(String value) {
    setState(() => _searchTerm = value);
  }

  void _onSearchClear() {
    _searchController.clear();
    setState(() => _searchTerm = '');
  }

  List<Widget> _buildContent(CobrosData cobrosData) {
    // Caso 1: Búsqueda sin resultados
    if (_searchTerm.isNotEmpty && cobrosData.isEmpty) {
      return [
        SliverToBoxAdapter(child: NoResultsState(searchTerm: _searchTerm)),
      ];
    }

    // Caso 2: Sin cobros en la fecha
    if (widget.cobrosData.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(fecha: widget.fechaSeleccionada),
        ),
      ];
    }

    // Caso 3: Mostrar cobros agrupados por recinto
    return _buildCobrosAgrupados(cobrosData);
  }

  List<Widget> _buildCobrosAgrupados(CobrosData cobrosData) {
    final List<Widget> slivers = [];

    for (final recinto in cobrosData.recintosOrdenados) {
      final cobrosRecinto = cobrosData.cobrosPorRecinto[recinto]!;
      final totalRecinto = cobrosData.totalPorRecinto(recinto);

      // Header del recinto
      slivers.add(
        SliverToBoxAdapter(
          child: RecintoHeader(
            recinto: recinto,
            cantidadCobros: cobrosRecinto.length,
            total: totalRecinto,
          ),
        ),
      );

      // Lista de cobros del recinto
      slivers.add(CobrosListSliver(cobros: cobrosRecinto));
    }

    return slivers;
  }
}
