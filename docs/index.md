---
okf_version: "0.1"
---

# design-note
* [Concept layer](design-notes/concepts-layer.md) - How the concept layer standardizes engineering principles (Clean Architecture, SOLID, etc.) agnostically across languages using skills, constitution rules, and structure templates
* [Execution mode routing](design-notes/execution-mode-routing.md) - Why implement-and-evaluate picks inline vs dispatch vs dispatch-parallel execution modes based on task count and coupling, with parallelization via scope declaration and worktree isolation
* [Gate vs skill](design-notes/gates-vs-skills.md) - Decision rule for splitting review concerns: mechanical/deterministic rules belong in gates, judgment-based concerns in skills
* [Knowledge-packs roadmap](design-notes/knowledge-packs-roadmap.md) - Roadmap for adding knowledge packs that inject stack/domain expertise during plan and implement phases, including stack-conventions, codebase-map, saas-security, pattern replication, and data-layer contracts
* [Ship-pack scoping](design-notes/ship-pack-scoping.md) - Scope analysis for a ship pack covering post-integration lifecycle, including observability-and-instrumentation (included) and contract-deprecation (deferred)

# plan
* [Keel Core Scaffolder](plans/2026-06-17-keel-core.md) - Implementation plan for keel's stack-agnostic core including bootstrap script, templates, generic gates, 4 active hooks, document phase skills, implementation phase skills, and TS pack dispatch
* [Agnostic concept layer](plans/2026-06-22-agnostic-concept-layer.md) - Design and implementation plan for a language-agnostic concept layer that standardizes engineering principles with skill guides, constitution rules, structure templates, and language-specific packs
* [Multi-client views](plans/2026-06-22-multi-client-views.md) - Plan for generating derived views from canonical keel content for other AI agents (Codex, Cursor, Copilot, Gemini, Windsurf) while maintaining advisory-only enforcement without mechanical hooks

# reference
* [Authoring keel skills](authoring-skills.md) - Guide for writing skills in keel following TDD methodology, including when to create a skill, SKILL.md structure, and how to wire new skills into the keel framework

# spec
* [Keel design](specs/2026-06-17-keel-design.md) - Design spec for keel: a spec-driven development scaffolder that installs SDD flow (agnostic core + stack packs) with active enforcement via hooks, templates, skills, and gates
