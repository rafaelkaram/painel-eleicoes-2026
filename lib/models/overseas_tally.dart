import 'package:flutter/foundation.dart';

import 'candidate_identity.dart';

/// Votação de um candidato na Zona ZZ.
@immutable
class OverseasCandidate {
  const OverseasCandidate({
    required this.identity,
    required this.votes,
    required this.share,
  }) : assert(share >= 0 && share <= 1, 'share é fração, não percentual');

  final CandidateIdentity identity;
  final int votes;

  /// Fração dos votos válidos da zona.
  final double share;

  String get name => identity.name;
  String get party => identity.party ?? '';
}

/// Totalização da Zona ZZ — eleitorado brasileiro residente no exterior.
///
/// O TSE publica a zona como se fosse uma unidade federativa (`cdabr: zz`),
/// com os mesmos campos de seção, eleitorado e votos.
@immutable
class OverseasTally {
  const OverseasTally({
    required this.candidates,
    required this.validVotes,
    required this.electorate,
    required this.turnout,
    required this.countedShare,
    required this.sections,
  });

  /// Candidatos ordenados do mais votado ao menos.
  final List<OverseasCandidate> candidates;

  /// Votos válidos na zona.
  final int validVotes;

  /// Eleitores aptos.
  final int electorate;

  /// Quantos compareceram.
  final int turnout;

  /// Fração de seções totalizadas.
  final double countedShare;

  /// Total de seções da zona.
  final int sections;

  double get turnoutShare => electorate == 0 ? 0 : turnout / electorate;

  bool get isComplete => countedShare >= 1;
}
