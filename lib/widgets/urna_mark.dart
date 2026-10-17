import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// O sinal do painel: a urna eletrônica brasileira.
///
/// A silhueta de cunha é o que identifica o objeto — tela escura à
/// esquerda, teclado à direita, e os três botões: branco, laranja CORRIGE e
/// verde CONFIRMA. Os dois últimos são, por coincidência boa, o âmbar e o
/// verde do próprio painel. Na tela da urna vai a barra dividida da
/// apuração.
///
/// Pintado direto no canvas em vez de carregar o SVG — são formas simples, e
/// isso evita somar uma dependência de renderização de SVG ao bundle só por
/// causa de um ícone. `assets/icons/urna.svg` é a mesma forma, para favicon
/// e PWA.
class UrnaMark extends StatelessWidget {
  const UrnaMark({super.key, this.size = 28, this.withPlate = true});

  final double size;

  /// Desenha a placa escura atrás. Sobre superfície já escura, pode sair.
  final bool withPlate;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _UrnaPainter(withPlate: withPlate),
        isComplex: false,
      ),
    );
  }
}

class _UrnaPainter extends CustomPainter {
  const _UrnaPainter({required this.withPlate});

  final bool withPlate;

  /// Espaço de desenho original, o mesmo do SVG.
  static const _design = 64.0;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / _design;
    Offset p(double x, double y) => Offset(x * k, y * k);
    RRect r(double x, double y, double w, double h, double radius) =>
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x * k, y * k, w * k, h * k),
          Radius.circular(radius * k),
        );

    final corpo = Paint()..color = AppColors.onSurface;
    final tecla = Paint()..color = AppColors.outline;
    final painel = Paint()..color = AppColors.surfaceContainerHighest;
    final verde = Paint()..color = AppColors.primary;
    final ambar = Paint()..color = AppColors.secondary;
    final escuro = Paint()..color = AppColors.surfaceContainerLowest;

    if (withPlate) canvas.drawRRect(r(0, 0, 64, 64, 14), escuro);

    // Cunha: dorso alto atrás, face caindo para a frente.
    final wedge = Path()
      ..moveTo(9 * k, 20.5 * k)
      ..lineTo(48.5 * k, 12 * k)
      ..arcToPoint(p(54.5, 15.9), radius: Radius.circular(5 * k))
      ..lineTo(58.8 * k, 46.3 * k)
      ..arcToPoint(p(54.9, 51), radius: Radius.circular(4 * k))
      ..lineTo(9 * k, 51 * k)
      ..arcToPoint(p(5, 47), radius: Radius.circular(4 * k))
      ..lineTo(5 * k, 24.4 * k)
      ..arcToPoint(p(9, 20.5), radius: Radius.circular(4 * k))
      ..close();
    canvas.drawPath(wedge, corpo);

    // Tela, com a barra dividida da apuração acesa dentro.
    canvas.drawRRect(r(9, 25, 26, 21, 2.5), escuro);
    canvas.save();
    canvas.clipRRect(r(12, 38, 20, 4.5, 2.25));
    canvas.drawRect(Rect.fromLTWH(12 * k, 38 * k, 10.3 * k, 4.5 * k), verde);
    canvas.drawRect(Rect.fromLTWH(22.3 * k, 38 * k, 9.7 * k, 4.5 * k), ambar);
    canvas.restore();

    // Teclado.
    canvas.drawRRect(r(38, 24, 16, 22, 2.5), painel);
    for (final (x, y) in const [
      (40.0, 26.5),
      (47.0, 26.5),
      (40.0, 31.0),
      (47.0, 31.0),
    ]) {
      canvas.drawRRect(r(x, y, 5, 3, 1), tecla);
    }

    // Branco, CORRIGE, CONFIRMA.
    canvas.drawRRect(r(39.4, 37, 4.2, 6, 1.3), corpo);
    canvas.drawRRect(r(43.9, 37, 4.2, 6, 1.3), ambar);
    canvas.drawRRect(r(48.4, 37, 4.2, 6, 1.3), verde);
  }

  @override
  bool shouldRepaint(_UrnaPainter old) => old.withPlate != withPlate;
}
