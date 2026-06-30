#!/usr/bin/env node
// SessionStart hook: index project Open Knowledge Format docs and inject a compact
// map before the first turn — every .md with a `type:` frontmatter key becomes a
// concept (name, type, path, [[links]]). Zero tool calls to discover what's documented.
// Zero-dep: node: builtins only. Never throws.
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join, relative } from "node:path";
import { readEvent } from "./_lib.mjs";

const MAX = 60; // cap injected concepts to bound the SessionStart token cost
const ROOTS = ["docs", "specs", ".specify/memory"]; // where keel keeps structured md
const SKIP = new Set([".git", "node_modules", ".specify/state"]);

const ev = await readEvent();
const cwd = ev.cwd || process.cwd();

function* walk(dir) {
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const e of entries) {
    if (e.isDirectory()) {
      if (SKIP.has(e.name)) continue;
      yield* walk(join(dir, e.name));
    } else if (e.name.endsWith(".md")) {
      yield join(dir, e.name);
    }
  }
}

// Minimal frontmatter parse: key:value lines inside the leading --- ... --- block.
function frontmatter(text) {
  if (!text.startsWith("---")) return null;
  const end = text.indexOf("\n---", 3);
  if (end < 0) return null;
  const fm = {};
  for (const line of text.slice(3, end).split("\n")) {
    const m = line.match(/^([A-Za-z0-9_-]+):\s*(.+?)\s*$/);
    if (m) fm[m[1]] = m[2].replace(/^["']|["']$/g, "");
  }
  return fm;
}

const concepts = [];
outer: for (const root of ROOTS) {
  const base = join(cwd, root);
  if (!existsSync(base)) continue;
  for (const path of walk(base)) {
    let text;
    try {
      text = readFileSync(path, "utf8");
    } catch {
      continue;
    }
    const fm = frontmatter(text);
    if (!fm || !fm.type) continue;
    const links = [...text.matchAll(/\[\[([^\]]+)\]\]/g)].map((m) => m[1]);
    concepts.push({
      name: fm.name || fm.title || relative(cwd, path).replace(/\.md$/, ""),
      type: fm.type,
      path: relative(cwd, path),
      links: [...new Set(links)].slice(0, 5),
    });
    if (concepts.length >= MAX) break outer;
  }
}

if (!concepts.length) process.exit(0);

// Group by type for a compact, scannable map.
const byType = {};
for (const c of concepts) (byType[c.type] ??= []).push(c);

const lines = [`Open Knowledge Format index — ${concepts.length} concept(s), zero tool calls:`];
for (const [type, items] of Object.entries(byType)) {
  lines.push(`\n[${type}]`);
  for (const c of items) {
    const lk = c.links.length ? `  -> ${c.links.join(", ")}` : "";
    lines.push(`  ${c.name} (${c.path})${lk}`);
  }
}

process.stdout.write(
  JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: lines.join("\n"),
    },
  }),
);
