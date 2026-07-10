# design-note
* [Concept layer](concepts-layer.md) - How the concept layer standardizes engineering principles (Clean Architecture, SOLID, etc.) agnostically across languages using skills, constitution rules, and structure templates
* [Execution mode routing](execution-mode-routing.md) - Why implement-and-evaluate picks inline vs dispatch vs dispatch-parallel execution modes based on task count and coupling, with parallelization via scope declaration and worktree isolation
* [Gate vs skill](gates-vs-skills.md) - Decision rule for splitting review concerns: mechanical/deterministic rules belong in gates, judgment-based concerns in skills
* [Knowledge-packs roadmap](knowledge-packs-roadmap.md) - Roadmap for adding knowledge packs that inject stack/domain expertise during plan and implement phases, including stack-conventions, codebase-map, saas-security, pattern replication, and data-layer contracts
* [Ship-pack scoping](ship-pack-scoping.md) - Scope analysis for a ship pack covering post-integration lifecycle, including observability-and-instrumentation (included) and contract-deprecation (deferred)
