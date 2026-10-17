import 'package:flutter/widgets.dart';

import 'candidate_identity.dart';

/// Região do país, usada no filtro da tela de governadores.
enum Region {
  norte('Norte'),
  nordeste('Nordeste'),
  centroOeste('Centro-Oeste'),
  sudeste('Sudeste'),
  sul('Sul');

  const Region(this.label);

  final String label;
}

/// Situação de uma disputa estadual.
enum RaceStatus {
  /// Totalização encerrada.
  elected('Eleito Definitivo', 'Matematicamente Eleito'),

  /// O que falta apurar já não vira a diferença.
  leading('Liderando', 'Diferença Nominal'),

  /// A diferença ainda cabe no que falta apurar.
  tooCloseToCall('Disputa Acirrada', 'Margem Voto a Voto');

  const RaceStatus(this.chipLabel, this.footnoteLabel);

  /// Texto do chip no topo do card.
  final String chipLabel;

  /// Rótulo do rodapé que acompanha a diferença de votos.
  final String footnoteLabel;
}

/// Um candidato ao governo estadual.
@immutable
class GovernorCandidate {
  const GovernorCandidate({
    required this.identity,
    required this.votes,
    required this.share,
  }) : assert(share >= 0 && share <= 1, 'share é fração, não percentual');

  /// Quem é o candidato. Vem do cadastro estático, não do feed de votos.
  final CandidateIdentity identity;

  String get name => identity.name;

  /// Sigla do partido. Vazia se o cadastro não trouxer.
  String get party => identity.party ?? '';

  final int votes;

  /// Fração dos votos válidos.
  final double share;

  /// Foto de urna. Sem ela o avatar cai nas iniciais.
  ///
  /// Nos dados de exemplo fica nula de propósito: são figuras públicas
  /// reais ao lado de números inventados, e rosto nessa combinação engana.
  /// Quando o feed do TSE entrar, o retrato vem com o resto do dado —
  /// indexado pelo id do candidato, como faz o seuimposto.
  ImageProvider? get portrait => identity.portrait;
}

/// Disputa pelo governo de uma unidade federativa.
@immutable
class GovernorRace {
  const GovernorRace({
    required this.uf,
    required this.name,
    required this.region,
    required this.electorate,
    required this.countedShare,
    required this.leader,
    required this.runnerUp,
    this.declaredStatus,
  }) : assert(countedShare >= 0 && countedShare <= 1, 'countedShare é fração');

  /// Sigla de duas letras.
  final String uf;

  /// Nome por extenso.
  final String name;

  final Region region;

  /// Eleitores aptos.
  final int electorate;

  /// Fração de seções totalizadas.
  final double countedShare;

  final GovernorCandidate leader;
  final GovernorCandidate runnerUp;

  /// Situação declarada pelo TSE, quando o feed traz.
  ///
  /// Se o órgão oficial disse que acabou, a palavra é dele — o painel não
  /// pode discordar da fonte na tela. A derivação local é o que roda
  /// enquanto o campo não vem.
  final RaceStatus? declaredStatus;

  /// Diferença entre os dois, em fração dos válidos.
  double get margin => leader.share - runnerUp.share;

  /// Diferença em votos nominais.
  int get voteGap => leader.votes - runnerUp.votes;

  /// Fração que falta totalizar.
  double get remaining => (1 - countedShare).clamp(0.0, 1.0);

  /// Situação da disputa, derivada — nunca digitada.
  ///
  /// A regra é a que importa numa noite de apuração: enquanto o que falta
  /// apurar for maior que a diferença, o resultado ainda pode virar. Um
  /// limiar fixo de margem erraria nos dois sentidos — 3,4 pontos com 0,9%
  /// de seções pendentes está decidido; 3,8 pontos com 8% pendentes não.
  RaceStatus get status {
    if (declaredStatus case final declarado?) return declarado;
    if (countedShare >= 1) return RaceStatus.elected;
    return margin <= remaining ? RaceStatus.tooCloseToCall : RaceStatus.leading;
  }
}

/// Resumo de quantas disputas estão em cada situação.
@immutable
class RaceSummary {
  const RaceSummary(this.counts);

  final Map<RaceStatus, int> counts;

  int operator [](RaceStatus status) => counts[status] ?? 0;

  int get total => counts.values.fold(0, (a, b) => a + b);

  static RaceSummary from(Iterable<GovernorRace> races) {
    final counts = <RaceStatus, int>{};
    for (final race in races) {
      counts[race.status] = (counts[race.status] ?? 0) + 1;
    }
    return RaceSummary(counts);
  }
}

/// Percentual geral apurado, ponderado pelo eleitorado de cada UF.
///
/// Média simples trataria Sergipe e São Paulo como iguais.
double overallCountedShare(Iterable<GovernorRace> races) {
  var eleitores = 0;
  var apurados = 0.0;
  for (final race in races) {
    eleitores += race.electorate;
    apurados += race.electorate * race.countedShare;
  }
  return eleitores == 0 ? 0 : apurados / eleitores;
}
