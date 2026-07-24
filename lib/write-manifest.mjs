#!/usr/bin/env node
// Writes/updates the keel installation manifest at <dir>/.specify/keel.json.
// ALWAYS called by bootstrap (unlike clients.json, which is gated by --agent).
// Zero-dep. Idempotent re-run: preserves installed_at, updates updated_at/version/commit/packs/agents.
// Usage: node write-manifest.mjs --dir <target> [--version v] [--commit sha] [--agents a,b] [--packs p,q]
import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";

function parseArgs(argv) {
  const out = { dir: ".", version: "", commit: "", agents: [], packs: [] };
  const list = (s) => (s || "").split(",").map((x) => x.trim()).filter(Boolean);
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--dir") out.dir = argv[++i];
    else if (argv[i] === "--version") out.version = argv[++i] || "";
    else if (argv[i] === "--commit") out.commit = argv[++i] || "";
    else if (argv[i] === "--agents") out.agents = list(argv[++i]);
    else if (argv[i] === "--packs") out.packs = list(argv[++i]);
  }
  return out;
}

const { dir, version, commit, agents, packs } = parseArgs(process.argv.slice(2));
const dest = join(dir, ".specify", "keel.json");

// Preserves installed_at if the manifest already exists (re-run/update); otherwise it's the 1st install.
let installedAt = null;
if (existsSync(dest)) {
  try { installedAt = JSON.parse(readFileSync(dest, "utf8")).installed_at || null; } catch {}
}
const now = new Date().toISOString();

const manifest = {
  keel_version: version || "unknown",
  commit: commit || "unknown",
  installed_at: installedAt || now,
  updated_at: now,
  agents: [...new Set(["claude", ...agents])],
  packs: [...new Set(packs)].sort(),
};

mkdirSync(dirname(dest), { recursive: true });
writeFileSync(dest, JSON.stringify(manifest, null, 2) + "\n");
console.log(`[keel] manifest ${installedAt ? "updated" : "written"} at ${dest} (v${manifest.keel_version})`);
