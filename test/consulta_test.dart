import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:painel_eleicoes_2026/data/tse_client.dart';
import 'package:painel_eleicoes_2026/data/tse_lookup.dart';
import 'package:painel_eleicoes_2026/screens/consulta_local_screen.dart';
import 'package:painel_eleicoes_2026/state/consulta_controller.dart';
import 'package:painel_eleicoes_2026/theme/app_theme.dart';

import 'helpers.dart';

/// Cadastro de municípios reduzido, no formato que o TSE publica.
const _munConfig = '''
{"abr":[{"cd":"sp","ds":"São Paulo","mu":[
  {"cd":"62910","cdi":"3509502","nm":"CAMPINAS","z":["0033","0379"]},
  {"cd":"71072","cdi":"3550308","nm":"SÃO PAULO","z":["0001"]}]},
 {"cd":"rj","ds":"Rio de Janeiro","mu":[
  {"cd":"60011","cdi":"3304557","nm":"RIO DE JANEIRO","z":["0001"]}]}]}
''';

/// Cadastro de seções, também reduzido.
const _secConfig = '''
{"abr":[{"cd":"sp","mu":[{"cd":"62910","nm":"CAMPINAS","zon":[
  {"cd":"0033","sec":[
    {"ns":"0001","da":"04/10/2026","ha":"22:59:36"},
    {"ns":"0002","da":"04/10/2026","ha":"23:04:11"}]},
  {"cd":"0379","sec":[{"ns":"0100","da":"","ha":""}]}]}]}]}
''';

ConsultaController fakeConsulta({int status = 200}) {
  final presidente = File('test/fixtures/tse-presidente-sp.json')
      .readAsStringSync();
  final governador = File('test/fixtures/tse-governador-sp.json')
      .readAsStringSync();

  // Responde em bytes UTF-8, como o TSE: `http.Response(String, …)` sem
  // charset cai em latin-1 e os acentos do cadastro quebram.
  http.Response utf8Response(String corpo) =>
      http.Response.bytes(utf8.encode(corpo), status);

  final mock = MockClient((req) async {
    final caminho = req.url.path;
    if (caminho.contains('mun-e')) return utf8Response(_munConfig);
    if (caminho.contains('-cs.json')) return utf8Response(_secConfig);
    return utf8Response(
      caminho.contains('-c0003-')
          ? fixtureJws(payload: governador)
          : fixtureJws(payload: presidente),
    );
  });

  return ConsultaController(
    client: TseClient(httpClient: mock),
    lookup: TseLookup(httpClient: mock),
  );
}

Future<void> pumpConsulta(
  WidgetTester tester,
  ConsultaController c, {
  Size surface = const Size(1500, 1200),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ConsultaScope(
      controller: c,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: ConsultaLocalScreen()),
      ),
    ),
  );
  await settle(tester);
}

void main() {
  usarImagensFalsas();

  group('ConsultaController', () {
    test('a cascata desce sozinha até a seção', () async {
      final c = fakeConsulta();
      addTearDown(c.dispose);

      await c.start();
      await c.sectionsReady;

      expect(c.status, ConsultaStatus.ready);
      expect(c.uf, 'SP');
      expect(c.municipio, '62910'); // CAMPINAS vem antes de SÃO PAULO
      expect(c.zona, '0033');
      expect(c.secao, '0001');
      expect(c.presidente, isNotNull);
      expect(c.governador, isNotNull);
    });

    test('municípios vêm ordenados por nome', () async {
      final c = fakeConsulta();
      addTearDown(c.dispose);
      await c.start();
      await c.sectionsReady;

      expect(
        c.municipalities.map((m) => m.name),
        orderedEquals(['CAMPINAS', 'SÃO PAULO']),
      );
    });

    test('trocar de zona troca a seção selecionada', () async {
      final c = fakeConsulta();
      addTearDown(c.dispose);
      await c.start();
      await c.sectionsReady;
      expect(c.secao, '0001');

      c.selectZone('0379');

      expect(c.zona, '0379');
      expect(c.secao, '0100');
    });

    test('seção sem carimbo é marcada como não transmitida', () async {
      final c = fakeConsulta();
      addTearDown(c.dispose);
      await c.start();
      await c.sectionsReady;
      c.selectZone('0379');

      expect(c.currentSection!.transmitted, isFalse);
      expect(c.sections.first.number, '0100');
    });

    test('seção com carimbo traz data e hora', () async {
      final c = fakeConsulta();
      addTearDown(c.dispose);
      await c.start();
      await c.sectionsReady;

      final s = c.currentSection!;
      expect(s.transmitted, isTrue);
      expect(s.transmittedDate, '04/10/2026');
      expect(s.transmittedTime, '22:59:36');
    });

    test('trocar de UF reinicia a cascata', () async {
      final c = fakeConsulta();
      addTearDown(c.dispose);
      await c.start();
      await c.sectionsReady;

      await c.selectUf('RJ');
      await c.sectionsReady;

      expect(c.uf, 'RJ');
      expect(c.municipio, '60011');
      expect(c.municipalities.single.name, 'RIO DE JANEIRO');
    });

    test('falha no cadastro vira estado de erro', () async {
      final c = fakeConsulta(status: 500);
      addTearDown(c.dispose);

      await c.start();
      await c.sectionsReady;

      expect(c.status, ConsultaStatus.failed);
      expect(c.error, contains('500'));
    });
  });

  group('ConsultaLocalScreen', () {
    testWidgets('mostra o município com o dado do TSE', (tester) async {
      final c = fakeConsulta();
      addTearDown(c.dispose);
      await c.start();
      await c.sectionsReady;
      await pumpConsulta(tester, c);

      expect(find.text('CAMPINAS — SP'), findsOneWidget);
      expect(find.textContaining('Código TSE: 62910'), findsOneWidget);
      expect(find.text('PRESIDENTE NO MUNICÍPIO'), findsOneWidget);
      expect(find.text('GOVERNADOR NO MUNICÍPIO'), findsOneWidget);
    });

    testWidgets('mostra o carimbo de transmissão da seção', (tester) async {
      final c = fakeConsulta();
      addTearDown(c.dispose);
      await c.start();
      await c.sectionsReady;
      await pumpConsulta(tester, c);

      expect(find.text('TRANSMITIDA'), findsOneWidget);
      expect(find.text('04/10/2026'), findsOneWidget);
      expect(find.text('22:59:36'), findsOneWidget);
    });

    testWidgets('diz o que não mostra, em vez de inventar o boletim', (
      tester,
    ) async {
      final c = fakeConsulta();
      addTearDown(c.dispose);
      await c.start();
      await c.sectionsReady;
      await pumpConsulta(tester, c);

      expect(find.textContaining('arquivo de urna do TSE'), findsOneWidget);
    });

    testWidgets('falha de rede aparece na tela', (tester) async {
      final c = fakeConsulta(status: 503);
      addTearDown(c.dispose);
      await c.start();
      await c.sectionsReady;
      await pumpConsulta(tester, c);

      expect(find.textContaining('503'), findsOneWidget);
    });
  });
}
