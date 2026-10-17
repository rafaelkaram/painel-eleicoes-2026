import 'candidate_identity.dart';
import 'governor_race.dart';

/// Disputas estaduais de exemplo, transcritas da tela do Stitch.
///
/// NÃO são resultado de eleição nenhuma. Os nomes são de figuras públicas
/// reais, mas os números são inventados — por isso a tela carrega o aviso de
/// dados de exemplo em destaque. Some junto com a entrada do feed do TSE.
///
/// O design fala em 12 unidades federativas no subtítulo, mas a tela gerada
/// traz 9 cards. Ficaram as 9 que existem: contagens, filtros e percentual
/// geral são todos derivados desta lista, então nada diverge.
abstract final class DemoRaces {
  static const all = <GovernorRace>[
    GovernorRace(
      uf: 'SP',
      name: 'São Paulo',
      region: Region.sudeste,
      electorate: 34667793,
      countedShare: 0.9740,
      leader: GovernorCandidate(
        identity: CandidateIdentity(name: 'Tarcísio Gomes', party: 'REP'),
        votes: 12618340,
        share: 0.5380,
      ),
      runnerUp: GovernorCandidate(
        identity: CandidateIdentity(name: 'Fernando Haddad', party: 'PT'),
        votes: 10835612,
        share: 0.4620,
      ),
    ),
    GovernorRace(
      uf: 'RS',
      name: 'Rio Grande do Sul',
      region: Region.sul,
      electorate: 8593418,
      countedShare: 0.9410,
      leader: GovernorCandidate(
        identity: CandidateIdentity(name: 'Eduardo Leite', party: 'PSDB'),
        votes: 3185042,
        share: 0.5080,
      ),
      runnerUp: GovernorCandidate(
        identity: CandidateIdentity(name: 'Onyx Lorenzoni', party: 'PL'),
        votes: 3084718,
        share: 0.4920,
      ),
    ),
    GovernorRace(
      uf: 'BA',
      name: 'Bahia',
      region: Region.nordeste,
      electorate: 11291528,
      countedShare: 0.9820,
      leader: GovernorCandidate(
        identity: CandidateIdentity(name: 'Jerônimo Rodrigues', party: 'PT'),
        votes: 4382110,
        share: 0.5240,
      ),
      runnerUp: GovernorCandidate(
        identity: CandidateIdentity(name: 'ACM Neto', party: 'UNIÃO'),
        votes: 3980609,
        share: 0.4760,
      ),
    ),
    GovernorRace(
      uf: 'SC',
      name: 'Santa Catarina',
      region: Region.sul,
      electorate: 5489658,
      countedShare: 1,
      leader: GovernorCandidate(
        identity: CandidateIdentity(name: 'Jorginho Mello', party: 'PL'),
        votes: 2864881,
        share: 0.6850,
      ),
      runnerUp: GovernorCandidate(
        identity: CandidateIdentity(name: 'Décio Lima', party: 'PT'),
        votes: 1317966,
        share: 0.3150,
      ),
    ),
    GovernorRace(
      uf: 'PE',
      name: 'Pernambuco',
      region: Region.nordeste,
      electorate: 7018098,
      countedShare: 0.9200,
      leader: GovernorCandidate(
        identity: CandidateIdentity(name: 'Raquel Lyra', party: 'PSDB'),
        votes: 2639400,
        share: 0.5190,
      ),
      runnerUp: GovernorCandidate(
        identity: CandidateIdentity(
          name: 'Marília Arraes',
          party: 'SOLIDARIEDADE',
        ),
        votes: 2446160,
        share: 0.4810,
      ),
    ),
    GovernorRace(
      uf: 'MS',
      name: 'Mato Grosso do Sul',
      region: Region.centroOeste,
      electorate: 1996510,
      countedShare: 0.9580,
      leader: GovernorCandidate(
        identity: CandidateIdentity(name: 'Eduardo Riedel', party: 'PSDB'),
        votes: 772480,
        share: 0.5410,
      ),
      runnerUp: GovernorCandidate(
        identity: CandidateIdentity(name: 'Capitão Contar', party: 'PRTB'),
        votes: 655402,
        share: 0.4590,
      ),
    ),
    GovernorRace(
      uf: 'AM',
      name: 'Amazonas',
      region: Region.norte,
      electorate: 2647748,
      countedShare: 0.8950,
      leader: GovernorCandidate(
        identity: CandidateIdentity(name: 'Wilson Lima', party: 'UNIÃO'),
        votes: 928310,
        share: 0.5665,
      ),
      runnerUp: GovernorCandidate(
        identity: CandidateIdentity(name: 'Eduardo Braga', party: 'MDB'),
        votes: 710344,
        share: 0.4335,
      ),
    ),
    GovernorRace(
      uf: 'SE',
      name: 'Sergipe',
      region: Region.nordeste,
      electorate: 1671801,
      countedShare: 0.9910,
      leader: GovernorCandidate(
        identity: CandidateIdentity(name: 'Fábio Mitidieri', party: 'PSD'),
        votes: 590220,
        share: 0.5170,
      ),
      runnerUp: GovernorCandidate(
        identity: CandidateIdentity(name: 'Rogério Carvalho', party: 'PT'),
        votes: 551411,
        share: 0.4830,
      ),
    ),
    GovernorRace(
      uf: 'ES',
      name: 'Espírito Santo',
      region: Region.sudeste,
      electorate: 2921459,
      countedShare: 0.9630,
      leader: GovernorCandidate(
        identity: CandidateIdentity(name: 'Renato Casagrande', party: 'PSB'),
        votes: 1054410,
        share: 0.5090,
      ),
      runnerUp: GovernorCandidate(
        identity: CandidateIdentity(name: 'Carlos Manato', party: 'PL'),
        votes: 1017130,
        share: 0.4910,
      ),
    ),
  ];
}
