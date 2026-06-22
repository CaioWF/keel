---
status: draft
feature: multi-client-views
date: 2026-06-22
---

# Plano — Milestone 2: geração de views multi-cliente

## 1. Entendimento

O harness hoje instala um único cliente: Claude Code (CLAUDE.md + `.claude/skills` +
`.mjs` hooks + gates). Milestone 2 adiciona a capacidade de **gerar views derivadas** do
mesmo conteúdo canônico para outros agentes de IA — Codex, Cursor, Copilot, Gemini CLI e
Windsurf — sem que nenhum deles vire dependência de runtime (continua Path A: views são
**saída**, não dependência).

Inspiração e padrão: `github.com/igoruehara/spec-driven` (`bin/adapters.mjs` + `bin/cli.mjs`),
todo zero-dep `.mjs` — alinhado à nossa regra de linguagem.

Restrição central já conhecida: **a espinha de enforcement do harness é específica do Claude
Code**. Os hooks `.mjs` (phase-gate default-deny, precommit-gate, injeção de constituição/STATE
no SessionStart) e o gate runner só rodam no Claude Code. Nenhum outro cliente tem PreToolUse
equivalente. Logo, as views não-Claude são **advisory**: levam as instruções e as skills (como
commands/rules), mas não o enforcement mecânico.

## 2. Investigação

Fonte canônica no harness:
- `core/claude/CLAUDE.md.tmpl` — instruções (sem frontmatter; começa em `# PROJECT`).
- `core/claude/skills/<name>/SKILL.md` — cada skill, com frontmatter `name`/`description`.
- Várias skills têm **arquivos companheiros** (`subagent-driven-development/implementer-prompt.md`,
  `task-reviewer-prompt.md`, `test-driven-development/testing-anti-patterns.md`).

Mapa de cada cliente (instruções · skills) — herdado do adapters.mjs de referência:

| Cliente | Instruções | Skills/commands | Layout |
|---|---|---|---|
| Claude (canônico) | `CLAUDE.md` | `.claude/skills/<n>/SKILL.md` | verbatim |
| Codex | `AGENTS.md` | `.agents/skills/<n>/SKILL.md` | skill-dir |
| Cursor | `.cursor/rules/sdd.mdc` | `.cursor/commands/<n>.md` | flat |
| Copilot | `.github/copilot-instructions.md` | `.github/prompts/<n>.prompt.md` | flat |
| Gemini | `GEMINI.md` | `.gemini/commands/<n>.toml` | flat |
| Windsurf | `.windsurf/rules/sdd.md` | `.windsurf/workflows/<n>.md` | flat |

Estado atual relevante:
- `bootstrap.sh` cria `AGENTS.md` como **symlink → CLAUDE.md** incondicionalmente. Quando Codex
  for selecionado, sua view de instruções também é `AGENTS.md` → precisa reconciliar (ver §5).
- Os gates `audit-structure.mjs` e `validate-mermaid.mjs` varrem o projeto inteiro e hoje só
  ignoram `node_modules`/`.git`/`.specify`. Views geradas (`.cursor/`, `.gemini/`, etc.) seriam
  varridas e dariam **falso-positivo** (frontmatter ausente, links reapontados, toml). Precisam
  entrar na IGNORE list — são artefatos derivados, não a fonte.

## 3. Mudanças propostas

**(1) `lib/adapters.mjs`** (novo, zero-dep) — registry + transforms, adaptado da referência:
- `stripFrontmatter(text)`, `parseSkill(text) → {name, description, body}`.
- transforms: `skillAsIs` (md cru, p/ cursor/copilot/windsurf), `skillAsToml` (gemini: escapa
  aspas/barras, `description` + `prompt = """..."""`).
- `ADAPTERS` registry com os 5 clientes extras (+ claude canônico).
- `emitInstructions(adapter, claudeMd)` — strip frontmatter conforme o adapter, reaponta
  `.claude/skills` → dir do cliente, e **prepende o banner advisory** (ver §4).
- `emitFor(adapter, claudeMd, skills)` — devolve `[{rel, content}]`:
  - layout `skill-dir` (Codex): copia **todos** os arquivos da pasta da skill (SKILL.md +
    companheiros) verbatim.
  - layout `flat`: emite só o corpo do `SKILL.md` transformado + **nota-ponteiro** ("prompts
    companheiros: ver fonte Claude `.claude/skills/<n>/`"). Companheiros não viram commands.

**(2) `lib/emit-views.mjs`** (novo, zero-dep) — orquestrador:
- args `--dir <target> --agents a,b,c`.
- lê a fonte **já instalada no target**: `CLAUDE.md` + `.claude/skills/<n>/` (incl. companheiros).
- para cada agente extra, `emitFor(...)` e escreve as emissões no target.
- escreve o manifesto `.specify/clients.json` = `{ version, agents:[...] }`.

**(3) `bootstrap.sh`** — flag `--agent=a,b,c` (csv) e `--all`:
- sem flag → comportamento atual (só Claude), **backward-compat preservado**.
- com flag → após o install core, chama `node "$SELF/lib/emit-views.mjs" --dir "$TARGET" --agents ...`.
- reconciliação do `AGENTS.md` (ver §5).

**(4) `core/gates/audit-structure.mjs` + `validate-mermaid.mjs`** — adicionar à IGNORE/derivados:
`.agents`, `.cursor`, `.gemini`, `.windsurf` (dirs) e, por arquivo gerado, `AGENTS.md`,
`GEMINI.md`, `.github/copilot-instructions.md`, `.github/prompts/`. (Espelha o audit da referência.)

**(5) Testes** — `tests/test-adapters.sh` (transforms + emitFor), `tests/test-emit-views.sh`
(emissão por cliente + manifesto), extensão do e2e (`--agent=all` instala as 5 views, gates
ainda passam, manifesto presente), regressão de IGNORE (view sem frontmatter não falha o audit),
backward-compat (sem flag = só Claude, nenhum dir de view criado).

## 4. Decisões de design

- **Padrão adapter registry** (porte da referência): cada cliente é dado declarativo
  (`{instructions, skills}`); adicionar cliente = uma entrada, sem código novo de emissão.
- **Banner advisory** no topo de toda instrução não-Claude:
  > Esta é uma view gerada a partir da fonte canônica do Claude Code. O SDD aqui é **advisory**:
  > a aplicação mecânica (gates, phase-gate, precommit) só roda no Claude Code. Não edite à mão —
  > regenere pela fonte.
- **skill-dir copia tudo; flat dropa companheiros + ponteiro** (decisão do usuário): fidelidade
  honesta sem poluir a lista de commands dos clientes flat.
- **Default Claude-only** (opt-in via `--agent`): não muda a experiência de quem só usa Claude.
- **Views são derivadas → entram na IGNORE dos gates**: o gate audita a fonte, não o artefato.
- **Manifesto `.specify/clients.json`**: registra os clientes gerados (audita-ignore + futura
  regeneração).
- **Fonte = target instalado** (não o `core/` do harness): emit-views lê o `CLAUDE.md`/`.claude`
  já copiado, então edições do projeto fluem para as views e o comando funciona em re-run.

## 5. Pontos de decisão

- **`AGENTS.md`: symlink vs view real.** Recomendado: se Codex selecionado ⇒ emit-views escreve
  `AGENTS.md` real (frontmatter strip = no-op no nosso caso, refs → `.agents/skills`) substituindo
  o symlink; se Codex **não** selecionado ⇒ mantém o symlink atual `AGENTS.md → CLAUDE.md`.
- **Regeneração.** Sem comando `update` dedicado neste milestone; re-rodar `bootstrap.sh --force
  --agent=...` regenera. (Um `sync` dedicado fica p/ depois.)
- **Parágrafos Claude-only nas views** (seção Quality Gates / paths de hooks no CLAUDE.md): manter
  no texto e cobrir pelo banner, em vez de remover por cliente. Menos código, honesto o bastante.

## 6. Ordem de implementação

1. `lib/adapters.mjs` (registry + transforms + emitFor com regra de companheiros) + `test-adapters.sh`.
2. `lib/emit-views.mjs` (lê target, emite, escreve manifesto) + `test-emit-views.sh`.
3. `bootstrap.sh`: flag `--agent/--all` + dispatch + reconciliação do `AGENTS.md`.
4. IGNORE de derivados em `audit-structure.mjs` + `validate-mermaid.mjs` + regressões.
5. e2e: `--agent=all` (5 views + manifesto + gates-passam) e backward-compat (sem flag = só Claude).
6. Nota no `CLAUDE.md.tmpl` (existência das views/advisory) + atualização do ledger.

## 7. Como validar

- Suite verde (alvo: 182 atuais + novos asserts, 0 falhas).
- e2e `--agent=all`: cada arquivo de instrução dos 5 clientes existe; cada skill virou command no
  formato certo (toml válido p/ gemini, skill-dir com companheiros p/ codex, ponteiro nos flat);
  `.specify/clients.json` lista os 5; `run-gates.sh` no projeto gerado sai 0 (derivados ignorados).
- Backward-compat: `bootstrap.sh` sem `--agent` não cria nenhum dir de view; `AGENTS.md` segue symlink.
- Manual: `bootstrap.sh --agent=cursor,gemini` em dir temporário, conferir `.cursor/rules/sdd.mdc`,
  `.gemini/commands/<skill>.toml` e o banner advisory.

## 8. Fora de escopo

- Comando `update`/`sync` dedicado e menu interativo (TUI readline) — bootstrap é flag-driven.
- Enforcement per-cliente (decisão: advisory only).
- Camada de produto da referência (Lean Inception, personas, MVP canvas) — não faz parte do harness.
- Tradução/i18n das views; portar os gates `.mjs` para CI de cada cliente.
