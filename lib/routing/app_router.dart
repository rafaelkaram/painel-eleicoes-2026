import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../dev/theme_preview.dart';
import '../screens/apuracao_presidencial_screen.dart';
import '../screens/consulta_local_screen.dart';
import '../screens/governadores_screen.dart';
import 'app_destination.dart';
import 'app_shell.dart';

/// Rotas do painel.
///
/// Declarativo com `go_router`: as três telas são branches de um
/// `StatefulShellRoute.indexedStack`, então o header e o NavigationRail ficam
/// montados uma vez só e cada tela preserva seu estado ao trocar de aba.
///
/// URLs usam a estratégia de hash (`/#/apuracao`), que é o padrão do Flutter
/// Web. Caminho limpo exigiria `flutter_web_plugins` com import condicional
/// mais rewrite no servidor — não compensa num painel interno.
abstract final class AppRouter {
  /// Rota de conferência do tema. Só existe em debug.
  static const devThemePath = '/dev/theme';

  static GoRouter create() {
    return GoRouter(
      initialLocation: AppDestination.initial.path,
      debugLogDiagnostics: kDebugMode,
      redirect: (context, state) {
        // Raiz cai no destino inicial em vez de dar 404.
        return state.uri.path == '/' ? AppDestination.initial.path : null;
      },
      errorBuilder: (context, state) {
        return RouteNotFoundScreen(location: state.uri.toString());
      },
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AppShell(navigationShell: navigationShell);
          },
          branches: [
            for (final destination in AppDestination.values)
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: destination.path,
                    name: destination.name,
                    builder: (context, state) => _screenFor(destination),
                  ),
                ],
              ),
          ],
        ),
        if (kDebugMode)
          GoRoute(
            path: devThemePath,
            name: 'devTheme',
            builder: (context, state) => const ThemePreviewPage(),
          ),
      ],
    );
  }

  static Widget _screenFor(AppDestination destination) {
    return switch (destination) {
      AppDestination.apuracao => const ApuracaoPresidencialScreen(),
      AppDestination.governadores => const GovernadoresScreen(),
      AppDestination.consulta => const ConsultaLocalScreen(),
    };
  }
}
