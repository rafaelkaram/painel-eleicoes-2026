import 'package:flutter/widgets.dart';

import 'candidate_identity.dart';
import 'candidate_tally.dart';
import 'overseas_tally.dart';
import 'state_tally.dart';
import 'vote_breakdown.dart';

/// Números de exemplo para desenvolver a tela antes de existir o feed do TSE.
///
/// NÃO são resultado de eleição nenhuma. Toda tela que consome isto precisa
/// deixar isso visível para quem olha — ver o aviso em
/// `ApuracaoPresidencialScreen`. Some junto com a entrada do feed real.
abstract final class DemoTallies {
  static const leading = CandidateTally(
    identity: CandidateIdentity(
      number: 13,
      name: 'Candidato A',
      coalition: 'Coligação Brasil do Futuro',
      portrait: AssetImage('assets/images/candidato-a.jpg'),
    ),
    votes: 58940120,
    share: 0.5172,
    standing: CandidateStanding.leading,
    standingLabel: 'Liderando com +3.920.800 votos',
    footnote: 'Matemática e Politicamente Líder',
    statesLabel: '14 ESTADOS + DF',
  );

  static const runnerUp = CandidateTally(
    identity: CandidateIdentity(
      number: 22,
      name: 'Candidato B',
      coalition: 'Aliança Nacional',
      portrait: AssetImage('assets/images/candidato-b.jpg'),
    ),
    votes: 55019320,
    share: 0.4828,
    standing: CandidateStanding.runnerUp,
    standingLabel: '2º Colocado',
    footnote: 'Diferença Nominal: -3.920.800 (-3,44%)',
    statesLabel: '12 ESTADOS',
  );

  /// Nome e coligação longos com margem apertada — o caso que quebra layout.
  static const stressTest = CandidateTally(
    identity: CandidateIdentity(
      number: 99,
      name: 'Maria Aparecida de Albuquerque',
      coalition: 'Coligação União e Reconstrução Nacional do Brasil',
    ),
    votes: 50123456,
    share: 0.5001,
    standing: CandidateStanding.leading,
    standingLabel: 'Liderando com +12.904 votos',
    footnote: 'Diferença dentro da margem de recontagem',
    statesLabel: '13 ESTADOS',
  );

  /// Fração de urnas totalizadas.
  static const urnsCounted = 0.9685;

  static const breakdown = <VoteBreakdown>[
    VoteBreakdown(label: 'VOTOS VÁLIDOS', share: 0.9420, votes: 113959440),
    VoteBreakdown(label: 'VOTOS NULOS', share: 0.0360, votes: 4355080),
    VoteBreakdown(label: 'VOTOS EM BRANCO', share: 0.0220, votes: 2661440),
    VoteBreakdown(
      label: 'ABSTENÇÃO ELEITORAL',
      share: 0.1910,
      votes: 28530110,
      tone: VoteBreakdownTone.alert,
    ),
  ];

  /// Margem de recontagem: a barra comparativa precisa ficar legível quando
  /// as duas fatias são quase iguais.
  static const photoFinishLeading = CandidateTally(
    identity: CandidateIdentity(
      number: 13,
      name: 'Candidato A',
      coalition: 'Coligação Brasil do Futuro',
    ),
    votes: 56980120,
    share: 0.5003,
    standing: CandidateStanding.leading,
    standingLabel: 'Liderando com +68.400 votos',
    footnote: 'Dentro da margem de recontagem',
    statesLabel: '13 ESTADOS',
  );

  static const photoFinishRunnerUp = CandidateTally(
    identity: CandidateIdentity(
      number: 22,
      name: 'Candidato B',
      coalition: 'Aliança Nacional',
    ),
    votes: 56911720,
    share: 0.4997,
    standing: CandidateStanding.runnerUp,
    standingLabel: '2º Colocado',
    footnote: 'Diferença Nominal: -68.400 (-0,06%)',
    statesLabel: '13 ESTADOS + DF',
  );

  /// Zona ZZ do 1º turno de 2026, transcrita do TSE.
  ///
  /// Serve de amostra para preview e teste. Em produção o painel busca a
  /// carga ao vivo; estes números são os que o TSE publicou.
  static const overseas = OverseasTally(
    sections: 1351,
    countedShare: 1,
    electorate: 916534,
    turnout: 341766,
    validVotes: 330882,
    candidates: [
      OverseasCandidate(
        identity: CandidateIdentity(number: 13, name: 'LULA', party: 'PT'),
        votes: 157387,
        share: 0.4757,
      ),
      OverseasCandidate(
        identity: CandidateIdentity(
          number: 22,
          name: 'FLAVIO BOLSONARO',
          party: 'PL',
        ),
        votes: 143900,
        share: 0.4349,
      ),
      OverseasCandidate(
        identity: CandidateIdentity(
          number: 70,
          name: 'ESCRITOR AUGUSTO CURY',
          party: 'AVANTE',
        ),
        votes: 9734,
        share: 0.0294,
      ),
    ],
  );

  static const states = <StateTally>[
    // Norte
    StateTally(uf: 'AC', name: 'Acre', shareA: 0.4120, countedShare: 0.996),
    StateTally(uf: 'AP', name: 'Amapá', shareA: 0.5840, countedShare: 0.991),
    StateTally(uf: 'AM', name: 'Amazonas', shareA: 0.5310, countedShare: 0.978),
    StateTally(uf: 'PA', name: 'Pará', shareA: 0.5695, countedShare: 0.984),
    StateTally(uf: 'RO', name: 'Rondônia', shareA: 0.3880, countedShare: 0.995),
    StateTally(uf: 'RR', name: 'Roraima', shareA: 0.3640, countedShare: 0.998),
    StateTally(
      uf: 'TO',
      name: 'Tocantins',
      shareA: 0.5420,
      countedShare: 0.993,
    ),
    // Nordeste
    StateTally(uf: 'MA', name: 'Maranhão', shareA: 0.7180, countedShare: 0.987),
    StateTally(uf: 'PI', name: 'Piauí', shareA: 0.7640, countedShare: 0.992),
    StateTally(uf: 'CE', name: 'Ceará', shareA: 0.6910, countedShare: 0.989),
    StateTally(
      uf: 'RN',
      name: 'Rio Grande do Norte',
      shareA: 0.6420,
      countedShare: 0.994,
    ),
    StateTally(uf: 'PB', name: 'Paraíba', shareA: 0.6080, countedShare: 0.996),
    StateTally(
      uf: 'PE',
      name: 'Pernambuco',
      shareA: 0.6530,
      countedShare: 0.985,
    ),
    StateTally(uf: 'AL', name: 'Alagoas', shareA: 0.6240, countedShare: 0.997),
    StateTally(uf: 'SE', name: 'Sergipe', shareA: 0.6370, countedShare: 0.998),
    StateTally(uf: 'BA', name: 'Bahia', shareA: 0.7145, countedShare: 0.994),
    // Centro-Oeste
    StateTally(
      uf: 'DF',
      name: 'Distrito Federal',
      shareA: 0.5090,
      countedShare: 0.999,
    ),
    StateTally(uf: 'GO', name: 'Goiás', shareA: 0.4210, countedShare: 0.990),
    StateTally(
      uf: 'MT',
      name: 'Mato Grosso',
      shareA: 0.3730,
      countedShare: 0.993,
    ),
    StateTally(
      uf: 'MS',
      name: 'Mato Grosso do Sul',
      shareA: 0.4050,
      countedShare: 0.995,
    ),
    // Sudeste
    StateTally(
      uf: 'MG',
      name: 'Minas Gerais',
      shareA: 0.5068,
      countedShare: 0.990,
    ),
    StateTally(
      uf: 'SP',
      name: 'São Paulo',
      shareA: 0.4588,
      countedShare: 0.980,
    ),
    StateTally(
      uf: 'RJ',
      name: 'Rio de Janeiro',
      shareA: 0.4740,
      countedShare: 0.982,
    ),
    StateTally(
      uf: 'ES',
      name: 'Espírito Santo',
      shareA: 0.4460,
      countedShare: 0.988,
    ),
    // Sul
    StateTally(uf: 'PR', name: 'Paraná', shareA: 0.4310, countedShare: 0.991),
    StateTally(
      uf: 'SC',
      name: 'Santa Catarina',
      shareA: 0.3920,
      countedShare: 0.994,
    ),
    StateTally(
      uf: 'RS',
      name: 'Rio Grande do Sul',
      shareA: 0.4220,
      countedShare: 0.970,
    ),
  ];
}
