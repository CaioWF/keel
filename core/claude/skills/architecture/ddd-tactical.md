# DDD tático (agnóstico de linguagem)

Fonte: Eric Evans, *Domain-Driven Design*. Os padrões táticos modelam o domínio dentro da camada
mais interna da Clean Architecture. Use quando há **regras de negócio e invariantes** de verdade
(não para CRUD anêmico).

## Os blocos

- **Value Object** — definido pelos valores, sem identidade; imutável. Ex.: `Money`, `Email`,
  `DateRange`. Comparado por valor. Carrega validação no construtor (não existe `Email` inválido).
- **Entity** — tem **identidade** estável ao longo do tempo, mesmo que os atributos mudem. Ex.:
  `Order`, `User`. Igualdade por id, não por atributos.
- **Aggregate** — cluster de entities/value objects tratado como uma unidade de consistência. Tem
  uma **raiz** (aggregate root); o mundo externo só referencia a raiz.
- **Repository** — abstração de coleção para carregar/salvar **aggregates** pela raiz. É uma
  **porta** (Clean Architecture): definida no domínio/application, implementada na infra.
- **Domain Service** — lógica de negócio que não pertence naturalmente a uma entity/value object
  (envolve várias). Sem estado.
- **Domain Event** — algo relevante que aconteceu no domínio (`OrderPlaced`); permite reações
  desacopladas.

## Fronteira de agregado (a regra que vira constituição)

- **Toda mutação passa pela raiz do agregado.** Ela garante as invariantes. Não altere entities
  internas por fora da raiz.
- Mantenha agregados **pequenos** — só o que precisa ser consistente na mesma transação.
- Entre agregados, referencie **por id**, não por objeto. Consistência entre agregados é eventual.
- Um repository por **aggregate root**, não por tabela.

## Red flags

- Entity anêmica (só getters/setters) com a regra de negócio espalhada em "services" de aplicação.
- Repository devolvendo entities internas de outro agregado.
- Invariante checada no controller em vez da raiz do agregado.
- Value object mutável ou aceitando estado inválido.

## Como aplicar

No plan-writer, identifique agregados e suas raízes antes de modelar persistência. Os repositories
são portas → casam com a dependency rule (domínio define, infra implementa). Profundidade
estratégica (bounded contexts, ubiquitous language) está fora deste guia tático.
