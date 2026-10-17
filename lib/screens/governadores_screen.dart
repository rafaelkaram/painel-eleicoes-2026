import 'package:flutter/material.dart';

import '../models/governor_race.dart';
import '../state/apuracao_controller.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';
import '../util/formatters.dart';
import '../data/tse_election.dart';
import '../widgets/elected_summary.dart';
import '../widgets/governor_map.dart';
import '../widgets/governor_race_card.dart';

/// `/governadores` — disputas estaduais pelo governo.
class GovernadoresScreen extends StatefulWidget {
  const GovernadoresScreen({super.key});

  @override
  State<GovernadoresScreen> createState() => _GovernadoresScreenState();
}

class _GovernadoresScreenState extends State<GovernadoresScreen> {
  /// `null` mostra todas as regiões.
  Region? _region;

  @override
  Widget build(BuildContext context) {
    final controller = ApuracaoScope.of(context);
    final races = controller.governorRaces;

    if (races.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.marginLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.lg,
          children: [
            _Header(races: races, turno: controller.turno.label),
            _SemDisputas(
              pendente: controller.detailsPending,
              turno: controller.turno.label,
            ),
          ],
        ),
      );
    }

    final segundoTurno = controller.turno == Turno.segundo;
    final eleitos = controller.electedFirstRound;

    // No 2º turno os cards são só de quem ainda disputa; quem já venceu
    // aparece no resumo compacto acima.
    final emDisputa = segundoTurno
        ? races.where((r) => r.status != RaceStatus.elected).toList()
        : races;

    final visible = _region == null
        ? emDisputa
        : emDisputa.where((race) => race.region == _region).toList();

    // O mapa mostra sempre o quadro completo dos governos: no 2º turno,
    // os eleitos no 1º mais as seis disputas abertas.
    final noMapa = segundoTurno ? [...eleitos, ...races] : races;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.marginLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.lg,
        children: [
          _Header(races: races, turno: controller.turno.label),
          if (segundoTurno && eleitos.isNotEmpty)
            ElectedSummary(races: eleitos),
          GovernorMap(races: noMapa),
          if (!segundoTurno)
            _FilterBar(
              races: races,
              selected: _region,
              onSelected: (region) => setState(() => _region = region),
            ),
          if (segundoTurno)
            Text(
              'EM DISPUTA NO 2º TURNO',
              style: context.text.labelSmall?.copyWith(
                color: context.election.contested,
                fontWeight: FontWeight.w700,
              ),
            ),
          _RaceGrid(races: visible),
          _TransmissionFooter(races: races),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.races, required this.turno});

  final List<GovernorRace> races;
  final String turno;

  static const _rowBreakpoint = 900.0;

  @override
  Widget build(BuildContext context) {
    final muted = context.text.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          spacing: AppSpacing.xs,
          children: [
            Flexible(
              child: Text(
                'TOTALIZAÇÃO OFICIAL TSE',
                style: muted,
                softWrap: false,
              ),
            ),
            Text('•', style: muted),
            Flexible(
              child: Text(
                'SESSÃO PLENÁRIA 2026',
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
        Text(
          'Eleições Estaduais — $turno para Governador',
          style: context.text.headlineLarge,
        ),
        Text(
          'Acompanhamento em tempo real das ${races.length} '
          'unidades federativas em disputa ativa',
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        const status = _SystemStatus(connected: false, lastUpdate: null);

        if (constraints.maxWidth < _rowBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.md,
            children: [titulo, status],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: titulo),
            const SizedBox(width: AppSpacing.md),
            status,
          ],
        );
      },
    );
  }
}

/// Estado da conexão com o feed.
///
/// Sem feed ligado, mostrar "Conectado TSE-DF" seria mentira — o painel diz
/// que não há canal até existir um.
class _SystemStatus extends StatelessWidget {
  const _SystemStatus({this.connected = false, this.lastUpdate});

  final bool connected;
  final DateTime? lastUpdate;

  @override
  Widget build(BuildContext context) {
    final muted = context.text.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final accent = connected
        ? context.election.leader
        : context.colors.onSurfaceVariant;

    Widget bloco(String rotulo, Widget valor) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rotulo, style: muted),
          const SizedBox(height: 2),
          valor,
        ],
      );
    }

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
        spacing: AppSpacing.lg,
        children: [
          bloco(
            'STATUS DO SISTEMA',
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.xs,
              children: [
                Icon(
                  connected ? Icons.cloud_done : Icons.cloud_off,
                  size: 14,
                  color: accent,
                ),
                Text(
                  connected ? 'Conectado TSE-DF' : 'Sem canal TSE',
                  style: context.text.labelMedium?.copyWith(color: accent),
                ),
              ],
            ),
          ),
          bloco(
            'ÚLTIMA ATUALIZAÇÃO',
            Text(
              lastUpdate == null ? '--:-- BRT' : '${lastUpdate!.hour}h',
              style: context.text.labelMedium?.copyWith(
                color: context.colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filtros por região e resumo das situações.
class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.races,
    required this.selected,
    required this.onSelected,
  });

  final List<GovernorRace> races;
  final Region? selected;
  final ValueChanged<Region?> onSelected;

  @override
  Widget build(BuildContext context) {
    final porRegiao = <Region, int>{};
    for (final race in races) {
      porRegiao[race.region] = (porRegiao[race.region] ?? 0) + 1;
    }
    final resumo = RaceSummary.from(races);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _FilterChip(
              label: 'Todos (${races.length})',
              active: selected == null,
              onTap: () => onSelected(null),
            ),
            for (final region in Region.values)
              if (porRegiao[region] case final total?)
                _FilterChip(
                  label: '${region.label} ($total)',
                  active: selected == region,
                  onTap: () => onSelected(region),
                ),
          ],
        ),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          children: [
            for (final status in RaceStatus.values)
              _SummaryEntry(status: status, count: resumo[status]),
          ],
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.election.leader;

    return Material(
      color: active
          ? accent.withValues(alpha: 0.15)
          : context.colors.surfaceContainerHigh,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            label,
            style: context.text.labelMedium?.copyWith(
              color: active ? accent : context.colors.onSurfaceVariant,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryEntry extends StatelessWidget {
  const _SummaryEntry({required this.status, required this.count});

  final RaceStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    // Mesma cor do chip do card: a legenda não pode discordar da grade.
    final color = switch (status) {
      RaceStatus.elected => context.colors.primaryContainer,
      RaceStatus.leading => context.election.leader,
      RaceStatus.tooCloseToCall => context.election.contested,
    };
    final rotulo = switch (status) {
      RaceStatus.elected => 'Definidos',
      RaceStatus.leading => 'Liderança consolidada',
      RaceStatus.tooCloseToCall => 'Voto a voto',
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        // "Definidos" e "liderança" são dois verdes próximos demais para se
        // distinguirem num quadrado de 10px. O selo repete o chip do card e
        // resolve pela forma, não pela cor.
        if (status == RaceStatus.elected)
          Icon(Icons.check_circle, size: 11, color: color)
        else
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.smAll,
            ),
          ),
        Text(
          '$rotulo: $count',
          style: context.text.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RaceGrid extends StatelessWidget {
  const _RaceGrid({required this.races});

  /// Abaixo disso, uma coluna.
  static const twoColumnBreakpoint = 768.0;

  /// Abaixo disso, duas colunas; acima, três.
  static const threeColumnBreakpoint = 1280.0;

  final List<GovernorRace> races;

  @override
  Widget build(BuildContext context) {
    if (races.isEmpty) {
      return Text(
        'Nenhuma disputa nesta região.',
        style: context.text.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (constraints.maxWidth) {
          < twoColumnBreakpoint => 1,
          < threeColumnBreakpoint => 2,
          _ => 3,
        };
        final gaps = AppSpacing.md * (columns - 1);
        final width = (constraints.maxWidth - gaps) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final race in races)
              SizedBox(
                width: width,
                child: GovernorRaceCard(race: race),
              ),
          ],
        );
      },
    );
  }
}

class _TransmissionFooter extends StatelessWidget {
  const _TransmissionFooter({required this.races});

  final List<GovernorRace> races;

  @override
  Widget build(BuildContext context) {
    final muted = context.text.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.xlAll,
      ),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.sm,
            children: [
              Icon(
                Icons.verified_user,
                size: 16,
                color: context.election.leader,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Boletins de urna transmitidos e criptografados',
                    style: context.text.bodySmall,
                  ),
                  Text('Resolução TSE nº 23.673/2026.', style: muted),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.md,
            children: [
              Text('TOTAL GERAL APURADO:', style: muted),
              Text(
                formatPercentual(overallCountedShare(races)),
                style: context.stats.statMetric.copyWith(
                  color: context.election.leader,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // Exportação ainda não existe: botão desabilitado em vez de um
              // clique que não faz nada.
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('EXPORTAR CSV'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Nenhuma disputa estadual carregada ainda.
class _SemDisputas extends StatelessWidget {
  const _SemDisputas({required this.pendente, required this.turno});

  final bool pendente;
  final String turno;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icons.how_to_vote_outlined,
              size: 16,
              color: context.colors.onSurfaceVariant,
            ),
          Flexible(
            child: Text(
              pendente
                  ? 'Buscando as disputas estaduais no TSE…'
                  : 'Nenhuma disputa de governador publicada para o $turno.',
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
