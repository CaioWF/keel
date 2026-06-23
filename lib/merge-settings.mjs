#!/usr/bin/env node
// Bootstrap-time helper: additively merge keel hook registrations into a
// target .claude/settings.json, deduping by command. Zero-dep (node: builtins).
// Usage: node merge-settings.mjs <settings.json> <settings.hooks.json>
import { readFileSync, writeFileSync } from "node:fs";

const [settingsPath, hooksPath] = process.argv.slice(2);
const settings = JSON.parse(readFileSync(settingsPath, "utf8"));
const add = JSON.parse(readFileSync(hooksPath, "utf8"));

const hooks = (settings.hooks ??= {});
const commands = (groups) => {
  const out = new Set();
  for (const g of groups) for (const h of g.hooks ?? []) out.add(h.command);
  return out;
};

for (const [event, groups] of Object.entries(add.hooks)) {
  const existing = (hooks[event] ??= []);
  const have = commands(existing);
  for (const g of groups) {
    const newCmds = commands([g]);
    const overlap = [...newCmds].some((c) => have.has(c));
    if (overlap) continue; // command already registered -> skip group
    existing.push(g);
  }
}

writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
