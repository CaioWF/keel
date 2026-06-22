#!/usr/bin/env node
// SessionStart hook: inject base SDD context — the project constitution (durable rules)
// and docs/STATE.md (volatile work memory: where we stopped, next step, blockers).
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { readEvent } from "./_lib.mjs";

const ev = await readEvent();
const cwd = ev.cwd || process.cwd();

const sources = [
  [join(cwd, ".specify", "memory", "constitution.md"), "Constituição do projeto"],
  [join(cwd, "docs", "STATE.md"), "STATE — memória de trabalho (onde paramos / próximo passo)"],
];

const parts = [];
for (const [path, label] of sources) {
  if (existsSync(path)) parts.push(`===== ${label} =====\n${readFileSync(path, "utf8").trim()}`);
}
if (!parts.length) process.exit(0);

process.stdout.write(
  JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: parts.join("\n\n"),
    },
  }),
);
