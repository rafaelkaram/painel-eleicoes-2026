import 'package:countries_world_map/countries_world_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../models/demo_tallies.dart';
import '../models/state_tally.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_extensions.dart';
import '../util/br_state_paths.dart';
import '../util/formatters.dart';

/// Mapa coroplético das 27 unidades federativas.
///
/// Geometria real das UFs vem de `countries_world_map`, que embute os
/// contornos como instruções de path em Dart — sem tile server, sem rede em
/// runtime. Num painel de sala de controle isso não é detalhe: mapa que
/// depende de baixar tile é mapa que some quando a internet oscila.
class TerritoryMap extends StatelessWidget {
  const TerritoryMap({
    super.key,
    required this.states,
    this.highlightUfs = const ['SP', 'MG', 'BA', 'RS'],
    this.onStateTap,
    this.leaderLabel = 'A',
    this.runnerUpLabel = 'B',
    this.leaderColor,
    this.runnerUpColor,
  });

  final List<StateTally> states;

  /// UFs destacadas na grade abaixo do mapa.
  final List<String> highlightUfs;

  /// Chamado ao tocar numa UF. A sigla vem no formato ISO (`BR-SP`).
  final void Function(StateTally state)? onStateTap;

  /// Como chamar cada lado na legenda, nos destaques e no tooltip.
  ///
  /// Com dado real vira o primeiro nome do candidato; com dado de exemplo
  /// fica em `A` e `B`.
  final String leaderLabel;
  final String runnerUpLabel;

  /// Cores de legenda partidária. Nulas, caem na semântica do painel.
  final Color? leaderColor;
  final Color? runnerUpColor;

  /// Breakpoint `sm` do design para a grade de destaques.
  static const _fourColumnBreakpoint = 640.0;

  @override
  Widget build(BuildContext context) {
    final corLider = leaderColor ?? context.election.leader;
    final corVice = runnerUpColor ?? context.election.contested;
    final byUf = {for (final state in states) state.uf: state};

    // Só entra no placar territorial quem já tem urna apurada: UF sem
    // seção totalizada não lidera para ninguém.
    final apuradas = states.where((s) => !s.awaitingCount);
    final countA = TerritoryCount.from(apuradas.where((s) => s.leadsA));
    final countB = TerritoryCount.from(apuradas.where((s) => !s.leadsA));
    final aguardando = apuradas.isEmpty;

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
          _Header(
            countA: countA,
            countB: countB,
            awaiting: aguardando,
            leaderColor: corLider,
            runnerUpColor: corVice,
          ),
          const SizedBox(height: AppSpacing.md),
          _MapCanvas(
            states: states,
            countA: countA,
            countB: countB,
            awaiting: aguardando,
            onStateTap: onStateTap,
            leaderLabel: leaderLabel,
            runnerUpLabel: runnerUpLabel,
            leaderColor: corLider,
            runnerUpColor: corVice,
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < _fourColumnBreakpoint
                  ? 2
                  : 4;
              final gaps = AppSpacing.gutter * (columns - 1);
              final width = (constraints.maxWidth - gaps) / columns;
              final destaques = [for (final uf in highlightUfs) ?byUf[uf]];

              return Wrap(
                spacing: AppSpacing.gutter,
                runSpacing: AppSpacing.gutter,
                children: [
                  for (final state in destaques)
                    SizedBox(
                      width: width,
                      child: _Highlight(
                        state: state,
                        leaderLabel: leaderLabel,
                        runnerUpLabel: runnerUpLabel,
                        leaderColor: corLider,
                        runnerUpColor: corVice,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.countA,
    required this.countB,
    required this.awaiting,
    required this.leaderColor,
    required this.runnerUpColor,
  });

  final TerritoryCount countA;
  final TerritoryCount countB;
  final bool awaiting;
  final Color leaderColor;
  final Color runnerUpColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Distribuição Territorial',
                style: context.text.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                awaiting
                    ? 'Nenhuma seção totalizada — mapa sem liderança definida'
                    : 'Liderança consolidada por unidades federativas apuradas',
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _ScoreBox(
          countA: countA,
          countB: countB,
          awaiting: awaiting,
          leaderColor: leaderColor,
          runnerUpColor: runnerUpColor,
        ),
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({
    required this.countA,
    required this.countB,
    required this.awaiting,
    required this.leaderColor,
    required this.runnerUpColor,
  });

  final TerritoryCount countA;
  final TerritoryCount countB;
  final bool awaiting;
  final Color leaderColor;
  final Color runnerUpColor;

  @override
  Widget build(BuildContext context) {
    Widget side(TerritoryCount count, Color color, IconData icon) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          Icon(icon, size: 18, color: color),
          Text(
            count.compactLabel,
            style: context.stats.statMetric.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: AppRadius.lgAll,
      ),
      // `0 vs 0` leria como empate apurado. Sem urna, o placar não existe.
      child: awaiting
          ? Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.xs,
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 16,
                  color: context.colors.onSurfaceVariant,
                ),
                Text(
                  'AGUARDANDO APURAÇÃO',
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.sm,
              children: [
                side(countA, leaderColor, Icons.verified),
                Text(
                  'vs',
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                side(countB, runnerUpColor, Icons.shield_outlined),
              ],
            ),
    );
  }
}

class _MapCanvas extends StatefulWidget {
  const _MapCanvas({
    required this.states,
    required this.countA,
    required this.countB,
    required this.awaiting,
    required this.onStateTap,
    required this.leaderLabel,
    required this.runnerUpLabel,
    required this.leaderColor,
    required this.runnerUpColor,
  });

  final List<StateTally> states;
  final TerritoryCount countA;
  final TerritoryCount countB;
  final bool awaiting;
  final void Function(StateTally state)? onStateTap;
  final String leaderLabel;
  final String runnerUpLabel;
  final Color leaderColor;
  final Color runnerUpColor;

  @override
  State<_MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<_MapCanvas> {
  /// Margem a partir da qual a UF pinta na cor cheia do líder.
  ///
  /// Margem eleitoral real raramente passa de 40 pontos, então mapear
  /// 0..1 direto deixaria o mapa inteiro lavado. Satura em 0,40.
  static const _fullSaturationMargin = 0.40;

  /// Piso de intensidade: mesmo num empate técnico a UF precisa dizer quem
  /// lidera, só que fraco.
  static const _floor = 0.45;

  static const _mapHeight = 384.0;

  /// Largura do tooltip.
  ///
  /// Dimensionada para dois nomes de candidato com o percentual ao lado.
  /// Com rótulos de uma letra sobraria espaço; com nome real, 216px
  /// truncavam o valor do líder.
  static const _tooltipWidth = 268.0;
  static const _tooltipHeight = 108.0;

  StateTally? _hovered;
  Offset _pointer = Offset.zero;

  StateTally? get _federalDistrict {
    for (final state in widget.states) {
      if (state.isFederalDistrict) return state;
    }
    return null;
  }

  /// Cor do lado que lidera, ou neutro enquanto não há urna apurada.
  Color _accentFor(BuildContext context, StateTally state) {
    if (state.awaitingCount) return context.colors.onSurfaceVariant;
    return state.leadsA ? widget.leaderColor : widget.runnerUpColor;
  }

  Color _fillFor(BuildContext context, StateTally state) {
    // UF sem seção totalizada fica no cinza de fundo, igual às que o mapa
    // não conhece: pintar de partido seria afirmar um resultado inexistente.
    if (state.awaitingCount) return context.colors.surfaceContainerHigh;

    final accent = state.leadsA ? widget.leaderColor : widget.runnerUpColor;
    final intensity =
        _floor +
        (state.margin / _fullSaturationMargin).clamp(0.0, 1.0) * (1 - _floor);
    return Color.lerp(context.colors.surfaceContainerHigh, accent, intensity)!;
  }

  /// Raio de tolerância ao redor do centro do DF, em pixels.
  ///
  /// O contorno do DF tem ~3px nesta escala — exigir o acerto exato tornaria
  /// o tooltip dele inalcançável na prática.
  static const _federalDistrictGrab = 9.0;

  void _updateHover(Offset local, Rect rect) {
    final geo = BrStatePaths.instance;
    var iso = geo.hitTest(
      local,
      rect,
      widget.states.map((state) => state.isoCode),
    );

    final df = _federalDistrict;
    if (df != null && iso != df.isoCode) {
      final center = geo.centerOf(df.isoCode, rect);
      if (center != null && (local - center).distance <= _federalDistrictGrab) {
        iso = df.isoCode;
      }
    }

    StateTally? found;
    if (iso != null) {
      for (final state in widget.states) {
        if (state.isoCode == iso) {
          found = state;
          break;
        }
      }
    }

    // Mover o ponteiro sobre o oceano não precisa repintar nada.
    if (found == null && _hovered == null) return;

    setState(() {
      _hovered = found;
      _pointer = local;
    });
  }

  void _clearHover() {
    if (_hovered == null) return;
    setState(() => _hovered = null);
  }

  @override
  Widget build(BuildContext context) {
    final geo = BrStatePaths.instance;
    final byIso = {for (final state in widget.states) state.isoCode: state};
    final colors = <String, Color>{
      for (final state in widget.states)
        state.isoCode: _fillFor(context, state),
    };

    return SizedBox(
      height: _mapHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest,
          borderRadius: AppRadius.xlAll,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final box = Size(constraints.maxWidth, constraints.maxHeight);
              final rect = geo.containRect(box);
              final df = _federalDistrict;
              final dfCenter = df == null
                  ? null
                  : geo.centerOf(df.isoCode, rect);
              final hovered = _hovered;

              return MouseRegion(
                onHover: (event) => _updateHover(event.localPosition, rect),
                onExit: (_) => _clearHover(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: SimpleMap(
                        instructions: SMapBrazil.instructions,
                        defaultColor: context.colors.surfaceContainerHigh,
                        colors: colors,
                        countryBorder: CountryBorder(
                          color: context.colors.surfaceContainerLowest,
                          width: 0.6,
                        ),
                        callback: widget.onStateTap == null
                            ? null
                            : (id, name, details) {
                                final state = byIso[id];
                                if (state != null) widget.onStateTap!(state);
                              },
                      ),
                    ),
                    if (hovered != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: TweenAnimationBuilder<double>(
                            // A chave reinicia a animação a cada UF nova.
                            key: ValueKey(hovered.isoCode),
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            builder: (context, t, _) => CustomPaint(
                              painter: _HoverReliefPainter(
                                path: geo.paths[hovered.isoCode]!,
                                rect: rect,
                                fill: colors[hovered.isoCode]!,
                                accent: _accentFor(context, hovered),
                                t: t,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                      child: IgnorePointer(
                        child: _Legend(
                          countA: widget.countA,
                          countB: widget.countB,
                          awaiting: widget.awaiting,
                          leaderLabel: widget.leaderLabel,
                          runnerUpLabel: widget.runnerUpLabel,
                          leaderColor: widget.leaderColor,
                          runnerUpColor: widget.runnerUpColor,
                        ),
                      ),
                    ),
                    // O DF tem 5.802 km²: some em qualquer escala nacional.
                    // Sem este marcador, a UF que decide o placar fica
                    // invisível no mapa.
                    if (df != null && dfCenter != null)
                      Positioned(
                        left: dfCenter.dx - 4,
                        top: dfCenter.dy - 4,
                        child: IgnorePointer(
                          child: _FederalDistrictMarker(state: df),
                        ),
                      ),
                    if (hovered != null)
                      Positioned(
                        left: (_pointer.dx + 14).clamp(0.0, _maxLeft(box)),
                        top: (_pointer.dy + 14).clamp(0.0, _maxTop(box)),
                        child: IgnorePointer(
                          child: _StateTooltip(
                            state: hovered,
                            leaderLabel: widget.leaderLabel,
                            runnerUpLabel: widget.runnerUpLabel,
                            accent: _accentFor(context, hovered),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  double _maxLeft(Size box) {
    final limit = box.width - _tooltipWidth;
    return limit < 0 ? 0 : limit;
  }

  double _maxTop(Size box) {
    final limit = box.height - _tooltipHeight;
    return limit < 0 ? 0 : limit;
  }
}

/// Marcador do Distrito Federal, ancorado no centro do próprio contorno.
///
/// São 5.802 km²: a UF some em qualquer escala nacional. O marcador é só um
/// ponto com anel e a sigla ao lado — o suficiente para localizar, sem
/// competir com o mapa. Quem lidera já está dito pela cor.
class _FederalDistrictMarker extends StatelessWidget {
  const _FederalDistrictMarker({required this.state});

  static const dotSize = 7.0;

  final StateTally state;

  @override
  Widget build(BuildContext context) {
    final accent = state.awaitingCount
        ? context.colors.onSurfaceVariant
        : state.leadsA
        ? context.election.leader
        : context.election.contested;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
            border: Border.all(
              color: context.colors.surfaceContainerLowest,
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          'DF',
          style: context.text.labelSmall?.copyWith(
            color: accent.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Relevo do estado sob o ponteiro.
///
/// Pinta por cima do mapa: sombra projetada, preenchimento clareado e
/// contorno aceso, tudo escalado a partir do centro da própria UF. Fica num
/// `CustomPaint` separado para não repintar o mapa inteiro a cada hover.
class _HoverReliefPainter extends CustomPainter {
  const _HoverReliefPainter({
    required this.path,
    required this.rect,
    required this.fill,
    required this.accent,
    required this.t,
  });

  /// Contorno da UF em espaço unitário.
  final Path path;

  /// Retângulo que o mapa ocupa.
  final Rect rect;

  /// Cor com que a UF já está pintada no mapa.
  final Color fill;

  /// Cor do líder, usada no contorno.
  final Color accent;

  /// Progresso da animação, de 0 a 1.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;

    final toScreen = Matrix4.identity()
      ..translateByDouble(rect.left, rect.top, 0, 1)
      ..scaleByDouble(rect.width, rect.height, 1, 1);
    final screen = path.transform(toScreen.storage);
    final center = screen.getBounds().center;

    canvas.save();
    // Levanta a UF a partir do próprio centro, senão ela desliza no mapa.
    canvas.translate(center.dx, center.dy);
    canvas.scale(1 + 0.045 * t);
    canvas.translate(-center.dx, -center.dy);

    canvas.drawPath(
      screen.shift(Offset(0, 1.5 + 2.5 * t)),
      Paint()
        ..color = const Color(0xFF000000).withValues(alpha: 0.6 * t)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + 5 * t),
    );

    canvas.drawPath(
      screen,
      Paint()..color = Color.lerp(fill, const Color(0xFFFFFFFF), 0.2 * t)!,
    );

    canvas.drawPath(
      screen,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = accent.withValues(alpha: t),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_HoverReliefPainter old) =>
      old.t != t || old.path != path || old.rect != rect || old.fill != fill;
}

/// Micro-tooltip da UF sob o ponteiro.
class _StateTooltip extends StatelessWidget {
  const _StateTooltip({
    required this.state,
    required this.leaderLabel,
    required this.runnerUpLabel,
    required this.accent,
  });

  final StateTally state;
  final String leaderLabel;
  final String runnerUpLabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final muted = context.text.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    return Container(
      width: _MapCanvasState._tooltipWidth,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: context.colors.tertiaryContainer),
        boxShadow: context.election.overlayShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${state.name} (${state.uf})',
            style: context.text.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'APURADO: ${formatPercentualCurto(state.countedShare)}',
            style: muted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (state.awaitingCount)
            Text(
              'Aguardando a primeira seção totalizada',
              style: context.text.labelLarge?.copyWith(color: accent),
              maxLines: 2,
            )
          else ...[
            Row(
              // Sem `Spacer`: ele é um `Expanded` e roubaria um terço da linha
              // dos dois textos, truncando o valor do líder.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${state.leadsA ? leaderLabel : runnerUpLabel}: '
                    '${formatPercentual(state.leaderShare)}',
                    style: context.text.labelLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    '${state.leadsA ? runnerUpLabel : leaderLabel}: '
                    '${formatPercentual(state.runnerUpShare)}',
                    style: muted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            Text(
              'MARGEM: ${formatPontos(state.margin)}',
              style: muted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.countA,
    required this.countB,
    required this.awaiting,
    required this.leaderLabel,
    required this.runnerUpLabel,
    required this.leaderColor,
    required this.runnerUpColor,
  });

  final TerritoryCount countA;
  final TerritoryCount countB;
  final bool awaiting;
  final String leaderLabel;
  final String runnerUpLabel;
  final Color leaderColor;
  final Color runnerUpColor;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, Color color) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.smAll,
            ),
          ),
          Text(label, style: context.text.labelSmall?.copyWith(color: color)),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh.withValues(alpha: 0.9),
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: awaiting
            ? [row('SEM SEÇÃO TOTALIZADA', context.colors.onSurfaceVariant)]
            : [
                row('$leaderLabel: ${countA.legendLabel}', leaderColor),
                row('$runnerUpLabel: ${countB.legendLabel}', runnerUpColor),
              ],
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({
    required this.state,
    required this.leaderLabel,
    required this.runnerUpLabel,
    required this.leaderColor,
    required this.runnerUpColor,
  });

  final StateTally state;
  final String leaderLabel;
  final String runnerUpLabel;
  final Color leaderColor;
  final Color runnerUpColor;

  @override
  Widget build(BuildContext context) {
    final muted = context.text.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final accent = state.awaitingCount
        ? context.colors.onSurfaceVariant
        : state.leadsA
        ? leaderColor
        : runnerUpColor;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // O percentual de apuração não pode ser o que some: nome longo
          // encolhe, o número fica.
          Row(
            children: [
              Flexible(
                child: Text(
                  state.name.toUpperCase(),
                  style: muted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                ' (${formatPercentualCurto(state.countedShare)} APUR.)',
                style: muted,
                maxLines: 1,
              ),
            ],
          ),
          if (state.awaitingCount)
            Text(
              'AGUARDANDO APURAÇÃO',
              style: context.text.labelLarge?.copyWith(color: accent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else ...[
            Text(
              '${state.leadsA ? leaderLabel : runnerUpLabel}: '
              '${formatPercentual(state.leaderShare)}',
              style: context.text.labelLarge?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${state.leadsA ? runnerUpLabel : leaderLabel}: '
              '${formatPercentual(state.runnerUpShare)}',
              style: muted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// --- Previews ---------------------------------------------------------

/// Envelope das previews. Público e top-level por exigência do `@Preview`.
Widget territoryPreviewWrapper(Widget child) {
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
  name: 'Mapa territorial',
  group: 'Apuração',
  size: Size(900, 680),
  brightness: Brightness.dark,
  wrapper: territoryPreviewWrapper,
)
Widget territoryMapPreview() {
  return const TerritoryMap(states: DemoTallies.states);
}

@Preview(
  name: 'Mapa territorial — coluna estreita',
  group: 'Apuração',
  size: Size(520, 720),
  brightness: Brightness.dark,
  wrapper: territoryPreviewWrapper,
)
Widget territoryMapNarrowPreview() {
  return const TerritoryMap(states: DemoTallies.states);
}
