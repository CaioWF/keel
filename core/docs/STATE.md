---
type: state
title: Project state
description: Between-session work-state tracking the current active feature, recent decisions, blockers, and deferred ideas.
---

# STATE — Memória viva do projeto

> Memória de trabalho **entre sessões** (humanos e agentes). É **volátil**: atualizada o tempo
> todo. Diferente do **ADR** (decisão durável e imutável — ver `docs/architecture/adr/`).
> Decisão estrutural → ADR; estado do trabalho → aqui. Atualize ao **pausar/encerrar**; leia ao
> **retomar**. Use a skill `handoff`. Injetado no contexto no início de cada sessão.

**Última atualização:** YYYY-MM-DD por <nome>

## Em andamento / próximo passo

> O que está aberto agora e a **próxima ação concreta** (não "continuar a feature" — diga o passo).

- Feature ativa: `specs/NNNN-<nome>/` — <fase atual: spec | plan | tasks | implement>
- Próximo passo: <ação específica, ex.: "implementar AC-3 no adapter X">

## Decisões recentes

> Resumo cronológico. Se for difícil de reverter, vire um ADR e linke aqui.

- YYYY-MM-DD: <decisão> — <ADR-NNNN se aplicável>

## Bloqueios

- [ ] <o que trava · quem/como destrava · desde quando>

## Ideias adiadas / backlog técnico

- <ideia → qual gatilho para reconsiderar>

## Todos soltos

- [ ] <tarefa que ainda não cabe numa spec>
