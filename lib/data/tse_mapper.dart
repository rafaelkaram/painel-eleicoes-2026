import 'package:flutter/widgets.dart';

import '../models/candidate_identity.dart';
import '../models/candidate_tally.dart';
import '../models/governor_race.dart';
import '../models/overseas_tally.dart';
import '../models/state_tally.dart';
import '../models/uf.dart';
import '../models/vote_breakdown.dart';
import '../util/formatters.dart';
import 'tse_election.dart';
import 'tse_payload.dart';

/// Traduz o resultado do TSE para os modelos que as telas já consomem.
abstract final class TseMapper {
  /// Os quatro tiles do topo.
  static List<VoteBreakdown> breakdown(TseResult r) {
    return [
      VoteBreakdown(
        label: 'VOTOS VÁLIDOS',
        share: r.votes.validShare,
        votes: r.votes.valid,
      ),
      VoteBreakdown(
        label: 'VOTOS NULOS',
        share: r.votes.nullShare,
        votes: r.votes.nulls,
      ),
      VoteBreakdown(
        label: 'VOTOS EM BRANCO',
        share: r.votes.blankShare,
        votes: r.votes.blank,
      ),
      VoteBreakdown(
        label: 'ABSTENÇÃO ELEITORAL',
        share: r.electorate.abstentionShare,
        votes: r.electorate.abstentions,
        tone: VoteBreakdownTone.alert,
      ),
    ];
  }

  /// Os dois primeiros colocados, prontos para os cards.
  ///
  /// Devolve lista vazia quando a eleição ainda não tem candidato definido —
  /// o 2º turno antes da votação, por exemplo.
  static List<CandidateTally> topTwo(TseResult r, {required int eleicao}) {
    if (r.candidates.length < 2) return const [];

    final lider = r.candidates[0];
    final vice = r.candidates[1];
    final diferenca = lider.votes - vice.votes;
    final diferencaShare = lider.share - vice.share;

    CandidateIdentity identidade(TseCandidate c) => CandidateIdentity(
      number: c.number,
      name: c.ballotName,
      party: c.party,
      coalition: c.party,
      portrait: _portrait(c, eleicao: eleicao, abrangencia: 'br'),
    );

    return [
      CandidateTally(
        identity: identidade(lider),
        votes: lider.votes,
        share: lider.share,
        standing: CandidateStanding.leading,
        standingLabel: diferenca > 0
            ? 'Liderando com ${formatDiferenca(diferenca)} votos'
            : 'Empate técnico',
        // A situação é a que o TSE declara, não uma conclusão nossa.
        footnote: lider.situation.isEmpty
            ? 'Aguardando apuração'
            : lider.situation,
        statesLabel: lider.situation.toUpperCase(),
      ),
      CandidateTally(
        identity: identidade(vice),
        votes: vice.votes,
        share: vice.share,
        standing: CandidateStanding.runnerUp,
        standingLabel: vice.situation.isEmpty ? '2º Colocado' : vice.situation,
        footnote: diferenca > 0
            ? 'Diferença Nominal: ${formatDiferenca(-diferenca)} '
                  '(${formatPercentualCurto(-diferencaShare)})'
            : 'Diferença Nominal: 0',
        statesLabel: vice.situation.toUpperCase(),
      ),
    ];
  }

  /// Mapa territorial: como cada UF votou para presidente.
  ///
  /// `shareA` é sempre a fração do candidato [numeroA] — o primeiro
  /// colocado nacional. Sem fixar isso, o mapa trocaria de cor conforme a
  /// UF e a legenda deixaria de significar qualquer coisa.
  static List<StateTally> states(
    Map<Uf, TseResult> porUf, {
    required int numeroA,
  }) {
    final estados = <StateTally>[];

    for (final entry in porUf.entries) {
      final r = entry.value;
      if (r.candidates.isEmpty) continue;

      final a = r.candidates.where((c) => c.number == numeroA).firstOrNull;
      if (a == null) continue;

      estados.add(
        StateTally(
          uf: entry.key.sigla,
          name: entry.key.label,
          shareA: a.share.clamp(0.0, 1.0),
          countedShare: r.sections.countedShare.clamp(0.0, 1.0),
        ),
      );
    }

    estados.sort((x, y) => x.uf.compareTo(y.uf));
    return estados;
  }

  /// Disputas estaduais pelo governo, a partir das cargas por UF.
  ///
  /// UF com menos de dois candidatos fica de fora: não há disputa para
  /// mostrar num card de dois lados.
  static List<GovernorRace> governorRaces(
    Map<Uf, TseResult> porUf, {
    required int eleicao,
  }) {
    final disputas = <GovernorRace>[];

    for (final entry in porUf.entries) {
      final r = entry.value;
      if (r.candidates.length < 2) continue;

      final lider = r.candidates[0];
      final vice = r.candidates[1];

      disputas.add(
        GovernorRace(
          uf: entry.key.sigla,
          name: entry.key.label,
          region: entry.key.region,
          electorate: r.electorate.total,
          countedShare: r.sections.countedShare.clamp(0.0, 1.0),
          leader: _governorCandidate(lider, eleicao, entry.key),
          runnerUp: _governorCandidate(vice, eleicao, entry.key),
          declaredStatus: _statusFromTse(lider),
        ),
      );
    }

    disputas.sort((x, y) => y.electorate.compareTo(x.electorate));
    return disputas;
  }

  static GovernorCandidate _governorCandidate(
    TseCandidate c,
    int eleicao,
    Uf uf,
  ) {
    return GovernorCandidate(
      identity: CandidateIdentity(
        number: c.number,
        name: c.ballotName,
        party: c.party,
        // A foto de candidato estadual fica sob a abrangência da UF, não
        // sob `br` como a dos presidenciáveis.
        portrait: _portrait(c, eleicao: eleicao, abrangencia: uf.slug),
      ),
      votes: c.votes,
      share: c.share.clamp(0.0, 1.0),
    );
  }

  static ImageProvider? _portrait(
    TseCandidate c, {
    required int eleicao,
    required String abrangencia,
  }) {
    if (c.sqcand.isEmpty) return null;
    return NetworkImage(
      TseEndpoints.portrait(
        eleicao: eleicao,
        sqcand: c.sqcand,
        abrangencia: abrangencia,
      ).toString(),
    );
  }

  /// Zona ZZ — o TSE publica o exterior como se fosse uma UF.
  static OverseasTally overseas(TseResult r, {required int eleicao}) {
    return OverseasTally(
      candidates: [
        for (final c in r.candidates)
          OverseasCandidate(
            identity: CandidateIdentity(
              number: c.number,
              name: c.ballotName,
              party: c.party,
              portrait: _portrait(c, eleicao: eleicao, abrangencia: 'zz'),
            ),
            votes: c.votes,
            share: c.share.clamp(0.0, 1.0),
          ),
      ],
      validVotes: r.votes.valid,
      electorate: r.electorate.total,
      turnout: r.electorate.turnout,
      countedShare: r.sections.countedShare.clamp(0.0, 1.0),
      sections: r.sections.total,
    );
  }

  /// Situação que o TSE declara, quando declara.
  ///
  /// Se o órgão oficial já disse que elegeu ou que vai a segundo turno, a
  /// palavra é dele. Sem declaração, devolve nulo e a derivação local
  /// assume.
  static RaceStatus? _statusFromTse(TseCandidate lider) {
    final situacao = lider.situation.toLowerCase();
    if (situacao.contains('turno')) return RaceStatus.tooCloseToCall;
    if (lider.elected || situacao.contains('eleito')) {
      return RaceStatus.elected;
    }
    return null;
  }
}
