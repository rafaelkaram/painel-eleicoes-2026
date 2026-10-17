import 'package:flutter/material.dart';

import 'routing/app_router.dart';
import 'state/apuracao_controller.dart';
import 'state/consulta_controller.dart';
import 'routing/url_strategy.dart';
import 'theme/app_theme.dart';

void main() {
  // Tira o `#` das URLs na web; no-op nas demais plataformas.
  configureUrlStrategy();
  runApp(const PainelEleicoesApp());
}

class PainelEleicoesApp extends StatefulWidget {
  const PainelEleicoesApp({super.key});

  @override
  State<PainelEleicoesApp> createState() => _PainelEleicoesAppState();
}

class _PainelEleicoesAppState extends State<PainelEleicoesApp> {
  // Criados uma vez e presos à instância do app: recriar o GoRouter a cada
  // build descartaria o histórico de navegação.
  final _router = AppRouter.create();
  final _apuracao = ApuracaoController();
  final _consulta = ConsultaController();

  @override
  void initState() {
    super.initState();
    _apuracao.start();
    _consulta.start();
  }

  @override
  void dispose() {
    _apuracao.dispose();
    _consulta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ApuracaoScope(
      controller: _apuracao,
      child: ConsultaScope(
        controller: _consulta,
        child: MaterialApp.router(
          title: 'Painel Eleições 2026',
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          // Dark-only por natureza: ver AppTheme.
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
        ),
      ),
    );
  }
}
