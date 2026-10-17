import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:painel_eleicoes_2026/data/tse_client.dart';
import 'package:painel_eleicoes_2026/data/tse_election.dart';
import 'package:painel_eleicoes_2026/state/apuracao_controller.dart';
import 'package:painel_eleicoes_2026/theme/app_theme.dart';

/// Payload real do 1º turno, embrulhado num JWS de mentira.
///
/// A assinatura não é verificada pelo cliente, então um terceiro segmento
/// qualquer basta para o teste exercitar o caminho real de decodificação.
String fixtureJws({String? payload}) {
  String seg(String texto) =>
      base64Url.encode(utf8.encode(texto)).replaceAll('=', '');
  final corpo =
      payload ??
      File('test/fixtures/tse-presidente-1t.json').readAsStringSync();
  return '${seg('{"alg":"EdDSA"}')}.${seg(corpo)}.assinatura';
}

/// Escolhe a fixture conforme o que a URL pede.
///
/// O controller busca a carga nacional, depois 27 de presidente e 27 de
/// governador. Responder tudo com o mesmo arquivo faria o teste validar
/// uma realidade que não existe.
String fixtureParaUrl(Uri url) {
  if (url.path.contains('-c0003-')) {
    return fixtureJws(payload: _leia('tse-governador-sp.json'));
  }
  if (url.path.contains('/dados/br/')) return fixtureJws();
  return fixtureJws(payload: _leia('tse-presidente-sp.json'));
}

String _leia(String nome) => File('test/fixtures/$nome').readAsStringSync();

/// Controller apontando para um TSE de mentira.
ApuracaoController fakeApuracao({
  int status = 200,
  String? body,
  Turno turno = Turno.primeiro,
  Duration? delay,
  bool autoPoll = false,
  Map<String, String> headers = const {},
  List<String>? bodies,
}) {
  var chamada = 0;
  final mock = MockClient((req) async {
    if (delay != null) await Future<void>.delayed(delay);
    if (bodies != null) {
      final corpo = bodies[chamada.clamp(0, bodies.length - 1)];
      chamada++;
      return http.Response(corpo, status, headers: headers);
    }
    if (body != null) return http.Response(body, status, headers: headers);
    return http.Response(fixtureParaUrl(req.url), status, headers: headers);
  });
  return ApuracaoController(
    client: TseClient(httpClient: mock),
    turno: turno,
    autoPoll: autoPoll,
  );
}

/// Monta um widget isolado com o tema do painel.
Future<void> pumpInTheme(
  WidgetTester tester,
  Widget child, {
  Size surface = const Size(1280, 720),
  ApuracaoController? apuracao,
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  // Só descarta o que criou aqui: controller vindo de fora é
  // responsabilidade de quem o criou, e descartar duas vezes estoura.
  final controller = apuracao ?? fakeApuracao();
  if (apuracao == null) addTearDown(controller.dispose);

  await tester.pumpWidget(
    ApuracaoScope(
      controller: controller,
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: child),
      ),
    ),
  );
  await settle(tester);
}

/// O pulso do indicador ao vivo nunca para, então `pumpAndSettle` estoura o
/// timeout. Dois pumps cobrem qualquer transição que interesse aqui.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Cor efetiva de um `Text` já renderizado.
Color? textColor(WidgetTester tester, String data) {
  return tester.widget<Text>(find.text(data)).style?.color;
}

/// PNG transparente de 1x1, para responder qualquer imagem de rede no teste.
final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAE'
  'hQGAhKmMIQAAAABJRU5ErkJggg==',
);

/// Faz `NetworkImage` responder no ambiente de teste.
///
/// O `flutter_test` devolve 400 para qualquer requisição de imagem, o que
/// enche a saída de exceção e quebra testes de tela que mostram retrato de
/// candidato. Aqui todas respondem o mesmo pixel.
class _ImagemFalsaOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeResponse implements HttpClientResponse {
  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _pixel.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_pixel).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Instala o atendimento falso de imagens para o arquivo de teste inteiro.
void usarImagensFalsas() {
  final anterior = HttpOverrides.current;
  setUpAll(() => HttpOverrides.global = _ImagemFalsaOverrides());
  tearDownAll(() => HttpOverrides.global = anterior);
}
