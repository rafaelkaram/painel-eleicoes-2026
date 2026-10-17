import 'package:flutter/material.dart';

import '../routing/app_destination.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';

/// Conteúdo provisório de uma tela cujo layout ainda não foi implementado.
///
/// Existe para que a navegação seja verificável de ponta a ponta sem fingir
/// que a tela está pronta. Lista os componentes que o design.md do Stitch
/// especifica para aquela tela — some assim que o layout real entrar.
class PendingScreen extends StatelessWidget {
  const PendingScreen({
    super.key,
    required this.destination,
    required this.planned,
  });

  final AppDestination destination;

  /// Componentes previstos no design para esta tela.
  final List<String> planned;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.marginLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.lg,
        children: [
          Text(destination.title, style: context.text.headlineLarge),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.sm,
            children: [
              Icon(
                Icons.construction_outlined,
                size: 16,
                color: context.election.contested,
              ),
              Text(
                'LAYOUT NÃO IMPLEMENTADO',
                style: context.text.labelSmall?.copyWith(
                  color: context.election.contested,
                ),
              ),
            ],
          ),
          PlannedItemsCard(planned: planned),
        ],
      ),
    );
  }
}

/// Lista o que o design prevê para um trecho que ainda não foi construído.
class PlannedItemsCard extends StatelessWidget {
  const PlannedItemsCard({super.key, required this.planned, this.title});

  final List<String> planned;

  /// Cabeçalho do card. Por padrão, `PREVISTO NO DESIGN`.
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Text(
              title ?? 'PREVISTO NO DESIGN',
              style: context.text.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            for (final item in planned)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.sm,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.colors.outline,
                        borderRadius: AppRadius.pill,
                      ),
                    ),
                  ),
                  Expanded(child: Text(item, style: context.text.bodyMedium)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
