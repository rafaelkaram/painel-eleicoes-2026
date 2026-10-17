import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Papéis tipográficos de telemetria que não têm slot no Material 3.
///
/// Acesse por `context.stats.statDisplay` em vez de referenciar
/// [AppTypography] direto, para que um tema alternativo (ex.: modo claro para
/// impressão de boletim) consiga sobrescrever.
@immutable
class AppStatStyles extends ThemeExtension<AppStatStyles> {
  const AppStatStyles({required this.statDisplay, required this.statMetric});

  /// Contagem absoluta de votos no card de candidato.
  final TextStyle statDisplay;

  /// Percentuais e métricas secundárias.
  final TextStyle statMetric;

  static const standard = AppStatStyles(
    statDisplay: AppTypography.statDisplay,
    statMetric: AppTypography.statMetric,
  );

  @override
  AppStatStyles copyWith({TextStyle? statDisplay, TextStyle? statMetric}) {
    return AppStatStyles(
      statDisplay: statDisplay ?? this.statDisplay,
      statMetric: statMetric ?? this.statMetric,
    );
  }

  @override
  AppStatStyles lerp(ThemeExtension<AppStatStyles>? other, double t) {
    if (other is! AppStatStyles) return this;
    return AppStatStyles(
      statDisplay: TextStyle.lerp(statDisplay, other.statDisplay, t)!,
      statMetric: TextStyle.lerp(statMetric, other.statMetric, t)!,
    );
  }
}

/// Semântica eleitoral: o que cada cor significa na apuração.
///
/// Existe para que a tela diga `tokens.contested` em vez de
/// `colorScheme.secondary` — quando a paleta mudar, a intenção sobrevive.
@immutable
class AppElectionTokens extends ThemeExtension<AppElectionTokens> {
  const AppElectionTokens({
    required this.leader,
    required this.contested,
    required this.uncalled,
    required this.alert,
    required this.leaderGlow,
    required this.contestedGlow,
    required this.overlayShadow,
  });

  /// Candidato líder, seção totalizada, pulso "AO VIVO".
  final Color leader;

  /// Margem matematicamente contestada, banner de projeção.
  final Color contested;

  /// Disputa ainda não definida, eleitorado total, filtro geográfico.
  final Color uncalled;

  /// Recontagem, anomalia estatística, marcador de 2º turno.
  final Color alert;

  /// Luminescência de borda de seção em processamento.
  final List<BoxShadow> leaderGlow;

  /// Luminescência de margem apertada.
  final List<BoxShadow> contestedGlow;

  /// Sombra ambiente de popover, flyout e tooltip (nível 2).
  final List<BoxShadow> overlayShadow;

  static const standard = AppElectionTokens(
    leader: AppColors.primary,
    contested: AppColors.secondary,
    uncalled: AppColors.tertiary,
    alert: AppColors.error,
    leaderGlow: <BoxShadow>[
      BoxShadow(color: Color(0x2600C853), blurRadius: 12),
    ],
    contestedGlow: <BoxShadow>[
      BoxShadow(color: Color(0x26EE9800), blurRadius: 12),
    ],
    overlayShadow: <BoxShadow>[
      BoxShadow(
        color: Color(0xA6000000),
        offset: Offset(0, 8),
        blurRadius: 24,
        spreadRadius: -4,
      ),
    ],
  );

  @override
  AppElectionTokens copyWith({
    Color? leader,
    Color? contested,
    Color? uncalled,
    Color? alert,
    List<BoxShadow>? leaderGlow,
    List<BoxShadow>? contestedGlow,
    List<BoxShadow>? overlayShadow,
  }) {
    return AppElectionTokens(
      leader: leader ?? this.leader,
      contested: contested ?? this.contested,
      uncalled: uncalled ?? this.uncalled,
      alert: alert ?? this.alert,
      leaderGlow: leaderGlow ?? this.leaderGlow,
      contestedGlow: contestedGlow ?? this.contestedGlow,
      overlayShadow: overlayShadow ?? this.overlayShadow,
    );
  }

  @override
  AppElectionTokens lerp(ThemeExtension<AppElectionTokens>? other, double t) {
    if (other is! AppElectionTokens) return this;
    return AppElectionTokens(
      leader: Color.lerp(leader, other.leader, t)!,
      contested: Color.lerp(contested, other.contested, t)!,
      uncalled: Color.lerp(uncalled, other.uncalled, t)!,
      alert: Color.lerp(alert, other.alert, t)!,
      leaderGlow: BoxShadow.lerpList(leaderGlow, other.leaderGlow, t)!,
      contestedGlow: BoxShadow.lerpList(contestedGlow, other.contestedGlow, t)!,
      overlayShadow: BoxShadow.lerpList(overlayShadow, other.overlayShadow, t)!,
    );
  }
}

/// Atalhos de leitura do tema.
extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppStatStyles get stats => Theme.of(this).extension<AppStatStyles>()!;
  AppElectionTokens get election =>
      Theme.of(this).extension<AppElectionTokens>()!;
}
