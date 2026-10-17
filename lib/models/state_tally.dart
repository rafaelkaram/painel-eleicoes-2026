import 'package:flutter/foundation.dart';

/// Totalização de uma unidade federativa.
@immutable
class StateTally {
  const StateTally({
    required this.uf,
    required this.name,
    required this.shareA,
    required this.countedShare,
  }) : assert(shareA >= 0 && shareA <= 1, 'share é fração, não percentual');

  /// Sigla de duas letras, ex.: `SP`.
  final String uf;

  /// Nome por extenso, ex.: `São Paulo`.
  final String name;

  /// Fração do Candidato A. A do B é o complemento.
  final double shareA;

  /// Fração de urnas totalizadas na UF.
  final double countedShare;

  double get shareB => 1 - shareA;

  /// `true` enquanto a UF não tem nenhuma seção totalizada.
  ///
  /// Zero voto dos dois lados deixa `shareA` em 0, e daí todo o resto
  /// conclui o que não dá para concluir: B liderando com margem cheia nos
  /// 27 estados. Antes da primeira urna não há líder — quem for perguntar
  /// por cor, rótulo ou margem precisa consultar isto primeiro.
  bool get awaitingCount => countedShare <= 0;

  bool get leadsA => shareA >= 0.5;

  double get leaderShare => leadsA ? shareA : shareB;
  double get runnerUpShare => 1 - leaderShare;

  /// Margem sobre a linha de equilíbrio, de 0 (empate) a 1 (unanimidade).
  double get margin => ((shareA - 0.5).abs() * 2).clamp(0.0, 1.0);

  /// Chave ISO 3166-2 usada pelo mapa.
  String get isoCode => 'BR-$uf';

  /// `true` quando o Distrito Federal.
  bool get isFederalDistrict => uf == 'DF';
}

/// Contagem de unidades por candidato, derivada da lista.
@immutable
class TerritoryCount {
  const TerritoryCount({
    required this.states,
    required this.withFederalDistrict,
  });

  /// Estados liderados, sem contar o DF.
  final int states;

  /// `true` se o DF também é desse candidato.
  final bool withFederalDistrict;

  /// Total de unidades federativas, DF incluído.
  int get units => states + (withFederalDistrict ? 1 : 0);

  /// `14 + DF`, para o resumo compacto do cabeçalho.
  String get compactLabel => withFederalDistrict ? '$states + DF' : '$states';

  /// `14 ESTADOS + DF`, para a legenda do mapa.
  String get legendLabel =>
      '$states ESTADO${states == 1 ? "" : "S"}${withFederalDistrict ? " + DF" : ""}';

  static TerritoryCount from(Iterable<StateTally> tallies) {
    return TerritoryCount(
      states: tallies.where((t) => !t.isFederalDistrict).length,
      withFederalDistrict: tallies.any((t) => t.isFederalDistrict),
    );
  }
}
