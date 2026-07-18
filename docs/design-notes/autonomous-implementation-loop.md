---
type: design-note
title: Autonomous implementation loop
description: Why keel's autonomous implementation mode is a thin opt-in envelope over implement-and-evaluate, not a new loop — the loop-engineering 2026 framing, the three gaps it closes, and why the driver is in-session
---

# Design note: loop autônomo de implementação

**Loop engineering** (termo de Boris Cherny, jun/2026) é a disciplina de parar de
promptar turn-by-turn e desenhar o *runtime que dirige o agente*: um **loop
contract** (definition-of-done checável por exit code), uma **state layer** fora
da context window (sobrevive à compaction), um **checker** que o agente não pode
pular, e **stop conditions**. Os quatro tipos de loop do campo — heartbeat (intervalo
curto), cron (agendado), hook (evento) e **goal** (itera até sucesso, então para) —
mapeiam um problema cada. Loop autônomo de implementação = **goal loop**.

O achado desta nota: keel **já tem o goal loop**. `implement-and-evaluate` é o corpo
— só nunca foi nomeado assim. O que falta para virar autônomo de verdade é um
**envelope opt-in** fino, não um loop novo.

## keel já é um goal loop (o mapa)

| Componente loop-engineering | Peça keel existente |
|---|---|
| **Loop contract** (done checável por exit code) | checkboxes de `tasks.md` + `Critérios de Aceitação` do `spec.md` + `run-gates.sh` (exit 0) |
| **Checker** (contexto fresco, sem checker-theater) | `evaluator` + `task-reviewer` = **subagents frescos** — o agente não revisa a si mesmo por construção |
| **State layer** (sobrevive compaction) | ledger `.git/sdd/<feature>/progress.md` — nunca re-faz task marcada done |
| **Bounded retry + escalação** | `implement-and-evaluate` step 3: mesma cena falha 3× sem progresso → para e reporta blocker |
| **Approval ≠ autonomy budget** | No-Commit Rule (`subagent-driven-development`): gate humano fica no commit, não em cada task |

A máquina de economia (Model Selection, snapshot por tree, brief por task) já está
ligada via os modos de execução — ver [Execution mode routing](execution-mode-routing.md).

## Os três gaps que o envelope fecha

O que separa "loop que um humano invoca e acompanha" de "loop autônomo":

1. **Driver.** Hoje um humano invoca `implement-and-evaluate` em-sessão e acompanha.
   Falta o runtime que *dirige até o fim* sem check-in. A regra
   **continuous-execution** de `subagent-driven-development` (não pausar entre tasks)
   já é metade disso; o envelope completa fixando o contrato e o teto.
2. **Budget global.** keel tem 3-strikes-por-cena, mas nenhum teto global de
   iterações. Sem ele, os anti-patterns *runaway iteration* e *cost blowup* ficam
   abertos. O envelope adiciona `KEEL_LOOP_MAX_ITERATIONS` (default 10) → estourou,
   para e escala.
3. **Contrato de autonomia explícito.** O que o loop pode fazer sozinho vs. o que
   exige checkpoint humano. Sem isso, *auto-approval sem gate* vira risco. O
   envelope lista os poderes (editar em-escopo, testar, rodar gates, despachar
   subagents, snapshots) e os checkpoints obrigatórios (commit, comando destrutivo,
   plan-errado, exaustão de budget/stall).

## A decisão: envelope opt-in, driver in-session

O modo autônomo é uma **skill separada** (`implement-autonomously`) que **invoca**
`implement-and-evaluate` por dentro — mesma relação pai→filho que
`implement-and-evaluate` tem com `implement-feature`. Razões:

- **Opt-in, discoverável.** É "a opção" de rodar autônomo, não o default. A cadeia
  canônica (`analyze → implement-and-evaluate → review-and-simplify`) fica intacta;
  o modo autônomo é a variante `analyze → implement-autonomously → review-and-simplify`.
- **Fonte única.** `implement-and-evaluate` continua o corpo reutilizável; o envelope
  só soma os três gaps. Nada de duplicar o loop.

**Driver = in-session continuous** (estilo `/goal` do Claude Code: roda até o
contrato fechar, sob teto de iterações). Escolhido sobre as alternativas por ser o
mais simples e zero-infra:

- **`/loop` + `ScheduleWakeup`** (self-paced local) — sobrevive a mais de uma context
  window por se re-agendar. Fica como evolução para features que estouram um contexto.
- **Routines/cron** (cloud, laptop fechado) — bom para backlog-as-queue (issue-driven),
  mas exige `ANTHROPIC_API_KEY` + setup cloud. Fica como evolução futura.

Coerente com o trade-off já assumido em [Execution mode routing](execution-mode-routing.md):
enforcement por **prompt**, não por tool estático. O budget e o stall-guard são
disciplina de prompt + contador no ledger, não um gate `.mjs` — mantém a fonte única
nas skills.

## Anti-patterns de loop-engineering cobertos

| Anti-pattern | Como keel + envelope cobre |
|---|---|
| Contrato interminável ("melhore o código") | done = exit codes concretos (`tasks.md` + ACs + gates) |
| Checker theater (agente revisa a si mesmo) | evaluator/reviewer são subagents **frescos** |
| Auto-approval sem gate | contrato de autonomia + No-Commit + checkpoint destrutivo |
| State no transcript ("na 1ª compaction esquece") | ledger `.git/sdd/<feature>/progress.md` externo |
| Retry sem diagnóstico | fix-runner carrega erro+contrato; exaustão grava `loop-report.md` |
| Runaway / cost blowup | `KEEL_LOOP_MAX_ITERATIONS` + stall-guard (3 iterações sem progresso) |

## Fora de escopo (fila, sem blocker)

- **Drivers cloud/self-paced** (Routines/cron, `ScheduleWakeup`) — anotados acima como
  evolução; esta iteração é só in-session.
- **Enforcement determinístico do budget/stall via gate `.mjs`** — mantido prompt-level;
  um `check-loop-progress.mjs` (compara contagem de checkbox vs. ledger) fica candidato
  futuro se o prompt-level falhar na prática.
- **Wiring na cadeia canônica** (`CLAUDE.md.tmpl`) — o modo é opt-in; a menção da
  variante na cadeia é follow-up separado.
- **Guard de comando destrutivo** — o checkpoint depende dele; hoje é convenção de
  prompt até o guard mecânico (hook PreToolUse) existir.

## Relacionado

- [Execution mode routing](execution-mode-routing.md) — inline vs. dispatch vs.
  dispatch-parallel; a fonte do model routing e dos snapshots que o loop reusa.
- [Gate vs skill](gates-vs-skills.md) — por que o enforcement determinístico vive em
  gates e o julgamento vive nas skills; base do "por que não hard-enforce o budget".
