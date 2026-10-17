import 'package:flutter/material.dart';

/// Destinos de navegação do painel.
///
/// Fonte única de verdade: o router e o NavigationRail derivam daqui, para não
/// divergirem quando uma tela entrar ou sair. O `name` do enum é usado como
/// nome da rota.
enum AppDestination {
  apuracao(
    path: '/apuracao',
    title: 'Apuração Presidencial',
    railLabel: 'APURAÇÃO',
    icon: Icons.how_to_vote_outlined,
    selectedIcon: Icons.how_to_vote,
  ),
  governadores(
    path: '/governadores',
    title: 'Governadores em Disputa',
    railLabel: 'GOVERNOS',
    icon: Icons.map_outlined,
    selectedIcon: Icons.map,
  ),
  consulta(
    path: '/consulta',
    title: 'Consulta Local & Seção',
    railLabel: 'CONSULTA',
    icon: Icons.pin_drop_outlined,
    selectedIcon: Icons.pin_drop,
  );

  const AppDestination({
    required this.path,
    required this.title,
    required this.railLabel,
    required this.icon,
    required this.selectedIcon,
  });

  /// Caminho na URL. Vira rota nomeada com o próprio `name` do enum.
  final String path;

  /// Título exibido no header. Mesmo rótulo da tela no Stitch.
  final String title;

  /// Rótulo do NavigationRail — curto, caixa alta, em JetBrains Mono.
  final String railLabel;

  final IconData icon;
  final IconData selectedIcon;

  /// Destino inicial do painel.
  static const initial = AppDestination.apuracao;
}
