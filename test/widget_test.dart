import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:painel_eleicoes_2026/theme/app_colors.dart';
import 'package:painel_eleicoes_2026/theme/app_theme.dart';
import 'package:painel_eleicoes_2026/theme/app_theme_extensions.dart';
import 'package:painel_eleicoes_2026/theme/app_typography.dart';

void main() {
  group('AppTheme.dark', () {
    test('usa a paleta canônica do Stitch, não a paleta navy da prosa', () {
      final scheme = AppTheme.dark.colorScheme;
      expect(scheme.surface, const Color(0xFF0F131C));
      expect(scheme.surfaceContainer, const Color(0xFF1C2028));
      expect(scheme.primary, const Color(0xFF3FE56C));
      expect(scheme.brightness, Brightness.dark);
      // A rampa navy descartada não pode reaparecer por engano.
      expect(scheme.surface, isNot(const Color(0xFF0B0F17)));
      expect(scheme.surfaceContainer, isNot(const Color(0xFF131B2E)));
    });

    test('todo papel monoespaçado trava figuras tabulares', () {
      final mono = <TextStyle>[
        AppTypography.labelLarge,
        AppTypography.labelMedium,
        AppTypography.labelSmall,
        AppTypography.statDisplay,
        AppTypography.statMetric,
      ];
      for (final style in mono) {
        expect(style.fontFamily, AppFonts.mono, reason: 'família errada');
        expect(
          style.fontFeatures,
          contains(const FontFeature.tabularFigures()),
          reason: 'sem tnum a coluna de votos treme a cada update',
        );
        expect(style.fontFeatures, contains(const FontFeature.slashedZero()));
      }
    });

    test('texto em linguagem natural usa Inter', () {
      expect(AppTypography.headlineLarge.fontFamily, AppFonts.body);
      expect(AppTypography.bodyMedium.fontFamily, AppFonts.body);
    });

    test('registra as extensões de telemetria e semântica eleitoral', () {
      final theme = AppTheme.dark;
      expect(theme.extension<AppStatStyles>(), isNotNull);
      expect(theme.extension<AppElectionTokens>(), isNotNull);
      expect(theme.extension<AppElectionTokens>()!.leader, AppColors.primary);
    });
  });

  testWidgets('o tema chega na árvore de widgets', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(captured.colors.surface, AppColors.surface);
    expect(captured.stats.statDisplay.fontSize, 28);
    expect(captured.election.contested, AppColors.secondary);
  });
}
