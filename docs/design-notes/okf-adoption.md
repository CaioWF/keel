---
type: design-note
title: OKF adoption
description: How keel adopts the Open Knowledge Format — the tooling map and why cross-links are relative markdown, not wiki-links or absolute
---

# Design note: adoção do Open Knowledge Format (OKF)

O **OKF** ([Open Knowledge Format](https://github.com/GoogleCloudPlatform/knowledge-catalog/tree/main/okf), Google) é um formato vendor-neutral de base de conhecimento em markdown + frontmatter YAML: um **conceito** = 1 `.md` com `type:` obrigatório (+ `title:`/`description:` recomendados); um **bundle** = uma pasta de conceitos; `index.md` e `log.md` são nomes reservados (índice navegável + changelog datado). keel adota o OKF como a camada de conhecimento durável do projeto — `docs/` é o bundle.

## keel como cidadão OKF (os papéis)

| Papel | Peça |
|---|---|
| **Consumer** | hook SessionStart `okf-index.mjs` — injeta um mapa dos conceitos (name/type/path/description/links) sem tool call; progressive disclosure acima de `KEEL_OKF_BUDGET` (default 60), sem truncar silencioso |
| **Producer** | `okf-build-index.mjs` — `build` gera a **árvore** de `index.md` por diretório; `check` é gate de freshness rodado no commit |
| **Viewer** | `okf-visualize.mjs` — grafo HTML self-contained (sem dependência GCP/Python do visualizador upstream) |
| **Ingest** | skill `okf-enrich` — destila uma fonte em páginas de conceito, atualiza o índice, faz append no `log.md` (o loop "LLM wiki" do Karpathy) |
| **Seeds** | `core/docs/` sai OKF-conforme no bootstrap; walkers pulam `_`-prefixados (templates) |

## Decisão: cross-link = markdown relativo

A spec OKF marca o link **absoluto bundle-relative** (`/dir/x.md`, `/` = raiz do bundle) como *"recommended for stability"*, com relativo também suportado. keel **rejeitou o absoluto** e usa **markdown relativo** — um link `[Título]` cujo alvo é `../dir/outro.md`. Motivo: o `/` é ambíguo entre camadas —

- para o **audit gate** do keel (`resolve(dirname(f), target)`), `/` = raiz do **filesystem** → link marcado quebrado → commit falha;
- no **GitHub**, `/` = raiz do **repo**, não do bundle;
- só o consumidor OKF-aware trata `/` como raiz do bundle.

Nenhuma das três leituras coincide, então o absoluto exigiria ensinar cada resolver (audit, hook, GitHub) e ainda quebraria o render nativo do GitHub. O **relativo** é OKF-conformante, resolve igual no audit + GitHub + Obsidian, e não precisa de mágica. A escolha inicial de `[[wikilinks]]` (path-of-least-resistance, já lida pelo hook) foi revertida a pedido — o hook ainda **lê** `[[]]` por back-compat, mas os docs usam markdown. Ver [Gate vs skill](gates-vs-skills.md): o enforcement OKF (freshness, links) vive em gates determinísticos; o julgamento (o que virar conceito) vive na skill `okf-enrich`.

## Fora de escopo (fila, sem blocker)

- Campos recomendados `tags`/`timestamp`/`resource` no mapa do hook (só `description` foi exposto).
- Validação de estrutura do `log.md` (hoje só o `okf-enrich` escreve; nada valida o formato).
