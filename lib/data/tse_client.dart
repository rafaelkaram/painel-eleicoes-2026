import 'package:http/http.dart' as http;

import '../models/uf.dart';
import 'tse_election.dart';
import 'tse_payload.dart';

/// Falha ao buscar resultado no TSE.
class TseException implements Exception {
  const TseException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'TseException($message)';
}

/// Carga do TSE junto com o que o cabeçalho diz sobre validade.
class TseFetch {
  const TseFetch({
    required this.result,
    required this.maxAge,
    required this.latency,
  });

  final TseResult result;

  /// Quanto a requisição levou, da chamada à resposta decodificada.
  final Duration latency;

  /// `max-age` do `cache-control` da resposta.
  ///
  /// É o próprio TSE dizendo de quanto em quanto tempo vale perguntar de
  /// novo: 5 segundos num arquivo que está apurando, quase um minuto num
  /// que está parado. Perguntar mais rápido só bate no cache da CDN.
  final Duration maxAge;
}

/// Busca resultados no portal público do TSE.
class TseClient {
  TseClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// Quanto esperar antes de desistir de uma carga.
  static const timeout = Duration(seconds: 15);

  /// Piso e teto do intervalo de polling, caso o cabeçalho venha estranho.
  static const minPollInterval = Duration(seconds: 5);
  static const maxPollInterval = Duration(minutes: 2);

  /// Resultado de um cargo numa abrangência.
  Future<TseFetch> fetch({
    required int eleicao,
    required Cargo cargo,
    String abrangencia = 'br',
  }) async {
    return _fetchUrl(
      TseEndpoints.results(
        eleicao: eleicao,
        cargo: cargo,
        abrangencia: abrangencia,
      ),
    );
  }

  Future<TseFetch> _fetchUrl(Uri url) async {
    final relogio = Stopwatch()..start();
    final http.Response resposta;
    try {
      resposta = await _http.get(url).timeout(timeout);
    } on Exception catch (e) {
      throw TseException('Não foi possível falar com o TSE: $e');
    }

    if (resposta.statusCode != 200) {
      throw TseException(
        'O TSE respondeu ${resposta.statusCode} para ${url.path}',
        statusCode: resposta.statusCode,
      );
    }

    try {
      return TseFetch(
        result: TseResult.fromJws(resposta.body),
        maxAge: _maxAge(resposta.headers['cache-control']),
        latency: relogio.elapsed,
      );
    } on FormatException catch (e) {
      throw TseException('Carga do TSE ilegível: ${e.message}');
    }
  }

  /// Lê `max-age=N` do `cache-control`, preso entre o piso e o teto.
  ///
  /// Requisição condicional não ajuda aqui: testado, a CDN do TSE ignora
  /// `If-None-Match` e devolve 200 com o corpo inteiro. Então o jeito de
  /// não desperdiçar é respeitar o intervalo, não conversar mais vezes.
  static Duration _maxAge(String? cacheControl) {
    final match = RegExp(r'max-age\s*=\s*(\d+)').firstMatch(cacheControl ?? '');
    final segundos = int.tryParse(match?.group(1) ?? '');
    if (segundos == null) return minPollInterval;
    final proposto = Duration(seconds: segundos);
    if (proposto < minPollInterval) return minPollInterval;
    if (proposto > maxPollInterval) return maxPollInterval;
    return proposto;
  }

  /// Resultado de um cargo dentro de um município.
  Future<TseFetch> fetchMunicipality({
    required int eleicao,
    required Cargo cargo,
    required String uf,
    required String municipio,
  }) {
    return _fetchUrl(
      TseEndpoints.municipality(
        eleicao: eleicao,
        cargo: cargo,
        uf: uf,
        municipio: municipio,
      ),
    );
  }

  /// Busca o mesmo cargo em várias unidades federativas.
  ///
  /// São 27 requisições. Vão em lotes pequenos de propósito: o navegador
  /// limita conexões simultâneas por host, e uma varredura gulosa empurra a
  /// consulta nacional para o fim da fila — medido, o intervalo efetivo do
  /// polling ia de 5 para 42 segundos. Quatro por vez deixa folga.
  ///
  /// UF que falhar simplesmente não entra no resultado, em vez de derrubar
  /// as outras 26: um mapa com 26 estados pintados e um cinza é melhor que
  /// uma tela de erro.
  Future<Map<Uf, TseFetch>> fetchUfs({
    required int eleicao,
    required Cargo cargo,
    List<Uf> ufs = Uf.values,
    int concurrency = 4,
  }) async {
    final resultado = <Uf, TseFetch>{};

    for (var i = 0; i < ufs.length; i += concurrency) {
      final lote = ufs.skip(i).take(concurrency);
      await Future.wait(
        lote.map((uf) async {
          try {
            resultado[uf] = await fetch(
              eleicao: eleicao,
              cargo: cargo,
              abrangencia: uf.slug,
            );
          } on TseException {
            // UF sem carga publicada é ausência, não erro fatal.
          }
        }),
      );
    }

    return resultado;
  }

  void close() => _http.close();
}
