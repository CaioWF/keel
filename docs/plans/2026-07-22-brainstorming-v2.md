---
type: plan
title: Brainstorming v2
description: Plan for upgrading the brainstorming skill into a real divergence→convergence ideation phase — binary depth dial, opt-in framed divergence via dispatch, a mandatory doubt-driven-development adversarial gate, and a durable brainstorm-template for capturing the reasoning trail
---

# Plano: brainstorming v2

> **Implementado em 2026-07-22** (escopo B). Levantado a partir de (a) a descontinuação do
> formato `spec-plan-format-8` (skill pessoal global, removida — ver §1) e (b) research
> competitivo dos players SDD atuais: GitHub Spec Kit, OpenSpec, BMAD, GSD, genkovich/sdd e o
> repo `uditakhourii/adhd`. Entregue: `brainstorm-template.md`, dial `padrão`/`deep` + divergência
> framed via dispatch, gate adversarial `doubt-driven-development`, wiring no `CLAUDE.md.tmpl`.
> Fora do escopo B (§8) segue como evolução futura.

## 1. Entendimento

O `brainstorming` é o ponto de entrada da cadeia SDD do keel (`brainstorming → prd-writer →
spec-writer → clarify → plan-writer → …`). Hoje ele define um **processo** bom (HARD-GATE
contra implementar cedo, perguntas uma-a-uma, propor 2-3 abordagens, handoff pro `prd-writer`)
mas tem três fraquezas:

1. **`brainstorm.md` é o único artefato da cadeia sem template.** A saída é "seções escaladas à
   complexidade" — livre. A trilha de raciocínio (o que foi investigado, quais trade-offs, o que
   ficou em aberto) evapora; só o design final sobrevive, e de forma inconsistente entre sessões.
2. **A divergência é fake.** "Propor 2-3 abordagens" acontece inline, single-agent, anchored — a
   segunda e terceira opção nascem contaminadas pela primeira. Não é divergência real.
3. **O stress-test é fraco.** O "spec self-review" (scan de placeholder/contradição) é uma
   checagem cosmética, não adversarial. Nada força o design a sobreviver a um ataque antes do
   handoff.

Contexto da remoção do plan-8: o `spec-plan-format-8` era uma skill pessoal global que impunha um
doc monolítico de 8 seções sobre `brainstorming`/`plan-writer`. Colidia com os templates
per-artefato do keel (spec/plan) e vazava pra dentro da cadeia. Foi removido. Os conceitos bons
dele (capturar Entendimento, Investigação e Pontos-de-decisão de forma durável) não têm dono na
cadeia atual — esta feature os reabsorve, no lugar certo (o brainstorm, upstream), sem
re-monolitizar.

## 2. Investigação

**Research competitivo (etapa de ideação de cada player):**

- **Spec Kit** — sem brainstorming dedicado; `clarify` é quality-gate de ambiguidade. Front-load =
  princípios na `constitution`.
- **OpenSpec** — entrada = `proposal` (a mudança proposta). "Actions, não phases travadas".
- **BMAD** — Analyst → Product Brief + **Advanced Elicitation**: pós-geração, IA sugere 5 métodos
  de raciocínio, user escolhe, aplica, loop accept/discard. Biblioteca grande de lentes
  (pre-mortem, inversion, red/blue-team, tree-of-thought, first-principles, five-whys).
- **GSD** — "specs são prompts"; multi-agente, contexto fresco por agente. Front-end leve.
- **genkovich/sdd** (primo filosófico do keel: skills atômicas socráticas + TDD) — skill
  `interview` = pass socrático antes da spec (fura premissas, nomeia trade-offs). **Depth dial**
  easy/medium/hard; hard dispara 3 análises via subagentes.
- **adhd** (`uditakhourii/adhd`) — loop de 2 fases com separação dura: **Diverge** = N Agent calls
  isolados em paralelo, cada um sob uma "cognitive frame", system prompt proíbe avaliação,
  branches não se veem (zero anchoring); **Focus** = critic separado que dá score
  (novelty/viability/fit), flag de traps, cluster por ângulo, aprofunda top-K.

**Padrões que todos têm e o keel não:** divergência antes de convergência · elicitation como
biblioteca nomeada · pass adversarial · depth dial que escala o *processo* · captura durável do
raciocínio.

**Primitivos que o keel JÁ tem** (a feature monta, não importa framework):

- `core/claude/skills/dispatching-parallel-agents/` + worktree isolation + model routing
  (`routing-minimum-capable-model`) → a fase "diverge" do adhd = keel despachando N idea-agents
  framed em haiku.
- `core/claude/skills/doubt-driven-development/SKILL.md` (3.6K, já existe) → o pass adversarial.
- `core/specify/templates/` é copiado inteiro por `bootstrap.sh:61` (`copy_tree core/specify →
  .specify`) → um novo template auto-ships, sem manifest.
- `core/claude/CLAUDE.md.tmpl` já descreve a cadeia (referência a atualizar).

## 3. Mudanças propostas

**Criar `core/specify/templates/brainstorm-template.md`** — o template durável que faltava. Cinco
seções fit-to-feature (não as 8 forçadas do plan-8 morto):

- **Entendimento** — request reformulado + premissas.
- **Investigação** — arquivos/docs lidos, padrões e constraints achados (alimenta e reusa
  `docs/codebase-map.md`).
- **Abordagens consideradas** — as 2-3 opções + a escolhida + o porquê (a trilha de trade-off; no
  modo `deep`, a saída do critic).
- **Decisões em aberto** — pontos a resolver, com handoff explícito pro `clarify` (ou "Nenhuma").
- **Esboço da solução** — o design aprovado, escalado à complexidade, **sem código**.

Frontmatter `status: draft` + `feature`/`date`, espelhando `spec-template.md`.

**Editar `core/claude/skills/brainstorming/SKILL.md`** — quatro mudanças:

- **Depth dial binário** no início do processo: `padrão` (fluxo conversacional atual, respeita
  off-signals — features pequenas) vs. `deep` (opt-in, destrava a divergência por dispatch).
  Anunciado explicitamente; default = `padrão`.
- **Modo `deep` = divergência framed via dispatch.** Quando o design tem forks reais e o user
  opta por `deep`: despacha N idea-agents isolados (via `dispatching-parallel-agents`, modelo
  barato), cada um sob uma cognitive frame, proibidos de avaliar, sem cross-anchoring; depois um
  pass critic (score novelty/viability/fit, flag traps, cluster) destila em 2-3 abordagens reais
  que entram na seção "Abordagens consideradas". Um conjunto pequeno e fixo de frames vive na
  própria skill (não os 15 do adhd — enxuto).
- **Substituir o "Spec Self-Review" pelo gate adversarial.** O passo 6 do checklist passa a
  invocar `doubt-driven-development` como stress-test obrigatório antes do handoff. O scan de
  placeholder/consistência vira sub-item dele, não o todo.
- **Passo "Write design doc" usa o template.** Passo 5 copia
  `.specify/templates/brainstorm-template.md` para `specs/<feature>/brainstorm.md` e preenche, em
  vez de escrever livre.

**Editar `core/claude/CLAUDE.md.tmpl`** — uma frase descrevendo o dial e o gate adversarial do
brainstorming (paralelo ao que já descreve `implement-and-evaluate`/`implement-autonomously`).

**Doc-consistency** — atualizar a linha do brainstorming no fluxo, se houver, em
`docs/design-notes/` que descreva a cadeia.

## 4. Decisões de design

- **Dial binário, não 3 níveis.** genkovich usa easy/medium/hard; o keel já tem "off-signals
  dispensam o fluxo" cobrindo o "easy". Dois estados (`padrão`/`deep`) bastam e evitam ceremônia.
- **Divergência por dispatch é opt-in raro (modo `deep`), não default.** Divergência framed é
  poderosa mas cara (N subagentes). A maioria das features não tem forks de design que a
  justifiquem. Espelha o adhd (que é opt-in "me dá umas formas de…") e o ethos lean do keel.
- **Reusar `doubt-driven-development`, não criar skill nova.** O pass adversarial já existe; a
  feature só o *insere* no ponto certo do brainstorming.
- **Template de 5 seções fit-to-feature, não 8 forçadas.** Captura os 3 conceitos órfãos do plan-8
  (Entendimento/Investigação/Decisões-em-aberto) sem replicar o que spec/plan já cobrem downstream
  (Mudanças/Ordem/Validar/Escopo).
- **Elicitation menu fica fora (era o escopo A).** Biblioteca de lentes nomeadas (pre-mortem,
  inversion, red-team) é valiosa mas ortogonal ao núcleo; entra depois se provar necessária.

## 5. Decisões em aberto

- **Quais cognitive frames embutir** no modo `deep`? Proposta: um punhado genérico e reusável
  (ex: `usuário-cético`, `manutenção-6-meses-depois`, `pior-caso-de-carga`, `primeiro-princípio`,
  `caminho-mais-simples`) em vez das frames codebase-específicas do adhd. Fechar na
  implementação.
- **N de idea-agents no `deep`** — fixo (ex: 4) ou escalado pelo número de forks? Proposta: 3-4
  fixo, barato e suficiente.
- **O gate adversarial bloqueia o handoff** (como o phase-gate) ou é forte-mas-prompt-level? Como
  o brainstorming roda antes de existir spec/plan aprovados, não há hook mecânico natural aqui —
  proposta: prompt-level obrigatório (igual ao resto do processo do brainstorming).

## 6. Ordem de implementação

1. `brainstorm-template.md` (novo) — isolado, sem dependência. TDD: teste de conformance que o
   template existe e carrega no bootstrap.
2. Editar `brainstorming/SKILL.md` — dial + template-write + gate adversarial (as 3 mudanças que
   não dependem do dispatch).
3. Modo `deep` (divergência por dispatch) — depende de 2; encaixa as frames + o pass critic.
4. `CLAUDE.md.tmpl` + doc-consistency.
5. Rodar a suíte + audit + bootstrap-e2e.

Passos 1-2 são paralelizáveis de 3-4 se escopos forem disjuntos (template vs. skill-prose).

## 7. Como validar

- **Test-fragment** novo em `tests/` (convenção: fragmento sourced, sem boilerplate/exit — ver
  `tests/lib.sh`), asserts: template existe; brainstorming SKILL referencia o template, o dial e
  `doubt-driven-development`; bootstrap ships o template em `.specify/templates/`.
- **audit-structure gate** verde (skills com frontmatter, sem link relativo quebrado).
- **bootstrap-e2e** — bootstrap num sandbox e confirmar `.specify/templates/brainstorm-template.md`
  presente e `CLAUDE.md` renderizado com a descrição do dial.
- Suíte inteira verde (hoje 601+).

## 8. Fora de escopo

- **Elicitation menu** (biblioteca de lentes nomeadas invocáveis) — evolução futura (escopo A).
- **Depth dial de 3 níveis** — decidido binário.
- **Frames codebase-específicas** estilo adhd/`wtfismyrepo` (que exigem varrer o repo) — as frames
  do `deep` são genéricas.
- **Gate mecânico (hook)** pro pass adversarial — prompt-level por ora.
- **Drivers cloud/self-paced** — não se aplica ao brainstorming.
