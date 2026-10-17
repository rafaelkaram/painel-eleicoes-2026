import 'package:flutter/material.dart';

/// Tokens de cor do design system "TSE Realtime Intelligence".
///
/// Fonte canônica: `designTheme.namedColors` do projeto Stitch
/// `projects/5202510786101872337` ("Painel Eleições 2026 Flutter"), que são os
/// mesmos valores aplicados no HTML das telas geradas.
///
/// A paleta "navy graphite" descrita em prosa no design.md
/// (#0B0F17 / #131B2E / #1A253F / #1F2C47) foi descartada: não ocorre em
/// nenhuma tela gerada. Ver theme/README.md.
abstract final class AppColors {
  // --- Superfícies -----------------------------------------------------
  // A separação entre planos é TONAL, não por borda: as telas geradas não
  // usam uma única classe `border-*`. Empilhe surfaceContainer* para criar
  // profundidade em vez de sombra.
  static const surface = Color(0xFF0F131C);
  static const surfaceDim = Color(0xFF0F131C);
  static const surfaceBright = Color(0xFF353942);
  static const surfaceContainerLowest = Color(0xFF0A0E16);
  static const surfaceContainerLow = Color(0xFF181C24);
  static const surfaceContainer = Color(0xFF1C2028);
  static const surfaceContainerHigh = Color(0xFF262A33);
  static const surfaceContainerHighest = Color(0xFF31353E);
  static const surfaceTint = Color(0xFF3CE36A);

  static const onSurface = Color(0xFFDFE2EE);
  static const onSurfaceVariant = Color(0xFFBBCBB8);

  static const inverseSurface = Color(0xFFDFE2EE);
  static const inverseOnSurface = Color(0xFF2C3039);

  static const outline = Color(0xFF869583);
  static const outlineVariant = Color(0xFF3C4A3C);

  // --- Primária: Verde Brasil / pulso ao vivo --------------------------
  // Líder da apuração, seções totalizadas, badge "AO VIVO".
  static const primary = Color(0xFF3FE56C);
  static const onPrimary = Color(0xFF003912);
  static const primaryContainer = Color(0xFF00C853);
  static const onPrimaryContainer = Color(0xFF004C1B);
  static const inversePrimary = Color(0xFF006E2A);
  static const primaryFixed = Color(0xFF69FF87);
  static const primaryFixedDim = Color(0xFF3CE36A);
  static const onPrimaryFixed = Color(0xFF002108);
  static const onPrimaryFixedVariant = Color(0xFF00531E);

  // --- Secundária: Dourado Eleitoral -----------------------------------
  // Margem matematicamente contestada, banners de projeção, avisos.
  static const secondary = Color(0xFFFFB95F);
  static const onSecondary = Color(0xFF472A00);
  static const secondaryContainer = Color(0xFFEE9800);
  static const onSecondaryContainer = Color(0xFF5B3800);
  static const secondaryFixed = Color(0xFFFFDDB8);
  static const secondaryFixedDim = Color(0xFFFFB95F);
  static const onSecondaryFixed = Color(0xFF2A1700);
  static const onSecondaryFixedVariant = Color(0xFF653E00);

  // --- Terciária: Azul Republicano -------------------------------------
  // Eleitorado total, filtros geográficos, status "não definido".
  static const tertiary = Color(0xFF82D2FF);
  static const onTertiary = Color(0xFF00354A);
  static const tertiaryContainer = Color(0xFF31B9F4);
  static const onTertiaryContainer = Color(0xFF004661);
  static const tertiaryFixed = Color(0xFFC4E7FF);
  static const tertiaryFixedDim = Color(0xFF7BD0FF);
  static const onTertiaryFixed = Color(0xFF001E2C);
  static const onTertiaryFixedVariant = Color(0xFF004C69);

  // --- Erro: Alerta Oposição -------------------------------------------
  // Recontagem, anomalia estatística, marcador de 2º turno.
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);

  static const scrim = Color(0xFF000000);
  static const shadow = Color(0xFF000000);
}
