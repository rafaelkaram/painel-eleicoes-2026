import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_extensions.dart';
import '../util/formatters.dart';
import 'pulse_dot.dart';

/// Faixa de abertura da tela de apuração: escopo, título do pleito e o
/// medidor de urnas totalizadas.
class TotalizationHeader extends StatelessWidget {
  const TotalizationHeader({
    super.key,
    required this.scope,
    required this.status,
    required this.title,
    required this.subtitle,
    required this.urnsCounted,
    this.live = true,
  });

  /// Ex.: `ELEIÇÕES GERAIS BRASIL 2026`.
  final String scope;

  /// Ex.: `TOTALIZAÇÃO NACIONAL OFICIAL`. Sai em verde.
  final String status;

  /// Ex.: `Eleição Presidencial 2026`.
  final String title;

  /// Ex.: `2º Turno`. Entra na mesma linha do título, com peso menor.
  final String subtitle;

  /// Fração de urnas já totalizadas, de 0 a 1.
  final double urnsCounted;

  /// Com o feed parado o pulso some.
  final bool live;

  /// Abaixo disso o medidor desce para a linha de baixo.
  static const _rowBreakpoint = 768.0;

  @override
  Widget build(BuildContext context) {
    final heading = _Heading(
      scope: scope,
      status: status,
      title: title,
      subtitle: subtitle,
    );
    final gauge = _UrnGauge(counted: urnsCounted, live: live);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _rowBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.md,
            children: [heading, gauge],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: heading),
            const SizedBox(width: AppSpacing.md),
            gauge,
          ],
        );
      },
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.scope,
    required this.status,
    required this.title,
    required this.subtitle,
  });

  final String scope;
  final String status;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final muted = context.text.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: AppSpacing.xs,
          children: [
            Flexible(child: Text(scope, style: muted, softWrap: false)),
            Text('•', style: muted),
            Flexible(
              child: Text(
                status,
                style: context.text.labelSmall?.copyWith(
                  color: context.election.leader,
                  fontWeight: FontWeight.w700,
                ),
                softWrap: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: title, style: context.text.headlineLarge),
              TextSpan(
                text: ' / $subtitle',
                style: context.text.headlineMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Medidor de urnas totalizadas.
class _UrnGauge extends StatelessWidget {
  const _UrnGauge({required this.counted, required this.live});

  final double counted;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final accent = context.election.leader;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: AppRadius.lgAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.md,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.xs,
                children: [
                  PulseDot(color: accent, active: live),
                  Text(
                    'TOTAL DE URNAS',
                    style: context.text.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                '${formatPercentual(counted)} APURADAS',
                style: context.stats.statMetric.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(
            width: 96,
            child: ClipRRect(
              borderRadius: AppRadius.pill,
              child: LinearProgressIndicator(
                value: counted,
                minHeight: AppMetrics.progressBarHeight,
                color: accent,
                backgroundColor: context.colors.surfaceContainerLowest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Previews ---------------------------------------------------------

/// Envelope das previews do painel. Público e top-level porque `@Preview`
/// só aceita callback constante e não privado.
Widget totalizationPreviewWrapper(Widget child) {
  return Theme(
    data: AppTheme.dark,
    child: Material(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    ),
  );
}

@Preview(
  name: 'Faixa de totalização',
  group: 'Apuração',
  size: Size(1100, 160),
  brightness: Brightness.dark,
  wrapper: totalizationPreviewWrapper,
)
Widget totalizationHeaderPreview() {
  return const TotalizationHeader(
    scope: 'ELEIÇÕES GERAIS BRASIL 2026',
    status: 'TOTALIZAÇÃO NACIONAL OFICIAL',
    title: 'Eleição Presidencial 2026',
    subtitle: '2º Turno',
    urnsCounted: 0.9685,
  );
}

@Preview(
  name: 'Faixa estreita, feed parado',
  group: 'Apuração',
  size: Size(620, 240),
  brightness: Brightness.dark,
  wrapper: totalizationPreviewWrapper,
)
Widget totalizationHeaderNarrowPreview() {
  return const TotalizationHeader(
    scope: 'ELEIÇÕES GERAIS BRASIL 2026',
    status: 'TOTALIZAÇÃO NACIONAL OFICIAL',
    title: 'Eleição Presidencial 2026',
    subtitle: '2º Turno',
    urnsCounted: 0.1204,
    live: false,
  );
}
