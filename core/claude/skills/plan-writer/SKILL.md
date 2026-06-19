---
name: plan-writer
description: Use after the spec is clarified to write the technical plan for the active feature into specs/<feature>/plan.md from the plan template, with status:draft frontmatter.
---

# plan-writer

When: spec exists and has been through clarify; before breaking work into tasks.

Template: `.specify/templates/plan-template.md`.

Output: `specs/<active-feature>/plan.md`.

Steps:
1. Resolve the active feature from `.specify/state` (fallback: newest dir under `specs/`).
2. Read `specs/<active-feature>/spec.md` to ground the plan in the approved requirements.
3. Copy `.specify/templates/plan-template.md` to `specs/<active-feature>/plan.md`.
4. Fill each section that exists in the template:
   - `Arquitetura` — main components, data flow, integration with existing systems.
   - `Estrutura de Arquivos` — concrete file/dir paths to add or touch.
   - `Decisões Técnicas` — tech decisions with rationale.
   - `Ordem de Implementação` — numbered implementation order.
   - `Como Validar` — unit/integration tests and quality checklist.
5. Keep `status: draft` in the frontmatter.

Approval: like the spec, the plan needs a human to flip its frontmatter to `status: approved`. The phase-gate hook requires BOTH `spec.md` and `plan.md` to carry `status: approved` before it allows any code edit — this file does not self-approve.

Next: tasks-writer.
