import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_theme.dart';
import '../../clientes/widgets/importar_clientes_sheet.dart';

/// Sección del header con diseño moderno
class HeaderSection extends StatelessWidget {
  final int total;
  final int activos;

  const HeaderSection({super.key, required this.total, required this.activos});

  int get _inactivos => total - activos;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleSection(onImportPressed: () => _mostrarImportarSheet(context)),
          const SizedBox(height: 20),
          _StatsRow(total: total, activos: activos, inactivos: _inactivos),
        ],
      ),
    );
  }

  void _mostrarImportarSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ImportarClientesSheet(),
    );
  }
}

/// Título y subtítulo del header con botón de importar
class _TitleSection extends StatelessWidget {
  final VoidCallback onImportPressed;

  const _TitleSection({required this.onImportPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icono con gradiente azul
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F4C75), Color(0xFF1B262C)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F4C75).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_city_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        // Título
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recintos',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Gestiona tus lugares de cobro',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        // Botón de importar
        _ImportButton(onPressed: onImportPressed),
      ],
    );
  }
}

/// Botón para importar clientes desde CSV
class _ImportButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ImportButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F4C75).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF0F4C75).withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.upload_file_rounded,
                color: const Color(0xFF0F4C75),
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                'Importar',
                style: TextStyle(
                  color: Color(0xFF0F4C75),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila de estadísticas con mini cards
class _StatsRow extends StatelessWidget {
  final int total;
  final int activos;
  final int inactivos;

  const _StatsRow({
    required this.total,
    required this.activos,
    required this.inactivos,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total',
            value: '$total',
            icon: Icons.business_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF0F4C75), Color(0xFF1B262C)],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Activos',
            value: '$activos',
            icon: Icons.check_circle_outline_rounded,
            color: AppTheme.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Inactivos',
            value: '$inactivos',
            icon: Icons.pause_circle_outline_rounded,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Card individual de estadística
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final LinearGradient? gradient;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final hasGradient = gradient != null;
    final displayColor = color ?? Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: hasGradient ? gradient : null,
        color: hasGradient ? null : displayColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: hasGradient
            ? null
            : Border.all(color: displayColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: hasGradient
                    ? Colors.white.withValues(alpha: 0.8)
                    : displayColor,
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: hasGradient ? Colors.white : displayColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: hasGradient
                  ? Colors.white.withValues(alpha: 0.7)
                  : AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
