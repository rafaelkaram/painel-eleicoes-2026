import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../models/candidate_tally.dart';
import '../models/demo_tallies.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_extensions.dart';
import '../util/formatters.dart';

/// Card de candidato da tela de Apuração Presidencial.
///
/// Reproduz o componente da tela do Stitch: selo do número sobre a foto,
/// chip de status em pílula, percentual em `stat-display`, votos em
/// `stat-metric` e barra de progresso de 12px. O acento cromático sai de
/// [CandidateTally.standing] — verde para o líder, âmbar para o segundo.
class CandidateCard extends StatelessWidget {
  const CandidateCard({
    super.key,
    required this.tally,
    this.partyColor,
    this.awaitingCount = false,
  });

  final CandidateTally tally;

  /// Cor da legenda partidária. Quando nula, o card usa a cor semântica de
  /// líder ou segundo colocado — é o que acontece quando o cadastro não
  /// trouxe sigla.
  final Color? partyColor;

  /// `true` quando o pleito ainda não teve nenhuma seção totalizada.
  ///
  /// Nesse estado o card não enuncia posição: "empate técnico" e "2º
  /// colocado" saem de uma ordenação entre dois zeros, e num turno que
  /// sequer começou isso é afirmar resultado onde não há nenhum.
  ///
  /// Vem do controlador, não dos votos do próprio candidato: numa noite de
  /// apuração de verdade um lado pode estar zerado com urna já aberta, e aí
  /// 2º colocado é informação legítima.
  final bool awaitingCount;

  @override
  Widget build(BuildContext context) {
    // A cor do partido manda no número, na barra e no selo. A situação
    // (liderando, 2º colocado) continua no verde e âmbar do painel: são
    // coisas diferentes e não podem se confundir.
    final status = tally.isLeading
        ? context.election.leader
        : context.election.contested;
    final accent = partyColor ?? status;
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? context.colors.onSurface
        : context.colors.surfaceContainerLowest;

    return ClipRRect(
      borderRadius: AppRadius.xlAll,
      child: ColoredBox(
        color: context.colors.surfaceContainerLow,
        child: Stack(
          children: [
            // Luminescência de canto do design — gradiente radial em vez de
            // blur real: mesmo resultado visual por uma fração do custo de
            // composição no canvas web.
            Positioned(
              top: -48,
              right: -48,
              child: IgnorePointer(
                child: Container(
                  width: 192,
                  height: 192,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accent.withValues(alpha: 0.10),
                        accent.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.md,
                children: [
                  _Identification(
                    tally: tally,
                    accent: accent,
                    onAccent: onAccent,
                    status: status,
                    awaitingCount: awaitingCount,
                  ),
                  _Tally(tally: tally, accent: accent),
                  _ShareBar(share: tally.share, accent: accent),
                  _Footer(
                    tally: tally,
                    accent: accent,
                    awaitingCount: awaitingCount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Identification extends StatelessWidget {
  const _Identification({
    required this.tally,
    required this.accent,
    required this.onAccent,
    required this.status,
    required this.awaitingCount,
  });

  final CandidateTally tally;
  final Color accent;
  final Color onAccent;
  final Color status;
  final bool awaitingCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BallotPhoto(
          number: tally.number,
          accent: accent,
          onAccent: onAccent,
          portrait: tally.portrait,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tally.name,
                style: context.text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                tally.coalition,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (!awaitingCount) ...[
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: _StandingChip(tally: tally, accent: status),
          ),
        ],
      ],
    );
  }
}

/// Foto de urna de 64px com o selo do número encostado no canto.
class _BallotPhoto extends StatelessWidget {
  const _BallotPhoto({
    required this.number,
    required this.accent,
    required this.onAccent,
    required this.portrait,
  });

  final int? number;
  final Color accent;
  final Color onAccent;
  final ImageProvider? portrait;

  @override
  Widget build(BuildContext context) {
    // O selo estoura a moldura da foto, então o Stack não pode cortar.
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHigh,
              borderRadius: AppRadius.xlAll,
              image: portrait == null
                  ? null
                  : DecorationImage(image: portrait!, fit: BoxFit.cover),
            ),
            child: portrait != null
                ? null
                : Icon(
                    Icons.person,
                    size: 32,
                    color: context.colors.onSurfaceVariant,
                  ),
          ),
          if (number != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: _NumberBadge(
                number: number!,
                accent: accent,
                onAccent: onAccent,
              ),
            ),
        ],
      ),
    );
  }
}

/// Selo do número de urna, encostado no canto da foto.
class _NumberBadge extends StatelessWidget {
  const _NumberBadge({
    required this.number,
    required this.accent,
    required this.onAccent,
  });

  final int number;
  final Color accent;
  final Color onAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(color: accent, borderRadius: AppRadius.baseAll),
      child: Text(
        '$number',
        style: context.text.labelMedium?.copyWith(
          color: onAccent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StandingChip extends StatelessWidget {
  const _StandingChip({required this.tally, required this.accent});

  final CandidateTally tally;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          // Só o líder carrega ícone; o chip do segundo é texto puro.
          if (tally.isLeading) Icon(Icons.trending_up, size: 16, color: accent),
          Flexible(
            child: Text(
              tally.standingLabel.toUpperCase(),
              style: context.text.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tally extends StatelessWidget {
  const _Tally({required this.tally, required this.accent});

  final CandidateTally tally;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          formatPercentual(tally.share),
          style: context.stats.statDisplay.copyWith(color: accent),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatVotos(tally.votes),
              style: context.stats.statMetric.copyWith(
                color: context.colors.onSurface,
              ),
            ),
            Text(
              'VOTOS TOTAIS',
              style: context.text.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.share, required this.accent});

  final double share;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.pill,
      child: LinearProgressIndicator(
        value: share,
        minHeight: AppMetrics.candidateProgressHeight,
        color: accent,
        backgroundColor: context.colors.surfaceContainerHighest,
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.tally,
    required this.accent,
    required this.awaitingCount,
  });

  final CandidateTally tally;
  final Color accent;
  final bool awaitingCount;

  @override
  Widget build(BuildContext context) {
    final muted = context.text.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return Row(
      children: [
        // Sem urna apurada não há o que confirmar: o selo verde ao lado de
        // "Aguardando apuração" lia como candidato já eleito.
        if (tally.isLeading && !awaitingCount) ...[
          Icon(Icons.verified, size: 16, color: context.election.leader),
          const SizedBox(width: AppSpacing.xs),
        ],
        Expanded(child: Text(tally.footnote, style: muted)),
        const SizedBox(width: AppSpacing.sm),
        Text(
          tally.statesLabel,
          style: context.text.labelSmall?.copyWith(
            color: context.election.leader,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// --- Previews ---------------------------------------------------------
// Rode com `flutter widget-preview start`, ou use o painel "Flutter Widget
// Preview" do VS Code.

/// Envelope comum das previews do painel: tema dark do projeto sobre a
/// superfície certa. Precisa ser público e top-level — o `@Preview` só
/// aceita callback constante e não privado.
Widget painelPreviewWrapper(Widget child) {
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
  name: 'Líder',
  group: 'Apuração',
  size: Size(620, 280),
  brightness: Brightness.dark,
  wrapper: painelPreviewWrapper,
)
Widget candidateCardLeadingPreview() {
  return const CandidateCard(tally: DemoTallies.leading);
}

@Preview(
  name: 'Segundo colocado',
  group: 'Apuração',
  size: Size(620, 280),
  brightness: Brightness.dark,
  wrapper: painelPreviewWrapper,
)
Widget candidateCardRunnerUpPreview() {
  return const CandidateCard(tally: DemoTallies.runnerUp);
}

@Preview(
  name: 'Nome longo e margem apertada',
  group: 'Apuração',
  size: Size(520, 280),
  brightness: Brightness.dark,
  wrapper: painelPreviewWrapper,
)
Widget candidateCardOverflowPreview() {
  return const CandidateCard(tally: DemoTallies.stressTest);
}
