import 'package:intl/intl.dart';

/// Formatação numérica em pt-BR para a telemetria da apuração.
///
/// Os formatters são caros de construir e estes rodam a cada frame de
/// atualização do feed, então ficam em cache no nível da biblioteca.
final NumberFormat _votos = NumberFormat.decimalPattern('pt_BR');
final NumberFormat _percentual = NumberFormat('#0.00', 'pt_BR');
final NumberFormat _percentualCurto = NumberFormat('#0.0', 'pt_BR');

/// `58940120` vira `58.940.120`.
String formatVotos(int votos) => _votos.format(votos);

/// `0.5172` vira `51,72%`.
String formatPercentual(double fracao) =>
    '${_percentual.format(fracao * 100)}%';

/// `0.5172` vira `51,7%`. Para espaços apertados como rótulo de barra.
String formatPercentualCurto(double fracao) =>
    '${_percentualCurto.format(fracao * 100)}%';

/// `3920800` vira `+3.920.800`; negativos mantêm o sinal.
String formatDiferenca(int votos) {
  final sinal = votos > 0 ? '+' : '';
  return '$sinal${_votos.format(votos)}';
}

/// `0.0824` vira `8,24 p.p.` — diferença em pontos percentuais.
String formatPontos(double fracao) =>
    '${_percentual.format(fracao * 100)} p.p.';
