import 'package:flutter/material.dart';

import '../models/overseas_tally.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';
import '../theme/party_colors.dart';
import '../util/formatters.dart';
import 'candidate_avatar.dart';

/// Painel da Zona ZZ — eleitorado brasileiro residente fora do país.
class OverseasPanel extends StatelessWidget {
  const OverseasPanel({super.key, required this.tally, this.maxCandidates = 5});

  final OverseasTally tally;

  /// Quantos candidatos listar. O resto vira uma linha de resumo.
  final int maxCandidates;

  @override
  Widget build(BuildContext context) {
    final mostrados = tally.candidates.take(maxCandidates).toList();
    final restantes = tally.candidates.skip(maxCandidates).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.xlAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(tally: tally),
          const SizedBox(height: AppSpacing.md),
          for (final candidato in mostrados) ...[
            _CandidateRow(candidate: candidato),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (restantes.isNotEmpty) _Restantes(candidates: restantes),
          const SizedBox(height: AppSpacing.sm),
          _Total(tally: tally),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.tally});

  final OverseasTally tally;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        Row(
          children: [
            Icon(Icons.public, size: 20, color: context.election.leader),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Votação no Exterior',
                style: context.text.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: tally.isComplete
                    ? context.colors.primaryContainer
                    : context.colors.surfaceContainerHigh,
                borderRadius: AppRadius.baseAll,
              ),
              child: Text(
                '${formatPercentualCurto(tally.countedShare)} APURADO',
                style: context.text.labelSmall?.copyWith(
                  color: tally.isComplete
                      ? context.colors.onPrimaryContainer
                      : context.election.leader,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Text(
          'Zona ZZ — ${formatVotos(tally.sections)} seções • '
          '${formatVotos(tally.electorate)} eleitores aptos',
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({required this.candidate});

  final OverseasCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final cor = PartyColors.isKnown(candidate.party)
        ? PartyColors.of(candidate.party)
        : context.colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: AppRadius.lgAll,
      ),
      child: Row(
        children: [
          CandidateAvatar(
            name: candidate.name,
            color: cor,
            portrait: candidate.identity.portrait,
            size: 26,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  candidate.name,
                  style: context.text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  candidate.party,
                  style: context.text.labelSmall?.copyWith(color: cor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatPercentualCurto(candidate.share),
                style: context.stats.statMetric.copyWith(
                  color: cor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                formatVotos(candidate.votes),
                style: context.text.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Linha única para quem ficou fora da lista.
class _Restantes extends StatelessWidget {
  const _Restantes({required this.candidates});

  final List<OverseasCandidate> candidates;

  @override
  Widget build(BuildContext context) {
    final votos = candidates.fold(0, (total, c) => total + c.votes);
    final fracao = candidates.fold(0.0, (total, c) => total + c.share);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Text(
        'Outras ${candidates.length} candidaturas somam '
        '${formatVotos(votos)} votos (${formatPercentualCurto(fracao)})',
        style: context.text.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.tally});

  final OverseasTally tally;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: AppRadius.lgAll,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'VOTOS VÁLIDOS NO EXTERIOR',
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  formatVotos(tally.validVotes),
                  style: context.text.labelLarge?.copyWith(
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'COMPARECIMENTO',
                style: context.text.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              Text(
                '${formatPercentualCurto(tally.turnoutShare)} • '
                '${formatVotos(tally.turnout)}',
                style: context.text.labelMedium?.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
