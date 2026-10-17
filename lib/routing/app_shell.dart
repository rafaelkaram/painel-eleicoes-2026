import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme_extensions.dart';
import '../widgets/app_header.dart';
import 'app_destination.dart';

/// Casca persistente do painel: header fixo + NavigationRail na borda
/// esquerda, com o conteúdo da branch ativa à direita.
///
/// Usa `StatefulShellRoute.indexedStack`, então cada tela mantém seu estado ao
/// trocar de aba. Isso importa: as telas são alimentadas por stream do TSE e
/// recriar a árvore a cada troca jogaria fora o buffer de apuração.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _select(int index) {
    navigationShell.goBranch(
      index,
      // Tocar na aba já ativa volta para a raiz daquela branch.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PainelAppBar(),
      body: Row(
        children: [
          _PainelNavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onSelected: _select,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _PainelNavigationRail extends StatelessWidget {
  const _PainelNavigationRail({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      // O design.md pede uma barra vertical de 2px na borda esquerda como
      // indicador. O NavigationRail do Material só oferece o indicador em
      // pílula atrás do ícone — é o que está aplicado (primary a 8%, via
      // AppTheme). Trocar exigiria um rail próprio.
      destinations: [
        for (final destination in AppDestination.values)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: Text(destination.railLabel),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          ),
      ],
    );
  }
}

/// Tela de rota desconhecida.
class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PainelAppBar(title: 'Rota desconhecida'),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.md,
          children: [
            Icon(Icons.error_outline, color: context.election.alert, size: 32),
            Text(location, style: context.text.labelLarge),
            FilledButton(
              onPressed: () => context.go(AppDestination.initial.path),
              child: const Text('VOLTAR PARA A APURAÇÃO'),
            ),
          ],
        ),
      ),
    );
  }
}
