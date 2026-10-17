# Painel Eleições 2026

Painel de acompanhamento da apuração das Eleições Gerais 2026, feito em
Flutter Web sobre os dados públicos do TSE.

> **Projeto pessoal, não oficial.** Não tem vínculo com o Tribunal Superior
> Eleitoral. Os números vêm do portal público de resultados do TSE, mas a
> fonte de verdade é sempre
> [resultados.tse.jus.br](https://resultados.tse.jus.br).

## O que tem

- **Apuração presidencial** — totalização nacional, composição dos votos,
  cards dos dois mais votados, barra comparativa, mapa coroplético das 27
  unidades federativas e votação no exterior (Zona ZZ).
- **Governadores** — as 27 disputas estaduais, mapa com o rosto de cada
  governador e, no 2º turno, o resumo de quem já venceu separado de quem
  ainda disputa.
- **Localizador de urna** — cascata UF → município → zona → seção, com o
  resultado do município e o carimbo de transmissão da urna.
- Alternância entre 1º e 2º turno em qualquer tela.

## De onde vêm os dados

Tudo sai do portal público do TSE. Não existe API com push: são arquivos
estáticos atrás de CDN, e acompanhar em tempo real é consultar de novo no
intervalo que o próprio `cache-control` da resposta indica.

| Dado | Caminho |
|---|---|
| Catálogo de eleições | `comum/config/ele-c.json` |
| Resultado por abrangência | `ele2026/{eleicao}/dados/{uf}/{uf}-c{cargo}-e{eleicao}-u.jws` |
| Resultado por município | `.../{uf}{municipio}-c{cargo}-e{eleicao}-u.jws` |
| Municípios e zonas | `ele2026/{eleicao}/config/mun-e{eleicao}-cm.json` |
| Seções e transmissão | `ele2026/arquivo-urna/3220/config/{uf}/{uf}-p003220-cs.json` |
| Foto do candidato | `ele2026/{eleicao}/fotos/{abrangencia}/{sqcand}.jpeg` |

Os arquivos `.jws` são assinados pelo TSE em EdDSA. O painel **extrai o
payload mas não verifica a assinatura** — conferir exigiria a chave pública
e uma biblioteca de criptografia. O carimbo na tela diz "arquivo assinado",
nunca "assinatura conferida".

O boletim de urna com os votos de cada seção não entra aqui: fica no
arquivo de urna do TSE em formato próprio, não como JSON.

## Rodando

```sh
flutter pub get
flutter run -d chrome
```

Ative os hooks uma vez por clone:

```sh
git config core.hooksPath .githooks
```

## Verificação

```sh
dart format --set-exit-if-changed --output=none lib test
flutter analyze
flutter test
```

A mesma sequência roda no `pre-commit` e na CI. O deploy publica no GitHub
Pages a cada push na `main`.

## Decisões que valem saber

- **Design system** extraído do Stitch e documentado em
  `lib/theme/README.md`, incluindo as divergências entre a prosa do
  design e o que as telas realmente renderizam.
- **Cores partidárias** em `lib/theme/party_colors.dart` são aproximações
  ajustadas para fundo escuro, não valores oficiais de marca. Quando duas
  legendas são da mesma família cromática — azul contra azul é comum no
  Brasil — a segunda é clareada para a barra não virar um bloco só.
- **Situação da disputa** é derivada: enquanto o que falta apurar for maior
  que a diferença, o resultado ainda pode virar. Quando o TSE declara a
  situação, a palavra dele vence a derivação.
- **Retratos sintéticos** em `assets/images/` são dos candidatos fictícios
  do design original e não retratam pessoas reais. Os rostos reais vêm do
  TSE em tempo de execução.
