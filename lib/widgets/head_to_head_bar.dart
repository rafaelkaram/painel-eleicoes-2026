import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../models/candidate_tally.dart';
import '../models/demo_tallies.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_extensions.dart';
import '../util/formatters.dart';

/// Barra comparativa entre os dois candidatos, com a diferença nominal.
///
/// Tudo é derivado de [leading] e [runnerUp] — a diferença não entra como
/// parâmetro próprio para não haver como exibir um número que não fecha com
/// os votos exibidos logo acima.
class HeadToHeadBar extends StatelessWidget {
  const HeadToHeadBar({
    super.key,
    required this.leading,
    required this.runnerUp,
    this.leadingColor,
    this.runnerUpColor,
  });

  final CandidateTally leading;
  final CandidateTally runnerUp;

  /// Cores de legenda. Nulas, caem na semântica de líder e segundo.
  final Color? leadingColor;
  final Color? runnerUpColor;

  /// Abaixo disso os três rótulos não cabem na mesma linha.
  static const _singleRowBreakpoint = 720.0;

  int get _difference => leading.votes - runnerUp.votes;

  @override
  Widget build(BuildContext context) {
    final leaderColor = leadingColor ?? context.election.leader;
    final runnerColor = runnerUpColor ?? context.election.contested;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.xlAll,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final side = [
                _SideLabel(
                  text:
                      '${leading.name.toUpperCase()} (${leading.number}) '
                      '— ${formatPercentual(leading.share)}',
                  color: leaderColor,
                  dotFirst: true,
                ),
                _SideLabel(
                  text:
                      '${formatPercentual(runnerUp.share)} — '
                      '${runnerUp.name.toUpperCase()} (${runnerUp.number})',
                  color: runnerColor,
                  dotFirst: false,
                ),
              ];
              final gap = Text(
                'DIFERENÇA: ${formatVotos(_difference.abs())} VOTOS',
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );

              if (constraints.maxWidth < _singleRowBreakpoint) {
                return Column(
                  spacing: AppSpacing.xs,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: side,
                    ),
                    gap,
                  ],
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  side[0],
                  Flexible(child: gap),
                  side[1],
                ],
              );
            },
          ),
          _SplitBar(
            leadingShare: leading.share,
            runnerUpShare: runnerUp.share,
            leaderColor: leaderColor,
            runnerColor: runnerColor,
          ),
          _Footnotes(leading: leading, runnerUp: runnerUp),
        ],
      ),
    );
  }
}

class _SideLabel extends StatelessWidget {
  const _SideLabel({
    required this.text,
    required this.color,
    required this.dotFirst,
  });

  final String text;
  final Color color;
  final bool dotFirst;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
    final label = Flexible(
      child: Text(
        text,
        style: context.text.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: dotFirst ? [dot, label] : [label, dot],
      ),
    );
  }
}

/// Trilho único dividido entre os dois candidatos, proporcional aos votos.
class _SplitBar extends StatelessWidget {
  const _SplitBar({
    required this.leadingShare,
    required this.runnerUpShare,
    required this.leaderColor,
    required this.runnerColor,
  });

  final double leadingShare;
  final double runnerUpShare;
  final Color leaderColor;
  final Color runnerColor;

  @override
  Widget build(BuildContext context) {
    // Flex é inteiro: a resolução de milésimo evita arredondar duas fatias
    // quase iguais para o mesmo valor.
    final leftFlex = (leadingShare * 1000).round().clamp(1, 1000);
    final rightFlex = (runnerUpShare * 1000).round().clamp(1, 1000);

    return Container(
      height: 16,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: leftFlex,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: leaderColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(9999),
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            flex: rightFlex,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: runnerColor,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(9999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footnotes extends StatelessWidget {
  const _Footnotes({required this.leading, required this.runnerUp});

  final CandidateTally leading;
  final CandidateTally runnerUp;

  @override
  Widget build(BuildContext context) {
    final muted = context.text.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            '${formatVotos(leading.votes)} votos',
            style: muted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: Text(
            '50,00% Linha de Equilíbrio',
            style: muted?.copyWith(
              color: context.colors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: Text(
            '${formatVotos(runnerUp.votes)} votos',
            style: muted,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// --- Previews ---------------------------------------------------------

/// Envelope das previews. Público e top-level por exigência do `@Preview`.
Widget headToHeadPreviewWrapper(Widget child) {
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
  name: 'Barra comparativa',
  group: 'Apuração',
  size: Size(1100, 160),
  brightness: Brightness.dark,
  wrapper: headToHeadPreviewWrapper,
)
Widget headToHeadBarPreview() {
  return const HeadToHeadBar(
    leading: DemoTallies.leading,
    runnerUp: DemoTallies.runnerUp,
  );
}

@Preview(
  name: 'Barra comparativa — estreita e empatada',
  group: 'Apuração',
  size: Size(560, 200),
  brightness: Brightness.dark,
  wrapper: headToHeadPreviewWrapper,
)
Widget headToHeadBarTightPreview() {
  return const HeadToHeadBar(
    leading: DemoTallies.photoFinishLeading,
    runnerUp: DemoTallies.photoFinishRunnerUp,
  );
}
