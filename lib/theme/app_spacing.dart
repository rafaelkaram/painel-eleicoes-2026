import 'package:flutter/widgets.dart';

/// Escala de espaçamento do Stitch (`designTheme.spacing`), convertida de rem
/// para pixels lógicos na base 16px.
abstract final class AppSpacing {
  static const xs = 4.0; // 0.25rem
  static const sm = 8.0; // 0.5rem
  static const md = 12.0; // 0.75rem
  static const lg = 16.0; // 1rem
  static const xl = 24.0; // 1.5rem

  /// Gutter do grid de 12 colunas. Apertado de propósito: maximiza banda
  /// visual na tela sem virar bagunça.
  static const gutter = 12.0; // 0.75rem
  static const gutterLarge = 16.0; // 1rem

  /// Margem externa do canvas de análise.
  static const margin = 16.0; // 1rem
  static const marginLarge = 24.0; // 1.5rem
}

/// Raios de canto.
///
/// Os valores vêm da escala `rounded` do design.md, mas o mapeamento por
/// componente vem do que as telas geradas realmente aplicam — que diverge da
/// prosa (ela pede 4px em cards e 2px em células). Ver theme/README.md.
abstract final class AppRadius {
  static const sm = 2.0; // 0.125rem — célula de tabela, trilho fino
  static const base = 4.0; // 0.25rem
  static const md = 6.0; // 0.375rem
  static const lg = 8.0; // 0.5rem  — card, painel, chip (padrão observado)
  static const xl = 12.0; // 0.75rem — painel grande, container do mapa

  static const smAll = BorderRadius.all(Radius.circular(sm));
  static const baseAll = BorderRadius.all(Radius.circular(base));
  static const lgAll = BorderRadius.all(Radius.circular(lg));
  static const xlAll = BorderRadius.all(Radius.circular(xl));

  /// Pílula. Reservada a dot de status, avatar e barra de progresso — não a
  /// chips, que mantêm [lg] para preservar a estética de terminal.
  static const pill = BorderRadius.all(Radius.circular(9999));
}

/// Métricas estruturais do layout de workstation desktop.
abstract final class AppMetrics {
  /// AppHeader fixo com os streams de status (AO VIVO, latência, última
  /// transmissão).
  static const headerHeight = 48.0;

  /// NavigationRail na borda esquerda.
  static const navRailCollapsed = 64.0;
  static const navRailExpanded = 220.0;

  /// Linha da tabela de votação em modo analítico denso.
  static const tableRowHeight = 36.0;

  /// Barra de progresso do card de candidato (`h-3` na tela gerada).
  /// A prosa do design.md pede 6px — vale o renderizado.
  static const candidateProgressHeight = 12.0;

  /// Barra de progresso inline, como a de urnas apuradas no header
  /// (`h-2` na tela gerada).
  static const progressBarHeight = 8.0;

  /// Colunas do canvas de análise.
  static const gridColumns = 12;
}
