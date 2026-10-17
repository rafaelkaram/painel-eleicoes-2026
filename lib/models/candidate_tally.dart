import 'package:flutter/widgets.dart';

import 'candidate_identity.dart';

/// Posição do candidato na apuração — define o acento cromático do card.
enum CandidateStanding {
  /// Primeiro colocado: acento verde (primary).
  leading,

  /// Segundo colocado: acento âmbar (secondary).
  runnerUp,
}

/// Totalização de um candidato num pleito.
@immutable
class CandidateTally {
  const CandidateTally({
    required this.identity,
    required this.votes,
    required this.share,
    required this.standing,
    required this.standingLabel,
    required this.footnote,
    required this.statesLabel,
  }) : assert(share >= 0 && share <= 1, 'share é fração, não percentual');

  /// Quem é o candidato. Vem do cadastro estático, não do feed de votos.
  final CandidateIdentity identity;

  String get name => identity.name;

  /// Coligação. Vazio se o cadastro não trouxer.
  String get coalition => identity.coalition ?? '';

  /// Número na urna — vai no selo sobre a foto, quando houver.
  int? get number => identity.number;

  /// Foto de urna. Sem ela o card cai no placeholder.
  ImageProvider? get portrait => identity.portrait;

  /// Votos nominais totalizados.
  final int votes;

  /// Fração dos votos válidos, de 0 a 1.
  final double share;

  final CandidateStanding standing;

  /// Texto do chip de status, ex.: `Liderando com +3.920.800 votos`.
  final String standingLabel;

  /// Rodapé à esquerda, ex.: `Diferença Nominal: -3.920.800 (-3,44%)`.
  final String footnote;

  /// Rodapé à direita, ex.: `14 ESTADOS + DF`.
  final String statesLabel;

  bool get isLeading => standing == CandidateStanding.leading;
}
