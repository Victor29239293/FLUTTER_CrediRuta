import 'package:flutter/material.dart';

import '../../../../config/theme/app_theme.dart';

/// Estado vacío cuando no hay recintos registrados
class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(),
            const SizedBox(height: 28),
            _buildTitle(),
            const SizedBox(height: 10),
            _buildSubtitle(),
            const SizedBox(height: 24),
            _buildHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F4C75).withValues(alpha: 0.08),
            const Color(0xFF1B262C).withValues(alpha: 0.05),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF0F4C75).withValues(alpha: 0.1),
        ),
      ),
      child: Icon(
        Icons.location_city_rounded,
        size: 52,
        color: const Color(0xFF0F4C75).withValues(alpha: 0.6),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Sin recintos',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Agrega tus lugares de cobro para\norganizar mejor tu trabajo',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: AppTheme.textSecondary,
        height: 1.5,
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F4C75).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0F4C75).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 16,
            color: const Color(0xFF0F4C75),
          ),
          const SizedBox(width: 8),
          Text(
            'Toca "Nuevo Recinto" para comenzar',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF0F4C75),
            ),
          ),
        ],
      ),
    );
  }
}
