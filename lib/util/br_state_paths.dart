import 'dart:convert';
import 'dart:ui';

import 'package:countries_world_map/countries_world_map.dart';

/// Contornos das unidades federativas em espaço unitário (0 a 1).
///
/// O `countries_world_map` guarda os paths como instruções `m x,y` / `l x,y`
/// / `c` com coordenadas já normalizadas. Reconstruí-los aqui permite duas
/// coisas que o pacote não entrega bem:
///
/// - **Hover preciso sem perder as bordas.** O `onHover` do pacote troca o
///   `CustomPaint` único por um `ClipPath` por UF e descarta o
///   `countryBorder`, o que funde estados da mesma cor num borrão. Com os
///   paths em mãos dá para testar `contains` sobre o ponteiro e manter o
///   desenho original.
/// - **Posição exata do marcador.** O `latLongToPixels` do pacote documenta
///   que a projeção é aproximada e desloca para baixo no hemisfério sul. O
///   centroide do próprio path não tem esse erro.
///
/// O parse roda uma vez e fica em cache — são ~145KB de instruções.
class BrStatePaths {
  BrStatePaths._({required this.paths, required this.size});

  /// Path de cada UF, indexado pelo código ISO (`BR-SP`), em espaço unitário.
  final Map<String, Path> paths;

  /// Dimensões nativas do mapa, para calcular o encaixe `BoxFit.contain`.
  final Size size;

  static BrStatePaths? _cached;

  static BrStatePaths get instance => _cached ??= _parse();

  /// Visível para teste: força um novo parse.
  static void resetCache() => _cached = null;

  static BrStatePaths _parse() {
    final json = jsonDecode(SMapBrazil.instructions) as Map<String, dynamic>;
    final paths = <String, Path>{};

    for (final entry in json['i'] as List<dynamic>) {
      final item = entry as Map<String, dynamic>;
      final path = Path();

      for (final raw in (item['i'] as List<dynamic>).cast<String>()) {
        if (raw == 'c') {
          path.close();
          continue;
        }
        final parts = raw.substring(1).split(',');
        final x = double.parse(parts[0]);
        final y = double.parse(parts[1]);
        switch (raw[0]) {
          case 'm':
            path.moveTo(x, y);
          case 'l':
            path.lineTo(x, y);
        }
      }

      paths[item['u'] as String] = path;
    }

    return BrStatePaths._(
      paths: paths,
      size: Size((json['w'] as num).toDouble(), (json['h'] as num).toDouble()),
    );
  }

  /// Retângulo que o mapa ocupa dentro de [box] sob `BoxFit.contain`.
  Rect containRect(Size box) {
    final scale = (box.width / size.width) < (box.height / size.height)
        ? box.width / size.width
        : box.height / size.height;
    final width = size.width * scale;
    final height = size.height * scale;
    return Rect.fromLTWH(
      (box.width - width) / 2,
      (box.height - height) / 2,
      width,
      height,
    );
  }

  /// UF sob o ponto [local], ou `null` fora do mapa.
  ///
  /// [local] é relativo à caixa que contém o mapa; [rect] vem de
  /// [containRect]. Só percorre as UFs de [isoCodes].
  String? hitTest(Offset local, Rect rect, Iterable<String> isoCodes) {
    if (!rect.contains(local)) return null;

    final point = Offset(
      (local.dx - rect.left) / rect.width,
      (local.dy - rect.top) / rect.height,
    );

    for (final iso in isoCodes) {
      if (paths[iso]?.contains(point) ?? false) return iso;
    }
    return null;
  }

  /// Centro do path de [isoCode] já posicionado dentro de [rect].
  Offset? centerOf(String isoCode, Rect rect) {
    final bounds = paths[isoCode]?.getBounds();
    if (bounds == null) return null;
    return Offset(
      rect.left + bounds.center.dx * rect.width,
      rect.top + bounds.center.dy * rect.height,
    );
  }
}
