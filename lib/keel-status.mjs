#!/usr/bin/env node
// Reads <dir>/.specify/keel.json and prints the keel installation status.
// Zero-dep. Compares against the source version (arg --source-version) if given, to flag outdated.
// Usage: node keel-status.mjs --dir <target> [--source-version v] [--source-commit sha]
import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";

function parseArgs(argv) {
  const out = { dir: ".", sourceVersion: "", sourceCommit: "" };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--dir") out.dir = argv[++i];
    else if (argv[i] === "--source-version") out.sourceVersion = argv[++i] || "";
    else if (argv[i] === "--source-commit") out.sourceCommit = argv[++i] || "";
  }
  return out;
}

const { dir, sourceVersion, sourceCommit } = parseArgs(process.argv.slice(2));
const src = join(dir, ".specify", "keel.json");

if (!existsSync(src)) {
  console.error(`[keel] no manifest at ${src} — keel not installed here (run bootstrap.sh).`);
  process.exit(1);
}

let m;
try { m = JSON.parse(readFileSync(src, "utf8")); }
catch { console.error(`[keel] manifest at ${src} is not valid JSON.`); process.exit(1); }

const agents = (m.agents || []).join(", ") || "(none)";
const packs = (m.packs || []).join(", ") || "(none)";
console.log(`keel ${m.keel_version || "unknown"} (commit ${m.commit || "unknown"})`);
console.log(`  installed: ${m.installed_at || "?"}`);
console.log(`  updated:   ${m.updated_at || "?"}`);
console.log(`  agents:    ${agents}`);
console.log(`  packs:     ${packs}`);

// Outdated signal: source given and diverges from installed.
if (sourceVersion && m.keel_version && sourceVersion !== m.keel_version) {
  console.log(`  ! outdated: source is ${sourceVersion} (installed ${m.keel_version}) — re-run bootstrap.sh --force`);
} else if (sourceCommit && m.commit && m.commit !== "unknown" && sourceCommit !== m.commit) {
  console.log(`  ! source commit ${sourceCommit} differs from installed ${m.commit} — re-run bootstrap.sh --force`);
}
