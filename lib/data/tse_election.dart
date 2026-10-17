/// Catálogo das eleições de 2026 no portal de resultados do TSE.
///
/// Os códigos vieram de `comum/config/ele-c.json`, que é o índice público do
/// TSE. Ficam fixos aqui porque são de uma eleição já realizada e não mudam
/// mais — e porque depender do índice a cada abertura adicionaria uma
/// requisição no caminho crítico sem ganho.
enum Turno {
  primeiro(
    label: '1º Turno',
    date: '04/10/2026',
    presidente: 6257,
    governador: 6259,
  ),
  segundo(
    label: '2º Turno',
    date: '25/10/2026',
    presidente: 6258,
    governador: 6260,
  );

  const Turno({
    required this.label,
    required this.date,
    required this.presidente,
    required this.governador,
  });

  final String label;

  /// Data da votação, como o TSE publica.
  final String date;

  /// Código da eleição para o cargo de presidente.
  final int presidente;

  /// Código da eleição para governador.
  final int governador;

  /// Unidades com 2º turno para governador. No 1º turno, todas votam.
  static const ufsSegundoTurnoGovernador = ['AM', 'RN', 'DF', 'ES', 'AC', 'TO'];
}

/// Cargo, no código que o TSE usa na URL.
enum Cargo {
  presidente(1),
  governador(3),
  senador(5);

  const Cargo(this.code);

  final int code;
}

/// Monta as URLs do portal de resultados.
abstract final class TseEndpoints {
  static const base = 'https://resultados.tse.jus.br/oficial/ele2026';

  /// Resultado de um cargo numa abrangência.
  ///
  /// O arquivo `.jws` é a versão assinada em EdDSA — é a que vale como
  /// procedência, e o payload dentro dela é o mesmo JSON do `.json` ao lado.
  static Uri results({
    required int eleicao,
    required Cargo cargo,
    String abrangencia = 'br',
  }) {
    final uf = abrangencia.toLowerCase();
    final c = cargo.code.toString().padLeft(4, '0');
    final e = eleicao.toString().padLeft(6, '0');
    return Uri.parse('$base/$eleicao/dados/$uf/$uf-c$c-e$e-u.jws');
  }

  /// Código do pleito de 2026, usado pelo arquivo de urna.
  static const pleito = 3220;

  /// Resultado de um cargo dentro de um município.
  ///
  /// Mesmo diretório da UF; o que muda é o prefixo do arquivo, que cola a
  /// sigla ao código do município: `sp62910-c0001-...`.
  static Uri municipality({
    required int eleicao,
    required Cargo cargo,
    required String uf,
    required String municipio,
  }) {
    final sigla = uf.toLowerCase();
    final c = cargo.code.toString().padLeft(4, '0');
    final e = eleicao.toString().padLeft(6, '0');
    return Uri.parse(
      '$base/$eleicao/dados/$sigla/$sigla$municipio-c$c-e$e-u.jws',
    );
  }

  /// Cadastro de municípios e zonas de uma eleição.
  static Uri municipalityConfig(int eleicao) {
    final e = eleicao.toString().padLeft(6, '0');
    return Uri.parse('$base/$eleicao/config/mun-e$e-cm.json');
  }

  /// Cadastro de seções de uma UF, do arquivo de urna.
  ///
  /// Pesado — meio megabyte comprimido por UF — então só é buscado quando
  /// alguém escolhe a unidade federativa.
  static Uri sectionConfig(String uf) {
    final sigla = uf.toLowerCase();
    final p = pleito.toString().padLeft(6, '0');
    return Uri.parse(
      '$base/arquivo-urna/$pleito/config/$sigla/$sigla-p$p-cs.json',
    );
  }

  /// Foto oficial do candidato, pela chave `sqcand` que vem no resultado.
  static Uri portrait({
    required int eleicao,
    required String sqcand,
    String abrangencia = 'br',
  }) {
    return Uri.parse(
      '$base/$eleicao/fotos/${abrangencia.toLowerCase()}/$sqcand.jpeg',
    );
  }
}
