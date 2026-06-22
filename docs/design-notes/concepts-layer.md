# Design note: a camada de conceito agnóstica (o container)

A camada de conceito é o lado **skill/agnóstico** da `gates-vs-skills.md` aplicado a
princípios de engenharia (Clean Architecture, SOLID, ...). Ela padroniza **o quê** construir
e o **formato**; o **enforcement** mecânico fica no pack por linguagem (o lado gate).

## A receita: um "conceito" é um triple uniforme

Para adicionar um conceito ao harness, preencha até quatro slots — só o primeiro é obrigatório:

1. **Guia (obrigatório)** — um companheiro da skill `architecture`:
   `core/claude/skills/architecture/<conceito>.md`. Agnóstico de linguagem: o princípio, quando
   aplicar, exemplos neutros, como mapeia para a estrutura. É o "como pensar".
2. **Regra de constituição (opcional)** — se o conceito tem um **não-negociável** verificável
   pelo agente, adicione uma linha imperativa em `## Princípios de arquitetura` da
   `constitution.md.tmpl`. Curto. A profundidade fica no guia, não aqui.
3. **Nota de estrutura (opcional)** — se o conceito molda o layout de pastas/módulos, descreva o
   formato em `architecture-template.md` (agnóstico; cada linguagem realiza com seu idioma).
4. **Pack de enforcement (opcional, por linguagem)** — se a regra dá para impor mecanicamente,
   o config vai num pack `packs/<lang>-<conceito>/` (ex.: `ts-clean-arch` com dependency-cruiser),
   plugado no `run-gates.sh`. NUNCA no core agnóstico.

## Por que esse formato

- **Skill umbrella + companheiros** (não N skills soltas): uma entrada na cadeia SDD, conceitos
  plugam como companheiros, audita limpo (só `SKILL.md` exige frontmatter).
- **Constituição só com o duro**: ela é injetada no SessionStart — manter enxuto. O guia carrega
  o resto.
- **Estrutura = formato, não código**: código de camada é específico de linguagem (= pack).
- **Guia ↔ pack**: o guia é a fonte; o pack é o guia expresso no linter de uma linguagem. Guia
  sem pack = advisory (aceitável); pack sem guia = regra sem racional (evitar).

## Conjunto curado atual

| Conceito | Guia | Regra constituição | Nota estrutura | Pack |
|---|---|---|---|---|
| Clean Architecture | `clean-architecture.md` | dependency rule | camadas | `ts-clean-arch` (deferido) |
| SOLID | `solid.md` | — | — | (lint por linguagem, depois) |
| Estratégia de testes | `testing-strategy.md` (aponta p/ `test-driven-development`) | testar comportamento | — | gate de teste já existe |
| DDD tático | `ddd-tactical.md` | fronteira de agregado | — | — |

Crescer = mais uma linha na tabela + os slots da receita. Sem tocar em código.
