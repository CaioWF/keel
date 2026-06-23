#!/usr/bin/env node
// PreToolUse(Edit|Write) gate: default-deny edits to code until the active
// feature has an approved spec.md AND plan.md. SDD artifacts/docs are exempt.
import { existsSync, readFileSync } from "node:fs";
import { join, basename } from "node:path";
import { readEvent, activeFeature } from "./_lib.mjs";

const ev = await readEvent();
const cwd = ev.cwd || process.cwd();
const file = (ev.tool_input && ev.tool_input.file_path) || "";

// Allow edits to SDD artifacts / docs / the constitution files themselves.
// Anchor the dir exemption to the TOP-LEVEL segment relative to cwd, so a
// coincidental nested dir (e.g. src/docs/, src/specs/) does NOT escape the
// gate. Files outside cwd fall through to default-deny.
const rel = file.startsWith(cwd + "/") ? file.slice(cwd.length + 1) : file;
const top = rel.split("/")[0];
const base = basename(file);
const exempt =
  top === "specs" ||
  top === ".specify" ||
  top === "docs" ||
  base === "CLAUDE.md" ||
  base === "AGENTS.md";
if (exempt) process.exit(0);

function isApproved(path) {
  if (!existsSync(path)) return false;
  const txt = readFileSync(path, "utf8");
  const m = txt.match(/^---\n([\s\S]*?)\n---/);
  const fm = m ? m[1] : "";
  return /^status:\s*approved\s*$/m.test(fm);
}

const feat = activeFeature(cwd);
const spec = join(cwd, "specs", feat, "spec.md");
const plan = join(cwd, "specs", feat, "plan.md");
if (feat && isApproved(spec) && isApproved(plan)) process.exit(0);

process.stderr.write(
  `[keel:phase-gate] Blocked: feature '${feat || "none"}' has no approved spec.md+plan.md (need 'status: approved' in both). Run the SDD flow (spec-writer -> plan-writer) before editing code.\n`,
);
process.exit(2);
