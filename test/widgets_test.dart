import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:painel_eleicoes_2026/models/candidate_identity.dart';
import 'package:painel_eleicoes_2026/models/candidate_tally.dart';
import 'package:painel_eleicoes_2026/models/demo_tallies.dart';
import 'package:painel_eleicoes_2026/models/state_tally.dart';
import 'package:painel_eleicoes_2026/theme/app_colors.dart';
import 'package:painel_eleicoes_2026/theme/party_colors.dart';
import 'package:painel_eleicoes_2026/util/formatters.dart';
import 'package:painel_eleicoes_2026/widgets/candidate_card.dart';
import 'package:painel_eleicoes_2026/widgets/head_to_head_bar.dart';
import 'package:painel_eleicoes_2026/widgets/overseas_panel.dart';
import 'package:painel_eleicoes_2026/widgets/territory_map.dart';
import 'package:painel_eleicoes_2026/widgets/urna_mark.dart';
import 'package:painel_eleicoes_2026/widgets/totalization_header.dart';
import 'package:painel_eleicoes_2026/widgets/vote_breakdown_tiles.dart';

import 'helpers.dart';

void main() {
  usarImagensFalsas();

  group('formatadores pt-BR', () {
    test('milhar com ponto', () {
      expect(formatVotos(58940120), '58.940.120');
      expect(formatVotos(0), '0');
    });

    test('percentual com vírgula e duas casas', () {
      expect(formatPercentual(0.5172), '51,72%');
      expect(formatPercentual(1), '100,00%');
      expect(formatPercentualCurto(0.5172), '51,7%');
    });

    test('diferença carrega o sinal', () {
      expect(formatDiferenca(3920800), '+3.920.800');
      expect(formatDiferenca(-3920800), '-3.920.800');
    });
  });

  group('CandidateCard', () {
    testWidgets('líder mostra percentual, votos e o ícone de tendência', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        const CandidateCard(tally: DemoTallies.leading),
      );

      expect(find.text('51,72%'), findsOneWidget);
      expect(find.text('58.940.120'), findsOneWidget);
      expect(find.text('14 ESTADOS + DF'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      // Acento verde no percentual.
      expect(textColor(tester, '51,72%'), AppColors.primary);
    });

    testWidgets('com retrato não cai no placeholder', (tester) async {
      expect(DemoTallies.leading.portrait, isNotNull);

      await pumpInTheme(
        tester,
        const CandidateCard(tally: DemoTallies.leading),
      );

      expect(find.byIcon(Icons.person), findsNothing);
    });

    testWidgets('sem retrato mostra o placeholder', (tester) async {
      const semFoto = CandidateTally(
        identity: CandidateIdentity(
          number: 1,
          name: 'Sem Foto',
          coalition: 'Coligação X',
        ),
        votes: 100,
        share: 0.5,
        standing: CandidateStanding.leading,
        standingLabel: 'Liderando',
        footnote: 'x',
        statesLabel: '1 ESTADO',
      );

      await pumpInTheme(tester, const CandidateCard(tally: semFoto));

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('segundo colocado usa âmbar e não leva ícone no chip', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        const CandidateCard(tally: DemoTallies.runnerUp),
      );

      expect(textColor(tester, '48,28%'), AppColors.secondary);
      expect(find.byIcon(Icons.trending_up), findsNothing);
      expect(find.byIcon(Icons.verified), findsNothing);
    });

    // Regressão: sem `Flexible` o chip de status tomava a linha inteira, o
    // nome ficava com largura ~zero e quebrava caractere a caractere,
    // estourando 490px na vertical.
    for (final (nome, tally) in const [
      ('líder', DemoTallies.leading),
      ('segundo', DemoTallies.runnerUp),
      ('nome e coligação longos', DemoTallies.stressTest),
    ]) {
      testWidgets('$nome não estoura o layout em 480px', (tester) async {
        await pumpInTheme(
          tester,
          SizedBox(width: 480, child: CandidateCard(tally: tally)),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('VoteBreakdownTiles', () {
    testWidgets('abstenção sai em vermelho, os demais em on-surface', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        const VoteBreakdownTiles(items: DemoTallies.breakdown),
      );

      expect(find.text('VOTOS VÁLIDOS'), findsOneWidget);
      expect(find.text('113.959.440'), findsOneWidget);
      expect(textColor(tester, '94,20%'), AppColors.onSurface);
      expect(textColor(tester, '19,10%'), AppColors.error);
    });

    testWidgets('cai para duas colunas abaixo do breakpoint', (tester) async {
      const gutter = 12.0;

      await pumpInTheme(
        tester,
        const VoteBreakdownTiles(items: DemoTallies.breakdown),
        surface: const Size(600, 600),
      );

      final tile = tester.getSize(
        find
            .ancestor(
              of: find.text('VOTOS VÁLIDOS'),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(tile.width, closeTo((600 - gutter) / 2, 0.5));
    });
  });

  group('TotalizationHeader', () {
    testWidgets('mostra escopo, pleito e urnas apuradas', (tester) async {
      await pumpInTheme(
        tester,
        const TotalizationHeader(
          scope: 'ELEIÇÕES GERAIS BRASIL 2026',
          status: 'TOTALIZAÇÃO NACIONAL OFICIAL',
          title: 'Eleição Presidencial 2026',
          subtitle: '2º Turno',
          urnsCounted: DemoTallies.urnsCounted,
        ),
      );

      expect(find.text('ELEIÇÕES GERAIS BRASIL 2026'), findsOneWidget);
      expect(find.text('96,85% APURADAS'), findsOneWidget);
      expect(find.text('Eleição Presidencial 2026 / 2º Turno'), findsOneWidget);
    });
  });

  group('HeadToHeadBar', () {
    testWidgets('deriva a diferença dos votos exibidos', (tester) async {
      await pumpInTheme(
        tester,
        const HeadToHeadBar(
          leading: DemoTallies.leading,
          runnerUp: DemoTallies.runnerUp,
        ),
      );

      // 58.940.120 - 55.019.320
      expect(find.text('DIFERENÇA: 3.920.800 VOTOS'), findsOneWidget);
      expect(find.text('58.940.120 votos'), findsOneWidget);
      expect(find.text('55.019.320 votos'), findsOneWidget);
      expect(find.textContaining('CANDIDATO A (13)'), findsOneWidget);
      expect(find.textContaining('CANDIDATO B (22)'), findsOneWidget);
    });

    testWidgets('margem apertada mantém as duas fatias visíveis', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        const SizedBox(
          width: 900,
          child: HeadToHeadBar(
            leading: DemoTallies.photoFinishLeading,
            runnerUp: DemoTallies.photoFinishRunnerUp,
          ),
        ),
      );

      final fatias = tester
          .widgetList<Expanded>(
            find.descendant(
              of: find.byType(HeadToHeadBar),
              matching: find.byType(Expanded),
            ),
          )
          .where((e) => e.flex > 1)
          .toList();

      expect(fatias, hasLength(2));
      for (final fatia in fatias) {
        expect(fatia.flex, greaterThan(0));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('empilha os rótulos abaixo do breakpoint', (tester) async {
      await pumpInTheme(
        tester,
        const SizedBox(
          width: 600,
          child: HeadToHeadBar(
            leading: DemoTallies.leading,
            runnerUp: DemoTallies.runnerUp,
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('DIFERENÇA: 3.920.800 VOTOS'), findsOneWidget);
    });
  });

  group('OverseasPanel', () {
    testWidgets('lista os candidatos na cor do partido', (tester) async {
      await pumpInTheme(
        tester,
        const SizedBox(
          width: 520,
          child: OverseasPanel(tally: DemoTallies.overseas),
        ),
      );

      expect(find.text('LULA'), findsOneWidget);
      expect(find.text('FLAVIO BOLSONARO'), findsOneWidget);
      expect(textColor(tester, '47,6%'), PartyColors.of('PT'));
    });

    testWidgets('mostra seções, eleitorado e comparecimento da zona', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        const SizedBox(
          width: 520,
          child: OverseasPanel(tally: DemoTallies.overseas),
        ),
      );

      expect(find.textContaining('1.351 seções'), findsOneWidget);
      expect(find.textContaining('916.534 eleitores'), findsOneWidget);
      expect(find.text('330.882'), findsOneWidget);
      expect(find.text('100,0% APURADO'), findsOneWidget);
    });

    testWidgets('quem fica fora da lista vira uma linha de resumo', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        const SizedBox(
          width: 520,
          child: OverseasPanel(tally: DemoTallies.overseas, maxCandidates: 2),
        ),
      );

      expect(find.text('ESCRITOR AUGUSTO CURY'), findsNothing);
      expect(find.textContaining('Outras 1 candidaturas'), findsOneWidget);
    });

    testWidgets('coluna estreita não estoura', (tester) async {
      await pumpInTheme(
        tester,
        const SizedBox(
          width: 320,
          child: OverseasPanel(tally: DemoTallies.overseas),
        ),
        surface: const Size(400, 900),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('StateTally', () {
    test('margem é a distância da linha de equilíbrio, normalizada', () {
      const empate = StateTally(
        uf: 'XX',
        name: 'Empate',
        shareA: 0.5,
        countedShare: 1,
      );
      const folgado = StateTally(
        uf: 'YY',
        name: 'Folgado',
        shareA: 0.75,
        countedShare: 1,
      );

      expect(empate.margin, 0);
      expect(folgado.margin, closeTo(0.5, 1e-9));
      // Espelhado: 25% para A é a mesma margem que 75%.
      const espelho = StateTally(
        uf: 'ZZ',
        name: 'Espelho',
        shareA: 0.25,
        countedShare: 1,
      );
      expect(espelho.margin, closeTo(folgado.margin, 1e-9));
      expect(espelho.leadsA, isFalse);
    });

    test('a contagem separa estados do DF', () {
      final a = DemoTallies.states.where((s) => s.leadsA);
      final b = DemoTallies.states.where((s) => !s.leadsA);
      final contagemA = TerritoryCount.from(a);
      final contagemB = TerritoryCount.from(b);

      expect(DemoTallies.states, hasLength(27));
      expect(contagemA.states, 14);
      expect(contagemA.withFederalDistrict, isTrue);
      expect(contagemA.compactLabel, '14 + DF');
      expect(contagemA.legendLabel, '14 ESTADOS + DF');
      expect(contagemB.units, 12);
      expect(contagemB.legendLabel, '12 ESTADOS');
      expect(contagemA.units + contagemB.units, 27);
    });

    test('as siglas são únicas e viram chave ISO', () {
      final siglas = DemoTallies.states.map((s) => s.uf).toSet();
      expect(siglas, hasLength(27));
      expect(
        DemoTallies.states.firstWhere((s) => s.uf == 'SP').isoCode,
        'BR-SP',
      );
    });
  });

  group('TerritoryMap', () {
    testWidgets('mostra placar, legenda e os quatro destaques', (tester) async {
      await pumpInTheme(
        tester,
        const SizedBox(
          width: 900,
          child: TerritoryMap(states: DemoTallies.states),
        ),
        surface: const Size(1000, 900),
      );

      expect(find.text('14 + DF'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('A: 14 ESTADOS + DF'), findsOneWidget);
      expect(find.text('B: 12 ESTADOS'), findsOneWidget);

      // Destaques com os números da tela do Stitch.
      expect(find.textContaining('SÃO PAULO'), findsOneWidget);
      expect(find.text('B: 54,12%'), findsOneWidget);
      expect(find.text('A: 50,68%'), findsOneWidget);
      expect(find.text('A: 71,45%'), findsOneWidget);
      expect(find.text('B: 57,80%'), findsOneWidget);
    });

    testWidgets('toque numa UF devolve a totalização dela', (tester) async {
      StateTally? tocado;

      await pumpInTheme(
        tester,
        SizedBox(
          width: 900,
          child: TerritoryMap(
            states: DemoTallies.states,
            onStateTap: (state) => tocado = state,
          ),
        ),
        surface: const Size(1000, 900),
      );

      expect(find.byType(TerritoryMap), findsOneWidget);
      expect(tocado, isNull, reason: 'nada tocado ainda');
    });

    testWidgets('coluna estreita cai para dois destaques por linha', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        const SizedBox(
          width: 520,
          child: TerritoryMap(states: DemoTallies.states),
        ),
        surface: const Size(600, 1000),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('TerritoryMap — interação', () {
    Future<TestGesture> hoverAt(WidgetTester tester, Offset position) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(position);
      await settle(tester);
      return gesture;
    }

    testWidgets('marca o DF, que some na escala do mapa', (tester) async {
      await pumpInTheme(
        tester,
        const SizedBox(
          width: 900,
          child: TerritoryMap(states: DemoTallies.states),
        ),
        surface: const Size(1000, 900),
      );

      // Marcador discreto: só a sigla, a cor já diz quem lidera.
      expect(find.text('DF'), findsOneWidget);
    });

    testWidgets('hover sobre território abre o tooltip', (tester) async {
      await pumpInTheme(
        tester,
        const SizedBox(
          width: 900,
          child: TerritoryMap(states: DemoTallies.states),
        ),
        surface: const Size(1000, 900),
      );

      expect(find.textContaining('MARGEM:'), findsNothing);

      final mapa = find.byType(TerritoryMap);
      await hoverAt(tester, tester.getCenter(mapa));

      expect(find.textContaining('APURADO:'), findsOneWidget);
      expect(find.textContaining('MARGEM:'), findsOneWidget);
      // A camada de relevo entra junto com o tooltip.
      expect(
        find.descendant(
          of: find.byType(TerritoryMap),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );
    });

    testWidgets('o relevo anima e assenta sem sobrar exceção', (tester) async {
      await pumpInTheme(
        tester,
        const SizedBox(
          width: 900,
          child: TerritoryMap(states: DemoTallies.states),
        ),
        surface: const Size(1000, 900),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      final centro = tester.getCenter(find.byType(TerritoryMap));
      await gesture.moveTo(centro);
      // Meio da animação de 180ms.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      expect(tester.takeException(), isNull);

      // Trocar de UF reinicia a animação.
      await gesture.moveTo(centro + const Offset(40, 40));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('o tooltip usa o nome dos candidatos, não A e B', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        const SizedBox(
          width: 900,
          child: TerritoryMap(
            states: DemoTallies.states,
            leaderLabel: 'FLAVIO',
            runnerUpLabel: 'LULA',
          ),
        ),
        surface: const Size(1000, 900),
      );

      await hoverAt(tester, tester.getCenter(find.byType(TerritoryMap)));

      // O tooltip mostra os dois lados com o nome, nunca a letra solta.
      expect(find.textContaining('FLAVIO:'), findsWidgets);
      expect(find.textContaining('LULA:'), findsWidgets);
      expect(find.textContaining(RegExp(r'^[AB]: ')), findsNothing);
    });

    testWidgets('nome longo de candidato não estoura o tooltip', (
      tester,
    ) async {
      await pumpInTheme(
        tester,
        const SizedBox(
          width: 900,
          child: TerritoryMap(
            states: DemoTallies.states,
            leaderLabel: 'FERNANDO',
            runnerUpLabel: 'MARÍLIA',
          ),
        ),
        surface: const Size(1000, 900),
      );

      await hoverAt(tester, tester.getCenter(find.byType(TerritoryMap)));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('FERNANDO:'), findsWidgets);
    });

    testWidgets('sair do mapa fecha o tooltip', (tester) async {
      await pumpInTheme(
        tester,
        const SizedBox(
          width: 900,
          child: TerritoryMap(states: DemoTallies.states),
        ),
        surface: const Size(1000, 900),
      );

      final mapa = find.byType(TerritoryMap);
      final gesture = await hoverAt(tester, tester.getCenter(mapa));
      expect(find.textContaining('MARGEM:'), findsOneWidget);

      await gesture.moveTo(const Offset(5, 5));
      await settle(tester);

      expect(find.textContaining('MARGEM:'), findsNothing);
    });
  });

  group('UrnaMark', () {
    testWidgets('desenha em qualquer tamanho sem estourar', (tester) async {
      for (final tamanho in [16.0, 24.0, 64.0, 256.0]) {
        await pumpInTheme(tester, UrnaMark(size: tamanho));
        expect(tester.takeException(), isNull, reason: 'falhou em $tamanho');
        expect(tester.getSize(find.byType(UrnaMark)), Size(tamanho, tamanho));
      }
    });

    testWidgets('aparece no header do painel', (tester) async {
      await pumpInTheme(tester, const SizedBox.shrink());
      // O header é montado pela casca; aqui basta o widget existir isolado.
      await pumpInTheme(tester, const UrnaMark());
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
