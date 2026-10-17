# Rotas

Navegação declarativa com `go_router`, seguindo a skill oficial
`flutter-setup-declarative-routing` do plugin `dart-flutter`.

## Tabela de rotas

| Caminho | Nome | Tela | Rail |
|---|---|---|---|
| `/apuracao` | `apuracao` | `ApuracaoPresidencialScreen` | APURAÇÃO |
| `/governadores` | `governadores` | `GovernadoresScreen` | GOVERNOS |
| `/consulta` | `consulta` | `ConsultaLocalScreen` | CONSULTA |
| `/dev/theme` | `devTheme` | `ThemePreviewPage` | — (só em debug) |

`/` redireciona para `/apuracao`. Qualquer outro caminho cai em
`RouteNotFoundScreen`.

`AppDestination` é a fonte única: router e NavigationRail derivam dele, então
acrescentar uma tela é acrescentar um valor no enum e um caso no
`AppRouter._screenFor` — o switch é exaustivo, o compilador cobra.

## Por que `StatefulShellRoute.indexedStack`

O header e o rail ficam montados uma vez só, e cada branch preserva seu
estado ao trocar de aba. Isso não é cosmético: as telas vão ser alimentadas
por stream do TSE, e remontar a árvore a cada troca jogaria fora o buffer de
apuração acumulado.

## Navegação programática

```dart
context.go(AppDestination.governadores.path);
context.goNamed(AppDestination.consulta.name);
```

## Pontos de atenção

- **Deploy web.** A path URL strategy está ligada (`/governadores`, sem `#`).
  O servidor precisa reescrever caminho desconhecido para `index.html`, senão
  um F5 numa rota interna devolve 404. `flutter run -d chrome` já resolve
  sozinho; Nginx, Hostinger ou S3 precisam da regra explícita.
- **Deep link nativo.** A skill cobre `AndroidManifest.xml`, `Info.plist`,
  `assetlinks.json` e `apple-app-site-association`. Nada disso foi feito: os
  alvos são web e macOS, onde não se aplica. Se Android ou iOS entrarem, essa
  etapa volta.
- **Indicador do rail.** O design.md pede uma barra vertical de 2px na borda
  esquerda. O `NavigationRail` do Material só oferece o indicador em pílula
  atrás do ícone, que é o que está aplicado. Trocar exige um rail próprio.
