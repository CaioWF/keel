# Clean Architecture (agnóstico de linguagem)

Fonte: Robert C. Martin, *Clean Architecture*. Objetivo: manter regras de negócio
independentes de framework, UI, banco e detalhes externos — para que detalhes possam mudar
sem reescrever o núcleo.

## As camadas (de dentro para fora)

1. **Entities / Domínio** — regras de negócio mais estáveis. Tipos e invariantes do negócio.
   Não conhecem nada de fora.
2. **Use cases / Application** — orquestram entidades para realizar uma intenção do usuário.
   Definem **portas** (interfaces) do que precisam do mundo externo.
3. **Interface adapters** — convertem entre o formato dos use cases e o mundo externo:
   controllers, presenters, gateways, mapeadores de repositório.
4. **Frameworks & drivers** — web framework, banco, fila, SDKs. O anel mais volátil.

## A dependency rule (a regra central)

**Dependências de código apontam só para dentro.** Um anel interno nunca conhece um externo.

- O domínio NÃO importa framework, I/O, ORM, HTTP, nem tipos de infra.
- Use cases dependem de **abstrações** (portas) que eles declaram; a infra **implementa** essas
  portas (inversão de dependência). O fluxo de controle pode ir para fora; o de **dependência de
  código**, não.
- Dado cruza fronteira como estrutura simples (DTO), nunca uma entidade do ORM vazando para o
  domínio.

## Como mapeia para estrutura

`domain/` (entities) · `application/` (use cases + portas) · `infrastructure/` (adapters/impl
das portas) · `interface/` (entrega: HTTP, CLI). Direção de import: `interface → application →
domain`, `infrastructure → application/domain` (implementando portas). Ver
`architecture-template.md` para o formato; cada linguagem realiza com seu idioma.

## Sinais de violação (red flags)

- `import` de framework/banco dentro de `domain/`.
- Use case instanciando um cliente HTTP/SQL concreto em vez de receber uma porta.
- Entidade do ORM usada como modelo de domínio.
- Regra de negócio dentro de controller/handler.

## Enforcement

Agnóstico aqui é guia. A imposição mecânica (proibir o import cruzando a fronteira) é por
linguagem: TS `dependency-cruiser`/`eslint-plugin-boundaries`, Python `import-linter`, Go
arch-tests + `internal/`, Java ArchUnit. Vem de um pack (ex.: `ts-clean-arch`), não do core.
