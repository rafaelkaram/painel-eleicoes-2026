import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../models/demo_tallies.dart';
import '../models/vote_breakdown.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_extensions.dart';
import '../util/formatters.dart';

/// Linha de tiles com o resumo de votos: válidos, nulos, brancos, abstenção.
///
/// Quatro colunas em tela larga, duas abaixo do breakpoint `md` do design.
class VoteBreakdownTiles extends StatelessWidget {
  const VoteBreakdownTiles({super.key, required this.items});

  final List<VoteBreakdown> items;

  /// Breakpoint `md` do design: abaixo disso cai para duas colunas.
  static const _fourColumnBreakpoint = 768.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < _fourColumnBreakpoint ? 2 : 4;
        final gaps = AppSpacing.gutter * (columns - 1);
        final tileWidth = (constraints.maxWidth - gaps) / columns;

        return Wrap(
          spacing: AppSpacing.gutter,
          runSpacing: AppSpacing.gutter,
          children: [
            for (final item in items)
              SizedBox(
                width: tileWidth,
                child: _Tile(item: item),
              ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});

  final VoteBreakdown item;

  @override
  Widget build(BuildContext context) {
    final shareColor = switch (item.tone) {
      VoteBreakdownTone.neutral => context.colors.onSurface,
      VoteBreakdownTone.alert => context.election.alert,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.label,
            style: context.text.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatPercentual(item.share),
                style: context.stats.statMetric.copyWith(color: shareColor),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  formatVotos(item.votes),
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Previews ---------------------------------------------------------

/// Envelope das previews dos tiles. Público e top-level por exigência do
/// `@Preview`.
Widget tilesPreviewWrapper(Widget child) {
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
  name: 'Tiles — quatro colunas',
  group: 'Apuração',
  size: Size(1100, 130),
  brightness: Brightness.dark,
  wrapper: tilesPreviewWrapper,
)
Widget voteBreakdownTilesPreview() {
  return const VoteBreakdownTiles(items: DemoTallies.breakdown);
}

@Preview(
  name: 'Tiles — duas colunas',
  group: 'Apuração',
  size: Size(560, 220),
  brightness: Brightness.dark,
  wrapper: tilesPreviewWrapper,
)
Widget voteBreakdownTilesNarrowPreview() {
  return const VoteBreakdownTiles(items: DemoTallies.breakdown);
}
