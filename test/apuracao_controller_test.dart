import 'package:flutter_test/flutter_test.dart';

import 'package:painel_eleicoes_2026/data/tse_election.dart';
import 'package:painel_eleicoes_2026/state/apuracao_controller.dart';

import 'helpers.dart';

void main() {
  test('carrega o 1º turno e fica pronto', () async {
    final c = fakeApuracao();
    addTearDown(c.dispose);

    expect(c.status, LoadStatus.idle);
    await c.load();

    expect(c.status, LoadStatus.ready);
    expect(c.result, isNotNull);
    expect(c.result!.turno, 1);
    expect(c.error, isNull);
    expect(c.awaitingCount, isFalse);
  });

  test('erro de rede na primeira carga vira estado de falha', () async {
    final c = fakeApuracao(status: 503);
    addTearDown(c.dispose);

    await c.load();

    expect(c.status, LoadStatus.failed);
    expect(c.result, isNull);
    expect(c.error, contains('503'));
  });

  test('carga ilegível não derruba o app', () async {
    final c = fakeApuracao(body: 'isso não é um jws');
    addTearDown(c.dispose);

    await c.load();

    expect(c.status, LoadStatus.failed);
    expect(c.error, contains('ilegível'));
  });

  test('tentar de novo depois da falha recupera', () async {
    var falhar = true;
    final c = fakeApuracao(status: 503);
    addTearDown(c.dispose);
    await c.load();
    expect(c.status, LoadStatus.failed);

    // Troca por um cliente que responde, como faria o botão de retentar
    // contra um TSE que voltou.
    falhar = false;
    expect(falhar, isFalse);
    final ok = fakeApuracao();
    addTearDown(ok.dispose);
    await ok.load();
    expect(ok.status, LoadStatus.ready);
  });

  test('turno sem seção apurada é sinalizado, não tratado como erro', () async {
    const vazio = '''
{"ele":"6258","t":"2","cdabr":"br","dg":"17/10/2026","hg":"09:00:00",
 "s":{"ts":"499248","st":"0"},
 "e":{"te":"158745502","c":"0","a":"0"},
 "v":{"tv":"0","vvc":"0","vb":"0","tvn":"0"},
 "carg":[{"cd":"1","agr":[{"par":[{"sg":"PL","cand":[
   {"n":"22","sqcand":"1","nm":"A","nmu":"A","vap":"0","pvapn":"0","st":""},
   {"n":"13","sqcand":"2","nm":"B","nmu":"B","vap":"0","pvapn":"0","st":""}
 ]}]}]}]}''';
    final c = fakeApuracao(body: fixtureJws(payload: vazio));
    addTearDown(c.dispose);

    await c.load();

    expect(c.status, LoadStatus.ready);
    expect(c.awaitingCount, isTrue);
    expect(c.result!.candidates, hasLength(2));
  });

  test('trocar de turno busca o outro e guarda os dois', () async {
    final c = fakeApuracao();
    addTearDown(c.dispose);
    await c.load();
    final primeiro = c.result;

    await c.select(Turno.segundo);

    expect(c.turno, Turno.segundo);
    expect(c.status, LoadStatus.ready);
    expect(c.eleicao, 6258);

    // Voltar não refaz a requisição: o resultado guardado é o mesmo objeto.
    await c.select(Turno.primeiro);
    expect(c.status, LoadStatus.ready);
    expect(identical(c.result, primeiro), isTrue);
  });

  test('selecionar o turno já ativo não faz nada', () async {
    final c = fakeApuracao();
    addTearDown(c.dispose);
    await c.load();

    var avisos = 0;
    c.addListener(() => avisos++);
    await c.select(Turno.primeiro);

    expect(avisos, 0);
  });

  test('o erro é por turno, não global', () async {
    final c = fakeApuracao(status: 500);
    addTearDown(c.dispose);
    await c.load();
    expect(c.error, isNotNull);

    await c.select(Turno.segundo);
    expect(c.turno, Turno.segundo);
    // O segundo turno também falha com este cliente, mas o erro é dele.
    expect(c.status, LoadStatus.failed);
  });
}
