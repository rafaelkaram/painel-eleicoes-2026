import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'tse_client.dart';
import 'tse_election.dart';

/// Um município no cadastro do TSE.
@immutable
class MunicipalityRef {
  const MunicipalityRef({
    required this.code,
    required this.name,
    required this.zones,
  });

  /// Código do município no TSE, o mesmo que entra na URL do resultado.
  final String code;

  final String name;

  /// Zonas eleitorais do município.
  final List<String> zones;
}

/// Uma seção, com o carimbo de transmissão da urna.
@immutable
class SectionRefTse {
  const SectionRefTse({
    required this.number,
    required this.transmittedDate,
    required this.transmittedTime,
  });

  /// Número da seção, com zeros à esquerda.
  final String number;

  /// `04/10/2026`.
  final String transmittedDate;

  /// `22:59:36`.
  final String transmittedTime;

  bool get transmitted => transmittedDate.isNotEmpty;
}

/// Cadastro de municípios, zonas e seções.
///
/// São dois arquivos diferentes do TSE: o de municípios é nacional e vem de
/// uma vez; o de seções é por UF e pesa meio megabyte comprimido, então só
/// é buscado quando alguém escolhe a unidade.
class TseLookup {
  TseLookup({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  final Map<String, List<MunicipalityRef>> _municipios = {};
  final Map<String, Map<String, Map<String, List<SectionRefTse>>>> _secoes = {};

  /// UFs com município cadastrado, em ordem.
  List<String> get ufs =>
      (_municipios.keys.toList()..sort()).map((u) => u.toUpperCase()).toList();

  List<MunicipalityRef> municipalitiesOf(String uf) =>
      _municipios[uf.toLowerCase()] ?? const [];

  /// Seções de uma zona, se o cadastro da UF já veio.
  List<SectionRefTse> sectionsOf(String uf, String municipio, String zona) =>
      _secoes[uf.toLowerCase()]?[municipio]?[zona] ?? const [];

  bool hasSections(String uf) => _secoes.containsKey(uf.toLowerCase());

  /// Carrega o cadastro nacional de municípios e zonas.
  Future<void> loadMunicipalities(int eleicao) async {
    if (_municipios.isNotEmpty) return;

    final json = await _get(TseEndpoints.municipalityConfig(eleicao));
    for (final abr
        in (json['abr'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()) {
      final uf = (abr['cd'] as String? ?? '').toLowerCase();
      if (uf.isEmpty) continue;

      _municipios[uf] = [
        for (final mu
            in (abr['mu'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
          MunicipalityRef(
            code: mu['cd'] as String? ?? '',
            name: mu['nm'] as String? ?? '',
            zones: [...(mu['z'] as List<dynamic>? ?? const []).cast<String>()]
              ..sort(),
          ),
      ]..sort((a, b) => a.name.compareTo(b.name));
    }
  }

  /// Carrega o cadastro de seções de uma UF.
  Future<void> loadSections(String uf) async {
    final sigla = uf.toLowerCase();
    if (_secoes.containsKey(sigla)) return;

    final json = await _get(TseEndpoints.sectionConfig(sigla));
    final porMunicipio = <String, Map<String, List<SectionRefTse>>>{};

    for (final abr
        in (json['abr'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()) {
      for (final mu
          in (abr['mu'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>()) {
        final zonas = <String, List<SectionRefTse>>{};
        for (final z
            in (mu['zon'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>()) {
          zonas[z['cd'] as String? ?? ''] = [
            for (final sec
                in (z['sec'] as List<dynamic>? ?? const [])
                    .cast<Map<String, dynamic>>())
              SectionRefTse(
                number: sec['ns'] as String? ?? '',
                transmittedDate: sec['da'] as String? ?? '',
                transmittedTime: sec['ha'] as String? ?? '',
              ),
          ];
        }
        porMunicipio[mu['cd'] as String? ?? ''] = zonas;
      }
    }

    _secoes[sigla] = porMunicipio;
  }

  Future<Map<String, dynamic>> _get(Uri url) async {
    final http.Response resposta;
    try {
      resposta = await _http.get(url).timeout(TseClient.timeout);
    } on Exception catch (e) {
      throw TseException('Não foi possível falar com o TSE: $e');
    }
    if (resposta.statusCode != 200) {
      throw TseException(
        'O TSE respondeu ${resposta.statusCode} para ${url.path}',
        statusCode: resposta.statusCode,
      );
    }
    return jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
  }

  void close() => _http.close();
}
