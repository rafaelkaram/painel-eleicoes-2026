import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';

/// Aviso de que os números em tela são fictícios.
///
/// Num painel eleitoral isso não é detalhe: número plausível sem rótulo vira
/// print e circula como se fosse apuração. Sai junto com a entrada do feed.
class DemoDataBanner extends StatelessWidget {
  const DemoDataBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final accent = context.election.contested;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: accent),
          Text(
            'DADOS DE EXEMPLO — NÃO É RESULTADO OFICIAL',
            style: context.text.labelSmall?.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}
