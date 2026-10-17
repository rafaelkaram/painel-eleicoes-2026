import 'package:countries_world_map/countries_world_map.dart';
import 'package:flutter/material.dart';

import '../models/governor_race.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';
import '../theme/party_colors.dart';
import '../util/br_state_paths.dart';
import 'candidate_avatar.dart';

/// Mapa dos governos estaduais, com o rosto de cada governador na sua UF.
///
/// Cada unidade é pintada na cor do partido de quem lidera; onde a disputa
/// ainda está aberta, a cor fica apagada e o rosto some — não há governador
/// para mostrar enquanto não houver decisão.
class GovernorMap extends StatelessWidget {
  const GovernorMap({super.key, required this.races, this.height = 460});

  final List<GovernorRace> races;
  final double height;

  /// Largura máxima do enquadramento.
  ///
  /// O contorno do Brasil é quase quadrado: num container largo, o
  /// `BoxFit.contain` encaixa pela altura e sobra deserto dos dois lados.
  static const _maxWidth = 720.0;

  /// Tamanho do rosto sobre a UF.
  static const _faceSize = 26.0;

  /// Rosto menor no marcador de duelo, para os dois caberem.
  static const _duelFaceSize = 22.0;

  /// Largura do par de rostos sobrepostos.
  static const _duelWidth = 38.0;

  /// UFs pequenas demais para o rosto caber dentro do contorno. Nelas o
  /// avatar fica deslocado para fora, com uma linha ligando.
  static const _deslocadas = {
    'BR-DF': Offset(-34, 16),
    'BR-RN': Offset(44, -30),
    'BR-PB': Offset(52, -8),
    'BR-PE': Offset(56, 14),
    'BR-AL': Offset(46, 34),
    'BR-SE': Offset(34, 46),
    'BR-RJ': Offset(22, 30),
    'BR-ES': Offset(40, 6),
  };

  @override
  Widget build(BuildContext context) {
    final geo = BrStatePaths.instance;
    final porIso = {for (final r in races) 'BR-${r.uf}': r};

    final cores = <String, Color>{
      for (final entry in porIso.entries)
        entry.key: _fill(context, entry.value),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: AppRadius.xlAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.md,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mapa dos Governos', style: context.text.headlineSmall),
              Text(
                'Cada unidade na cor do partido de quem venceu',
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Center(
            child: SizedBox(
              height: height,
              width: _maxWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerLowest,
                  borderRadius: AppRadius.xlAll,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final rect = geo.containRect(
                        Size(constraints.maxWidth, constraints.maxHeight),
                      );

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: SimpleMap(
                              instructions: SMapBrazil.instructions,
                              defaultColor: context.colors.surfaceContainerHigh,
                              colors: cores,
                              countryBorder: CountryBorder(
                                color: context.colors.surfaceContainerLowest,
                                width: 0.6,
                              ),
                            ),
                          ),
                          for (final entry in porIso.entries)
                            ..._face(
                              context,
                              geo,
                              rect,
                              entry.key,
                              entry.value,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cor de preenchimento da UF.
  Color _fill(BuildContext context, GovernorRace race) {
    final decidida = race.status == RaceStatus.elected;
    final cor = PartyColors.isKnown(race.leader.party)
        ? PartyColors.of(race.leader.party)
        : context.election.leader;

    // Disputa aberta fica esmaecida: ainda não há governo para mostrar.
    return decidida
        ? cor
        : Color.lerp(context.colors.surfaceContainerHigh, cor, 0.35)!;
  }

  /// Marcador da UF: o rosto do eleito, ou o duelo de quem ainda disputa.
  List<Widget> _face(
    BuildContext context,
    BrStatePaths geo,
    Rect rect,
    String iso,
    GovernorRace race,
  ) {
    final centro = geo.centerOf(iso, rect);
    if (centro == null) return const [];

    final decidida = race.status == RaceStatus.elected;
    final deslocamento = _deslocadas[iso] ?? Offset.zero;
    final destino = centro + deslocamento;
    final cor = PartyColors.isKnown(race.leader.party)
        ? PartyColors.of(race.leader.party)
        : context.election.leader;
    final corLinha = decidida ? cor : context.election.contested;

    final marcador = decidida
        ? _rostoEleito(context, race, cor)
        : _duelo(context, race, cor);
    final largura = decidida ? _faceSize : _duelWidth;

    return [
      // Linha ligando o marcador deslocado à UF de origem.
      if (deslocamento != Offset.zero)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _LeaderLinePainter(
                from: centro,
                to: destino,
                color: corLinha.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      Positioned(
        left: destino.dx - largura / 2,
        top: destino.dy - _faceSize / 2,
        child: Tooltip(
          message: decidida
              ? '${race.name}\n${race.leader.name} (${race.leader.party})'
              : '${race.name} — 2º turno\n'
                    '${race.leader.name} (${race.leader.party}) x '
                    '${race.runnerUp.name} (${race.runnerUp.party})',
          child: marcador,
        ),
      ),
    ];
  }

  Widget _rostoEleito(BuildContext context, GovernorRace race, Color cor) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: context.colors.surfaceContainerLowest,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: CandidateAvatar(
          name: race.leader.name,
          color: cor,
          portrait: race.leader.portrait,
          size: _faceSize,
        ),
      ),
    );
  }

  /// Dois rostos sobrepostos: a UF ainda está em disputa.
  ///
  /// Sem isso, estado indeciso ficava só apagado no mapa — o que lê como
  /// ausência de dado, não como duelo em aberto.
  Widget _duelo(BuildContext context, GovernorRace race, Color corLider) {
    final corVice = PartyColors.distinguish(
      corLider,
      PartyColors.isKnown(race.runnerUp.party)
          ? PartyColors.of(race.runnerUp.party)
          : context.election.contested,
    );

    Widget rosto(GovernorCandidate c, Color cor) => Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: context.colors.surfaceContainerLowest,
          width: 2,
        ),
      ),
      child: ClipOval(
        child: CandidateAvatar(
          name: c.name,
          color: cor,
          portrait: c.portrait,
          size: _duelFaceSize,
        ),
      ),
    );

    return SizedBox(
      width: _duelWidth,
      height: _faceSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(left: 0, child: rosto(race.leader, corLider)),
          Positioned(right: 0, child: rosto(race.runnerUp, corVice)),
          // Selo do 2º turno entre os dois rostos.
          Container(
            width: 13,
            height: 13,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.election.contested,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.colors.surfaceContainerLowest,
                width: 1.5,
              ),
            ),
            child: Text(
              '2',
              style: TextStyle(
                fontSize: 8,
                height: 1,
                fontWeight: FontWeight.w700,
                color: context.colors.surfaceContainerLowest,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Traço curto ligando o rosto deslocado à sua unidade federativa.
class _LeaderLinePainter extends CustomPainter {
  const _LeaderLinePainter({
    required this.from,
    required this.to,
    required this.color,
  });

  final Offset from;
  final Offset to;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = color
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(from, 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LeaderLinePainter old) =>
      old.from != from || old.to != to || old.color != color;
}
