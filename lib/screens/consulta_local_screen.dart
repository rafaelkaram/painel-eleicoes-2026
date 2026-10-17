import 'package:flutter/material.dart';

import '../data/tse_lookup.dart';
import '../data/tse_payload.dart';
import '../models/vote_breakdown.dart';
import '../state/consulta_controller.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';
import '../theme/party_colors.dart';
import '../util/formatters.dart';
import '../widgets/candidate_avatar.dart';
import '../widgets/section_selector.dart';
import '../widgets/vote_breakdown_tiles.dart';

/// `/consulta` — localizador de urna e resultado do município.
class ConsultaLocalScreen extends StatelessWidget {
  const ConsultaLocalScreen({super.key});

  /// Abaixo disso os dois painéis empilham.
  static const _twoColumnBreakpoint = 1100.0;

  @override
  Widget build(BuildContext context) {
    final c = ConsultaScope.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.marginLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.lg,
        children: [
          const _Header(),
          if (c.status == ConsultaStatus.failed)
            _Falhou(mensagem: c.error ?? 'Falha desconhecida')
          else ...[
            SectionSelector(steps: _passos(c)),
            LayoutBuilder(
              builder: (context, constraints) {
                final municipio = _MunicipioPanel(controller: c);
                final secao = _SecaoPanel(controller: c);

                if (constraints.maxWidth < _twoColumnBreakpoint) {
                  return Column(
                    spacing: AppSpacing.gutterLarge,
                    children: [municipio, secao],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.gutterLarge,
                  children: [
                    Expanded(flex: 6, child: municipio),
                    Expanded(flex: 4, child: secao),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  List<SelectorStep<String>> _passos(ConsultaController c) {
    return [
      SelectorStep<String>(
        step: 1,
        label: 'Estado (UF)',
        value: c.uf,
        options: {for (final uf in c.lookup.ufs) uf: uf},
        onChanged: c.selectUf,
        loading: c.status == ConsultaStatus.loading,
      ),
      SelectorStep<String>(
        step: 2,
        label: 'Município',
        value: c.municipio,
        options: {for (final m in c.municipalities) m.code: m.name},
        onChanged: c.selectMunicipality,
      ),
      SelectorStep<String>(
        step: 3,
        label: 'Zona Eleitoral',
        value: c.zona,
        options: {for (final z in c.zones) z: 'Zona $z'},
        onChanged: c.selectZone,
      ),
      SelectorStep<String>(
        step: 4,
        label: 'Seção',
        value: c.secao,
        options: {for (final s in c.sections) s.number: 'Seção ${s.number}'},
        onChanged: c.selectSection,
        loading: c.loadingSections,
        emptyHint: 'cadastro de seções indisponível',
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final accent = context.election.leader;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.manage_search, size: 28, color: accent),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Localizador de Urna & Resultado',
                style: context.text.headlineLarge,
              ),
              Text(
                'Como o seu município votou e quando a sua urna transmitiu',
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHigh,
            borderRadius: AppRadius.lgAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.xs,
            children: [
              Icon(Icons.verified, size: 16, color: accent),
              Text(
                'BASE PÚBLICA DO TSE',
                style: context.text.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Painel esquerdo: como o município votou nos dois cargos.
class _MunicipioPanel extends StatelessWidget {
  const _MunicipioPanel({required this.controller});

  final ConsultaController controller;

  @override
  Widget build(BuildContext context) {
    final municipio = controller.currentMunicipality;
    final presidente = controller.presidente;

    if (municipio == null || presidente == null) {
      return _Caixa(
        child: _Aguardando(
          texto: 'Escolha um município para ver a totalização.',
        ),
      );
    }

    return _Caixa(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.md,
        children: [
          _MunicipioHeader(
            nome: municipio.name,
            uf: controller.uf ?? '',
            codigo: municipio.code,
            resultado: presidente,
          ),
          VoteBreakdownTiles(items: _tiles(presidente)),
          _CargoBloco(titulo: 'PRESIDENTE', resultado: presidente),
          if (controller.governador case final g?)
            _CargoBloco(titulo: 'GOVERNADOR', resultado: g),
        ],
      ),
    );
  }

  List<VoteBreakdown> _tiles(TseResult r) => [
    VoteBreakdown(
      label: 'VOTOS VÁLIDOS',
      share: r.votes.validShare,
      votes: r.votes.valid,
    ),
    VoteBreakdown(
      label: 'COMPARECIMENTO',
      share: r.electorate.turnoutShare,
      votes: r.electorate.turnout,
    ),
    VoteBreakdown(
      label: 'ABSTENÇÃO',
      share: r.electorate.abstentionShare,
      votes: r.electorate.abstentions,
      tone: VoteBreakdownTone.alert,
    ),
  ];
}

class _MunicipioHeader extends StatelessWidget {
  const _MunicipioHeader({
    required this.nome,
    required this.uf,
    required this.codigo,
    required this.resultado,
  });

  final String nome;
  final String uf;
  final String codigo;
  final TseResult resultado;

  @override
  Widget build(BuildContext context) {
    final completo = resultado.sections.countedShare >= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.location_city, size: 20, color: context.election.leader),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                '$nome — $uf',
                style: context.text.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: completo
                    ? context.colors.primaryContainer
                    : context.colors.surfaceContainerHigh,
                borderRadius: AppRadius.baseAll,
              ),
              child: Text(
                '${formatPercentualCurto(resultado.sections.countedShare)} '
                'TOTALIZADO',
                style: context.text.labelSmall?.copyWith(
                  color: completo
                      ? context.colors.onPrimaryContainer
                      : context.election.leader,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Código TSE: $codigo • '
          '${formatVotos(resultado.electorate.total)} eleitores aptos • '
          '${formatVotos(resultado.sections.counted)} de '
          '${formatVotos(resultado.sections.total)} seções',
          style: context.text.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Os candidatos de um cargo dentro do município.
class _CargoBloco extends StatelessWidget {
  const _CargoBloco({required this.titulo, required this.resultado});

  final String titulo;
  final TseResult resultado;

  /// Quantos candidatos listar antes de resumir o resto.
  static const _limite = 4;

  @override
  Widget build(BuildContext context) {
    final mostrados = resultado.candidates.take(_limite).toList();
    final restantes = resultado.candidates.skip(_limite).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          Text(
            '$titulo NO MUNICÍPIO',
            style: context.text.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          for (final c in mostrados) _Linha(candidato: c),
          if (restantes.isNotEmpty)
            Text(
              'Outras ${restantes.length} candidaturas somam '
              '${formatVotos(restantes.fold(0, (t, c) => t + c.votes))} votos',
              style: context.text.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.candidato});

  final TseCandidate candidato;

  @override
  Widget build(BuildContext context) {
    final cor = PartyColors.isKnown(candidato.party)
        ? PartyColors.of(candidato.party)
        : context.colors.onSurfaceVariant;

    return Row(
      children: [
        CandidateAvatar(name: candidato.ballotName, color: cor, size: 22),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            candidato.ballotName,
            style: context.text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            candidato.party,
            style: context.text.labelSmall?.copyWith(color: cor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        Text(
          formatPercentual(candidato.share),
          style: context.stats.statMetric.copyWith(
            color: cor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${formatVotos(candidato.votes)})',
          style: context.text.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Painel direito: a transmissão da urna da seção escolhida.
class _SecaoPanel extends StatelessWidget {
  const _SecaoPanel({required this.controller});

  final ConsultaController controller;

  @override
  Widget build(BuildContext context) {
    final secao = controller.currentSection;

    return _Caixa(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.md,
        children: [
          Row(
            children: [
              Icon(Icons.how_to_vote, size: 20, color: context.election.leader),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Transmissão da Urna',
                  style: context.text.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (controller.loadingSections)
            _Aguardando(texto: 'Buscando o cadastro de seções da UF…')
          else if (secao == null)
            _Aguardando(
              texto: 'Escolha uma seção para ver o carimbo de transmissão.',
            )
          else
            _Transmissao(secao: secao, controller: controller),
          const _NotaBoletim(),
        ],
      ),
    );
  }
}

class _Transmissao extends StatelessWidget {
  const _Transmissao({required this.secao, required this.controller});

  final SectionRefTse secao;
  final ConsultaController controller;

  @override
  Widget build(BuildContext context) {
    final transmitida = secao.transmitted;
    final cor = transmitida
        ? context.election.leader
        : context.election.contested;

    Widget item(String rotulo, String valor) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              rotulo,
              style: context.text.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            valor,
            style: context.text.labelLarge?.copyWith(
              color: context.colors.onSurface,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLowest,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                transmitida ? Icons.check_circle : Icons.hourglass_empty,
                size: 15,
                color: cor,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                transmitida ? 'TRANSMITIDA' : 'SEM REGISTRO DE TRANSMISSÃO',
                style: context.text.labelSmall?.copyWith(
                  color: cor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          item('MUNICÍPIO', controller.currentMunicipality?.name ?? '--'),
          item('ZONA', controller.zona ?? '--'),
          item('SEÇÃO', secao.number),
          item('DATA', transmitida ? secao.transmittedDate : '--'),
          item('HORA', transmitida ? secao.transmittedTime : '--'),
        ],
      ),
    );
  }
}

/// O que esta tela não mostra, e por quê.
class _NotaBoletim extends StatelessWidget {
  const _NotaBoletim();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: AppRadius.lgAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 15,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'O boletim de urna com os votos desta seção fica no arquivo '
              'de urna do TSE, publicado em formato assinado próprio e não '
              'como JSON. O que esta tela mostra é o carimbo de '
              'transmissão, que vem do cadastro público de seções.',
              style: context.text.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Caixa extends StatelessWidget {
  const _Caixa({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.xlAll,
      ),
      child: child,
    );
  }
}

class _Aguardando extends StatelessWidget {
  const _Aguardando({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.election.leader,
          ),
        ),
        Flexible(
          child: Text(
            texto,
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _Falhou extends StatelessWidget {
  const _Falhou({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return _Caixa(
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 18, color: context.election.alert),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              mensagem,
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
