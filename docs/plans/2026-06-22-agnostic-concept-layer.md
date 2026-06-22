---
status: draft
feature: agnostic-concept-layer
date: 2026-06-22
---

# Plano — Milestone 3: camada de conceito agnóstica + enforcement por linguagem

## 1. Entendimento

Reframe do usuário sobre o `ts-clean-arch`: em vez de um pack preso a uma linguagem,
investir em **conceitos de engenharia agnósticos** (Clean Architecture, SOLID, etc.). O
harness padroniza o **formato/estrutura** do que se cria; cada linguagem materializa com
suas especificidades.

Isso é a `docs/design-notes/gates-vs-skills.md` um nível acima — **duas camadas, não
ou/ou**:

- **Camada de conceito (core, agnóstica)** = metade "skill/judgment". Princípios, regra de
  dependência, layout de camadas — sem linguagem. Padroniza o QUE e o FORMATO. Reusável em
  qualquer stack. É o item 4 do `.git/sdd/todo.md` (abstrair livros/conceitos).
- **Camada de enforcement (pack, por linguagem)** = metade "gate/mecânica". A regra de
  dependência só se impõe com o mecanismo de cada ecossistema (TS `eslint-plugin-boundaries`/
  `dependency-cruiser`, Python `import-linter`, Go arch-tests, Java ArchUnit). Cada pack é
  **fino**: só o config que impõe as MESMAS regras da camada de conceito.

Guia sem enforcement = drift; enforcement sem guia = regra sem racional, não portável. O guia
é a fonte; cada pack é o guia expresso no linter de uma linguagem. **`ts-clean-arch` rebaixa**
de "a coisa" para "o primeiro pack fino", construído só quando validarmos num projeto TS real.

Decisões já tomadas (usuário): a camada de conceito assume as **três formas combinadas**
(skill + seção de constituição + template de estrutura) e é um **container para um conjunto
curado** de conceitos.

## 2. Investigação

Peças existentes que a camada encaixa:
- `core/specify/memory/constitution.md.tmpl` — injetada no SessionStart; lugar das regras duras.
- `core/specify/templates/` — onde vive o template de estrutura.
- `core/claude/skills/` — já usa o padrão **skill + arquivos companheiros** (ex.:
  `subagent-driven-development` com `implementer-prompt.md`). Serve de container natural.
- `core/claude/skills/test-driven-development/` — já cobre "testar comportamento". A
  estratégia de testes do conjunto curado deve **referenciar** essa skill, não duplicá-la.
- `bootstrap.sh` — já copia skills/templates/constituição e tem o seam `packs/<lang>/install.sh`
  (forward-ref do ts-clean-arch, hoje no-op).
- `docs/design-notes/gates-vs-skills.md` — a "Exception" já diz: core embarca gates de
  artefato agnósticos; gates de source ficam no pack. A camada de conceito é o complemento
  agnóstico do lado skill.

Âncora de livros: Clean Architecture (Uncle Bob). O conjunto curado proposto (§5): Clean
Architecture, SOLID, estratégia de testes, DDD tático.

## 3. Mudanças propostas

**(1) Skill container `architecture`** — `core/claude/skills/architecture/SKILL.md` (índice +
quando usar + como aplicar na cadeia SDD) com **um companheiro por conceito**:
- `clean-architecture.md` — camadas (entities/use-cases/interface-adapters/frameworks), a
  **dependency rule** (deps apontam pra dentro), exemplos neutros de linguagem.
- `solid.md` — os 5 princípios como heurísticas acionáveis.
- `testing-strategy.md` — pirâmide/estratégia; **aponta** para `test-driven-development`
  (comportamento > implementação), não reescreve.
- `ddd-tactical.md` — entity, value object, aggregate + boundary, repository, domain service.

**(2) Seção de constituição** — em `constitution.md.tmpl`, `## Princípios de arquitetura`: só
os **não-negociáveis** distilados (regra de dependência; domínio não importa framework/IO;
fronteira de agregado; "teste comportamento, não implementação"). Curto e imperativo — a
profundidade fica na skill.

**(3) Template de estrutura** — `core/specify/templates/architecture-template.md`: layout
agnóstico de feature (domain/application/infrastructure/interface), o que vai em cada camada,
a direção das dependências, e a nota de que **cada linguagem realiza com seu idioma** (TS
pastas+barrels, Go packages, Python módulos). É FORMATO, não código.

**(4) Design note `concepts-layer.md`** — a **receita do container**: um "conceito" =
companheiro de skill (guia) + regra de constituição opcional + nota de estrutura opcional +
pack de enforcement opcional. Garante que adicionar um conceito depois seja uniforme.

**(5) `ts-clean-arch` redefinido** (fora do build deste milestone) — pack fino que referencia
a camada: config `dependency-cruiser`/eslint-boundaries + `install.sh`, plugado no run-gates.
Construído na validação de um projeto TS real.

**(6) Wiring + testes** — `CLAUDE.md.tmpl` cita a skill `architecture` na cadeia; bootstrap
não muda (já copia skills/templates/constituição). Testes: skill+companheiros existem e passam
no audit; constituição tem a seção; template existe; um conceito-exemplo segue a receita.

## 4. Decisões de design

- **Skill umbrella + companheiros = o container** (não N skills soltas): uma entrada na cadeia,
  conceitos plugam como companheiros. Menos sprawl, audita limpo (só o SKILL.md exige frontmatter).
- **Conceito = triple uniforme** (guia-companheiro + regra-constituição opcional + nota-estrutura
  opcional), documentado na design note → adições futuras uniformes.
- **Constituição carrega só o duro; a skill carrega a profundidade.** Evita duplicar e mantém o
  contexto do SessionStart enxuto.
- **Template de estrutura é FORMATO, não scaffolding de código** — código é específico de
  linguagem (= pack). Core agnóstico não pode embarcar layout de código real.
- **Enforcement continua sendo a metade pack** (gates-vs-skills): a camada de conceito é o
  lado skill; o pack por linguagem é o lado gate. `ts-clean-arch` é o primeiro pack, não o produto.
- **testing-strategy referencia, não duplica, `test-driven-development`.**

## 5. Pontos de decisão

- **Conjunto curado exato.** Proposto: Clean Architecture + SOLID + estratégia-de-testes + DDD
  tático. Alternativas: dobrar testing dentro de TDD (não criar companheiro próprio); incluir
  hexagonal/ports-adapters (sobrepõe Clean Arch — provável cortar).
- **Umbrella skill vs N skills.** Recomendado umbrella+companheiros (container). Alternativa: uma
  skill por conceito (mais descobrível pelo `description`, mais sprawl).
- **Template de estrutura: 1 arquivo vs 1 por camada.** Recomendado 1 arquivo (visão única).
- **Authoring inline vs delegado.** Os 4 companheiros são authoring de conteúdo (destilar livros)
  — candidato a delegar a implementers sonnet com review do controller (selective-orchestration),
  ou inline. Decidir no build.

## 6. Ordem de implementação

1. Design note `concepts-layer.md` (a receita) — define o molde antes de encher.
2. Seção `## Princípios de arquitetura` na constituição (as regras duras).
3. Skill `architecture` SKILL.md (índice/como-aplicar) + os 4 companheiros.
4. Template `architecture-template.md` (formato de camadas + nota por-linguagem).
5. `CLAUDE.md.tmpl` cita a skill; testes (existência + audit + constituição + receita).
6. (Deferido) `ts-clean-arch` como primeiro pack fino — na validação de projeto TS real.

## 7. Como validar

- Suite verde (220 atuais + novos asserts, 0 falhas).
- Skill `architecture` + 4 companheiros existem; SKILL.md tem frontmatter; audit passa
  (companheiros não exigem frontmatter, regra já vigente).
- Constituição tem `## Princípios de arquitetura` com a dependency rule.
- Template `architecture-template.md` presente e descreve as 4 camadas + nota por-linguagem.
- e2e do bootstrap inalterado (skill/template/constituição já copiados).
- A receita da design note é seguível: adicionar um 5º conceito = 1 companheiro (+ regra/nota
  opcionais), sem tocar em código.

## 8. Fora de escopo

- Packs concretos por linguagem (`ts-clean-arch`, `py-clean-arch`, ...) — milestone separado, na
  validação de projeto real de cada stack.
- Scaffolding de código real das camadas (é pack/linguagem).
- Cobertura exaustiva de livros além do conjunto curado (a receita permite crescer depois).
- Reescrever `test-driven-development` (a estratégia de testes referencia a skill existente).
