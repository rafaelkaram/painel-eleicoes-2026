import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/tse_client.dart';
import '../data/tse_election.dart';
import '../data/tse_lookup.dart';
import '../data/tse_payload.dart';

/// Em que ponto está a consulta.
enum ConsultaStatus { idle, loading, ready, failed }

/// Estado do localizador de urna.
///
/// A cascata é UF → município → zona → seção. Cada degrau depende de um
/// cadastro diferente do TSE, e o de seções é pesado o bastante para só ser
/// buscado quando alguém escolhe a unidade federativa.
class ConsultaController extends ChangeNotifier {
  ConsultaController({
    TseClient? client,
    TseLookup? lookup,
    this.turno = Turno.primeiro,
  }) : _client = client ?? TseClient(),
       _lookup = lookup ?? TseLookup();

  final TseClient _client;
  final TseLookup _lookup;
  final Turno turno;

  ConsultaStatus _status = ConsultaStatus.idle;
  String? _erro;
  bool _descartado = false;

  String? _uf;
  String? _municipio;
  String? _zona;
  String? _secao;

  TseResult? _presidente;
  TseResult? _governador;
  bool _carregandoSecoes = false;
  Future<void>? _secoesFuture;

  ConsultaStatus get status => _status;
  String? get error => _erro;

  TseLookup get lookup => _lookup;

  String? get uf => _uf;
  String? get municipio => _municipio;
  String? get zona => _zona;
  String? get secao => _secao;

  /// Resultado do município para presidente.
  TseResult? get presidente => _presidente;

  /// Resultado do município para governador.
  TseResult? get governador => _governador;

  /// `true` enquanto o cadastro de seções da UF está vindo.
  bool get loadingSections => _carregandoSecoes;

  /// Completa quando o cadastro de seções da UF atual terminou.
  ///
  /// A carga roda em segundo plano para a cascata não travar esperando meio
  /// megabyte. Quem precisa do resultado — um teste, ou um deep link que
  /// aponta direto para uma seção — espera por aqui.
  Future<void> get sectionsReady => _secoesFuture ?? Future<void>.value();

  List<MunicipalityRef> get municipalities =>
      _uf == null ? const [] : _lookup.municipalitiesOf(_uf!);

  MunicipalityRef? get currentMunicipality {
    for (final m in municipalities) {
      if (m.code == _municipio) return m;
    }
    return null;
  }

  List<String> get zones => currentMunicipality?.zones ?? const [];

  List<SectionRefTse> get sections =>
      (_uf == null || _municipio == null || _zona == null)
      ? const []
      : _lookup.sectionsOf(_uf!, _municipio!, _zona!);

  SectionRefTse? get currentSection {
    for (final s in sections) {
      if (s.number == _secao) return s;
    }
    return null;
  }

  /// Carrega o cadastro nacional e escolhe um ponto de partida.
  Future<void> start({String ufInicial = 'SP'}) async {
    _status = ConsultaStatus.loading;
    notifyListeners();

    try {
      await _lookup.loadMunicipalities(turno.presidente);
      if (_descartado) return;
      _status = ConsultaStatus.ready;
      await selectUf(ufInicial);
    } on TseException catch (e) {
      if (_descartado) return;
      _erro = e.message;
      _status = ConsultaStatus.failed;
      notifyListeners();
    }
  }

  Future<void> selectUf(String uf) async {
    _uf = uf.toUpperCase();
    _municipio = null;
    _zona = null;
    _secao = null;
    _presidente = null;
    _governador = null;
    notifyListeners();

    final primeiro = municipalities.isEmpty ? null : municipalities.first;
    if (primeiro != null) await selectMunicipality(primeiro.code);

    // O cadastro de seções é grande; vem em segundo plano para a cascata
    // não travar esperando por ele.
    _secoesFuture = _carregarSecoes();
    unawaited(_secoesFuture!);
  }

  Future<void> selectMunicipality(String codigo) async {
    _municipio = codigo;
    _zona = zones.isEmpty ? null : zones.first;
    _secao = null;
    notifyListeners();

    await _carregarResultados();
    _ajustarSecao();
  }

  void selectZone(String zona) {
    _zona = zona;
    _secao = null;
    _ajustarSecao();
    notifyListeners();
  }

  void selectSection(String secao) {
    _secao = secao;
    notifyListeners();
  }

  Future<void> _carregarResultados() async {
    final uf = _uf;
    final municipio = _municipio;
    if (uf == null || municipio == null) return;

    try {
      final cargas = await Future.wait([
        _client.fetchMunicipality(
          eleicao: turno.presidente,
          cargo: Cargo.presidente,
          uf: uf,
          municipio: municipio,
        ),
        _client.fetchMunicipality(
          eleicao: turno.governador,
          cargo: Cargo.governador,
          uf: uf,
          municipio: municipio,
        ),
      ]);
      if (_descartado || municipio != _municipio) return;
      _presidente = cargas[0].result;
      _governador = cargas[1].result;
      _erro = null;
    } on TseException catch (e) {
      if (_descartado || municipio != _municipio) return;
      _presidente = null;
      _governador = null;
      _erro = e.message;
    }
    notifyListeners();
  }

  Future<void> _carregarSecoes() async {
    final uf = _uf;
    if (uf == null || _lookup.hasSections(uf)) return;

    _carregandoSecoes = true;
    notifyListeners();
    try {
      await _lookup.loadSections(uf);
    } on TseException {
      // Sem cadastro de seções a tela continua útil: município e zona já
      // respondem. Só o seletor de seção fica vazio.
    }
    if (_descartado) return;
    _carregandoSecoes = false;
    _ajustarSecao();
    notifyListeners();
  }

  void _ajustarSecao() {
    final lista = sections;
    _secao = lista.isEmpty ? null : lista.first.number;
  }

  @override
  void dispose() {
    _descartado = true;
    _client.close();
    _lookup.close();
    super.dispose();
  }
}

/// Disponibiliza o [ConsultaController] para a árvore.
class ConsultaScope extends InheritedNotifier<ConsultaController> {
  const ConsultaScope({
    super.key,
    required ConsultaController controller,
    required super.child,
  }) : super(notifier: controller);

  static ConsultaController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ConsultaScope>();
    assert(scope != null, 'Faltou um ConsultaScope acima deste widget');
    return scope!.notifier!;
  }
}
