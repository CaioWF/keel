---
type: plan
title: Architecture styles
description: Plan for adding hexagonal, onion and layered as selectable architecture-style guides alongside Clean Architecture, with the style choice recorded per project instead of hardcoded in the template
---

# Plano: estilos de arquitetura selecionáveis

> Plano de feature **futuro** — nada implementado. Levantado em 2026-07-15 a partir da avaliação
> do mgr-method (github.com/maurigre/mgr-method), que trata o estilo de arquitetura como escolha
> de instalação (`--arch hexagonal|clean|onion|layered`).

## 1. Entendimento

O keel hoje assume **um** estilo de arquitetura: Clean Architecture. O guia
`clean-architecture.md` é o único companheiro de estilo, e suas 4 camadas
(`domain`/`application`/`infrastructure`/`interface`) estão fixas na tabela do
`architecture-template.md`. Projetos que usam Hexagonal (Ports & Adapters), Onion ou Layered
não têm guia, e o template os obriga a descrever a estrutura no vocabulário de outro estilo.

O pedido é ter esses estilos disponíveis. Assumo que **não** é para copiar o modelo do
mgr-method (estilo escolhido por flag no instalador): pela receita do
[Concept layer](../design-notes/concepts-layer.md), estilo de arquitetura é um **conceito** —
entra como companheiro da skill `architecture`, não como skill nova nem como flag de bootstrap.
A escolha por projeto pertence à constituição + a um ADR, que é onde as decisões duráveis já
moram. Confirmar em §5.

## 2. Investigação

- `core/claude/skills/architecture/SKILL.md` — skill umbrella; indexa 5 companheiros
  (`clean-architecture`, `solid`, `testing-strategy`, `ddd-tactical`, `minimalism`) e define o
  passo-a-passo de aplicação na cadeia SDD. O passo 2 manda aplicar a dependency rule "ver
  `clean-architecture.md`" — acoplado ao estilo.
- `core/claude/skills/architecture/clean-architecture.md` — os 4 anéis, a dependency rule, sinais
  de violação, e a nota de que enforcement mecânico é por pack de linguagem. É o molde de formato
  que os guias novos devem seguir.
- `docs/design-notes/concepts-layer.md` — **a receita**: um conceito preenche até 4 slots (guia
  obrigatório; regra de constituição, nota de estrutura e pack de enforcement opcionais), e a
  tabela "Conjunto curado atual" lista o que existe. Justifica skill umbrella + companheiros em
  vez de N skills soltas (uma entrada na cadeia SDD; só `SKILL.md` exige frontmatter no gate).
- `core/specify/memory/constitution.md.tmpl` — `## Princípios de arquitetura` traz a
  **dependency rule** como não-negociável ("dependências apontam para dentro"), mais domínio puro,
  fronteira de agregado, teste de comportamento, mínimo viável.
- `core/specify/templates/architecture-template.md` — tabela de camadas hardcoded em Clean, com
  a direção de dependência e uma seção "Realização nesta linguagem/stack".
- `tests/test-architecture.sh` — asserta a existência de cada companheiro, que a SKILL.md indexa
  cada um, que a constituição tem a dependency rule, e que o template nomeia `domain`.
- `core/gates/audit-structure.mjs:52` — só `SKILL.md` exige frontmatter; companheiros ao lado não
  são skills. Confirma que guias novos não custam nada ao gate.
- `docs/design-notes/gates-vs-skills.md` (via concepts-layer) — estilo é julgamento → lado skill;
  enforcement mecânico → pack por linguagem.

## 3. Mudanças propostas

**Criar** — `core/claude/skills/architecture/hexagonal.md`
Guia Ports & Adapters (Cockburn): aplicação no centro, portas primárias (driving) vs secundárias
(driven), adapters de cada lado, simetria de I/O. Mesmo formato do `clean-architecture.md`
(camadas → regra central → mapeia para estrutura → red flags → enforcement). Deixa explícita a
relação com Clean: mesma dependency rule, vocabulário e granularidade diferentes.

**Criar** — `core/claude/skills/architecture/onion.md`
Guia Onion (Palermo): anéis concêntricos, domain model no centro, domain services, application
services, infra na casca externa. Mesma dependency rule; difere de Clean por explicitar os anéis
de serviço de domínio.

**Criar** — `core/claude/skills/architecture/layered.md`
Guia Layered (Fowler). **Descritivo, não recomendado por padrão** — ver a decisão em §4: o layered
clássico viola a dependency rule da constituição. O guia deve dizer isso na primeira linha, servir
para *ler* e evoluir código legado em camadas, e apontar a rota de migração para Clean/Onion
(inverter a dependência da camada de dados via porta).

**Modificar** — `core/claude/skills/architecture/SKILL.md`
Nova seção "Estilo de arquitetura": os estilos são **alternativas**, escolhe-se um por projeto (ou
por bounded context), e o escolhido fica registrado na constituição. O passo 2 do "Como aplicar"
deixa de citar `clean-architecture.md` fixo e passa a citar o guia do estilo ativo. Índice de
companheiros ganha os 3 novos, agrupados como estilos vs conceitos transversais (SOLID, testes,
DDD, minimalismo valem em qualquer estilo).

**Modificar** — `core/specify/templates/architecture-template.md`
A tabela de camadas deixa de ser fixa em Clean: ganha um campo "Estilo" no topo, e a tabela vira
preenchível a partir do guia do estilo ativo, com o exemplo Clean como default preenchido. A
seção "Realização nesta linguagem/stack" não muda.

**Modificar** — `core/specify/memory/constitution.md.tmpl`
`## Princípios de arquitetura` ganha uma linha declarando o estilo ativo do projeto
(`**Estilo:** Clean | Hexagonal | Onion | Layered (legado)`). A dependency rule permanece como
está para os três primeiros; ver §5 sobre o caso Layered.

**Modificar** — `docs/design-notes/concepts-layer.md`
Tabela "Conjunto curado atual" ganha as 3 linhas novas. Nota de que estilos são um sub-grupo
mutuamente exclusivo dentro do container — a receita não previa alternativas, só adições.

**Modificar** — `tests/test-architecture.sh`
Asserts: cada guia novo existe e é indexado pela SKILL.md; cada guia de estilo nomeia sua regra
central; `layered.md` carrega o aviso de que não é o default; constituição tem o campo de estilo;
template tem o campo de estilo.

## 4. Decisões de design

- **Companheiros, não skills.** O pedido veio como "skills de arquitetura" e o mgr-method as
  trata como skills separadas (`arch-hexagonal`, `arch-clean`, `arch-onion`, `arch-layered`).
  A receita do `concepts-layer.md` já decidiu o contrário para o keel: umbrella + companheiros =
  uma entrada na cadeia SDD e um só `SKILL.md` a auditar. Quatro skills de estilo dariam quatro
  entradas concorrentes na cadeia para uma escolha que é única por projeto.
- **Estilo na constituição, não no `bootstrap.sh`.** O mgr-method pergunta no install
  (`--arch hexagonal`). No keel a constituição já é a fonte per-projeto e é injetada no
  SessionStart; `constitution-writer` já a preenche. Uma flag de bootstrap criaria uma segunda
  fonte de verdade para a mesma decisão, e o bootstrap é re-executável (`--force`) enquanto a
  escolha de estilo não deve mudar em silêncio a cada update.
- **Layered entra como descritivo, não como opção de igual peso.** Clean, Hexagonal e Onion são
  variações de vocabulário sobre a **mesma** dependency rule. O layered clássico (UI → negócio →
  dados) aponta a dependência para **fora**, na direção do banco — exatamente o que a constituição
  proíbe hoje. Trade-off descartado: tornar a dependency rule condicional ao estilo. Isso
  enfraqueceria o não-negociável mais importante do keel para acomodar justamente o estilo que
  menos queremos que seja escolhido. Layered fica como guia de leitura de legado + rota de migração.
- **Escrever os 3 guias de uma vez, mesmo com bloat.** Um projeto usa um estilo só. O custo é ~2KB
  de markdown por guia, carregados sob demanda (companheiros não entram no contexto sozinhos — a
  SKILL.md os referencia). O ganho é a simetria: sem os três, "estilo é uma escolha" é afirmação
  sem alternativa de verdade por trás.

## 5. Pontos de decisão

- **Layered: entra descritivo ou fica fora?** Recomendo entrar como descritivo (§4). A alternativa
  é não escrever `layered.md` — o keel simplesmente não fala de layered, e projetos legados usam o
  guia de Clean como alvo. Mais enxuto, mas deixa sem resposta "meu projeto é em camadas, e agora?".
  Confirma o descritivo?
- **Escolha por projeto ou por bounded context?** Recomendo por projeto (uma linha na
  constituição) — é o caso comum e mantém a constituição enxuta. Por contexto exigiria o estilo no
  `architecture-template.md` de cada feature, com risco de deriva. Confirma?
- **`constitution-writer` pergunta o estilo?** Recomendo que sim: a skill já entrevista para
  preencher a constituição, e o estilo é exatamente o tipo de decisão que ela captura. Implica
  editar mais uma skill além das listadas em §3. Confirma?
- **A escolha de estilo vira ADR?** Recomendo sim, via `adr-writer` — é hard-to-reverse e tem
  consequências além da feature, que é o critério que a própria skill define. A constituição diz
  *qual* é o estilo; o ADR diz *por quê*. Confirma?

## 6. Ordem de implementação

1. `hexagonal.md` e `onion.md` — **paralelos** entre si (arquivos novos, independentes, mesmo
   molde do `clean-architecture.md`).
2. `layered.md` — **depende** da decisão de §5 sobre o enquadramento descritivo.
3. `SKILL.md` — a seção de estilo e o reindexe; **depende** de 1 e 2 (precisa dos nomes finais).
4. `architecture-template.md` + `constitution.md.tmpl` — o campo de estilo; **paralelos** entre si,
   dependem de 3 estar definido.
5. `constitution-writer` — a pergunta de estilo, se §5 confirmar; depende de 4.
6. `concepts-layer.md` — tabela + nota do sub-grupo; depende de tudo acima estar estável.
7. `tests/test-architecture.sh` — asserts; por último, refletindo o que de fato entrou.
8. `okf-build-index.mjs build docs` — os guias não são conceitos OKF (companheiros não têm
   `type:`), mas este plano e o design-note editado são; rodar para não quebrar o gate de
   freshness no commit.

## 7. Como validar

- `bash tests/run.sh` verde, incluindo os asserts novos do `test-architecture.sh`.
- Bootstrap num sandbox (`mktemp -d` + `bootstrap.sh --dir "$S"`) e `run-gates.sh` verde lá —
  pega link quebrado em guia novo. Cuidado conhecido: `audit-structure` trata qualquer `](` como
  link real, então exemplos de sintaxe de link precisam de placeholder (`XXXX`/`NNNN`) ou de ser
  escritos quebrados.
- Comportamento observável: numa sessão com a constituição declarando `Estilo: Hexagonal`, pedir um
  plano de feature e verificar que `plan-writer` preenche o `architecture-template.md` com o
  vocabulário de portas/adapters, não com as 4 camadas de Clean.
- Contra-teste do Layered: com `Estilo: Layered (legado)`, confirmar que o agente sinaliza a tensão
  com a dependency rule em vez de aceitá-la em silêncio.

## 8. Fora de escopo

- **Flag `--arch` no `bootstrap.sh`** — decidido contra em §4.
- **Packs de enforcement por linguagem** (`ts-hexagonal`, ArchUnit, import-linter). O guia é
  advisory; pack é outro plano, e `ts-clean-arch` já está deferido desde o plano do concept layer.
- **Migração automática de estilo** (reescrever um projeto layered para clean). O guia descreve a
  rota; ninguém a executa.
- **Estilos além dos 4** (event-driven, vertical slice, modular monolith, microservices). Só entram
  com demanda real — a tabela do `concepts-layer.md` cresce uma linha por vez.
- **Mudar a dependency rule da constituição.** Explicitamente preservada; ver §4.
- **`junit-clean` e demais skills do mgr-method** — território de pack por linguagem, avaliadas e
  descartadas na mesma sessão.

## Relacionado

- [Concept layer](../design-notes/concepts-layer.md) — a receita que este plano segue
- [Gate vs skill](../design-notes/gates-vs-skills.md) — por que estilo é skill e enforcement é pack
- [Agnostic concept layer](2026-06-22-agnostic-concept-layer.md) — o plano que criou o container
