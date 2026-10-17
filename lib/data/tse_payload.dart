import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Leitura do payload de resultados do TSE.
///
/// O formato usa siglas curtas e manda **todo número como string**, com
/// vírgula decimal no padrão brasileiro. Toda a conversão fica concentrada
/// aqui para que o resto do app só veja `int` e `double`.
@immutable
class TseResult {
  const TseResult({
    required this.eleicao,
    required this.turno,
    required this.abrangencia,
    required this.generatedAt,
    required this.generationId,
    required this.sections,
    required this.electorate,
    required this.votes,
    required this.candidates,
  });

  final String eleicao;
  final int turno;

  /// `br` ou a sigla da UF.
  final String abrangencia;

  /// Data e hora da geração, como o TSE publica: `05/10/2026 12:51:47`.
  final String generatedAt;

  /// Id de geração da carga (`idg`). Cresce a cada republicação.
  ///
  /// É o número de sequência desta fonte. Nós diferentes da CDN servem
  /// idades de cache diferentes, então uma resposta pode chegar mais velha
  /// que a que já está na tela — sem comparar `idg`, o painel andaria para
  /// trás na frente de quem está assistindo.
  final int generationId;

  final TseSections sections;
  final TseElectorate electorate;
  final TseVotes votes;

  /// Candidatos do cargo, achatados e ordenados do mais votado ao menos.
  final List<TseCandidate> candidates;

  /// Decodifica o payload de um arquivo `.jws`.
  ///
  /// O JWS é `header.payload.assinatura` em base64url. Aqui só se extrai o
  /// payload — conferir a assinatura EdDSA exigiria a chave pública do TSE e
  /// uma biblioteca de criptografia, e isso é outro trabalho.
  static TseResult fromJws(String jws) {
    final partes = jws.trim().split('.');
    if (partes.length != 3) {
      throw const FormatException('JWS malformado: esperava três segmentos');
    }
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(partes[1])),
    );
    return fromJson(jsonDecode(payload) as Map<String, dynamic>);
  }

  static TseResult fromJson(Map<String, dynamic> json) {
    final candidatos = <TseCandidate>[];

    for (final cargo
        in (json['carg'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()) {
      for (final agr
          in (cargo['agr'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>()) {
        for (final par
            in (agr['par'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>()) {
          for (final cand
              in (par['cand'] as List<dynamic>? ?? const [])
                  .cast<Map<String, dynamic>>()) {
            candidatos.add(TseCandidate.fromJson(cand, partido: par));
          }
        }
      }
    }
    candidatos.sort((a, b) => b.votes.compareTo(a.votes));

    return TseResult(
      eleicao: json['ele'] as String? ?? '',
      turno: int.tryParse(json['t'] as String? ?? '') ?? 0,
      abrangencia: json['cdabr'] as String? ?? 'br',
      generatedAt: '${json['dg'] ?? ''} ${json['hg'] ?? ''}'.trim(),
      generationId: tseInt(json['idg']),
      sections: TseSections.fromJson(
        json['s'] as Map<String, dynamic>? ?? const {},
      ),
      electorate: TseElectorate.fromJson(
        json['e'] as Map<String, dynamic>? ?? const {},
      ),
      votes: TseVotes.fromJson(json['v'] as Map<String, dynamic>? ?? const {}),
      candidates: candidatos,
    );
  }
}

/// Seções eleitorais.
@immutable
class TseSections {
  const TseSections({required this.total, required this.counted});

  final int total;
  final int counted;

  double get countedShare => total == 0 ? 0 : counted / total;

  static TseSections fromJson(Map<String, dynamic> j) =>
      TseSections(total: tseInt(j['ts']), counted: tseInt(j['st']));
}

/// Eleitorado e comparecimento.
@immutable
class TseElectorate {
  const TseElectorate({
    required this.total,
    required this.turnout,
    required this.abstentions,
  });

  final int total;
  final int turnout;
  final int abstentions;

  double get turnoutShare => total == 0 ? 0 : turnout / total;
  double get abstentionShare => total == 0 ? 0 : abstentions / total;

  static TseElectorate fromJson(Map<String, dynamic> j) => TseElectorate(
    total: tseInt(j['te']),
    turnout: tseInt(j['c']),
    abstentions: tseInt(j['a']),
  );
}

/// Composição dos votos.
@immutable
class TseVotes {
  const TseVotes({
    required this.total,
    required this.valid,
    required this.blank,
    required this.nulls,
  });

  /// Total apurado, incluindo branco e nulo.
  final int total;

  final int valid;
  final int blank;

  /// Total de nulos.
  ///
  /// Vem de `tvn`, não de `vn`. O TSE separa os nulos comuns (`vn`) dos
  /// nulos técnicos (`vnt`), e só a soma dos dois fecha com o total
  /// apurado. Usar `vn` deixaria milhares de votos fora da conta — foi o
  /// teste de fechamento que apontou.
  final int nulls;

  double _share(int parte) => total == 0 ? 0 : parte / total;

  double get validShare => _share(valid);
  double get blankShare => _share(blank);
  double get nullShare => _share(nulls);

  static TseVotes fromJson(Map<String, dynamic> j) => TseVotes(
    total: tseInt(j['tv']),
    valid: tseInt(j['vvc']),
    blank: tseInt(j['vb']),
    nulls: tseInt(j['tvn']),
  );
}

/// Candidato com a votação dele.
@immutable
class TseCandidate {
  const TseCandidate({
    required this.number,
    required this.sqcand,
    required this.name,
    required this.ballotName,
    required this.party,
    required this.votes,
    required this.share,
    required this.situation,
    required this.elected,
  });

  /// Número na urna.
  final int number;

  /// Identificador do candidato no TSE. É a chave da foto oficial.
  final String sqcand;

  final String name;

  /// Nome de urna — é o que a tela mostra.
  final String ballotName;

  final String party;

  final int votes;

  /// Fração dos votos válidos, de 0 a 1.
  final double share;

  /// Situação declarada pelo TSE: `Eleito`, `2º turno`, `Não eleito`.
  final String situation;

  /// `true` quando o TSE marca o candidato como eleito.
  final bool elected;

  /// `true` quando o TSE levou o candidato ao segundo turno.
  bool get goesToRunoff => situation.toLowerCase().contains('turno');

  static TseCandidate fromJson(
    Map<String, dynamic> j, {
    required Map<String, dynamic> partido,
  }) {
    final urna = (j['nmu'] as String?)?.trim();
    return TseCandidate(
      number: tseInt(j['n']),
      sqcand: j['sqcand'] as String? ?? '',
      name: j['nm'] as String? ?? '',
      ballotName: (urna?.isNotEmpty ?? false)
          ? urna!
          : j['nm'] as String? ?? '',
      party: partido['sg'] as String? ?? '',
      votes: tseInt(j['vap']),
      share: tsePercent(j['pvapn'] ?? j['pvap']),
      situation: j['st'] as String? ?? '',
      elected: (j['e'] as String? ?? '').toLowerCase() == 's',
    );
  }
}

/// Inteiro a partir do texto do TSE, que manda tudo como string.
int tseInt(Object? value) {
  if (value is int) return value;
  final texto = value?.toString().replaceAll('.', '').trim() ?? '';
  return int.tryParse(texto) ?? 0;
}

/// Percentual do TSE (`"47,03"` ou `"47,027772356"`) como fração de 0 a 1.
double tsePercent(Object? value) {
  if (value is num) return value / 100;
  final texto = value?.toString().replaceAll(',', '.').trim() ?? '';
  return (double.tryParse(texto) ?? 0) / 100;
}
