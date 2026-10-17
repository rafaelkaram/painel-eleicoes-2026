import 'package:flutter/widgets.dart';

/// Quem é o candidato — a parte do dado que não muda durante a apuração.
///
/// Fica separada da totalização de propósito. No feed, a carga que se repete
/// a cada minuto traz só `{"13": 58940120}`: votos indexados pelo número na
/// urna. Nome, partido, coligação e foto vêm uma vez e ficam em cache. Era o
/// que mais pesava se viesse junto a cada atualização.
@immutable
class CandidateIdentity {
  const CandidateIdentity({
    required this.name,
    this.number,
    this.party,
    this.coalition,
    this.portrait,
  });

  /// Número na urna — é por ele que o feed indexa os votos.
  ///
  /// Nulo enquanto o cadastro não trouxer. Melhor ausente que inventado:
  /// número errado na tela de uma apuração é erro factual.
  final int? number;

  /// Nome de urna.
  final String name;

  /// Sigla do partido, quando a tela mostra partido.
  final String? party;

  /// Coligação, quando a tela mostra coligação.
  final String? coalition;

  /// Foto de urna. No feed oficial vem por id do candidato no TSE.
  final ImageProvider? portrait;
}
