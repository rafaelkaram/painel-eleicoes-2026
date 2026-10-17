import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../models/demo_races.dart';
import '../models/governor_race.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_extensions.dart';
import '../theme/party_colors.dart';
import '../util/formatters.dart';
import 'candidate_avatar.dart';
import 'pulse_dot.dart';

/// Card de uma disputa estadual pelo governo.
class GovernorRaceCard extends StatelessWidget {
  const GovernorRaceCard({super.key, required this.race});

  final GovernorRace race;

  @override
  Widget build(BuildContext context) {
    // Cada candidato sai na cor do seu partido. Quando as duas legendas são
    // da mesma família — azul contra azul é comum no Brasil — a do segundo
    // é afastada, senão a barra vira um bloco só.
    final (leaderColor, runnerUpColor) = PartyColors.pairFor(
      race.leader.party,
      race.runnerUp.party,
      leaderFallback: context.election.leader,
      runnerUpFallback: context.election.contested,
    );

    // Disputa decidida ganha moldura e brilho na cor do vencedor. É o
    // estado final: merece separar-se visualmente do que ainda corre.
    final eleito = race.status == RaceStatus.elected;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.xlAll,
        border: eleito
            ? Border.all(color: leaderColor.withValues(alpha: 0.55))
            : null,
        boxShadow: eleito
            ? [
                BoxShadow(
                  color: leaderColor.withValues(alpha: 0.14),
                  blurRadius: 18,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(race: race),
          const SizedBox(height: AppSpacing.md),
          _CountedBox(race: race),
          const SizedBox(height: AppSpacing.md),
          _CandidateLine(
            candidate: race.leader,
            color: leaderColor,
            winner: eleito,
          ),
          const SizedBox(height: AppSpacing.xs),
          _SplitBar(
            race: race,
            leaderColor: leaderColor,
            runnerUpColor: runnerUpColor,
            // Disputa encerrada: a fatia do derrotado recua para o vencedor
            // ficar sozinho em primeiro plano.
            dimRunnerUp: eleito,
          ),
          const SizedBox(height: AppSpacing.xs),
          _CandidateLine(
            candidate: race.runnerUp,
            color: runnerUpColor,
            defeated: eleito,
          ),
          const SizedBox(height: AppSpacing.md),
          _Footnote(race: race),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.race});

  final GovernorRace race;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHigh,
            borderRadius: AppRadius.lgAll,
          ),
          child: Text(
            race.uf,
            style: context.text.labelLarge?.copyWith(
              color: context.colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                race.name,
                style: context.text.headlineSmall?.copyWith(height: 1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${formatVotos(race.electorate)} eleitores aptos',
                style: context.text.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatusChip(status: race.status),
      ],
    );
  }
}

/// Chip de situação. Disputa aberta pulsa; encerrada leva selo.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final RaceStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      RaceStatus.elected => (
        context.colors.primaryContainer,
        context.colors.onPrimaryContainer,
      ),
      RaceStatus.leading => (
        context.colors.surfaceContainerHigh,
        context.election.leader,
      ),
      RaceStatus.tooCloseToCall => (
        context.colors.surfaceContainerHigh,
        context.election.contested,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.baseAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          if (status == RaceStatus.elected)
            Icon(Icons.check_circle, size: 13, color: foreground)
          else
            PulseDot(color: foreground, size: 6),
          Text(
            status.chipLabel.toUpperCase(),
            style: context.text.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountedBox extends StatelessWidget {
  const _CountedBox({required this.race});

  final GovernorRace race;

  @override
  Widget build(BuildContext context) {
    final encerrada = race.status == RaceStatus.elected;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  encerrada ? 'TOTALIZAÇÃO CONCLUÍDA' : 'SEÇÕES TOTALIZADAS',
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                formatPercentual(race.countedShare),
                style: context.stats.statMetric.copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: AppRadius.pill,
            child: LinearProgressIndicator(
              value: race.countedShare,
              minHeight: 6,
              color: context.election.leader,
              backgroundColor: context.colors.surfaceContainerHigh,
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateLine extends StatelessWidget {
  const _CandidateLine({
    required this.candidate,
    required this.color,
    this.winner = false,
    this.defeated = false,
  });

  final GovernorCandidate candidate;
  final Color color;

  /// Vencedor de uma disputa encerrada: faixa tingida, selo e rosto maior.
  final bool winner;

  /// Derrotado de uma disputa encerrada: recua para o segundo plano.
  final bool defeated;

  @override
  Widget build(BuildContext context) {
    final linha = Row(
      children: [
        CandidateAvatar(
          name: candidate.name,
          color: color,
          portrait: candidate.portrait,
          size: winner ? 34 : 28,
        ),
        const SizedBox(width: avatarGap),
        Flexible(
          child: Text(
            candidate.name,
            style: winner
                ? context.text.titleSmall?.copyWith(
                    color: context.colors.onSurface,
                  )
                : context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            candidate.party,
            style: context.text.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (winner) ...[
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.emoji_events, size: 15, color: color),
        ],
        const SizedBox(width: AppSpacing.sm),
        Text(
          formatPercentual(candidate.share),
          style:
              (winner
                      ? context.stats.statDisplay.copyWith(fontSize: 22)
                      : context.stats.statMetric)
                  .copyWith(color: color, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 4),
        Text(
          '(${formatVotos(candidate.votes)})',
          style: context.text.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );

    if (winner) {
      // Faixa tingida com uma barra de acento à esquerda: o vencedor sai
      // do mesmo plano do adversário sem precisar gritar.
      return Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.lgAll,
        ),
        child: linha,
      );
    }

    if (defeated) {
      // Derrotado recua, mas continua legível: quem perdeu e por quanto é
      // parte do resultado.
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Opacity(opacity: 0.6, child: linha),
      );
    }

    return linha;
  }
}

/// Trilho único dividido entre os dois candidatos.
class _SplitBar extends StatelessWidget {
  const _SplitBar({
    required this.race,
    required this.leaderColor,
    required this.runnerUpColor,
    this.dimRunnerUp = false,
  });

  final GovernorRace race;
  final Color leaderColor;
  final Color runnerUpColor;

  /// Esmaece a fatia do derrotado numa disputa já encerrada.
  final bool dimRunnerUp;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.pill,
      child: SizedBox(
        height: 12,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: (race.leader.share * 1000).round().clamp(1, 1000),
              child: ColoredBox(color: leaderColor),
            ),
            Expanded(
              flex: (race.runnerUp.share * 1000).round().clamp(1, 1000),
              child: ColoredBox(
                color: dimRunnerUp
                    ? runnerUpColor.withValues(alpha: 0.45)
                    : runnerUpColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote({required this.race});

  final GovernorRace race;

  @override
  Widget build(BuildContext context) {
    final encerrada = race.status == RaceStatus.elected;
    final muted = context.text.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    return Row(
      children: [
        if (encerrada) ...[
          Icon(Icons.verified, size: 14, color: context.election.leader),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            race.status.footnoteLabel,
            style: encerrada
                ? context.text.labelSmall?.copyWith(
                    color: context.election.leader,
                    fontWeight: FontWeight.w600,
                  )
                : muted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          formatDiferenca(race.voteGap),
          style: context.stats.statMetric.copyWith(
            color: context.colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          race.status == RaceStatus.tooCloseToCall
              ? 'votos (${formatPercentualCurto(race.margin)})'
              : 'votos',
          style: muted,
        ),
      ],
    );
  }
}

// --- Previews ---------------------------------------------------------

/// Envelope das previews. Público e top-level por exigência do `@Preview`.
Widget racePreviewWrapper(Widget child) {
  return Theme(
    data: AppTheme.dark,
    child: Material(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(child: child),
      ),
    ),
  );
}

@Preview(
  name: 'Disputa — liderando',
  group: 'Governadores',
  size: Size(520, 300),
  brightness: Brightness.dark,
  wrapper: racePreviewWrapper,
)
Widget raceCardLeadingPreview() {
  return GovernorRaceCard(race: DemoRaces.all.first);
}

@Preview(
  name: 'Disputa — voto a voto',
  group: 'Governadores',
  size: Size(520, 300),
  brightness: Brightness.dark,
  wrapper: racePreviewWrapper,
)
Widget raceCardTightPreview() {
  return GovernorRaceCard(race: DemoRaces.all.firstWhere((r) => r.uf == 'RS'));
}

@Preview(
  name: 'Disputa — encerrada',
  group: 'Governadores',
  size: Size(520, 300),
  brightness: Brightness.dark,
  wrapper: racePreviewWrapper,
)
Widget raceCardElectedPreview() {
  return GovernorRaceCard(race: DemoRaces.all.firstWhere((r) => r.uf == 'SC'));
}

@Preview(
  name: 'Disputa — coluna estreita, nomes longos',
  group: 'Governadores',
  size: Size(360, 320),
  brightness: Brightness.dark,
  wrapper: racePreviewWrapper,
)
Widget raceCardNarrowPreview() {
  return SizedBox(
    width: 320,
    child: GovernorRaceCard(
      race: DemoRaces.all.firstWhere((r) => r.uf == 'PE'),
    ),
  );
}
