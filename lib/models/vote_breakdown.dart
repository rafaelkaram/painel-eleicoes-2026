import 'package:flutter/foundation.dart';

/// Peso visual de um tile do resumo de votos.
enum VoteBreakdownTone {
  /// Número neutro: percentual em `on-surface`.
  neutral,

  /// Número que pede atenção — abstenção, nulos acima do esperado.
  /// Percentual em `error`.
  alert,
}

/// Uma linha do resumo de votos: válidos, nulos, brancos, abstenção.
@immutable
class VoteBreakdown {
  const VoteBreakdown({
    required this.label,
    required this.share,
    required this.votes,
    this.tone = VoteBreakdownTone.neutral,
  }) : assert(share >= 0 && share <= 1, 'share é fração, não percentual');

  /// Rótulo em caixa alta, ex.: `VOTOS VÁLIDOS`.
  final String label;

  /// Fração de 0 a 1.
  final double share;

  /// Valor absoluto.
  final int votes;

  final VoteBreakdownTone tone;
}
