import 'package:flutter/material.dart';

/// Tipografia do design system "TSE Realtime Intelligence".
///
/// Pareamento: `Inter` para linguagem natural (nomes de candidato, geografia)
/// e `JetBrains Mono` para toda telemetria numérica (votos, % apurado,
/// timestamps, rótulos de coluna).
///
/// As famílias já estão declaradas no pubspec.yaml como fontes variáveis
/// (eixo `wght`), em `assets/fonts/`. Uma declaração por família cobre toda a
/// escala de peso — o Flutter interpola o eixo a partir de [FontWeight].
///
/// Nada de `google_fonts`: o download em runtime atrasa o primeiro paint e
/// adiciona uma dependência de rede a um painel de sala de controle que
/// precisa subir mesmo com a internet instável.
///
/// Ambas as fontes estão sob SIL OFL 1.1 (licenças em `assets/fonts/`).
abstract final class AppFonts {
  static const body = 'Inter';
  static const mono = 'JetBrainsMono';
}

/// Figuras tabulares + zero cortado.
///
/// Exigência explícita do design.md e a única regra da prosa que as telas
/// geradas NÃO cumpriram — o HTML do Stitch não emite `font-feature-settings`.
/// Sem isso, cada atualização via WebSocket muda a largura dos dígitos e a
/// coluna de votos treme verticalmente. Aplicado em todo papel monoespaçado.
const List<FontFeature> kTabularFigures = <FontFeature>[
  FontFeature.tabularFigures(),
  FontFeature.slashedZero(),
];

/// Escala tipográfica do Stitch mapeada para os papéis do Material 3.
///
/// `letterSpacing` do design.md vem em `em`; no Flutter é em pixels lógicos,
/// então cada valor já está convertido (em × fontSize). `height` é múltiplo
/// do fontSize (lineHeight ÷ fontSize).
abstract final class AppTypography {
  // --- Inter: linguagem natural ---------------------------------------

  /// headline-lg — 32/40, -0.02em
  static const headlineLarge = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.64,
  );

  /// headline-md — 24/32, -0.015em
  static const headlineMedium = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    letterSpacing: -0.36,
  );

  /// headline-sm — 20/28
  static const headlineSmall = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
  );

  /// body-lg — 16/24
  static const bodyLarge = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  /// body-md — 14/20
  static const bodyMedium = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  /// body-sm — 12/16
  static const bodySmall = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
  );

  // --- JetBrains Mono: telemetria e rótulos ----------------------------
  // Rótulos usam caixa alta com tracking positivo. Aplique o uppercase no
  // widget (`'ao vivo'.toUpperCase()`), não aqui — o estilo não transforma.

  /// label-lg — 13/16, +0.02em
  static const labelLarge = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 16 / 13,
    letterSpacing: 0.26,
    fontFeatures: kTabularFigures,
  );

  /// label-md — 11/14, +0.04em
  static const labelMedium = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 14 / 11,
    letterSpacing: 0.44,
    fontFeatures: kTabularFigures,
  );

  /// label-sm — 10/12, +0.06em. O papel mais usado das telas (53 ocorrências
  /// só na Apuração Presidencial): cabeçalho de coluna, badge, timestamp.
  static const labelSmall = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 12 / 10,
    letterSpacing: 0.6,
    fontFeatures: kTabularFigures,
  );

  /// stat-display — 28/32, -0.03em. Contagem de votos do card de candidato.
  static const statDisplay = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 32 / 28,
    letterSpacing: -0.84,
    fontFeatures: kTabularFigures,
  );

  /// stat-metric — 18/24, -0.02em. Percentuais e métricas secundárias.
  static const statMetric = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    letterSpacing: -0.36,
    fontFeatures: kTabularFigures,
  );

  // --- Papéis derivados -------------------------------------------------
  // O Stitch não define `title-*`, mas widgets do Material (AppBar, ListTile,
  // ExpansionTile) consomem esses slots. Derivados de Inter para não cair na
  // métrica padrão do Roboto. Não são tokens do design system.

  static const titleLarge = headlineSmall;

  static const titleMedium = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
  );

  static const titleSmall = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
  );

  /// TextTheme completo. `display*` fica de fora de propósito: o Stitch não
  /// definiu esses papéis. Eles herdam a métrica do Material com Inter
  /// aplicado via `ThemeData.fontFamily`.
  static const textTheme = TextTheme(
    headlineLarge: headlineLarge,
    headlineMedium: headlineMedium,
    headlineSmall: headlineSmall,
    titleLarge: titleLarge,
    titleMedium: titleMedium,
    titleSmall: titleSmall,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: labelLarge,
    labelMedium: labelMedium,
    labelSmall: labelSmall,
  );
}
