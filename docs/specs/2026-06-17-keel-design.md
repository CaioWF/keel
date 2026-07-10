---
type: spec
title: Keel design
description: Design spec for keel: a spec-driven development scaffolder that installs SDD flow (agnostic core + stack packs) with active enforcement via hooks, templates, skills, and gates
---

# Keel — SDD Scaffolder · Design

**Data:** 2026-06-17
**Status:** Aprovado para planejamento

---

## 1. Entendimento

`keel` é um scaffolder de spec-driven development (SDD). Não é um projeto de
código de aplicação: é um esqueleto reutilizável que, rodado na raiz de qualquer
projeto novo, instala o fluxo SDD completo (documentos + skills + gates ativos)
para qualquer agente de IA, com foco primário em Claude Code.

Base conceitual: GitHub **spec-kit** (constitution → spec → plan → tasks →
implement), porém reconstruído do zero, sem vínculo com o pipeline atual do
usuário (`spec-driven-pipeline`, `spec-plan-format-8`). Quando `keel` estiver
pronto e validado, ele vira o padrão canônico e o pipeline antigo é
descontinuado.

Diferencial sobre spec-kit: spec-kit entrega apenas **gates passivos**
(markdown que o agente pode ignorar). `keel` adiciona uma **camada ativa** —
hooks executáveis que forçam o fluxo (bloqueiam código sem spec, rodam quality
gates antes de commit, injetam contexto de fase).

### Objetivo
Um comando (`bootstrap.sh`) que transforma um diretório vazio (ou existente) num
projeto com o fluxo SDD pronto: documentos, skills de orquestração, hooks que
forçam disciplina, e — se o projeto for Node/TS — um pack opinativo de clean
architecture.

### Critérios de sucesso
- `bootstrap.sh` instala o core em qualquer projeto (não assume Node).
- Em projeto TS detectado, oferece e instala o `ts-clean-arch` pack.
- É idempotente: re-rodar não destrói customizações; só adiciona o que falta.
- Os 4 gates ativos funcionam de fato (bloqueiam/rodam/injetam).
- O fluxo de skills cobre constitution → PRD → spec → clarify → plan → tasks →
  analyze → implement → evaluate → fix → review.
- Repo versionado no GitHub, distribuível via `degit`/clone.

---

## 2. Investigação

### spec-kit (base de referência)
Gera `.specify/` (memory/constitution.md, templates de spec/plan/tasks, scripts),
`specs/NNN-feature/` (artefatos por feature), e comandos por agente
(`.claude/commands/*.md`). Não escreve código de app; só o passo `/implement`
delega geração ao agente. Gates são markdown passivo.

### Keel de referência do usuário (16 screenshots "MBA-VIDEOMAX")
Fonte do estilo de CLAUDE.md e dos scripts de gate. Extraído:

- **CLAUDE.md** com regras imperativas (MUST / DO NOT): environment scripts
  obrigatórios; clean-arch skill obrigatória no backend; "DO NOT CREATE YOUR OWN
  LINTERS"; quality gates via `run-gates.mjs`; code style (funções 4-20 linhas,
  arquivos <400, SRP, nomes específicos, tipos explícitos, sem `any`); comments
  (WHY não WHAT, docstring com intent+exemplo, referenciar issue/SHA); frontend
  tests via `playwright-cli`; backend tests F.I.R.S.T com fakes nomeados;
  logging JSON estruturado; monorepo `apps/web` (Next 16) + `apps/backend`;
  Postgres com DB por branch; design system `docs/design/design-system-pages/`.
- **`run-gates.mjs`**: wrapper que roda tsc, eslint, depcruise,
  clean-architecture, madge, knip; trata `madge` (ciclos); summarize com exit
  code.
- **`check-architecture.ts`**: linter próprio — whitelist `domain/_shared`,
  sufixo por pasta (`*.entity.ts`/`*.vo.ts`/`*.usecase.ts`/`*-repository.ts`/
  `*.handler.ts`), kebab-case, usecase = 1 método público (SRP).
- **Árvore**: `.claude/{agents,skills{clean-arch,evaluator,fix-runner,
  implement-and-evaluate,implement-feature,prd-writer,spec-writer},
  playwright-cli}` + `apps/` + `docs/`.

### Restrições do ambiente
- Hooks de JSON são `.mjs` Node **zero-dependência** (só `node:` builtins).
  Sem `jq`, sem python, sem pacote de terceiro. Motivo: dono audita JS, não
  Python; JSON nativo mata o bug de heredoc/stdin; mesma imunidade de
  supply-chain (o risco é a árvore npm, não o runtime `node`).
- `bootstrap.sh` e `run-gates.sh` são shell fino de orquestração e delegam
  TODO parse de JSON a helpers `.mjs` zero-dep (`lib/merge-settings.mjs` e
  `core/gates/has-npm-script.mjs`). Nenhum python sobrevive no repo.
- Alvos reais são todos JS/TS; assumir `node` presente é aceitável (sempre no
  bootstrap; no run-gates só no caminho npm, onde já existe package.json).

---

## 3. Mudanças propostas

Repo novo `~/keel/` (git, destino GitHub). Estrutura:

```
keel/
├── bootstrap.sh                # scaffolder agnóstico (shell puro)
├── README.md
├── docs/specs/                 # specs do próprio keel
├── core/                       # agnóstico, sempre instalado
│   ├── claude/
│   │   ├── CLAUDE.md.tmpl
│   │   ├── settings.json.tmpl  # registra os 4 hooks
│   │   ├── skills/
│   │   │   ├── constitution-writer/
│   │   │   ├── prd-writer/
│   │   │   ├── spec-writer/
│   │   │   ├── clarify/
│   │   │   ├── plan-writer/
│   │   │   ├── tasks-writer/
│   │   │   ├── analyze/
│   │   │   ├── implement-feature/
│   │   │   ├── evaluator/
│   │   │   ├── fix-runner/
│   │   │   ├── implement-and-evaluate/
│   │   │   └── code-review/
│   │   └── hooks/
│   │       ├── _lib.mjs           # resolvers compartilhados (zero-dep)
│   │       ├── phase-gate.mjs
│   │       ├── precommit-gate.mjs
│   │       ├── phase-sensor.mjs
│   │       └── load-constitution.mjs
│   ├── specify/
│   │   ├── memory/constitution.md.tmpl
│   │   └── templates/{prd,spec,plan,tasks,checklist}-template.md
│   └── gates/
│       └── run-gates.sh        # genérico: detecta lint/test/build do projeto
└── packs/
    └── ts-clean-arch/          # node-específico
        ├── claude/skills/
        │   ├── clean-arch/
        │   │   ├── SKILL.md
        │   │   ├── scripts/{run-gates.mjs,check-architecture.ts,scaffold.mjs}
        │   │   ├── linters/  references/  templates/
        │   └── playwright-cli/
        ├── scripts/{init.sh,stop.sh,migrate-dev.sh}
        └── claude-md-fragment.md  # seções backend/gates/tests anexadas ao CLAUDE.md
```

### Projeto-alvo após `bootstrap.sh` (core + TS pack)
```
project/
├── CLAUDE.md            # + AGENTS.md -> CLAUDE.md (symlink)
├── .claude/{skills,hooks,settings.json}
├── .specify/{memory/constitution.md, templates/}
├── specs/               # artefatos SDD por feature (NNN-nome/)
├── scripts/             # (TS pack) init/stop/migrate-dev
└── docs/design/design-system-pages/  # (TS pack)
```

### Regra de linguagem
**Todo parse de JSON = `.mjs` Node zero-dep (hooks + `_lib` + helpers
`merge-settings.mjs`/`has-npm-script.mjs`). `bootstrap.sh` + `run-gates.sh` =
shell fino de orquestração que delega JSON aos helpers. Packs Node = `.mjs`/
`.ts`. Python eliminado do repo inteiro.**

---

## 4. Decisões de design

- **Núcleo agnóstico + packs.** Core (fluxo SDD, gates genéricos, skills de
  documento) não assume stack. `clean-arch` e `playwright-cli` vivem no
  `ts-clean-arch` pack, instalado só quando o bootstrap detecta TS
  (package.json + tsconfig.json). Mantém universalidade sem perder o poder
  opinativo da referência.
- **CLAUDE.md fonte + AGENTS.md symlink.** Uma fonte só; AGENTS.md aponta pra
  ela. Cobre Claude Code e agentes que leem AGENTS.md.
- **`.mjs` zero-dep nos hooks (revisado 2026-06-17).** Antes era shell+python3
  "denominador comum". Revertido: dono audita JS não Python (entender o que roda
  = propriedade de segurança), JSON nativo elimina o bug de heredoc/stdin, e
  zero-dep tem a mesma imunidade de supply-chain. Alvos reais são JS/TS.
- **Camada ativa via hooks.** O que diferencia de spec-kit. Gates passivos
  (markdown) não bastam; hooks forçam o fluxo de verdade.
- **Idempotência.** Bootstrap nunca sobrescreve arquivo existente sem flag
  `--force`; merge aditivo em `settings.json`.
- **Reconstrução limpa.** Sem importar nada do pipeline atual; ele será
  descontinuado ao fim.
- **Autossuficiência (caminho A).** O keel porta as skills de disciplina
  genérica do superpowers pra dentro do projeto, auditadas — `brainstorming`,
  `systematic-debugging`, `using-git-worktrees`, `dispatching-parallel-agents`,
  `verification-before-completion`. Meta: dropar a dependência do superpowers de
  vez (decisão de segurança: reduz superfície de cadeia de suprimentos de plugin
  de terceiros que auto-atualiza). `brainstorming` é a porta de entrada do fluxo
  e prioridade de adaptação — preserva o diálogo (1 pergunta/vez, MC, abordagens
  com recomendação, design em seções, HARD GATE pré-implementação); só troca o
  estado terminal (encadeia em `prd-writer`) e remove amarras do superpowers.

### Fluxo SDD (skill por etapa)
0. `brainstorming` → diálogo de descoberta → `specs/NNN/brainstorm.md`, seta
   `.specify/state` (porta de entrada; HARD GATE)
1. `constitution-writer` → `.specify/memory/constitution.md` (governança)
2. `prd-writer` → `specs/NNN/prd.md` (problema, hipótese, sucesso)
3. `spec-writer` → `spec.md` (spec funcional, user stories, acceptance)
4. `clarify` → resolve ambiguidades na spec antes do plan
5. `plan-writer` → `plan.md` (arquitetura, decisões técnicas)
6. `tasks-writer` → `tasks.md` (quebra acionável)
7. `analyze` → checagem de consistência spec × plan × tasks
8. `implement-feature` → código por task (usa clean-arch pack se TS)
9. `evaluator` → score contra acceptance
10. `fix-runner` → roda gates, corrige até verde
11. `implement-and-evaluate` → orquestra loop 8→9→10
12. `code-review` → gate final pré-merge

### Os 4 gates ativos
| Gate | Evento | Ação |
|------|--------|------|
| `phase-gate` | PreToolUse `Edit`/`Write` | bloqueia edição de código se a feature ativa não tem `spec.md`+`plan.md`; libera edição dos próprios docs SDD |
| `precommit-gate` | PreToolUse `Bash` (git commit) | roda `run-gates.sh` core (+ `run-gates.mjs` do TS pack); aborta commit se falhar |
| `phase-sensor` | UserPromptSubmit | lê estado de `specs/`, injeta lembrete da próxima etapa do fluxo |
| `load-constitution` | SessionStart | injeta princípios da constitution no contexto |

### CLAUDE.md gerado
- **Core (sempre):** SDD workflow + ordem das skills; code style; comments;
  structure; logging. Regras imperativas estilo referência (MUST / DO NOT).
- **TS pack (anexado):** Environment scripts; Quality Gates; Frontend Tests
  (playwright-cli); Backend Tests (F.I.R.S.T, fakes nomeados); Monorepo;
  Database (Postgres, DB por branch); Design System.

---

## 5. Pontos de decisão (resolvidos)

- Base: spec-kit (mais simples), trocável depois. ✔
- Sem vínculo com pipeline atual; antigo descontinuado ao fim. ✔
- Distribuição: bootstrap script (não CLI oficial, não template-clone puro). ✔
- Stack: núcleo agnóstico + packs. ✔
- Doc: CLAUDE.md fonte + AGENTS.md symlink. ✔
- Repo: dedicado no GitHub, `keel`. ✔
- Linguagem: hooks `.mjs` zero-dep; bootstrap+gates shell; packs mjs/ts. ✔

### Em aberto (resolver no plano)
- Mecanismo de "aprovado" que o `phase-gate` lê (frontmatter `status:` no
  spec/plan? arquivo `.specify/state`?).
- Como `phase-sensor` detecta a feature ativa (branch? arquivo de estado? dir
  mais recente em `specs/`?).
- Formato exato dos templates de PRD/spec/plan/tasks (seções).

---

## 6. Ordem de implementação

1. **Esqueleto do repo** + `README.md` + `bootstrap.sh` mínimo (cria dirs,
   copia core, symlink AGENTS.md, merge settings.json, idempotência).
2. **Templates `.specify/`** (constitution + prd/spec/plan/tasks/checklist).
3. **Skills core de documento**: constitution-writer, prd-writer, spec-writer,
   clarify, plan-writer, tasks-writer, analyze.
4. **Gate genérico** `run-gates.sh` (detecta scripts lint/test/build).
5. **Os 4 hooks** + registro em `settings.json.tmpl`.
6. **Skills de implementação**: implement-feature, evaluator, fix-runner,
   implement-and-evaluate, code-review.
7. **CLAUDE.md.tmpl** core.
8. **TS pack** `ts-clean-arch`: clean-arch (run-gates.mjs, check-architecture.ts,
   scaffold.mjs), playwright-cli, env scripts, claude-md-fragment.
9. **Detecção de stack** no bootstrap + instalação condicional do pack.
10. **Validação end-to-end** num projeto-teste vazio e num projeto TS.

---

## 7. Como validar

- Rodar `bootstrap.sh` em dir vazio → core instalado, sem erro, AGENTS.md
  symlink ok, sem TS pack.
- Rodar em projeto TS (package.json+tsconfig) → TS pack instalado.
- Re-rodar (idempotência) → nada destruído, sem duplicação em settings.json.
- `phase-gate`: tentar editar código sem spec aprovada → bloqueado; com spec
  aprovada → liberado.
- `precommit-gate`: commit com lint/test falhando → abortado.
- `phase-sensor`: prompt em projeto com spec a meio → lembrete correto.
- Fluxo completo numa feature de teste: constitution → ... → code-review,
  artefatos gerados em `specs/NNN/`.
- Gates clean-arch (TS pack): violação de sufixo/whitelist → reportada.

---

## 8. Fora de escopo

- Suporte a packs além de `ts-clean-arch` (ex: Python, Go) — futuro.
- CLI publicada em npm — por ora distribuição via clone/degit.
- Migração automática de projetos do pipeline antigo.
- Integração com outros agentes além de Claude Code (AGENTS.md cobre leitura
  básica, sem comandos por agente como spec-kit faz).
- GUI / dashboard de fase.

## Relacionado

- [[Keel Core Scaffolder]] — o plano que implementa este design
- [[Multi-client views]] — a extensão que gera views derivadas para outros clientes de IA
- [[Authoring keel skills]] — guia para escrever novas skills dentro do keel
