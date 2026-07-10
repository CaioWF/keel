---
type: design-note
title: Knowledge-packs roadmap
description: Roadmap for adding knowledge packs that inject stack/domain expertise during plan and implement phases, including stack-conventions, codebase-map, saas-security, pattern replication, and data-layer contracts
---

# Knowledge-packs roadmap

Origem: screenshot de um agente (projeto `finance-lite`) usando skills de **conhecimento
de stack/domínio** injetado durante o *implement* — não como review. Keel hoje tem skills de
**processo** (pipeline SDD) + packs de **review** (api/ui). O gap: nenhum pack de conhecimento
alimenta as fases de plan/implement *antes* de escrever código.

Skills observados na imagem: `directory-map`, `typescript-expert`, `frontend-design`,
`saas-security-checklist`, `naming-conventions`, `postgresql-best-practices`.

## TODO (fazer de um por um)

- [x] **1. Pack `stack-conventions`** — conhecimento de stack injetado no plan/implement, não no
  review. Cobre `naming-conventions` (camelCase código / snake_case DB), `postgres-conventions`
  (índices, RLS), `typescript-conventions`. Consumido por `plan-writer` + `implement-feature`.
  *Maior gap: cobre 3 dos 6 skills da imagem.*
  **Feito:** novo registry `impl-conventions.txt` (living, espelha `review-lenses.txt`), seed no
  bootstrap + auto-install por stack-detection (tsconfig / postgres|prisma). `plan-writer` step 2a e
  `implement-feature` step 3 consultam o registry. `copy_tree` virou variádico (multi-skip). Teste
  `tests/test-pack-stack-conventions.sh` (24 asserts). Suite: 375 run, 0 failed.

- [x] **2. Skill `codebase-map`** — mapeia repo uma vez (estrutura em profundidade) → artefato
  persistido em `docs/`, reusado por todas as fases. Token-efficient. Hoje keel não tem mapeamento
  estrutural reusável.
  **Feito:** core skill `codebase-map` (companheira, on-demand como `architecture`) produz
  `docs/codebase-map.md` (living, depth≈3, token-lean). `plan-writer` step 2a consulta/gera antes de
  desenhar; CLAUDE.md.tmpl documenta como companion; `analyze`/`implement-feature` reusam. Ship
  automático via `core/claude/skills`. Testes em `test-skills-core.sh` (+5 asserts). Suite: 380 run, 0 failed.

- [x] **3. Pack `saas-security`** — checklist de **domínio** (auth/billing/RLS/tenant-isolation),
  não processo genérico. Reforça server-side enforcement ("bloqueio real no backend, não só blur").
  Casa com regra whitelist do CLAUDE.md. Referenciado por `security-review`.
  **Feito:** review lens `saas-security` (espelha api-review/ui-review), registrado em
  `review-lenses.txt`, fan-out por `review-and-simplify` junto de `security-review`. Checklist: gate
  client→enforce server, whitelist authz, tenant/RLS/IDOR, paywall/quota bypass, webhook-sig+idempotência,
  auth-flow (validade/tentativas/single-use/entropia/off-by-one expiry). Testes em `test-packs.sh`
  (+9 asserts). Suite: 389 run, 0 failed.

- [x] **4. Princípio "replicar padrão existente antes de inventar"** — codificar em `analyze` /
  `plan-writer`: pattern-match código existente antes de projetar novo. Bloqueia divergência de
  arquitetura. (agente da imagem replicou o fluxo do `finance-lite` em vez de inventar.)
  **Feito:** `plan-writer` step 2c ("Replicate before inventing" — achar feature existente mais
  próxima via mapa, replicar layering/erro/naming/placement; divergir só com razão em `Decisões
  Técnicas`). `analyze` cross-check flaga divergência sem razão registrada como finding
  ("architecture divergence"). Usa o mapa do #2. Testes em `test-skills-core.sh` (+2). Suite: 391 run, 0 failed.

- [x] **5. Seção "data-layer contract" no plano** — quando o plano toca DB/migration: exigir
  mapeamento código↔schema (camelCase↔snake_case) + RLS explícito. Estende `spec-plan-format-8`;
  casa com pack `migration-safety` existente.
  **Feito:** nova seção condicional `Contrato da Camada de Dados` no `plan-template.md` (mapeamento
  código↔schema + site único, keys/constraints/tipos, índices, RLS allow-list, migração
  aditiva/reversível; `N/A` quando não toca DB). `plan-writer` step 4 preenche condicionalmente,
  puxando de `postgres-conventions` quando instalado; `migration-safety` revisa depois. Testes em
  `test-templates.sh` + `test-skills-core.sh` (+2). Suite: 393 run, 0 failed.

## Ordem
1 → 2 → 3 → 4 → 5. Começar por #1 (gap estrutural, maior cobertura).

## Relacionado

- [[Ship-pack scoping]] — nota que escopeia possíveis packs de pós-integração, complementando este roadmap de packs de conhecimento
