#!/usr/bin/env node
// Bootstrap-time helper: additively merge keel hook registrations AND native
// permission rules into a target .claude/settings.json. Hooks dedup by command;
// permission buckets (deny/ask/allow) dedup by exact rule. Zero-dep (node:
// builtins). Usage: node merge-settings.mjs <settings.json> <settings.hooks.json>
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

for (const [event, groups] of Object.entries(add.hooks ?? {})) {
  const existing = (hooks[event] ??= []);
  const have = commands(existing);
  for (const g of groups) {
    const newCmds = commands([g]);
    const overlap = [...newCmds].some((c) => have.has(c));
    if (overlap) continue; // command already registered -> skip group
    existing.push(g);
  }
}

// Native permission rules (deny/ask/allow): union into each bucket, dedup by
// exact rule string, preserving any rules the user already set.
if (add.permissions) {
  const perms = (settings.permissions ??= {});
  for (const [bucket, rules] of Object.entries(add.permissions)) {
    if (!Array.isArray(rules)) continue;
    const cur = (perms[bucket] ??= []);
    const have = new Set(cur);
    for (const r of rules) {
      if (!have.has(r)) { cur.push(r); have.add(r); }
    }
  }
}

writeFileSync(settingsPath, JSON.stringify(settings, null, 2));
