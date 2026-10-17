import 'package:flutter_test/flutter_test.dart';

import 'package:painel_eleicoes_2026/models/feed_envelope.dart';

void main() {
  FeedEnvelope carga({
    int versao = FeedEnvelope.supportedVersion,
    int seq = 10,
    String recarregar = 'build-1',
  }) {
    return FeedEnvelope(
      versao: versao,
      seq: seq,
      gerado: DateTime.utc(2026, 10, 25, 20),
      recarregar: recarregar,
    );
  }

  test('primeira carga é sempre aceita', () {
    expect(evaluateFeed(carga()), FeedVerdict.accept);
  });

  test('sequência maior avança a tela', () {
    expect(
      evaluateFeed(carga(seq: 11), current: carga(seq: 10)),
      FeedVerdict.accept,
    );
  });

  test('resposta atrasada é descartada', () {
    // Dois nós de CDN com idades de cache diferentes: sem isso a tela
    // andaria para trás na frente de quem está assistindo.
    expect(
      evaluateFeed(carga(seq: 9), current: carga(seq: 10)),
      FeedVerdict.stale,
    );
    expect(
      evaluateFeed(carga(seq: 10), current: carga(seq: 10)),
      FeedVerdict.stale,
    );
  });

  test('schema desconhecido não é renderizado', () {
    expect(evaluateFeed(carga(versao: 99)), FeedVerdict.unsupportedVersion);
    expect(
      evaluateFeed(carga(versao: 99, seq: 11), current: carga(seq: 10)),
      FeedVerdict.unsupportedVersion,
    );
  });

  test('build novo manda recarregar', () {
    expect(
      evaluateFeed(
        carga(seq: 11, recarregar: 'build-2'),
        current: carga(seq: 10, recarregar: 'build-1'),
      ),
      FeedVerdict.needsReload,
    );
  });

  test('recarregar vence o descarte por atraso', () {
    // Um build novo pode ter zerado a sequência. Se isso virasse "stale",
    // o painel ficaria preso para sempre no código velho.
    expect(
      evaluateFeed(
        carga(seq: 1, recarregar: 'build-2'),
        current: carga(seq: 500, recarregar: 'build-1'),
      ),
      FeedVerdict.needsReload,
    );
  });
}
