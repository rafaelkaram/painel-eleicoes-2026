import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:painel_eleicoes_2026/routing/app_destination.dart';
import 'package:painel_eleicoes_2026/routing/app_router.dart';
import 'package:painel_eleicoes_2026/routing/app_shell.dart';
import 'package:painel_eleicoes_2026/screens/apuracao_presidencial_screen.dart';
import 'package:painel_eleicoes_2026/screens/consulta_local_screen.dart';
import 'package:painel_eleicoes_2026/screens/governadores_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:painel_eleicoes_2026/data/tse_client.dart';
import 'package:painel_eleicoes_2026/state/apuracao_controller.dart';
import 'package:painel_eleicoes_2026/state/consulta_controller.dart';
import 'package:painel_eleicoes_2026/theme/app_theme.dart';
import 'package:painel_eleicoes_2026/widgets/app_header.dart';

import 'helpers.dart';

/// O badge AO VIVO pulsa sem parar, então `pumpAndSettle` nunca assenta e
/// estoura o timeout. Dois pumps dão conta de qualquer transição de rota.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// Cliente que nunca responde nada útil: o teste de rota não exercita a
/// consulta, só precisa que o escopo exista.
final _vazio = MockClient((_) async => http.Response('{}', 404));

void main() {
  usarImagensFalsas();

  late GoRouter router;

  setUp(() => router = AppRouter.create());

  Future<void> pumpApp(WidgetTester tester) async {
    // Workstation desktop: o rail e o header não cabem na janela padrão
    // de teste (800x600).
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = fakeApuracao();
    addTearDown(controller.dispose);
    await controller.load();

    final consulta = ConsultaController(client: TseClient(httpClient: _vazio));
    addTearDown(consulta.dispose);

    await tester.pumpWidget(
      ApuracaoScope(
        controller: controller,
        child: ConsultaScope(
          controller: consulta,
          child: MaterialApp.router(routerConfig: router, theme: AppTheme.dark),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('abre na apuração presidencial', (tester) async {
    await pumpApp(tester);

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(ApuracaoPresidencialScreen), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppDestination.apuracao.path,
    );
  });

  testWidgets('a raiz redireciona para o destino inicial', (tester) async {
    await pumpApp(tester);

    router.go('/');
    await settle(tester);

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppDestination.initial.path,
    );
    expect(find.byType(ApuracaoPresidencialScreen), findsOneWidget);
  });

  testWidgets('cada destino tem sua rota e sua tela', (tester) async {
    await pumpApp(tester);

    const tituloNoCorpo = {
      AppDestination.apuracao: 'Eleição Presidencial 2026 / 1º Turno',
      AppDestination.governadores:
          'Eleições Estaduais — 1º Turno para Governador',
      AppDestination.consulta: 'Localizador de Urna & Resultado',
    };
    final telaPorDestino = {
      AppDestination.apuracao: ApuracaoPresidencialScreen,
      AppDestination.governadores: GovernadoresScreen,
      AppDestination.consulta: ConsultaLocalScreen,
    };

    for (final entry in telaPorDestino.entries) {
      router.go(entry.key.path);
      await settle(tester);

      expect(
        find.byType(entry.value),
        findsOneWidget,
        reason: '${entry.key.path} deveria renderizar ${entry.value}',
      );
      // O corpo carrega o próprio título; na apuração ele é o nome do
      // pleito, não o rótulo do destino.
      expect(find.text(tituloNoCorpo[entry.key]!), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(PainelAppBar.marca),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('navegar pelo rail troca a branch sem remontar a casca', (
    tester,
  ) async {
    await pumpApp(tester);
    final shellInicial = tester.widget<AppShell>(find.byType(AppShell));

    await tester.tap(find.text(AppDestination.consulta.railLabel));
    await settle(tester);

    expect(find.byType(ConsultaLocalScreen), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppDestination.consulta.path,
    );
    // Mesma casca, outra branch: o indexedStack preserva as telas.
    expect(
      tester.widget<AppShell>(find.byType(AppShell)).runtimeType,
      shellInicial.runtimeType,
    );
  });

  testWidgets('rota desconhecida cai na tela de erro', (tester) async {
    await pumpApp(tester);

    router.go('/zona-eleitoral-inexistente');
    await settle(tester);

    expect(find.byType(RouteNotFoundScreen), findsOneWidget);
    expect(find.text('/zona-eleitoral-inexistente'), findsOneWidget);

    await tester.tap(find.text('VOLTAR PARA A APURAÇÃO'));
    await settle(tester);

    expect(find.byType(ApuracaoPresidencialScreen), findsOneWidget);
  });
}
