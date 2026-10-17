import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:painel_eleicoes_2026/data/tse_election.dart';
import 'package:painel_eleicoes_2026/data/tse_payload.dart';

void main() {
  // Payload real do 1º turno de 2026, presidente, abrangência nacional.
  final json = jsonDecode(
    File('test/fixtures/tse-presidente-1t.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final resultado = TseResult.fromJson(json);

  group('conversão de números do TSE', () {
    test('inteiro vem como texto e pode ter ponto de milhar', () {
      expect(tseInt('158745502'), 158745502);
      expect(tseInt('1.234'), 1234);
      expect(tseInt(42), 42);
      expect(tseInt(null), 0);
      expect(tseInt('não é número'), 0);
    });

    test('percentual usa vírgula decimal e vira fração', () {
      expect(tsePercent('47,03'), closeTo(0.4703, 1e-9));
      expect(tsePercent('47,027772356'), closeTo(0.47027772356, 1e-12));
      expect(tsePercent('100,00'), 1);
      expect(tsePercent(null), 0);
    });
  });

  group('TseResult', () {
    test('lê a identificação da carga', () {
      expect(resultado.eleicao, '6257');
      expect(resultado.turno, 1);
      expect(resultado.abrangencia, 'br');
      expect(resultado.generatedAt, '05/10/2026 12:51:47');
    });

    test('seções conferem com o publicado', () {
      expect(resultado.sections.total, 499248);
      expect(resultado.sections.counted, 499248);
      expect(resultado.sections.countedShare, 1);
    });

    test('eleitorado e comparecimento batem', () {
      expect(resultado.electorate.total, 158745502);
      expect(resultado.electorate.turnout, 125275835);
      expect(resultado.electorate.turnoutShare, closeTo(0.7892, 1e-4));
      // Não fecha exatamente em 1: `te` conta o eleitorado inteiro, e
      // comparecimento e abstenção só existem para as seções instaladas.
      // A sobra são os 423 eleitores de seções que não foram instaladas.
      expect(
        resultado.electorate.turnoutShare +
            resultado.electorate.abstentionShare,
        closeTo(1, 1e-5),
      );
      expect(
        resultado.electorate.total -
            resultado.electorate.turnout -
            resultado.electorate.abstentions,
        423,
      );
    });

    test('votos somam o total apurado', () {
      final v = resultado.votes;
      expect(v.total, 125275835);
      expect(v.valid, 119300788);
      // Fecha porque `nulls` lê `tvn`, que soma nulos comuns e técnicos.
      expect(v.valid + v.blank + v.nulls, v.total);
      expect(v.nulls, 3674249);
      expect(v.validShare, closeTo(0.9523, 1e-4));
      expect(v.blankShare, closeTo(0.0184, 1e-4));
    });

    test('candidatos vêm achatados e ordenados por votos', () {
      expect(resultado.candidates, hasLength(12));
      final votos = resultado.candidates.map((c) => c.votes).toList();
      expect(votos, orderedEquals([...votos]..sort((a, b) => b.compareTo(a))));
    });

    test('o mais votado é o que o TSE publicou', () {
      final primeiro = resultado.candidates.first;
      expect(primeiro.ballotName, 'FLAVIO BOLSONARO');
      expect(primeiro.number, 22);
      expect(primeiro.party, 'PL');
      expect(primeiro.votes, 56104503);
      expect(primeiro.share, closeTo(0.4703, 1e-4));
      expect(primeiro.sqcand, '280002551544');
      expect(primeiro.goesToRunoff, isTrue);
      expect(primeiro.elected, isTrue);
    });

    test('a soma dos nominais fecha com os válidos', () {
      final soma = resultado.candidates.fold(0, (total, c) => total + c.votes);
      expect(soma, resultado.votes.valid);
    });

    test('exatamente dois candidatos foram ao segundo turno', () {
      final aoSegundo = resultado.candidates
          .where((c) => c.goesToRunoff)
          .toList();
      expect(aoSegundo, hasLength(2));
    });
  });

  group('JWS', () {
    test('extrai o payload de um JWS bem formado', () {
      String seg(Object o) =>
          base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
      final jws = '${seg({'alg': 'EdDSA'})}.${seg(json)}.assinatura';

      final lido = TseResult.fromJws(jws);
      expect(lido.eleicao, '6257');
      expect(lido.candidates.first.votes, 56104503);
    });

    test('recusa entrada que não é JWS', () {
      expect(() => TseResult.fromJws('sem pontos'), throwsFormatException);
      expect(() => TseResult.fromJws('a.b'), throwsFormatException);
    });
  });

  group('TseEndpoints', () {
    test('monta a URL do resultado com o preenchimento certo', () {
      final url = TseEndpoints.results(
        eleicao: Turno.primeiro.presidente,
        cargo: Cargo.presidente,
      );
      expect(
        url.toString(),
        'https://resultados.tse.jus.br/oficial/ele2026/6257/dados/br/'
        'br-c0001-e006257-u.jws',
      );
    });

    test('abrangência estadual entra em minúscula nos dois lugares', () {
      final url = TseEndpoints.results(
        eleicao: Turno.segundo.governador,
        cargo: Cargo.governador,
        abrangencia: 'AM',
      );
      expect(
        url.toString(),
        'https://resultados.tse.jus.br/oficial/ele2026/6260/dados/am/'
        'am-c0003-e006260-u.jws',
      );
    });

    test('a foto é indexada pelo sqcand', () {
      expect(
        TseEndpoints.portrait(eleicao: 6257, sqcand: '280002551544').toString(),
        'https://resultados.tse.jus.br/oficial/ele2026/6257/fotos/br/'
        '280002551544.jpeg',
      );
    });

    test('o catálogo separa os dois turnos', () {
      expect(Turno.primeiro.presidente, 6257);
      expect(Turno.segundo.presidente, 6258);
      expect(Turno.primeiro.governador, 6259);
      expect(Turno.segundo.governador, 6260);
      expect(Turno.segundo.date, '25/10/2026');
    });
  });
}
