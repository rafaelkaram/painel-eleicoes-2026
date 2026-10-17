import 'governor_race.dart';

/// As 27 unidades federativas, com nome e região.
///
/// O TSE devolve só a sigla nas cargas por abrangência; nome e região vêm
/// daqui. Lista fixa porque não muda.
enum Uf {
  ac('Acre', Region.norte),
  al('Alagoas', Region.nordeste),
  am('Amazonas', Region.norte),
  ap('Amapá', Region.norte),
  ba('Bahia', Region.nordeste),
  ce('Ceará', Region.nordeste),
  df('Distrito Federal', Region.centroOeste),
  es('Espírito Santo', Region.sudeste),
  go('Goiás', Region.centroOeste),
  ma('Maranhão', Region.nordeste),
  mg('Minas Gerais', Region.sudeste),
  ms('Mato Grosso do Sul', Region.centroOeste),
  mt('Mato Grosso', Region.centroOeste),
  pa('Pará', Region.norte),
  pb('Paraíba', Region.nordeste),
  pe('Pernambuco', Region.nordeste),
  pi('Piauí', Region.nordeste),
  pr('Paraná', Region.sul),
  rj('Rio de Janeiro', Region.sudeste),
  rn('Rio Grande do Norte', Region.nordeste),
  ro('Rondônia', Region.norte),
  rr('Roraima', Region.norte),
  rs('Rio Grande do Sul', Region.sul),
  sc('Santa Catarina', Region.sul),
  se('Sergipe', Region.nordeste),
  sp('São Paulo', Region.sudeste),
  to('Tocantins', Region.norte);

  const Uf(this.label, this.region);

  /// Nome por extenso.
  final String label;

  final Region region;

  /// Sigla em maiúscula, como as telas mostram.
  String get sigla => name.toUpperCase();

  /// Sigla em minúscula, como a URL do TSE pede.
  String get slug => name;

  static Uf? bySigla(String sigla) {
    final alvo = sigla.toLowerCase().trim();
    for (final uf in values) {
      if (uf.name == alvo) return uf;
    }
    return null;
  }
}
