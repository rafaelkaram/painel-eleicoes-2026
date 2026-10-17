import 'package:flutter/material.dart';

import '../data/tse_mapper.dart';
import '../data/tse_payload.dart';
import '../widgets/territory_map.dart';
import '../state/apuracao_controller.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';
import '../theme/party_colors.dart';
import '../widgets/candidate_card.dart';
import '../widgets/head_to_head_bar.dart';
import '../widgets/overseas_panel.dart';
import '../widgets/totalization_header.dart';
import '../widgets/vote_breakdown_tiles.dart';

/// `/apuracao` — totalização presidencial, com dado oficial do TSE.
class ApuracaoPresidencialScreen extends StatelessWidget {
  const ApuracaoPresidencialScreen({super.key});

  /// Breakpoint `lg` do design: abaixo disso os cards empilham.
  static const _twoColumnBreakpoint = 1024.0;

  @override
  Widget build(BuildContext context) {
    final controller = ApuracaoScope.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.marginLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.lg,
        children: switch (controller.status) {
          LoadStatus.idle || LoadStatus.loading => const [_Carregando()],
          LoadStatus.failed => [
            _Falhou(
              mensagem: controller.error ?? 'Falha desconhecida',
              onRetry: controller.load,
            ),
          ],
          LoadStatus.ready => _conteudo(context, controller),
        },
      ),
    );
  }

  List<Widget> _conteudo(BuildContext context, ApuracaoController controller) {
    final resultado = controller.result!;
    final candidatos = TseMapper.topTwo(resultado, eleicao: controller.eleicao);

    // Cada candidato sai na cor do próprio partido. Quando as duas siglas
    // forem da mesma família cromática, a do segundo é afastada.
    final (corLider, corVice) = candidatos.length == 2
        ? PartyColors.pairFor(
            candidatos[0].identity.party ?? '',
            candidatos[1].identity.party ?? '',
            leaderFallback: context.election.leader,
            runnerUpFallback: context.election.contested,
          )
        : (context.election.leader, context.election.contested);

    return [
      TotalizationHeader(
        scope: 'ELEIÇÕES GERAIS BRASIL 2026',
        status: 'TOTALIZAÇÃO NACIONAL OFICIAL',
        title: 'Eleição Presidencial 2026',
        subtitle: controller.turno.label,
        urnsCounted: resultado.sections.countedShare,
        live: !controller.awaitingCount,
      ),
      _Procedencia(resultado: resultado),
      if (controller.awaitingCount)
        _AguardandoApuracao(turno: controller.turno.label)
      else
        VoteBreakdownTiles(items: TseMapper.breakdown(resultado)),
      if (candidatos.length == 2) ...[
        LayoutBuilder(
          builder: (context, constraints) {
            final lider = CandidateCard(
              tally: candidatos[0],
              partyColor: corLider,
            );
            final vice = CandidateCard(
              tally: candidatos[1],
              partyColor: corVice,
            );
            if (constraints.maxWidth < _twoColumnBreakpoint) {
              return Column(
                spacing: AppSpacing.gutterLarge,
                children: [lider, vice],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.gutterLarge,
              children: [
                Expanded(child: lider),
                Expanded(child: vice),
              ],
            );
          },
        ),
        if (!controller.awaitingCount)
          HeadToHeadBar(
            leading: candidatos[0],
            runnerUp: candidatos[1],
            leadingColor: corLider,
            runnerUpColor: corVice,
          ),
      ],
      _TerritoryAndOverseas(
        controller: controller,
        leaderColor: corLider,
        runnerUpColor: corVice,
        leaderLabel: candidatos.isEmpty
            ? 'CAND A'
            : candidatos[0].name.split(' ').first.toUpperCase(),
        runnerUpLabel: candidatos.length < 2
            ? 'CAND B'
            : candidatos[1].name.split(' ').first.toUpperCase(),
      ),
    ];
  }
}

/// Carimbo de origem da carga.
class _Procedencia extends StatelessWidget {
  const _Procedencia({required this.resultado});

  final TseResult resultado;

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
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.xs,
            children: [
              Icon(Icons.verified_user, size: 14, color: accent),
              Text(
                'DADO OFICIAL DO TSE — ARQUIVO ASSINADO (EdDSA)',
                style: context.text.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            'eleição ${resultado.eleicao} • gerado em ${resultado.generatedAt}',
            style: context.text.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Carregando extends StatelessWidget {
  const _Carregando();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.md,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.election.leader,
            ),
          ),
          Text(
            'Buscando a totalização no TSE…',
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Falhou extends StatelessWidget {
  const _Falhou({required this.mensagem, required this.onRetry});

  final String mensagem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.xlAll,
        border: Border.all(
          color: context.election.alert.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.sm,
            children: [
              Icon(Icons.cloud_off, size: 18, color: context.election.alert),
              Text(
                'NÃO FOI POSSÍVEL CARREGAR A APURAÇÃO',
                style: context.text.labelSmall?.copyWith(
                  color: context.election.alert,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            mensagem,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('TENTAR DE NOVO'),
          ),
        ],
      ),
    );
  }
}

/// Turno publicado pelo TSE, mas sem nenhuma seção totalizada ainda.
class _AguardandoApuracao extends StatelessWidget {
  const _AguardandoApuracao({required this.turno});

  final String turno;

  @override
  Widget build(BuildContext context) {
    final accent = context.election.contested;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          Icon(Icons.hourglass_empty, size: 16, color: accent),
          Flexible(
            child: Text(
              '$turno ainda sem seção totalizada — os candidatos abaixo são '
              'os que o TSE já classificou.',
              style: context.text.labelSmall?.copyWith(color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha de baixo: mapa territorial e votação no exterior.
///
/// O mapa já roda com as 27 cargas reais do TSE. O painel do exterior
/// continua em dado de exemplo: depende da abrangência ZZ, que é outra
/// carga.
class _TerritoryAndOverseas extends StatelessWidget {
  const _TerritoryAndOverseas({
    required this.controller,
    required this.leaderLabel,
    required this.runnerUpLabel,
    required this.leaderColor,
    required this.runnerUpColor,
  });

  final ApuracaoController controller;
  final String leaderLabel;
  final String runnerUpLabel;
  final Color leaderColor;
  final Color runnerUpColor;

  static const _twoColumnBreakpoint = 1024.0;

  @override
  Widget build(BuildContext context) {
    final estados = controller.states;
    final territory = estados.isEmpty
        ? _MapaCarregando(pendente: controller.detailsPending)
        : TerritoryMap(
            states: estados,
            leaderLabel: leaderLabel,
            runnerUpLabel: runnerUpLabel,
            leaderColor: leaderColor,
            runnerUpColor: runnerUpColor,
          );
    final exterior = controller.overseas;
    final overseas = exterior == null
        ? _ExteriorPendente(pendente: controller.detailsPending)
        : OverseasPanel(tally: exterior);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < _twoColumnBreakpoint) {
              return Column(
                spacing: AppSpacing.gutterLarge,
                children: [territory, overseas],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.gutterLarge,
              children: [
                Expanded(flex: 8, child: territory),
                Expanded(flex: 4, child: overseas),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Espaço do painel do exterior enquanto a carga da Zona ZZ não chega.
class _ExteriorPendente extends StatelessWidget {
  const _ExteriorPendente({required this.pendente});

  final bool pendente;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.xlAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          if (pendente)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.election.leader,
              ),
            )
          else
            Icon(
              Icons.public_off,
              size: 16,
              color: context.colors.onSurfaceVariant,
            ),
          Flexible(
            child: Text(
              pendente
                  ? 'Buscando a votação no exterior…'
                  : 'Zona ZZ sem carga publicada para este turno.',
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Espaço do mapa enquanto as 27 cargas não chegam.
class _MapaCarregando extends StatelessWidget {
  const _MapaCarregando({required this.pendente});

  final bool pendente;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.xlAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          if (pendente)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.election.leader,
              ),
            )
          else
            Icon(
              Icons.map_outlined,
              size: 16,
              color: context.colors.onSurfaceVariant,
            ),
          Text(
            pendente
                ? 'Buscando a apuração das 27 unidades federativas…'
                : 'Nenhuma unidade federativa com carga publicada.',
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
