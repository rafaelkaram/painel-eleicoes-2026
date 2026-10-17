import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:painel_eleicoes_2026/models/demo_tallies.dart';
import 'package:painel_eleicoes_2026/util/br_state_paths.dart';

void main() {
  final geo = BrStatePaths.instance;

  test('extrai as 27 unidades federativas', () {
    expect(geo.paths, hasLength(27));
    for (final state in DemoTallies.states) {
      expect(
        geo.paths.containsKey(state.isoCode),
        isTrue,
        reason: '${state.isoCode} não está no mapa',
      );
    }
  });

  test('o cache devolve a mesma instância', () {
    expect(identical(BrStatePaths.instance, geo), isTrue);
  });

  group('containRect', () {
    test('centraliza horizontalmente quando a caixa é larga demais', () {
      final rect = geo.containRect(const Size(1000, 400));
      final escala = 400 / geo.size.height;

      expect(rect.height, closeTo(400, 0.001));
      expect(rect.width, closeTo(geo.size.width * escala, 0.001));
      expect(rect.left, closeTo((1000 - rect.width) / 2, 0.001));
      expect(rect.top, closeTo(0, 0.001));
    });

    test('centraliza verticalmente quando a caixa é alta demais', () {
      final rect = geo.containRect(const Size(300, 900));
      final escala = 300 / geo.size.width;

      expect(rect.width, closeTo(300, 0.001));
      expect(rect.height, closeTo(geo.size.height * escala, 0.001));
      expect(rect.top, closeTo((900 - rect.height) / 2, 0.001));
    });
  });

  group('hitTest', () {
    final rect = geo.containRect(const Size(800, 600));
    final isos = DemoTallies.states.map((s) => s.isoCode);

    test('fora do retângulo não acerta nada', () {
      expect(geo.hitTest(Offset(rect.left - 5, rect.top), rect, isos), isNull);
      expect(geo.hitTest(const Offset(-10, -10), rect, isos), isNull);
    });

    test('o canto superior esquerdo do enquadramento é oceano', () {
      // O bounding box do mapa começa a noroeste do território, fora do país.
      expect(geo.hitTest(rect.topLeft, rect, isos), isNull);
    });

    test('o centro do enquadramento cai em território brasileiro', () {
      final acerto = geo.hitTest(rect.center, rect, isos);
      expect(acerto, isNotNull);
      expect(acerto, startsWith('BR-'));
    });
  });

  group('centerOf', () {
    test('o centro do DF fica dentro do enquadramento', () {
      final rect = geo.containRect(const Size(800, 600));
      final centro = geo.centerOf('BR-DF', rect);

      expect(centro, isNotNull);
      expect(rect.contains(centro!), isTrue);
    });

    test('UF inexistente devolve null', () {
      final rect = geo.containRect(const Size(800, 600));
      expect(geo.centerOf('BR-XX', rect), isNull);
    });
  });
}
