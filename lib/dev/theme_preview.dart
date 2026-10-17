import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';

/// Página de verificação do tema — não faz parte do produto.
///
/// Serve para conferir lado a lado com as telas do Stitch se a extração ficou
/// fiel: escala tipográfica, rampa de superfícies e os componentes que o
/// design.md especifica (badge AO VIVO, card de candidato, cabeçalho de
/// tabela densa, chip de status).
class ThemePreviewPage extends StatelessWidget {
  const ThemePreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Eleições 2026'),
        actions: const [
          _LiveBadge(),
          SizedBox(width: AppSpacing.lg),
          _Telemetry(label: 'LATÊNCIA', value: '18ms'),
          SizedBox(width: AppSpacing.lg),
          _Telemetry(label: 'ÚLTIMA TRANSMISSÃO', value: '17:04:12'),
          SizedBox(width: AppSpacing.marginLarge),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.marginLarge),
        children: const [
          _Section(title: 'Superfícies', child: _SurfaceRamp()),
          _Section(title: 'Tipografia', child: _TypeScale()),
          _Section(title: 'Card de candidato', child: _CandidateCard()),
          _Section(title: 'Tabela densa', child: _DenseTable()),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: context.text.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    final leader = context.election.leader;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: leader,
            borderRadius: AppRadius.pill,
            boxShadow: context.election.leaderGlow,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'AO VIVO - TSE DIVULGAÇÃO',
          style: context.text.labelSmall?.copyWith(color: leader),
        ),
      ],
    );
  }
}

class _Telemetry extends StatelessWidget {
  const _Telemetry({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted = context.colors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: context.text.labelSmall?.copyWith(color: muted),
        ),
        Text(value, style: context.text.labelSmall?.copyWith(color: muted)),
      ],
    );
  }
}

class _SurfaceRamp extends StatelessWidget {
  const _SurfaceRamp();

  static const _ramp = <(String, Color)>[
    ('lowest', AppColors.surfaceContainerLowest),
    ('surface', AppColors.surface),
    ('low', AppColors.surfaceContainerLow),
    ('container', AppColors.surfaceContainer),
    ('high', AppColors.surfaceContainerHigh),
    ('highest', AppColors.surfaceContainerHighest),
    ('bright', AppColors.surfaceBright),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (name, color) in _ramp)
          Container(
            width: 112,
            height: 64,
            padding: const EdgeInsets.all(AppSpacing.sm),
            alignment: Alignment.bottomLeft,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.lgAll,
            ),
            child: Text(name, style: context.text.labelSmall),
          ),
      ],
    );
  }
}

class _TypeScale extends StatelessWidget {
  const _TypeScale();

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.sm,
      children: [
        Text('Apuração Presidencial', style: t.headlineLarge),
        Text('Governadores em Disputa', style: t.headlineMedium),
        Text('Consulta Local & Seção', style: t.headlineSmall),
        Text(
          'Corpo de texto em Inter para nomes e geografia.',
          style: t.bodyLarge,
        ),
        // 0 e 1 lado a lado conferem o zero cortado e a largura tabular.
        Text('1.234.567.890  00:00:00', style: context.stats.statDisplay),
        Text('48,72% APURADO', style: context.stats.statMetric),
        Text('MUNICÍPIO / ZONA ELEITORAL', style: t.labelSmall),
      ],
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHigh,
                    borderRadius: AppRadius.smAll,
                    border: Border(
                      left: BorderSide(
                        color: context.election.leader,
                        width: 3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nome do Candidato',
                        style: context.text.titleMedium,
                      ),
                      Text('PARTIDO · 00', style: context.text.labelSmall),
                    ],
                  ),
                ),
                Text('58.412.907', style: context.stats.statDisplay),
              ],
            ),
            ClipRRect(
              borderRadius: AppRadius.pill,
              child: LinearProgressIndicator(value: 0.5231),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('52,31%', style: context.stats.statMetric),
                Chip(
                  label: const Text('ELEITO MATEMATICAMENTE'),
                  backgroundColor: context.election.leader.withValues(
                    alpha: 0.15,
                  ),
                  labelStyle: context.text.labelMedium?.copyWith(
                    color: context.election.leader,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DenseTable extends StatelessWidget {
  const _DenseTable();

  static const _rows = <(String, String, String)>[
    ('São Paulo (SP)', '98,4%', '24.812.004'),
    ('Minas Gerais (MG)', '97,1%', '11.204.556'),
    ('Rio de Janeiro (RJ)', '95,8%', '9.337.120'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('UNIDADE FEDERATIVA')),
          DataColumn(label: Text('% APURADO'), numeric: true),
          DataColumn(label: Text('VOTOS VÁLIDOS'), numeric: true),
        ],
        rows: [
          for (final (uf, apurado, votos) in _rows)
            DataRow(
              cells: [
                DataCell(Text(uf)),
                // Célula numérica precisa do papel mono explícito: o tema não
                // alcança o nível da célula.
                DataCell(Text(apurado, style: context.text.labelLarge)),
                DataCell(Text(votos, style: context.text.labelLarge)),
              ],
            ),
        ],
      ),
    );
  }
}
