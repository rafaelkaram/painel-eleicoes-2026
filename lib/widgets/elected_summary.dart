import 'package:flutter/material.dart';

import '../models/governor_race.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';
import '../theme/party_colors.dart';
import '../util/formatters.dart';
import 'candidate_avatar.dart';

/// Faixa compacta com quem já está eleito.
///
/// No 2º turno é o resumo do que já foi decidido: rosto, UF e partido, sem
/// barra nem percentual. O detalhe fica para os cards de quem ainda disputa.
class ElectedSummary extends StatelessWidget {
  const ElectedSummary({
    super.key,
    required this.races,
    this.title = 'JÁ ELEITOS NO 1º TURNO',
  });

  final List<GovernorRace> races;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (races.isEmpty) return const SizedBox.shrink();

    final ordenadas = [...races]
      ..sort((a, b) => b.electorate.compareTo(a.electorate));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.xlAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          Row(
            children: [
              Icon(Icons.verified, size: 16, color: context.election.leader),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: context.text.labelSmall?.copyWith(
                    color: context.election.leader,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${races.length} de 27',
                style: context.text.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [for (final race in ordenadas) _ElectedChip(race: race)],
          ),
        ],
      ),
    );
  }
}

class _ElectedChip extends StatelessWidget {
  const _ElectedChip({required this.race});

  final GovernorRace race;

  @override
  Widget build(BuildContext context) {
    final cor = PartyColors.isKnown(race.leader.party)
        ? PartyColors.of(race.leader.party)
        : context.election.leader;

    return Tooltip(
      message:
          '${race.name}\n${race.leader.name} '
          '(${race.leader.party}) — ${formatPercentual(race.leader.share)}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs,
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: cor.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CandidateAvatar(
              name: race.leader.name,
              color: cor,
              portrait: race.leader.portrait,
              size: 26,
            ),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.xs,
                  children: [
                    Text(
                      race.uf,
                      style: context.text.labelSmall?.copyWith(
                        color: cor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Text(
                        race.leader.name,
                        style: context.text.labelMedium?.copyWith(
                          color: context.colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  race.leader.party,
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
