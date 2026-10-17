import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:painel_eleicoes_2026/models/candidate_identity.dart';
import 'package:painel_eleicoes_2026/models/demo_races.dart';
import 'package:painel_eleicoes_2026/models/governor_race.dart';
import 'package:painel_eleicoes_2026/screens/governadores_screen.dart';
import 'package:painel_eleicoes_2026/theme/party_colors.dart';
import 'package:painel_eleicoes_2026/widgets/candidate_avatar.dart';
import 'package:painel_eleicoes_2026/widgets/elected_summary.dart';
import 'package:painel_eleicoes_2026/widgets/governor_map.dart';
import 'package:painel_eleicoes_2026/widgets/governor_race_card.dart';

import 'helpers.dart';

void main() {
  usarImagensFalsas();

  GovernorRace porUf(String uf) =>
      DemoRaces.all.firstWhere((race) => race.uf == uf);

  group('GovernorRace.status', () {
    // Os rótulos que a tela do Stitch mostra em cada card. A regra derivada
    // precisa reproduzir os nove — inclusive os dois casos que um limiar
    // fixo de margem erraria: SE (3,40 p.p.) está decidido e PE (3,80 p.p.)
    // não, porque o que falta apurar é diferente.
    const esperado = {
      'SP': RaceStatus.leading,
      'RS': RaceStatus.tooCloseToCall,
      'BA': RaceStatus.leading,
      'SC': RaceStatus.elected,
      'PE': RaceStatus.tooCloseToCall,
      'MS': RaceStatus.leading,
      'AM': RaceStatus.leading,
      'SE': RaceStatus.leading,
      'ES': RaceStatus.tooCloseToCall,
    };

    test('reproduz os rótulos do design', () {
      for (final entry in esperado.entries) {
        expect(
          porUf(entry.key).status,
          entry.value,
          reason: '${entry.key} deveria ser ${entry.value.chipLabel}',
        );
      }
    });

    test('a virada acontece quando o pendente alcança a diferença', () {
      final pe = porUf('PE');
      final se = porUf('SE');

      // PE tem margem maior que SE, mas muito mais seção pendente.
      expect(pe.margin, greaterThan(se.margin));
      expect(pe.remaining, greaterThan(pe.margin));
      expect(se.remaining, lessThan(se.margin));
    });

    test('totalização concluída encerra a disputa', () {
      expect(porUf('SC').countedShare, 1);
      expect(porUf('SC').status, RaceStatus.elected);
      expect(porUf('SC').status.footnoteLabel, 'Matematicamente Eleito');
    });

    test('diferença em votos bate com os totais exibidos', () {
      final sp = porUf('SP');
      expect(sp.voteGap, sp.leader.votes - sp.runnerUp.votes);
      expect(sp.voteGap, 1782728);
    });
  });

  group('resumo e totais', () {
    test('conta cada situação', () {
      final resumo = RaceSummary.from(DemoRaces.all);
      expect(resumo.total, 9);
      expect(resumo[RaceStatus.elected], 1);
      expect(resumo[RaceStatus.leading], 5);
      expect(resumo[RaceStatus.tooCloseToCall], 3);
    });

    test('o apurado geral é ponderado pelo eleitorado', () {
      const grande = GovernorRace(
        uf: 'XX',
        name: 'Grande',
        region: Region.sudeste,
        electorate: 9000000,
        countedShare: 1,
        leader: GovernorCandidate(
          identity: CandidateIdentity(name: 'A', party: 'P'),
          votes: 6,
          share: 0.6,
        ),
        runnerUp: GovernorCandidate(
          identity: CandidateIdentity(name: 'B', party: 'Q'),
          votes: 4,
          share: 0.4,
        ),
      );
      const pequeno = GovernorRace(
        uf: 'YY',
        name: 'Pequeno',
        region: Region.norte,
        electorate: 1000000,
        countedShare: 0,
        leader: GovernorCandidate(
          identity: CandidateIdentity(name: 'A', party: 'P'),
          votes: 6,
          share: 0.6,
        ),
        runnerUp: GovernorCandidate(
          identity: CandidateIdentity(name: 'B', party: 'Q'),
          votes: 4,
          share: 0.4,
        ),
      );

      // Média simples daria 0,5; ponderada dá 0,9.
      expect(overallCountedShare([grande, pequeno]), closeTo(0.9, 1e-9));
      expect(overallCountedShare([]), 0);
    });
  });

  group('GovernorRaceCard', () {
    testWidgets('disputa encerrada traz selo e não pulsa', (tester) async {
      await pumpInTheme(
        tester,
        SizedBox(width: 480, child: GovernorRaceCard(race: porUf('SC'))),
      );

      expect(find.text('ELEITO DEFINITIVO'), findsOneWidget);
      expect(find.text('TOTALIZAÇÃO CONCLUÍDA'), findsOneWidget);
      expect(find.text('Matematicamente Eleito'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('+1.546.915'), findsOneWidget);
    });

    testWidgets('voto a voto mostra a margem em pontos', (tester) async {
      await pumpInTheme(
        tester,
        SizedBox(width: 480, child: GovernorRaceCard(race: porUf('RS'))),
      );

      expect(find.text('DISPUTA ACIRRADA'), findsOneWidget);
      expect(find.text('Margem Voto a Voto'), findsOneWidget);
      expect(find.text('votos (1,6%)'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('liderando mostra diferença nominal', (tester) async {
      await pumpInTheme(
        tester,
        SizedBox(width: 480, child: GovernorRaceCard(race: porUf('SP'))),
      );

      expect(find.text('LIDERANDO'), findsOneWidget);
      expect(find.text('Diferença Nominal'), findsOneWidget);
      expect(find.text('Tarcísio Gomes'), findsOneWidget);
      expect(find.text('53,80%'), findsOneWidget);
      expect(find.text('(12.618.340)'), findsOneWidget);
    });

    testWidgets('card estreito com partido longo não estoura', (tester) async {
      await pumpInTheme(
        tester,
        SizedBox(width: 320, child: GovernorRaceCard(race: porUf('PE'))),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('GovernadoresScreen', () {
    testWidgets('mostra as disputas que vieram do TSE', (tester) async {
      final c = fakeApuracao();
      addTearDown(c.dispose);
      await c.load();
      await c.loadDetails();

      await pumpInTheme(
        tester,
        const GovernadoresScreen(),
        surface: const Size(1400, 1000),
        apuracao: c,
      );

      // A fixture responde a mesma carga de SP para toda UF, então são 27
      // disputas — o que interessa aqui é que vieram do controller e que o
      // candidato é o real, não o inventado.
      expect(find.byType(GovernorRaceCard), findsWidgets);
      expect(find.textContaining('Todos ('), findsOneWidget);
      expect(find.textContaining('TARCÍSIO'), findsWidgets);
    });

    testWidgets('sem carga, avisa em vez de mostrar dado falso', (
      tester,
    ) async {
      final c = fakeApuracao();
      addTearDown(c.dispose);

      await pumpInTheme(
        tester,
        const GovernadoresScreen(),
        surface: const Size(1400, 1000),
        apuracao: c,
      );

      expect(find.byType(GovernorRaceCard), findsNothing);
      expect(find.textContaining('Buscando as disputas'), findsOneWidget);
    });

    testWidgets('filtrar por região reduz a grade', (tester) async {
      final c = fakeApuracao();
      addTearDown(c.dispose);
      await c.load();
      await c.loadDetails();

      await pumpInTheme(
        tester,
        const GovernadoresScreen(),
        surface: const Size(1400, 1000),
        apuracao: c,
      );

      final todas = tester.widgetList(find.byType(GovernorRaceCard)).length;
      await tester.tap(find.textContaining('Sul ('));
      await settle(tester);

      final doSul = tester.widgetList(find.byType(GovernorRaceCard)).length;
      expect(doSul, lessThan(todas));
      expect(doSul, 3); // PR, RS, SC
    });

    testWidgets('sem feed o status não finge conexão', (tester) async {
      await pumpInTheme(
        tester,
        const GovernadoresScreen(),
        surface: const Size(1400, 1000),
      );

      expect(find.text('Sem canal TSE'), findsOneWidget);
      expect(find.text('Conectado TSE-DF'), findsNothing);
      expect(find.text('--:-- BRT'), findsOneWidget);
    });
  });

  group('PartyColors', () {
    test('toda sigla em cena tem cor própria, sem cair no fallback', () {
      final siglas = <String>{
        for (final race in DemoRaces.all) ...[
          race.leader.party,
          race.runnerUp.party,
        ],
      };

      for (final sigla in siglas) {
        expect(
          PartyColors.isKnown(sigla),
          isTrue,
          reason: '$sigla sem cor cadastrada',
        );
        expect(PartyColors.of(sigla), isNot(PartyColors.fallback));
      }
    });

    test('sigla desconhecida cai no neutro, sem inventar cor', () {
      expect(PartyColors.of('XYZ'), PartyColors.fallback);
      expect(PartyColors.isKnown('XYZ'), isFalse);
    });

    test('a busca ignora caixa e espaço', () {
      expect(PartyColors.of(' pt '), PartyColors.of('PT'));
    });

    test('cores distantes e já legíveis passam intactas', () {
      final pt = PartyColors.of('PT');
      final psdb = PartyColors.of('PSDB');
      expect(PartyColors.distinguish(pt, psdb), psdb);
    });

    test('nenhuma cor afastada some no fundo escuro', () {
      // O PSD contra o azul do PL foi o caso que quebrou: separar
      // escurecendo deixava a legenda ilegível em `#0F131C`.
      for (final sigla in ['PSD', 'PT', 'PSDB', 'MDB', 'PL', 'PRTB']) {
        final ajustada = PartyColors.distinguish(
          PartyColors.of('PL'),
          PartyColors.of(sigla),
        );
        expect(
          HSLColor.fromColor(ajustada).lightness,
          greaterThanOrEqualTo(0.43),
          reason: '$sigla ficou escuro demais para o fundo do painel',
        );
      }
    });

    test('cores próximas são afastadas mantendo o matiz', () {
      const azul = Color(0xFF2F6FD0);
      const quaseIgual = Color(0xFF3272D4);

      final afastada = PartyColors.distinguish(azul, quaseIgual);
      expect(afastada, isNot(quaseIgual));

      final matizOriginal = HSLColor.fromColor(quaseIgual).hue;
      final matizNovo = HSLColor.fromColor(afastada).hue;
      expect(matizNovo, closeTo(matizOriginal, 2));

      final lumOriginal = HSLColor.fromColor(quaseIgual).lightness;
      final lumNova = HSLColor.fromColor(afastada).lightness;
      // Sempre para cima: num fundo escuro, clarear é o único lado seguro.
      expect(lumNova, greaterThan(lumOriginal + 0.1));
    });

    test(
      'siglas desconhecidas caem nas cores semânticas, não em dois cinzas',
      () {
        const verde = Color(0xFF3FE56C);
        const ambar = Color(0xFFFFB95F);

        final (lider, vice) = PartyColors.pairFor(
          'PLP',
          'FED',
          leaderFallback: verde,
          runnerUpFallback: ambar,
        );
        expect(lider, verde);
        expect(vice, ambar);
      },
    );

    test('sigla conhecida de um lado só não arrasta o outro para o cinza', () {
      const verde = Color(0xFF3FE56C);
      const ambar = Color(0xFFFFB95F);

      final (lider, vice) = PartyColors.pairFor(
        'PT',
        'INEXISTENTE',
        leaderFallback: verde,
        runnerUpFallback: ambar,
      );
      expect(lider, PartyColors.of('PT'));
      expect(vice, isNot(PartyColors.fallback));
    });

    test('nas disputas reais os dois lados nunca somem um no outro', () {
      for (final race in DemoRaces.all) {
        final lider = PartyColors.of(race.leader.party);
        final vice = PartyColors.distinguish(
          lider,
          PartyColors.of(race.runnerUp.party),
        );
        final distancia =
            ((lider.r - vice.r) * (lider.r - vice.r) +
                (lider.g - vice.g) * (lider.g - vice.g) +
                (lider.b - vice.b) * (lider.b - vice.b)) /
            3;
        expect(
          distancia,
          greaterThanOrEqualTo(0.02),
          reason:
              '${race.uf}: ${race.leader.party} x '
              '${race.runnerUp.party} ficaram indistinguíveis',
        );
      }
    });
  });

  group('CandidateAvatar', () {
    test('iniciais pegam o primeiro e o último nome', () {
      expect(CandidateAvatar.initialsOf('Tarcísio Gomes'), 'TG');
      expect(CandidateAvatar.initialsOf('ACM Neto'), 'AN');
      expect(CandidateAvatar.initialsOf('Rogério Carvalho'), 'RC');
    });

    test('conectivos não viram inicial', () {
      expect(CandidateAvatar.initialsOf('Maria da Silva'), 'MS');
      expect(CandidateAvatar.initialsOf('João dos Santos'), 'JS');
      expect(CandidateAvatar.initialsOf('Ana e Costa'), 'AC');
    });

    test('nome único e entrada vazia não quebram', () {
      expect(CandidateAvatar.initialsOf('Lula'), 'LU');
      expect(CandidateAvatar.initialsOf('X'), 'X');
      expect(CandidateAvatar.initialsOf('   '), '?');
      expect(CandidateAvatar.initialsOf('  Tiririca  '), 'TI');
    });

    testWidgets('sem foto, o card mostra as iniciais dos dois', (tester) async {
      await pumpInTheme(
        tester,
        SizedBox(width: 480, child: GovernorRaceCard(race: porUf('SP'))),
      );

      expect(find.text('TG'), findsOneWidget); // Tarcísio Gomes
      expect(find.text('FH'), findsOneWidget); // Fernando Haddad
    });

    testWidgets('com foto, as iniciais saem de cena', (tester) async {
      await pumpInTheme(
        tester,
        const CandidateAvatar(
          name: 'Tarcísio Gomes',
          color: Color(0xFF5C8AE6),
          portrait: AssetImage('assets/images/candidato-a.jpg'),
        ),
      );

      expect(find.text('TG'), findsNothing);
    });
  });

  group('situação declarada pelo servidor', () {
    test('o TSE vence a derivação local', () {
      final sp = porUf('SP');
      expect(sp.status, RaceStatus.leading);

      final declarada = GovernorRace(
        uf: sp.uf,
        name: sp.name,
        region: sp.region,
        electorate: sp.electorate,
        countedShare: sp.countedShare,
        leader: sp.leader,
        runnerUp: sp.runnerUp,
        declaredStatus: RaceStatus.tooCloseToCall,
      );

      expect(declarada.status, RaceStatus.tooCloseToCall);
    });

    test('sem declaração, a derivação continua valendo', () {
      expect(porUf('RS').declaredStatus, isNull);
      expect(porUf('RS').status, RaceStatus.tooCloseToCall);
    });
  });

  group('destaque dos eleitos', () {
    testWidgets('card de disputa encerrada ganha moldura e rosto maior', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        SizedBox(width: 480, child: GovernorRaceCard(race: porUf('SC'))),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(GovernorRaceCard),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoracao = container.decoration! as BoxDecoration;
      expect(decoracao.border, isNotNull, reason: 'faltou a moldura');
      expect(decoracao.boxShadow, isNotNull, reason: 'faltou o brilho');

      // O rosto do vencedor é maior que o do segundo.
      final avatares = tester
          .widgetList<CandidateAvatar>(find.byType(CandidateAvatar))
          .toList();
      expect(avatares.first.size, greaterThan(avatares.last.size));
    });

    testWidgets('dentro do card o vencedor se separa do derrotado', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        SizedBox(width: 520, child: GovernorRaceCard(race: porUf('SC'))),
      );

      // Troféu só na linha de quem venceu.
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);

      // O derrotado recua, o vencedor não.
      final recuos = tester.widgetList<Opacity>(
        find.descendant(
          of: find.byType(GovernorRaceCard),
          matching: find.byType(Opacity),
        ),
      );
      expect(recuos, hasLength(1));
      expect(recuos.first.opacity, lessThan(1));
    });

    testWidgets('disputa aberta trata os dois lados igual', (tester) async {
      await pumpInTheme(
        tester,
        SizedBox(width: 520, child: GovernorRaceCard(race: porUf('RS'))),
      );

      expect(find.byIcon(Icons.emoji_events), findsNothing);
      expect(
        find.descendant(
          of: find.byType(GovernorRaceCard),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });

    testWidgets('disputa aberta não leva moldura', (tester) async {
      await pumpInTheme(
        tester,
        SizedBox(width: 480, child: GovernorRaceCard(race: porUf('RS'))),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(GovernorRaceCard),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoracao = container.decoration! as BoxDecoration;
      expect(decoracao.border, isNull);
      expect(decoracao.boxShadow, isNull);
    });
  });

  group('ElectedSummary', () {
    testWidgets('lista os eleitos com UF, nome e partido', (tester) async {
      final eleitos = DemoRaces.all
          .where((r) => r.status == RaceStatus.elected)
          .toList();

      await pumpInTheme(
        tester,
        SizedBox(width: 900, child: ElectedSummary(races: eleitos)),
        surface: const Size(1000, 700),
      );

      expect(find.textContaining('JÁ ELEITOS'), findsOneWidget);
      expect(find.text('${eleitos.length} de 27'), findsOneWidget);
      for (final race in eleitos) {
        expect(find.text(race.uf), findsOneWidget);
      }
    });

    testWidgets('lista vazia não desenha nada', (tester) async {
      await pumpInTheme(tester, const ElectedSummary(races: []));
      expect(find.textContaining('JÁ ELEITOS'), findsNothing);
    });
  });

  group('GovernorMap', () {
    testWidgets('eleito ganha um rosto; disputa aberta ganha o duelo', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        SizedBox(width: 900, child: GovernorMap(races: DemoRaces.all)),
        surface: const Size(1000, 900),
      );

      final eleitos = DemoRaces.all
          .where((r) => r.status == RaceStatus.elected)
          .length;
      final abertas = DemoRaces.all.length - eleitos;

      // Um rosto por eleito, dois por disputa em aberto.
      expect(
        find.byType(CandidateAvatar),
        findsNWidgets(eleitos + abertas * 2),
      );
      // E o selo de 2º turno em cada disputa aberta.
      expect(find.text('2'), findsNWidgets(abertas));
      expect(tester.takeException(), isNull);
    });

    testWidgets('sem disputa nenhuma o mapa ainda desenha', (tester) async {
      await pumpInTheme(
        tester,
        const SizedBox(width: 900, child: GovernorMap(races: [])),
        surface: const Size(1000, 900),
      );

      expect(find.byType(CandidateAvatar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
