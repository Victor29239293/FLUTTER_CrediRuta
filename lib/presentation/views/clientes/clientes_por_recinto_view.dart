import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../config/theme/app_theme.dart';
import '../../../domain/cliente_model.dart';
import '../../../domain/recinto_model.dart';
import '../../../infrastructure/local_storage_service.dart';
import 'widgets/cliente_card.dart';
import 'widgets/cliente_form_sheet.dart';
import 'widgets/clientes_empty_state.dart';
import 'widgets/clientes_header.dart';

/// Vista que muestra la lista de clientes de un recinto específico.
///
/// Permite:
/// - Ver todos los clientes asociados al recinto
/// - Crear nuevos clientes mediante FAB
/// - Editar/eliminar clientes existentes
/// - Buscar clientes por nombre
class ClientesPorRecintoView extends StatefulWidget {
  final Recinto recinto;

  const ClientesPorRecintoView({super.key, required this.recinto});

  @override
  State<ClientesPorRecintoView> createState() => _ClientesPorRecintoViewState();
}

class _ClientesPorRecintoViewState extends State<ClientesPorRecintoView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ValueListenableBuilder<Box<Cliente>>(
        valueListenable: LocalStorageService.clientesBox.listenable(),
        builder: (context, box, _) {
          final todosClientes = LocalStorageService.obtenerClientesPorRecinto(
            widget.recinto.id,
          );

          // Filtrar por búsqueda
          final clientes = _searchQuery.isEmpty
              ? todosClientes
              : todosClientes
                    .where(
                      (c) =>
                          c.nombre.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          (c.referencia?.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ??
                              false),
                    )
                    .toList();

          return _ClientesContent(
            recinto: widget.recinto,
            clientes: clientes,
            totalClientes: todosClientes.length,
            searchQuery: _searchQuery,
            onSearchChanged: (value) => setState(() => _searchQuery = value),
          );
        },
      ),
      floatingActionButton: _NuevoClienteFAB(
        onPressed: () => _mostrarFormularioCliente(context),
      ),
    );
  }

  void _mostrarFormularioCliente(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClienteFormSheet(recintoId: widget.recinto.id),
    );
  }
}

/// Contenido principal de la vista de clientes
class _ClientesContent extends StatelessWidget {
  final Recinto recinto;
  final List<Cliente> clientes;
  final int totalClientes;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _ClientesContent({
    required this.recinto,
    required this.clientes,
    required this.totalClientes,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final clientesActivos = clientes.where((c) => c.activo).length;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header con info del recinto y estadísticas
        SliverToBoxAdapter(
          child: ClientesHeader(
            recinto: recinto,
            totalClientes: totalClientes,
            clientesActivos: clientesActivos,
          ),
        ),

        // Barra de búsqueda si hay clientes
        if (totalClientes > 0)
          SliverToBoxAdapter(
            child: _SearchBar(value: searchQuery, onChanged: onSearchChanged),
          ),

        // Lista de clientes o estado vacío
        if (totalClientes == 0)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: ClientesEmptyState(),
          )
        else if (clientes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _NoResultsState(query: searchQuery),
          )
        else
          _buildClientesList(),

        // Espacio inferior para el FAB
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildClientesList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ClienteCard(
              cliente: clientes[index],
              recintoNombre: recinto.nombre,
            ),
          ),
          childCount: clientes.length,
        ),
      ),
    );
  }
}

/// Barra de búsqueda
class _SearchBar extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Buscar cliente...',
            hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
            suffixIcon: value.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppTheme.textMuted,
                      size: 18,
                    ),
                    onPressed: () => onChanged(''),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}

/// Estado sin resultados de búsqueda
class _NoResultsState extends StatelessWidget {
  final String query;

  const _NoResultsState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppTheme.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin resultados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron clientes para "$query"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// FAB para crear nuevo cliente
class _NuevoClienteFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const _NuevoClienteFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F4C75), Color(0xFF1B262C)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F4C75).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Nuevo Cliente',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
