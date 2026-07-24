#!/usr/bin/env node
// Structural audit of SDD documentation (zero-dep, node: builtins only).
// Deterministic rules (serves as a gate; exit 1 on any violation):
//   • every skill (.claude/skills/ * /SKILL.md) has frontmatter with `name` and `description`
//   • every specs/NNNN-* folder has spec.md
//   • relative links in .md don't point to a nonexistent file
// Does NOT require frontmatter on every .md (CLAUDE.md, README, ADRs don't have it) — only on skills.
// Usage: node audit-structure.mjs [dir]   (default: ".")
import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join, dirname, relative, resolve, extname, basename } from "node:path";

const ROOT = resolve(process.argv[2] || ".");
// Generated view dirs (non-Claude clients) are artifacts derived from the canonical source
// (.claude/ + CLAUDE.md) — auditing the source is enough and avoids false positives.
const IGNORE = new Set(["node_modules", ".git", ".specify", ".agents", ".cursor", ".gemini", ".windsurf"]);
// Generated instruction files (outside their own dir) that are also derived views.
const isGenerated = (f) => {
  const r = relative(ROOT, f).replace(/\\/g, "/");
  return r === "AGENTS.md" || r === "GEMINI.md" ||
    r === ".github/copilot-instructions.md" || r.startsWith(".github/prompts/");
};
const errors = [];
const err = (f, m) => errors.push(`${relative(ROOT, f) || f}: ${m}`);

function walk(dir) {
  const out = [];
  for (const n of readdirSync(dir)) {
    if (IGNORE.has(n) || n.startsWith(".tmp")) continue;
    const f = join(dir, n);
    let st;
    try { st = statSync(f); } catch { continue; }
    if (st.isDirectory()) out.push(...walk(f));
    else if (extname(f) === ".md") out.push(f);
  }
  return out;
}

function parseFrontmatter(text) {
  if (!text.startsWith("---")) return null;
  const end = text.indexOf("\n---", 3);
  if (end === -1) return null;
  const keys = {};
  for (const line of text.slice(3, end).split("\n")) {
    const m = line.match(/^([A-Za-z_][\w-]*)\s*:/);
    if (m) keys[m[1]] = line.slice(m[0].length).trim();
  }
  return keys;
}

// Only each skill's SKILL.md requires frontmatter; companion files (prompts,
// anti-patterns, refs) sit alongside it and are not skills.
const isSkill = (f) => f.replace(/\\/g, "/").includes("/.claude/skills/") && basename(f) === "SKILL.md";
const files = walk(ROOT).filter((f) => !isGenerated(f));

// 1) skills need frontmatter name + description
for (const f of files) {
  if (!isSkill(f)) continue;
  const fm = parseFrontmatter(readFileSync(f, "utf8"));
  if (!fm) { err(f, "skill missing frontmatter"); continue; }
  if (!fm.name) err(f, "skill missing `name`");
  if (!fm.description) err(f, "skill missing `description`");
}

// 2) every specs/NNNN-* needs spec.md
const specsDir = join(ROOT, "specs");
if (existsSync(specsDir)) {
  for (const n of readdirSync(specsDir)) {
    if (/^\d+-/.test(n) && !existsSync(join(specsDir, n, "spec.md")))
      err(join(specsDir, n), "feature missing `spec.md`");
  }
}

// 3) broken relative links
const linkRe = /\]\(([^)]+)\)/g;
for (const f of files) {
  const text = readFileSync(f, "utf8");
  let m;
  while ((m = linkRe.exec(text))) {
    let target = m[1].trim();
    if (/^(https?:|mailto:|#)/.test(target)) continue;
    if (/[<>]|XXXX|NNNN|NNN|\s/.test(target)) continue; // template placeholders
    target = target.split("#")[0];
    if (!target) continue;
    if (!existsSync(resolve(dirname(f), target))) err(f, `broken link → ${target}`);
  }
}

if (errors.length) {
  console.error(`\n✗ Structural audit: ${errors.length} problem(s)\n`);
  for (const e of errors) console.error(`  • ${e}`);
  console.error("");
  process.exit(1);
}
console.log(`✓ Structural audit: ${files.length} docs OK (skills, specs, links).`);
