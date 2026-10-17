import 'package:flutter/foundation.dart';

/// Metadados que acompanham toda carga do feed de apuração.
///
/// Os três campos existem por motivos diferentes e nenhum é opcional na
/// prática — são baratos de incluir agora e caros de acrescentar depois que
/// o painel já está no ar:
///
/// - [seq] descarta resposta fora de ordem. Polling através de CDN recebe
///   respostas de nós diferentes, com idades de cache diferentes; sem
///   sequência a tela anda para trás na frente de quem está assistindo.
/// - [versao] deixa o cliente recusar um formato que não entende, em vez de
///   renderizar lixo.
/// - [recarregar] é o carimbo do build dos arquivos estáticos. Mudou, o
///   código em memória ficou velho para o dado novo e a página precisa
///   recarregar inteira.
@immutable
class FeedEnvelope {
  const FeedEnvelope({
    required this.versao,
    required this.seq,
    required this.gerado,
    required this.recarregar,
  });

  /// Versão do schema da carga.
  final int versao;

  /// Sequência monotônica. Só avança.
  final int seq;

  /// Quando o servidor gerou esta carga.
  final DateTime gerado;

  /// Carimbo do build dos arquivos estáticos.
  final String recarregar;

  /// Única versão que este cliente sabe ler.
  static const supportedVersion = 1;
}

/// O que fazer com uma carga recém-chegada.
enum FeedVerdict {
  /// Aplica na tela.
  accept,

  /// Chegou atrasada; a tela já mostra algo mais novo. Descarta em silêncio.
  stale,

  /// Formato desconhecido. Não renderiza e avisa.
  unsupportedVersion,

  /// Os estáticos foram reconstruídos. Recarrega a página inteira.
  needsReload,
}

/// Decide o destino de [incoming] diante do que já está em tela.
///
/// A ordem importa: um build novo pode ter mudado o schema e zerado a
/// sequência, então recarregar vem antes de descartar por atraso.
FeedVerdict evaluateFeed(FeedEnvelope incoming, {FeedEnvelope? current}) {
  if (incoming.versao != FeedEnvelope.supportedVersion) {
    return FeedVerdict.unsupportedVersion;
  }
  if (current == null) return FeedVerdict.accept;
  if (incoming.recarregar != current.recarregar) return FeedVerdict.needsReload;
  if (incoming.seq <= current.seq) return FeedVerdict.stale;
  return FeedVerdict.accept;
}
