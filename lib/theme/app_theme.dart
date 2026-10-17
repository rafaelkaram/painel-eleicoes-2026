import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_theme_extensions.dart';
import 'app_typography.dart';

/// Tema do "Painel Eleições 2026", extraído do design system
/// "TSE Realtime Intelligence" (Stitch `projects/5202510786101872337`).
///
/// Requer Flutter 3.27+ (usa `CardThemeData` e `Color.withValues`).
///
/// O design é dark-only por natureza: uma sala de apuração roda horas em
/// ambiente escuro e a paleta foi construída para contraste sustentado. Não
/// existe variante clara no Stitch — se um dia precisar (boletim impresso),
/// derive uma nova em vez de forçar esta.
abstract final class AppTheme {
  static const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    primaryFixed: AppColors.primaryFixed,
    primaryFixedDim: AppColors.primaryFixedDim,
    onPrimaryFixed: AppColors.onPrimaryFixed,
    onPrimaryFixedVariant: AppColors.onPrimaryFixedVariant,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    secondaryFixed: AppColors.secondaryFixed,
    secondaryFixedDim: AppColors.secondaryFixedDim,
    onSecondaryFixed: AppColors.onSecondaryFixed,
    onSecondaryFixedVariant: AppColors.onSecondaryFixedVariant,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    tertiaryFixed: AppColors.tertiaryFixed,
    tertiaryFixedDim: AppColors.tertiaryFixedDim,
    onTertiaryFixed: AppColors.onTertiaryFixed,
    onTertiaryFixedVariant: AppColors.onTertiaryFixedVariant,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    surfaceDim: AppColors.surfaceDim,
    surfaceBright: AppColors.surfaceBright,
    surfaceContainerLowest: AppColors.surfaceContainerLowest,
    surfaceContainerLow: AppColors.surfaceContainerLow,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    surfaceTint: AppColors.surfaceTint,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: AppColors.inverseOnSurface,
    inversePrimary: AppColors.inversePrimary,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    scrim: AppColors.scrim,
    shadow: AppColors.shadow,
  );

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      canvasColor: AppColors.surface,

      // Pega os papéis que o Stitch não definiu (display*) com a fonte certa.
      fontFamily: AppFonts.body,
      textTheme: AppTypography.textTheme,

      // Workstation de alta densidade: linhas e controles apertados.
      visualDensity: VisualDensity.compact,

      // As telas geradas não usam uma única borda: profundidade é puramente
      // tonal. O tint do M3 sobre superfície mataria essa hierarquia.
      splashFactory: InkSparkle.splashFactory,

      extensions: const <ThemeExtension<dynamic>>[
        AppStatStyles.standard,
        AppElectionTokens.standard,
      ],

      appBarTheme: AppBarTheme(
        toolbarHeight: AppMetrics.headerHeight,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.onSurface,
        ),
      ),

      cardTheme: const CardThemeData(
        color: AppColors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(
        color: AppColors.onSurfaceVariant,
        size: 20,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        minWidth: AppMetrics.navRailCollapsed,
        useIndicator: true,
        indicatorColor: AppColors.primary.withValues(alpha: 0.08),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
        ),
        selectedIconTheme: const IconThemeData(
          color: AppColors.primary,
          size: 20,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.onSurfaceVariant,
          size: 20,
        ),
        selectedLabelTextStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.primary,
        ),
        unselectedLabelTextStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        labelType: NavigationRailLabelType.all,
      ),

      // Tabela de votação por município/zona em modo denso.
      // Células numéricas precisam de `AppTypography.statMetric` ou
      // `labelLarge` aplicados por célula — o tema não alcança esse nível.
      dataTableTheme: DataTableThemeData(
        headingRowColor: const WidgetStatePropertyAll(AppColors.surface),
        headingRowHeight: AppMetrics.tableRowHeight,
        dataRowMinHeight: AppMetrics.tableRowHeight,
        dataRowMaxHeight: AppMetrics.tableRowHeight,
        columnSpacing: AppSpacing.xl,
        horizontalMargin: AppSpacing.lg,
        dividerThickness: 1,
        headingTextStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        dataTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.onSurface,
        ),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceContainerHigh,
        linearMinHeight: AppMetrics.progressBarHeight,
        circularTrackColor: AppColors.surfaceContainerHigh,
      ),

      // Chips de status ("ELEITO MATEMATICAMENTE", "2º TURNO CONFIRMADO")
      // mantêm canto de 8px — pílula só para dot e barra de progresso.
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.onSurface,
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.tertiaryContainer),
          boxShadow: AppElectionTokens.standard.overlayShadow,
        ),
        textStyle: AppTypography.bodySmall.copyWith(color: AppColors.onSurface),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        waitDuration: const Duration(milliseconds: 300),
      ),

      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        textStyle: AppTypography.bodyMedium,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.lgAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.lgAll,
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.lgAll,
          borderSide: BorderSide(color: AppColors.primary),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.lgAll,
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          textStyle: AppTypography.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          textStyle: AppTypography.labelLarge,
          side: const BorderSide(color: AppColors.outlineVariant),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurfaceVariant,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelLarge,
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.outlineVariant,
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: AppTypography.headlineSmall,
        contentTextStyle: AppTypography.bodyMedium,
      ),

      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(8),
        thumbColor: WidgetStatePropertyAll(
          AppColors.outline.withValues(alpha: 0.4),
        ),
        radius: const Radius.circular(AppRadius.base),
      ),
    );
  }
}
