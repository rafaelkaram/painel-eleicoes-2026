# Tema — TSE Realtime Intelligence

Extraído do projeto Stitch `projects/5202510786101872337`
("Painel Eleições 2026 Flutter") via MCP, em 17/10/2026.

| Arquivo | Conteúdo |
|---|---|
| `app_colors.dart` | Tokens de cor crus (M3 completo) |
| `app_typography.dart` | Escala tipográfica + `TextTheme` |
| `app_spacing.dart` | Espaçamento, raios e métricas de layout |
| `app_theme_extensions.dart` | Papéis de telemetria e semântica eleitoral |
| `app_theme.dart` | Montagem do `ThemeData` |

Leia via `context.colors`, `context.text`, `context.stats` e
`context.election` (extensões em `app_theme_extensions.dart`) em vez de
referenciar `AppColors` direto nas telas.

## Divergências resolvidas

O `design.md` do Stitch tem duas camadas que não concordam entre si: o
*frontmatter* YAML (gerado, aplicado nas telas) e a *prosa* de marca (escrita,
parcialmente ignorada pelo gerador). Onde discordam, vale o que as telas
geradas realmente renderizam — é o artefato que existe e foi aprovado
visualmente. Verificado baixando o HTML da tela "Apuração Presidencial" e
contando as ocorrências de cada token.

**1. Paleta.** A prosa descreve uma rampa navy — canvas `#0B0F17`, card
`#131B2E`, elevado `#1A253F`, borda `#1F2C47`. Nenhum desses hexadecimais
aparece no HTML renderizado. O que a tela usa é o conjunto M3 gerado a partir
do seed `#00C853`: surface `#0F131C`, container `#1C2028`, high `#262A33`.
Adotada a segunda. Há um teste em `test/widget_test.dart` que falha se a rampa
navy reaparecer.

**2. Raios e pílulas.** A prosa pede 4px em cards, 2px em células e proíbe
pílulas. As telas usam `rounded-lg` (8px) em card e painel, `rounded-xl`
(12px) em container grande, e pílula em dot de status, avatar e barra de
progresso — nunca em chip. Adotado o renderizado; a intenção da prosa (chip
não é pílula) continua respeitada.

**3. Figuras tabulares.** A prosa exige
`font-feature-settings: "tnum" 1, "zero" 1` em todo número, para a coluna de
votos não tremer a cada update via WebSocket. O HTML do Stitch **não** emite
isso — é a única regra da prosa que vale a pena resgatar, porque é funcional e
não estética. Aplicada em todo papel monoespaçado via `kTabularFigures`.

**4. Altura da barra de progresso.** Prosa diz 6px, telas usam 8px. Adotado
8px (`AppMetrics.progressBarHeight`).

## Limites conhecidos

- `display*` do `TextTheme` não foi definido pelo Stitch; herda a métrica do
  Material com Inter aplicado.
- `title*` é derivado, não é token do design system — existe porque widgets do
  Material consomem esses slots.
- Célula numérica de tabela precisa do papel mono aplicado no widget
  (`context.text.labelLarge`); `DataTableThemeData` não chega nesse nível.
- Tema dark-only. Não existe variante clara no Stitch.
