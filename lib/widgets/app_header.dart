import 'package:flutter/material.dart';

import '../data/tse_election.dart';
import '../state/apuracao_controller.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';
import 'pulse_dot.dart';
import 'urna_mark.dart';

/// Header fixo de 48px com os streams de status.
///
/// Spec do design.md: altura 48, fundo `surface`, badge AO VIVO à esquerda das
/// métricas de sincronismo.
class PainelAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PainelAppBar({
    super.key,
    this.title = marca,
    this.latency,
    this.lastSync,
  });

  /// Texto institucional do header, como na tela do Stitch. O título da tela
  /// não vem para cá: ele já é o H1 do corpo e o rail marca o destino ativo.
  static const marca = 'TSE Eleições Gerais 2026';

  final String title;

  /// Latência da última leitura do TSE. `null` enquanto não há conexão.
  final Duration? latency;

  /// Horário da última transmissão recebida.
  final DateTime? lastSync;

  @override
  Size get preferredSize => const Size.fromHeight(AppMetrics.headerHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: AppSpacing.lg,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const UrnaMark(size: 24, withPlate: false),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      actions: [
        const TurnoToggle(),
        const SizedBox(width: AppSpacing.lg),
        const LiveBadge(),
        const SizedBox(width: AppSpacing.lg),
        HeaderTelemetry(
          label: 'LATÊNCIA',
          value: latency == null ? '--' : '${latency!.inMilliseconds}ms',
        ),
        const SizedBox(width: AppSpacing.lg),
        HeaderTelemetry(
          label: 'ÚLTIMA TRANSMISSÃO',
          value: lastSync == null ? '--:--:--' : _clock(lastSync!),
        ),
        const SizedBox(width: AppSpacing.marginLarge),
      ],
    );
  }

  static String _clock(DateTime t) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(t.hour)}:${pad(t.minute)}:${pad(t.second)}';
  }
}

/// Badge "AO VIVO - TSE DIVULGAÇÃO" com o pulso verde do design.
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key, this.live = true});

  final bool live;

  @override
  Widget build(BuildContext context) {
    final color = live ? context.election.leader : context.colors.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PulseDot(color: color, active: live),
        const SizedBox(width: AppSpacing.sm),
        Text(
          live ? 'AO VIVO - TSE DIVULGAÇÃO' : 'DESCONECTADO',
          style: context.text.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Par rótulo/valor das métricas de sincronismo do header.
class HeaderTelemetry extends StatelessWidget {
  const HeaderTelemetry({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted = context.text.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: muted),
        Text(value, style: muted),
      ],
    );
  }
}

/// Alternador entre 1º e 2º turno, como no header do design.
class TurnoToggle extends StatelessWidget {
  const TurnoToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ApuracaoScope.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        for (final turno in Turno.values)
          _TurnoButton(
            turno: turno,
            ativo: controller.turno == turno,
            onTap: () => controller.select(turno),
          ),
      ],
    );
  }
}

class _TurnoButton extends StatelessWidget {
  const _TurnoButton({
    required this.turno,
    required this.ativo,
    required this.onTap,
  });

  final Turno turno;
  final bool ativo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.election.leader;

    return Material(
      color: ativo
          ? accent.withValues(alpha: 0.15)
          : context.colors.surfaceContainerHigh,
      borderRadius: AppRadius.lgAll,
      child: InkWell(
        onTap: ativo ? null : onTap,
        borderRadius: AppRadius.lgAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            turno.label.toUpperCase(),
            style: context.text.labelSmall?.copyWith(
              color: ativo ? accent : context.colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
