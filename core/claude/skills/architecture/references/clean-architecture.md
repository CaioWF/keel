# Clean Architecture (language-agnostic)

Source: Robert C. Martin, *Clean Architecture*. Goal: keep business rules
independent of framework, UI, database, and external details — so details can change
without rewriting the core.

## The layers (from inside out)

1. **Entities / Domain** — the most stable business rules. Business types and invariants.
   Know nothing about the outside.
2. **Use cases / Application** — orchestrate entities to fulfill a user intent.
   Define **ports** (interfaces) for what they need from the outside world.
3. **Interface adapters** — convert between the use cases' format and the outside world:
   controllers, presenters, gateways, repository mappers.
4. **Frameworks & drivers** — web framework, database, queue, SDKs. The most volatile ring.

## The dependency rule (the central rule)

**Code dependencies point only inward.** An inner ring never knows about an outer one.

- The domain does NOT import framework, I/O, ORM, HTTP, or infra types.
- Use cases depend on **abstractions** (ports) they declare; infra **implements** these
  ports (dependency inversion). Control flow can go outward; **code dependency**
  cannot.
- Data crosses the boundary as a plain structure (DTO), never an ORM entity leaking into
  the domain.

## How it maps to structure

`domain/` (entities) · `application/` (use cases + ports) · `infrastructure/` (adapters/port
implementations) · `interface/` (delivery: HTTP, CLI). Import direction: `interface → application →
domain`, `infrastructure → application/domain` (implementing ports). See
`architecture-template.md` for the format; each language realizes it in its own idiom.

## Violation signals (red flags)

- `import` of framework/database inside `domain/`.
- Use case instantiating a concrete HTTP/SQL client instead of receiving a port.
- ORM entity used as the domain model.
- Business rule inside a controller/handler.

## Enforcement

Language-agnostic here is guidance. Mechanical enforcement (forbidding the import across the
boundary) is per language: TS `dependency-cruiser`/`eslint-plugin-boundaries`, Python `import-linter`, Go
arch-tests + `internal/`, Java ArchUnit. It comes from a pack (e.g. `ts-clean-arch`), not from core.
