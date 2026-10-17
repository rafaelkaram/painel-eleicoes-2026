import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';

/// Avatar de candidato.
///
/// Com [portrait], mostra a foto. Sem ela, cai nas iniciais sobre um fundo
/// tingido com a cor do partido — o lugar da foto fica ocupado e legível em
/// vez de virar um buraco cinza.
class CandidateAvatar extends StatelessWidget {
  const CandidateAvatar({
    super.key,
    required this.name,
    required this.color,
    this.portrait,
    this.size = 28,
  });

  final String name;

  /// Cor do partido, usada no fundo e nas iniciais.
  final Color color;

  /// Foto de urna, quando houver.
  final ImageProvider? portrait;

  final double size;

  /// Partículas que não entram nas iniciais.
  static const _connectives = {'de', 'da', 'do', 'dos', 'das', 'e'};

  /// `Tarcísio Gomes` vira `TG`; `ACM Neto` vira `AN`; `Lula` vira `LU`.
  static String initialsOf(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .where((part) => !_connectives.contains(part.toLowerCase()))
        .toList();

    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final only = parts.first;
      return (only.length == 1 ? only : only.substring(0, 2)).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        image: portrait == null
            ? null
            : DecorationImage(image: portrait!, fit: BoxFit.cover),
      ),
      child: portrait != null
          ? null
          : Text(
              initialsOf(name),
              style: context.text.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

/// Espaço entre o avatar e o nome, para o card manter o ritmo do design.
const avatarGap = AppSpacing.sm;
