# Documento de Requisitos do Produto (PRD)

## Problema

- [Descrever o problema ou oportunidade identificada]
- [Impacto no negócio ou no usuário]

## Hipótese

- [Enunciado da hipótese sobre a solução]
- [Por que acreditamos que isso funcionará]

## Usuário/Contexto

- [Perfil do usuário alvo]
- [Cenários de uso]
- [Contexto e constraints]

## Métrica de Sucesso

- [KPI ou OKR mensurável]
- [Como avaliar sucesso da feature]

## Dependências e Interfaces

**Consome (entradas)** — do que esta feature depende para funcionar:

- [Origem (feature `NNN-nome` / serviço / sistema externo) → o que é consumido]

**Expõe (saídas)** — o que esta feature passa a oferecer a terceiros:

- [Contrato/endpoint/evento/dado/tela exposto → quem consome]

**Dependências** — acoplamentos com direção explícita:

- [`specs/NNN-nome` ou sistema externo — bloqueia esta feature / é desbloqueado por ela]

## Fora de Escopo

- [O que não será entregue nesta fase]
- [Melhorias futuras consideradas]
