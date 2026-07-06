# Design note: roteamento de modo de execução (inline vs. dispatch)

O keel tem **dois modos** de executar o loop de implementação de uma feature — mas até
esta nota nada decidia qual usar, e o default caiu silenciosamente no modo mais caro.

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
| ≥3 tasks independentes | **dispatch** | delega a `subagent-driven-development` — snapshot + brief + implementer subagent + Model Selection |

Racional: dispatch tem overhead real (snapshot de árvore, brief-file, round-trip, re-integração).
Compensa quando há paralelismo/volume que polui contexto; não compensa em feature curta ou
acoplada, onde o inline é mais barato em wall-clock e contexto.

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
