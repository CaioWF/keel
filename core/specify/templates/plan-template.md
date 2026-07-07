---
status: draft
---

# [Feature] — Plano

## Arquitetura

- [Componentes principais]
- [Fluxo de dados]
- [Integração com sistemas existentes]

## Estrutura de Arquivos

- [src/components/...]
- [src/services/...]
- [tests/...]

## Decisões Técnicas

- [Tech decision 1 e justificativa]
- [Tech decision 2 e justificativa]

## Contrato da Camada de Dados

> Preencher SÓ quando o plano adiciona/altera tabela, coluna, índice ou migração.
> Caso contrário, escrever `N/A — não toca a camada de dados` e seguir.

- **Mapeamento código↔schema**: [campo `camelCase` (código) ↔ coluna `snake_case` (DB), e onde o mapeamento vive — ex. Prisma `@map`/`@@map`, ou a camada de query. Um site, não espalhado.]
- **Tabelas/colunas**: [PK explícita; FKs com `on delete`; tipos (`timestamptz`/`numeric`/…); constraints `not null`/`unique`/`check`.]
- **Índices**: [FK e colunas de filtro/sort em hot path; ordem de índice composto; `unique` para invariantes reais.]
- **RLS**: [tabelas tenant/user-scoped → RLS habilitado + policy allow-list na coluna de escopo. Ou `N/A` com motivo.]
- **Migração**: [aditiva e reversível; coluna nova non-null via default ou backfill+`set not null`.]

## Ordem de Implementação

1. [Tarefa 1: Descrição]
2. [Tarefa 2: Descrição]
3. [Tarefa 3: Descrição]

## Como Validar

- [Testes unitários]
- [Testes de integração]
- [Checklist de qualidade]
