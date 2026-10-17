import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/tse_client.dart';
import '../data/tse_election.dart';
import '../data/tse_mapper.dart';
import '../data/tse_payload.dart';
import '../models/governor_race.dart';
import '../models/overseas_tally.dart';
import '../models/state_tally.dart';
import '../models/uf.dart';

/// Em que ponto está a carga de um turno.
enum LoadStatus { idle, loading, ready, failed }

/// Estado da apuração presidencial, por turno, com atualização contínua.
///
/// O TSE não empurra dado: são arquivos estáticos atrás de CDN. Acompanhar
/// em tempo real é perguntar de novo no intervalo que o próprio
/// `cache-control` da resposta indica.
class ApuracaoController extends ChangeNotifier with WidgetsBindingObserver {
  ApuracaoController({
    TseClient? client,
    Turno turno = Turno.primeiro,
    this.autoPoll = true,
  }) : _client = client ?? TseClient(),
       // ignore: prefer_initializing_formals — o campo é privado e mutável.
       _turno = turno;

  final TseClient _client;

  /// Liga a repetição automática. Desligado no teste, para o tempo não
  /// correr sozinho.
  final bool autoPoll;

  final Map<Turno, TseResult> _cache = {};
  final Map<Turno, String> _erros = {};
  final Map<Turno, Map<Uf, TseResult>> _presidenteUf = {};
  final Map<Turno, Map<Uf, TseResult>> _governadorUf = {};
  final Map<Turno, TseResult> _exterior = {};

  Turno _turno;
  LoadStatus _status = LoadStatus.idle;
  Timer? _timer;
  Timer? _timerDetalhe;
  Duration _interval = TseClient.minPollInterval;
  Duration? _latencia;
  DateTime? _atualizadoEm;
  bool _varrendoUfs = false;
  bool _paused = false;
  bool _observando = false;
  bool _descartado = false;
  int _descartadas = 0;

  Turno get turno => _turno;
  LoadStatus get status => _status;

  /// Resultado do turno selecionado, se já veio.
  TseResult? get result => _cache[_turno];

  /// Mensagem de erro do turno selecionado, se a carga falhou.
  String? get error => _erros[_turno];

  /// Código da eleição do turno atual, usado para montar a URL da foto.
  int get eleicao => _turno.presidente;

  /// Intervalo atual entre as consultas, vindo do `cache-control`.
  Duration get pollInterval => _interval;

  /// Quanto demorou a última consulta bem-sucedida.
  Duration? get latency => _latencia;

  /// Quando a última carga foi aplicada na tela.
  DateTime? get lastUpdated => _atualizadoEm;

  /// `true` quando a repetição está suspensa — aba oculta, por exemplo.
  bool get paused => _paused;

  /// Quantas respostas foram descartadas por chegarem atrasadas.
  ///
  /// Exposto porque é o tipo de coisa que, se estiver subindo, explica uma
  /// tela que parece travada.
  int get staleResponses => _descartadas;

  /// Quanto esperar entre duas varreduras das 27 UFs.
  ///
  /// São 27 requisições por varredura. Repetir isso no ritmo da carga
  /// nacional seria 27 vezes o tráfego para uma visão que muda devagar —
  /// liderança estadual não vira de segundo em segundo.
  static const detailInterval = Duration(seconds: 60);

  /// Totalização presidencial por UF, para o mapa.
  List<StateTally> get states {
    final porUf = _presidenteUf[_turno];
    final nacional = result;
    if (porUf == null || nacional == null || nacional.candidates.isEmpty) {
      return const [];
    }
    return TseMapper.states(porUf, numeroA: nacional.candidates.first.number);
  }

  /// Disputas estaduais pelo governo no turno selecionado.
  List<GovernorRace> get governorRaces => governorRacesFor(_turno);

  /// Disputas estaduais de um turno específico.
  ///
  /// A tela do 2º turno precisa das duas coisas ao mesmo tempo: quem já foi
  /// eleito no 1º e quem ainda está em disputa no 2º.
  List<GovernorRace> governorRacesFor(Turno turno) {
    final porUf = _governadorUf[turno];
    if (porUf == null) return const [];
    return TseMapper.governorRaces(porUf, eleicao: turno.governador);
  }

  /// Governadores já eleitos no 1º turno.
  List<GovernorRace> get electedFirstRound =>
      governorRacesFor(Turno.primeiro)
          .where((r) => r.status == RaceStatus.elected)
          .toList();

  /// Votação na Zona ZZ, quando a carga do exterior já veio.
  OverseasTally? get overseas {
    final r = _exterior[_turno];
    return r == null ? null : TseMapper.overseas(r, eleicao: _turno.presidente);
  }

  /// `true` enquanto as cargas por UF ainda não chegaram.
  bool get detailsPending => _presidenteUf[_turno] == null;

  /// `true` quando não há mais o que esperar: 100% das seções totalizadas.
  ///
  /// Arquivo encerrado não muda mais — o do 1º turno está parado desde 7 de
  /// outubro. Continuar perguntando de cinco em cinco segundos é tráfego
  /// jogado fora, no nosso lado e no do TSE. O site de referência faz o
  /// mesmo: para de consultar quando o pleito fecha.
  bool get countingClosed {
    final r = result;
    return r != null &&
        r.sections.counted >= r.sections.total &&
        r.sections.total > 0;
  }

  /// `true` quando o painel ainda está consultando o TSE de tempos em tempos.
  bool get polling => autoPoll && !_paused && !countingClosed;

  /// `true` quando o turno existe no TSE mas ainda não tem seção apurada.
  bool get awaitingCount {
    final r = result;
    return r != null && r.sections.counted == 0;
  }

  /// Começa a acompanhar: primeira carga e, daí em diante, repetição.
  ///
  /// Só aqui o controller se registra no ciclo de vida. Quem usa o
  /// controller fora de um app montado — um teste de unidade, por exemplo —
  /// chama `load()` direto e não precisa de binding nenhum.
  Future<void> start() async {
    if (!_observando) {
      WidgetsBinding.instance.addObserver(this);
      _observando = true;
    }
    await load();
    unawaited(loadDetails());
  }

  /// Troca o turno exibido e busca a carga dele se ainda não veio.
  Future<void> select(Turno turno) async {
    if (turno == _turno) return;
    _turno = turno;
    _status = _cache.containsKey(turno)
        ? LoadStatus.ready
        : (_erros.containsKey(turno) ? LoadStatus.failed : LoadStatus.idle);
    notifyListeners();
    await load();
    if (_presidenteUf[turno] == null) unawaited(loadDetails());
  }

  /// Busca o turno atual e reprograma a próxima consulta.
  Future<void> load() async {
    final alvo = _turno;
    if (_status != LoadStatus.ready) {
      _status = LoadStatus.loading;
      _erros.remove(alvo);
      notifyListeners();
    }

    try {
      final carga = await _client.fetch(
        eleicao: alvo.presidente,
        cargo: Cargo.presidente,
      );
      // Uma troca de turno durante a requisição descarta a resposta antiga.
      if (alvo != _turno) return;

      _interval = carga.maxAge;
      _latencia = carga.latency;
      if (_aceita(alvo, carga.result)) {
        _cache[alvo] = carga.result;
        _atualizadoEm = DateTime.now();
      } else {
        _descartadas++;
      }
      _erros.remove(alvo);
      _status = LoadStatus.ready;
    } on TseException catch (e) {
      if (alvo != _turno) return;
      // Uma falha pontual não apaga o que já está na tela.
      _erros[alvo] = e.message;
      if (!_cache.containsKey(alvo)) _status = LoadStatus.failed;
    }

    notifyListeners();
    _schedule();
  }

  /// Varre as 27 UFs para o mapa e para as disputas estaduais.
  ///
  /// Roda em segundo plano: a tela nacional não espera por ela.
  ///
  /// UF que falhar fica de fora: um mapa com 26 estados pintados é melhor
  /// que uma tela de erro.
  Future<void> loadDetails() async {
    if (_descartado || _varrendoUfs) return;
    _varrendoUfs = true;
    try {
      await _varrerUfs();
    } finally {
      _varrendoUfs = false;
    }
  }

  Future<void> _varrerUfs() async {
    final alvo = _turno;

    // No 2º turno, governador só existe onde houve segundo turno.
    final ufsGoverno = alvo == Turno.primeiro
        ? Uf.values
        : [
            for (final sigla in Turno.ufsSegundoTurnoGovernador)
              ?Uf.bySigla(sigla),
          ];

    // Em sequência, não em paralelo: duas varreduras juntas dobram as
    // conexões simultâneas e sufocam a consulta nacional, que é a que muda
    // a cada minuto numa noite de apuração.
    final presidentePorUf = await _client.fetchUfs(
      eleicao: alvo.presidente,
      cargo: Cargo.presidente,
    );
    if (_descartado || alvo != _turno) return;

    final governadorPorUf = await _client.fetchUfs(
      eleicao: alvo.governador,
      cargo: Cargo.governador,
      ufs: ufsGoverno,
    );
    final cargas = [presidentePorUf, governadorPorUf];

    // No 2º turno a tela mostra também quem já venceu no 1º, então a
    // carga do primeiro turno precisa estar em mãos.
    if (alvo == Turno.segundo && _governadorUf[Turno.primeiro] == null) {
      final primeiro = await _client.fetchUfs(
        eleicao: Turno.primeiro.governador,
        cargo: Cargo.governador,
      );
      if (_descartado) return;
      _governadorUf[Turno.primeiro] = {
        for (final e in primeiro.entries) e.key: e.value.result,
      };
    }

    // A Zona ZZ é publicada como se fosse uma UF, fora da lista das 27.
    TseResult? exterior;
    try {
      exterior = (await _client.fetch(
        eleicao: alvo.presidente,
        cargo: Cargo.presidente,
        abrangencia: 'zz',
      )).result;
    } on TseException {
      // Exterior ausente não impede o resto.
    }

    if (_descartado || alvo != _turno) return;
    if (exterior != null) _exterior[alvo] = exterior;

    _presidenteUf[alvo] = {
      for (final e in cargas[0].entries) e.key: e.value.result,
    };
    _governadorUf[alvo] = {
      for (final e in cargas[1].entries) e.key: e.value.result,
    };

    notifyListeners();
    _scheduleDetails();
  }

  void _scheduleDetails() {
    _timerDetalhe?.cancel();
    if (_descartado || !autoPoll || _paused || countingClosed) return;
    _timerDetalhe = Timer(detailInterval, loadDetails);
  }

  /// Rejeita carga mais velha que a exibida, pelo `idg`.
  bool _aceita(Turno turno, TseResult nova) {
    final atual = _cache[turno];
    if (atual == null) return true;
    return nova.generationId > atual.generationId;
  }

  void _schedule() {
    _timer?.cancel();
    if (_descartado || !autoPoll || _paused || countingClosed) return;
    _timer = Timer(_interval, load);
  }

  /// Suspende a repetição. A tela continua mostrando o último dado.
  void pause() {
    if (_paused) return;
    _paused = true;
    _timer?.cancel();
    _timerDetalhe?.cancel();
    notifyListeners();
  }

  /// Retoma a repetição e busca imediatamente, para cobrir o tempo parado.
  ///
  /// Com a apuração encerrada, consulta uma vez para confirmar e para de
  /// novo — pode ter virado turno enquanto a aba estava oculta.
  void resume() {
    if (!_paused) return;
    _paused = false;
    notifyListeners();
    load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Painel esquecido aberto a noite toda não precisa baixar nada.
    switch (state) {
      case AppLifecycleState.resumed:
        resume();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        pause();
    }
  }

  @override
  void dispose() {
    _descartado = true;
    _timer?.cancel();
    _timerDetalhe?.cancel();
    if (_observando) WidgetsBinding.instance.removeObserver(this);
    _client.close();
    super.dispose();
  }
}

/// Disponibiliza o [ApuracaoController] para a árvore.
class ApuracaoScope extends InheritedNotifier<ApuracaoController> {
  const ApuracaoScope({
    super.key,
    required ApuracaoController controller,
    required super.child,
  }) : super(notifier: controller);

  static ApuracaoController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ApuracaoScope>();
    assert(scope != null, 'Faltou um ApuracaoScope acima deste widget');
    return scope!.notifier!;
  }
}
