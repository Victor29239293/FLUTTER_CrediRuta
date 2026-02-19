import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../config/theme/app_theme.dart';
import '../../../domain/cliente_model.dart';
import '../../../domain/cobro_model.dart';
import '../../../domain/recinto_model.dart';
import '../../../infrastructure/local_storage_service.dart';
import '../cobro_rapido/nuevo_cobro_rapido_screen.dart';
import '../recintos/widgets/reordenar_recintos_sheet.dart';

/// Vista del Home que muestra recintos expandibles con sus clientes.
///
/// Flujo:
/// 1. El usuario ve una lista de recintos activos
/// 2. Al tocar un recinto, se expande y muestra sus clientes
/// 3. Al tocar un cliente, navega a NuevoCobroRapidoScreen
class HomeRecintosView extends StatefulWidget {
  const HomeRecintosView({super.key});

  @override
  State<HomeRecintosView> createState() => _HomeRecintosViewState();
}

class _HomeRecintosViewState extends State<HomeRecintosView> {
  // Conjunto de recintos expandidos (para mantener el estado)
  final Set<String> _recintosExpandidos = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ValueListenableBuilder<Box<Recinto>>(
        // Escucha cambios en los recintos
        valueListenable: LocalStorageService.recintosBox.listenable(),
        builder: (context, recintosBox, _) {
          return ValueListenableBuilder<Box<Cobro>>(
            // También escucha cambios en cobros para actualizar contadores
            valueListenable: LocalStorageService.cobrosBox.listenable(),
            builder: (context, cobrosBox, _) {
              final recintos = LocalStorageService.obtenerRecintosActivos();
              return _buildContent(recintos);
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(List<Recinto> recintos) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header con estadísticas del día
        SliverToBoxAdapter(
          child: _HomeHeader(
            onReordenarPressed: () => _mostrarReordenarSheet(),
          ),
        ),

        // Lista de recintos o estado vacío
        if (recintos.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyRecintosState(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecintoExpandibleCard(
                    recinto: recintos[index],
                    isExpanded: _recintosExpandidos.contains(
                      recintos[index].id,
                    ),
                    onToggle: () => _toggleRecinto(recintos[index].id),
                    onClienteTap: (cliente) =>
                        _navegarACobroRapido(recintos[index], cliente),
                  ),
                ),
                childCount: recintos.length,
              ),
            ),
          ),

        // Espacio inferior
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  /// Muestra el bottom sheet para reordenar recintos
  void _mostrarReordenarSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => const ReordenarRecintosSheet(),
      ),
    );
  }

  /// Alterna el estado expandido de un recinto
  void _toggleRecinto(String recintoId) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_recintosExpandidos.contains(recintoId)) {
        _recintosExpandidos.remove(recintoId);
      } else {
        _recintosExpandidos.add(recintoId);
      }
    });
  }

  /// Navega a la pantalla de cobro rápido
  void _navegarACobroRapido(Recinto recinto, Cliente cliente) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            NuevoCobroRapidoScreen(recinto: recinto, cliente: cliente),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// HEADER CON ESTADÍSTICAS DEL DÍA (versión premium)
// ============================================================

class _HomeHeader extends StatelessWidget {
  final VoidCallback? onReordenarPressed;

  const _HomeHeader({this.onReordenarPressed});

  @override
  Widget build(BuildContext context) {
    // Obtener cobros del día
    final cobrosHoy = LocalStorageService.obtenerCobrosDeHoy();
    final totalHoy = cobrosHoy.fold<double>(0, (sum, c) => sum + c.abono);
    final totalEfectivo = cobrosHoy
        .where((c) => c.metodoPago == 'Efectivo')
        .fold<double>(0, (sum, c) => sum + c.abono);
    final totalTransferencia = cobrosHoy
        .where((c) => c.metodoPago == 'Transferencia')
        .fold<double>(0, (sum, c) => sum + c.abono);
    final cantidadCobros = cobrosHoy.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de sección
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.efectivo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: AppTheme.efectivo,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen del día',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '$cantidadCobros cobros realizados',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cards de estadísticas
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _StatCard(
                  label: 'Total hoy',
                  value: '\$${totalHoy.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F4C75), Color(0xFF1B262C)],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  label: 'Efectivo',
                  value: '\$${totalEfectivo.toStringAsFixed(0)}',
                  color: AppTheme.efectivo,
                  icon: Icons.payments_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  label: 'Transfer',
                  value: '\$${totalTransferencia.toStringAsFixed(0)}',
                  color: AppTheme.transferencia,
                  icon: Icons.swap_horiz_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Subtítulo para recintos
          Row(
            children: [
              const Text(
                'Selecciona un recinto',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              // Botón para reordenar recintos
              GestureDetector(
                onTap: onReordenarPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.reorder_rounded,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ordenar',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4C75).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CARD DE RECINTO EXPANDIBLE
// ============================================================

class _RecintoExpandibleCard extends StatelessWidget {
  final Recinto recinto;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Function(Cliente) onClienteTap;

  const _RecintoExpandibleCard({
    required this.recinto,
    required this.isExpanded,
    required this.onToggle,
    required this.onClienteTap,
  });

  // Colores para cada recinto (basado en el hash del nombre)
  Color get _accentColor {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFFEC4899), // Pink
      const Color(0xFF3B82F6), // Blue
    ];
    return colors[recinto.nombre.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    // Obtener clientes del recinto
    final clientes = LocalStorageService.obtenerClientesActivosPorRecinto(
      recinto.id,
    );
    final cobrosHoyRecinto = LocalStorageService.obtenerCobrosDeHoy()
        .where((c) => c.recinto == recinto.nombre)
        .length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded
              ? _accentColor.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.1),
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? _accentColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isExpanded ? 20 : 10,
            offset: const Offset(0, 4),
            spreadRadius: isExpanded ? 2 : 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del recinto (siempre visible)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    // Icono del recinto con gradiente
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _accentColor,
                            _accentColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _accentColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.store_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Información del recinto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recinto.nombre,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _InfoChip(
                                icon: Icons.group_rounded,
                                label: '${clientes.length}',
                                color: AppTheme.textMuted,
                              ),
                              if (cobrosHoyRecinto > 0) ...[
                                const SizedBox(width: 10),
                                _InfoChip(
                                  icon: Icons.check_circle_rounded,
                                  label: '$cobrosHoyRecinto hoy',
                                  color: AppTheme.efectivo,
                                  filled: true,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Botón de expansión
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? _accentColor.withValues(alpha: 0.1)
                            : AppTheme.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isExpanded ? _accentColor : AppTheme.textMuted,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lista de clientes (visible cuando está expandido)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: _buildClientesList(clientes),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
              sizeCurve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientesList(List<Cliente> clientes) {
    if (clientes.isEmpty) {
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_add_alt_1_rounded,
                color: AppTheme.textMuted,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Sin clientes registrados',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.grey.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.background.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: clientes.asMap().entries.map((entry) {
              final index = entry.key;
              final cliente = entry.value;
              return _ClienteListTile(
                cliente: cliente,
                onTap: () => onClienteTap(cliente),
                isLast: index == clientes.length - 1,
                accentColor: _accentColor,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LIST TILE DE CLIENTE
// ============================================================

class _ClienteListTile extends StatelessWidget {
  final Cliente cliente;
  final VoidCallback onTap;
  final bool isLast;
  final Color accentColor;

  const _ClienteListTile({
    required this.cliente,
    required this.onTap,
    required this.isLast,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final inicial = cliente.nombre.isNotEmpty
        ? cliente.nombre[0].toUpperCase()
        : '?';

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Avatar con inicial
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor.withValues(alpha: 0.2),
                          accentColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        inicial,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Nombre y referencia
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nombre,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (cliente.referencia != null &&
                            cliente.referencia!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            cliente.referencia!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Botón de cobrar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.efectivo,
                          AppTheme.efectivo.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.efectivo.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Cobrar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Container(
            margin: const EdgeInsets.only(left: 70),
            height: 1,
            color: Colors.grey.withValues(alpha: 0.1),
          ),
      ],
    );
  }
}

// ============================================================
// ESTADO VACÍO
// ============================================================

class _EmptyRecintosState extends StatelessWidget {
  const _EmptyRecintosState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.15),
                    AppTheme.primary.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.store_mall_directory_rounded,
                size: 48,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Sin recintos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Crea recintos desde el tab "Recintos"\npara comenzar a cobrar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tip: Ve al tab Recintos →',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
}
