import 'package:flutter/material.dart';
import '../../../../config/theme/app_theme.dart';

/// Estado vacío cuando no hay resultados de búsqueda
class NoResultsState extends StatelessWidget {
  final String searchTerm;

  const NoResultsState({super.key, required this.searchTerm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          _buildIcon(Icons.search_off_rounded),
          const SizedBox(height: 24),
          const Text(
            'Sin resultados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No se encontraron cobros para "$searchTerm"',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 40, color: AppTheme.textMuted),
    );
  }
}

/// Estado vacío cuando no hay cobros en la fecha seleccionada
class EmptyState extends StatelessWidget {
  final DateTime fecha;

  const EmptyState({super.key, required this.fecha});

  bool get _isToday {
    final now = DateTime.now();
    return fecha.year == now.year &&
        fecha.month == now.month &&
        fecha.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(),
            const SizedBox(height: 32),
            _buildTitle(),
            const SizedBox(height: 12),
            _buildSubtitle(),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.receipt_long_outlined,
        size: 56,
        color: AppTheme.textMuted,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      _isToday ? 'Sin cobros hoy' : 'Sin cobros',
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      _isToday
          ? 'Comienza registrando tu primer cobro'
          : 'No hay cobros registrados en esta fecha',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 15,
        color: AppTheme.textSecondary,
        height: 1.5,
      ),
    );
  }
}
