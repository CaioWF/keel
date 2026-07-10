---
type: design-note
title: Execution mode routing
description: Why implement-and-evaluate picks inline vs dispatch vs dispatch-parallel execution modes based on task count and coupling, with parallelization via scope declaration and worktree isolation
---

# Design note: roteamento de modo de execução (inline vs. dispatch)

O keel tem **três modos** de executar o loop de implementação de uma feature (`inline`,
`dispatch`, `dispatch-parallel`) — mas até esta nota nada decidia qual usar, e o default caiu
silenciosamente no modo mais caro. O terceiro modo (`dispatch-parallel`) foi somado depois;
sua seção própria está mais abaixo.

## O problema

A cadeia canônica (`CLAUDE.md.tmpl`) roda `implement-and-evaluate` como loop de execução.
Ele invocava `implement-feature`, `evaluator` e `fix-runner` **inline** (via Skill tool) —
tudo no modelo da sessão. Nenhum split em subagents, nenhum model routing.

Ao mesmo tempo, `subagent-driven-development` carrega uma seção **Model Selection** completa
(least-powerful-model por role, model explícito por dispatch, cheap para transcrição, top para
o whole-branch review) + snapshot de árvore + brief por task. A máquina de economia existia,
documentada e detalhada — **desconectada** da cadeia. Só era citada por `review-and-simplify`
e `security-review` como fonte do mecanismo de snapshot, nunca invocada pelo loop.

Consequência: task mecânica de 1 arquivo, avaliação e gate-fix pagavam o preço do modelo da
sessão (ex.: Opus), contrariando o próprio doc do projeto.

## A decisão: modo por forma da feature

`implement-and-evaluate` escolhe o modo **uma vez**, antes do loop, lendo `tasks.md` (contagem
e independência de tasks) + `plan.md` (acoplamento):

| Sinal | Modo | Como roda cada task |
|---|---|---|
| ≤2 tasks, **ou** tightly-coupled (mesmo estado/arquivos) | **inline** | `implement-feature` como Skill, modelo da sessão; `fix-runner` inline |
| ≥3 tasks independentes, scopes sobrepostos ou não declarados | **dispatch** | delega a `subagent-driven-development` — snapshot + brief + implementer subagent, um por vez + Model Selection |
| ≥3 tasks independentes com `[scope: …]` declarado e **disjunto par-a-par** | **dispatch-parallel** | mesmo skill em modo batch — tasks disjuntas rodam concorrentes, cada uma em worktree próprio (`isolation: "worktree"`), merge-back por batch |

Racional: dispatch tem overhead real (snapshot de árvore, brief-file, round-trip, re-integração);
o variante paralelo soma setup de worktree + merge-back por batch. Compensa quando há
paralelismo/volume que polui contexto; não compensa em feature curta ou acoplada, onde o inline
é mais barato em wall-clock e contexto.

## O terceiro modo: dispatch-parallel (partição + worktree)

`dispatch` sempre rodou implementers **um por vez** — a hard rule *"never dispatch multiple
implementation subagents in parallel (they conflict)"* existia porque todos dividiam **um único
worktree**: dois implementers editando concorrente = clobber. O bloqueio era o worktree
compartilhado, não o paralelismo em si.

`dispatch-parallel` remove o bloqueio combinando duas coisas — nenhuma sozinha basta:

1. **Partição por file-scope.** Cada task declara `[scope: glob]` no `tasks.md` (o `tasks-writer`
   deriva do `Estrutura de Arquivos` do plan). `validate-parallel-scope.mjs partition` agrupa em
   batches onde os scopes são **disjuntos par-a-par** — nenhum par de tasks no mesmo batch pode
   tocar o mesmo arquivo. Scope ausente ou amplo (`**`) cai em batch de um → roda sozinho. É
   whitelist, não blacklist: só paraleliza o que é **provadamente** disjunto; a dúvida serializa.
2. **Isolamento por worktree.** Cada implementer concorrente roda com `isolation: "worktree"` —
   checkout próprio, build/test próprios. Mesmo que a declaração de scope estivesse errada, os
   writes ficam contidos no worktree até o merge-back; o `check` do `validate-parallel-scope`
   verifica post-hoc que o implementer não escreveu fora do scope antes de integrar.

Merge-back é conflict-free **por construção**: scopes disjuntos ⟹ os diffs de cada worktree tocam
arquivos distintos ⟹ aplicar em qualquer ordem não colide. O modelo de review por tree-snapshot
sobrevive: um `BATCH_BASE` antes do batch, um `BATCH_HEAD` depois do merge-back, e cada task é
revisada na sua fatia (`git diff BATCH_BASE BATCH_HEAD -- <scope>`).

Por que os dois juntos e não um só: partição sozinha (mesmo worktree) protege os *arquivos-fonte*
se a declaração estiver certa, mas build/test concorrentes no mesmo diretório ainda colidem
(portas, DB, coverage) — e uma declaração errada clobra de verdade. Worktree sozinho (sem
partição) isola tudo, mas o merge-back vira reconciliação de conflitos e quebra o review por
snapshot único. A combinação fecha os dois furos: partição decide **o que** é seguro paralelizar,
worktree garante o isolamento de **runtime**, e a interseção vazia torna a integração trivial.

## Os pontos de inserção (onde a decisão foi plugada)

1. **Declaração dos dois modos** — bloco `## Mode Selection` no topo de
   `implement-and-evaluate/SKILL.md`, antes do loop. É o pai da decisão.
2. **Sinal de decisão** — a regra da tabela acima, codificada nesse bloco (fonte: `tasks.md` +
   `plan.md`).
3. **Ligar o track órfão** — step 2a de `implement-and-evaluate` passa a bifurcar: inline invoca
   `implement-feature`; dispatch delega a `subagent-driven-development` (que já tem todo o
   maquinário).
4. **Model routing no modo inline** — `implement-feature` e `fix-runner` ganham nota: quando
   despachados como subagent (via `dispatching-parallel-agents`), dimensionar o modelo à
   dificuldade real da task, não herdar o da sessão. Fonte da regra já existe em
   `dispatching-parallel-agents` (cost-aware routing) + skill `routing-minimum-capable-model`.

## Ambiguidade corrigida junto

`CLAUDE.md.tmpl` listava `... implement-feature → implement-and-evaluate → ...` como **etapas
irmãs sequenciais**. Mas `implement-and-evaluate` **invoca** `implement-feature` por dentro no
modo inline — rodar as duas em sequência executaria `implement-feature` duas vezes. A cadeia foi
corrigida: `implement-feature` é **filho** de `implement-and-evaluate` (modo inline), não etapa
irmã. A cadeia canônica agora vai direto de `analyze → implement-and-evaluate`.

## Por que não hard-enforce (por que não subagents estáticos)

O routing fica no julgamento do controller (`implement-and-evaluate`), não travado em
`.claude/agents/*.md` estáticos. O bootstrap só propaga `skills/` e `hooks/` — não há tree
`agents/`. Manter a decisão nas skills preserva a fonte única (uso standalone continua) e evita
duplicar lógica num wrapper de agent. Trade-off aceito: enforcement por prompt, não por tool.

## Relacionado

- [[Keel Core Scaffolder]] — o plano que implementa este roteamento de modos de execução
