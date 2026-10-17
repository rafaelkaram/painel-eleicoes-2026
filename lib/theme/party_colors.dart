import 'package:flutter/material.dart';

/// Cores de legenda partidária, ajustadas para fundo escuro.
///
/// **São aproximações.** Foram escolhidas a partir da identidade visual
/// conhecida de cada partido e clareadas para ter contraste sobre
/// `#0F131C` — não são valores oficiais de marca. Quando aparecer a
/// especificação correta, é aqui que se corrige: um lugar só, e tudo que
/// pinta por partido acompanha.
///
/// Boa parte das legendas brasileiras usa azul. Por isso [distinguish]
/// existe: sem ela, PSDB contra PL viraria uma barra azul única.
abstract final class PartyColors {
  static const _table = <String, Color>{
    'PT': Color(0xFFE03A3E), // vermelho
    'PSDB': Color(0xFF0F9BD7), // azul tucano
    'PL': Color(0xFF2F6FD0), // azul
    'REP': Color(0xFF5C8AE6), // azul claro
    'REPUBLICANOS': Color(0xFF5C8AE6), // como o TSE escreve por extenso
    'MDB': Color(0xFF1FA55C), // verde
    'PSB': Color(0xFFE8503A), // vermelho alaranjado
    'PSD': Color(0xFF16A3A3), // azul esverdeado
    'UNIÃO': Color(0xFF1C4FA1), // azul
    'SOLIDARIEDADE': Color(0xFFF2994A), // laranja
    'PRTB': Color(0xFF8FBF26), // verde amarelado
  };

  /// Usada quando a sigla não está na tabela. Neutra de propósito: melhor
  /// um cinza honesto que uma cor inventada na hora.
  static const fallback = Color(0xFF8A94A6);

  static Color of(String party) =>
      _table[party.toUpperCase().trim()] ?? fallback;

  /// `true` se a sigla tem cor própria cadastrada.
  static bool isKnown(String party) =>
      _table.containsKey(party.toUpperCase().trim());

  /// Par de cores para os dois lados de uma disputa.
  ///
  /// Partido conhecido manda. Quando a sigla não está na tabela — fictícia,
  /// nova, ou erro de cadastro — cai nas cores semânticas de líder e
  /// segundo colocado, que pelo menos distinguem. Dois cinzas idênticos não
  /// informam nada.
  static (Color leader, Color runnerUp) pairFor(
    String leaderParty,
    String runnerUpParty, {
    required Color leaderFallback,
    required Color runnerUpFallback,
  }) {
    if (!isKnown(leaderParty) && !isKnown(runnerUpParty)) {
      return (leaderFallback, runnerUpFallback);
    }
    final leader = isKnown(leaderParty) ? of(leaderParty) : leaderFallback;
    final runnerUp = isKnown(runnerUpParty)
        ? of(runnerUpParty)
        : runnerUpFallback;
    return (leader, distinguish(leader, runnerUp));
  }

  /// Distância perceptual mínima aceitável entre duas cores na mesma barra.
  static const _minDistance = 0.22;

  /// Piso de luminosidade para a cor continuar legível no fundo escuro.
  ///
  /// Abaixo disso a legenda some contra `#0F131C` — foi o que aconteceu com
  /// o PSD depois de ser afastado do azul do PL para baixo.
  static const _legibilityFloor = 0.44;

  /// Afasta [other] de [base] quando as duas quase coincidem.
  ///
  /// Mantém o matiz — a cor continua reconhecível como a do partido — e
  /// mexe só na luminosidade, sempre **clareando**. Num painel escuro,
  /// escurecer para separar troca um problema por outro pior: as duas
  /// ficam distinguíveis entre si e invisíveis contra o fundo.
  static Color distinguish(Color base, Color other) {
    final hsl = HSLColor.fromColor(other);
    final precisaAfastar = _distance(base, other) < _minDistance;

    var lightness = hsl.lightness;
    if (precisaAfastar) lightness += 0.24;
    if (lightness < _legibilityFloor) lightness = _legibilityFloor;

    final ajustada = hsl.withLightness(lightness.clamp(0.0, 0.88)).toColor();
    return ajustada;
  }

  /// Distância aproximada em RGB normalizado. Simples de propósito: só
  /// precisa responder "essas duas somem uma na outra?".
  static double _distance(Color a, Color b) {
    final dr = a.r - b.r;
    final dg = a.g - b.g;
    final db = a.b - b.b;
    return (dr * dr + dg * dg + db * db) / 3;
  }
}
