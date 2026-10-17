import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';

/// Um degrau da cascata do localizador.
class SelectorStep<T> {
  const SelectorStep({
    required this.step,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.loading = false,
    this.emptyHint,
  });

  final int step;
  final String label;
  final T? value;

  /// Valor interno para rótulo exibido, na ordem em que aparece.
  final Map<T, String> options;

  final ValueChanged<T> onChanged;

  /// Mostra um indicador no lugar do campo enquanto o cadastro não veio.
  final bool loading;

  /// Texto quando não há nada para escolher.
  final String? emptyHint;
}

/// Os seletores em cascata do localizador de urna.
class SectionSelector extends StatelessWidget {
  const SectionSelector({super.key, required this.steps});

  final List<SelectorStep<String>> steps;

  /// Abaixo disso os seletores empilham em duas colunas.
  static const _rowBreakpoint = 900.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < _rowBreakpoint ? 2 : 4;
        final gaps = AppSpacing.md * (columns - 1);
        final width = (constraints.maxWidth - gaps) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final step in steps)
              SizedBox(
                width: width,
                child: _Field(step: step),
              ),
          ],
        );
      },
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.step});

  final SelectorStep<String> step;

  @override
  Widget build(BuildContext context) {
    final vazio = step.options.isEmpty || step.value == null;
    final unico = step.options.length <= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${step.step}. ${step.label.toUpperCase()}',
          style: context.text.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHigh,
            borderRadius: AppRadius.lgAll,
          ),
          child: step.loading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.sm,
                  children: [
                    SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.election.leader,
                      ),
                    ),
                    Text(
                      'carregando…',
                      style: context.text.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : vazio
              ? Text(
                  step.emptyHint ?? 'sem opções',
                  style: context.text.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: step.value,
                    isExpanded: true,
                    isDense: true,
                    borderRadius: AppRadius.lgAll,
                    dropdownColor: context.colors.surfaceContainerHigh,
                    menuMaxHeight: 420,
                    icon: Icon(
                      Icons.expand_more,
                      size: 18,
                      color: context.colors.onSurfaceVariant,
                    ),
                    style: context.text.bodyMedium?.copyWith(
                      color: context.colors.onSurface,
                    ),
                    // Uma opção só não é escolha: desabilita em vez de
                    // fingir que há alternativa.
                    onChanged: unico
                        ? null
                        : (v) => v == null ? null : step.onChanged(v),
                    items: [
                      for (final entry in step.options.entries)
                        DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
