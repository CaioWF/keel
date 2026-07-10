---
type: adr
title: Registrar decisões de arquitetura
description: Formalize architecture decision records as immutable documents to preserve structural reasoning and improve onboarding.
---

# ADR-0001: Registrar decisões de arquitetura

- **Status:** aceito
- **Data:** YYYY-MM-DD
- **Decisores:** <time>

## Contexto

Decisões estruturais (escolha de stack, fronteiras de módulo, padrões transversais) se perdem
quando ficam só na cabeça de quem decidiu ou diluídas em threads de chat. Quem chega depois
(humano ou agente) refaz a discussão sem saber o que já foi descartado e por quê. O `docs/STATE.md`
guarda o estado **volátil** do trabalho — não é o lugar de uma decisão durável.

## Decisão

Vamos registrar cada decisão de arquitetura significativa como um **ADR** (Architecture Decision
Record) imutável em `docs/architecture/adr/NNNN-titulo.md`, usando `_template.md`. Um ADR é
append-only: para mudar de ideia, cria-se um novo ADR que marca o anterior como "substituído por".

## Alternativas consideradas

- **Só o STATE.md** — mistura estado volátil com decisão durável; o histórico do porquê se perde a
  cada atualização do STATE.
- **Wiki/Confluence externo** — sai do repositório, dessincroniza do código e não versiona junto.

## Consequências

- **Positivas:** histórico rastreável do *porquê*; onboarding (humano e agente) mais rápido; o STATE
  fica enxuto e linka para o ADR.
- **Negativas / trade-offs:** disciplina de escrever o ADR no momento da decisão.
- **Neutras:** ADRs viram parte do diff e do review como qualquer outro arquivo.
