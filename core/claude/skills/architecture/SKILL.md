---
name: architecture
description: Use ao desenhar a estrutura de uma feature ou módulo (na fase de plano, ou ao refatorar) para aplicar princípios de engenharia agnósticos de linguagem — Clean Architecture, SOLID, estratégia de testes e DDD tático. Container de guias; cada conceito é um companheiro.
---

# architecture — princípios de engenharia agnósticos

Container dos conceitos de arquitetura do harness. Agnóstico de linguagem: descreve **como
pensar** a estrutura; cada linguagem realiza com seu idioma, e o enforcement mecânico (quando
existe) vem de um pack por linguagem, não daqui.

## Quando usar

- Na fase **plan-writer**, ao decidir camadas/módulos/fronteiras da feature.
- Ao **refatorar** estrutura existente, ou quando o `architecture-template.md` for preenchido.
- Sempre que uma decisão de dependência ou de fronteira aparecer.

Os não-negociáveis já estão na constituição (`## Princípios de arquitetura`, injetada no
SessionStart) — esta skill é a profundidade e o racional por trás deles.

## Como aplicar (na cadeia SDD)

1. Identifique o **domínio** da feature (entidades, regras de negócio) e separe-o do que é
   framework/I/O/infra.
2. Aplique a **dependency rule**: dependências apontam para dentro (ver `clean-architecture.md`).
3. Modele o domínio com **DDD tático** quando houver invariantes/estado (ver `ddd-tactical.md`).
4. Verifique o desenho contra **SOLID** (ver `solid.md`) — uma responsabilidade por unidade,
   dependa de abstração, não de detalhe.
5. Planeje os testes pela **estratégia de testes** (ver `testing-strategy.md`), que reforça a
   skill `test-driven-development` (comportamento > implementação).

## Conceitos (companheiros)

- `clean-architecture.md` — camadas + dependency rule.
- `solid.md` — os 5 princípios como heurísticas.
- `testing-strategy.md` — pirâmide/estratégia; referencia `test-driven-development`.
- `ddd-tactical.md` — entity, value object, aggregate, repository, domain service.

Adicionar um conceito: ver `docs/design-notes/concepts-layer.md` (a receita do container).
