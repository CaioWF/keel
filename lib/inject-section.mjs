#!/usr/bin/env node
// Marker-block editor for living project docs (CLAUDE.md and friends).
//
// A keel block is delimited by `<!-- BEGIN:keel:<id> -->` / `<!-- END:keel:<id> -->`.
// Two kinds of content live in blocks, and both must survive a keel upgrade that
// rewrites the surrounding body:
//   - project-learned facts (environment, tests, conventions) written by `learn-session`
//   - pack-contributed sections, re-rendered by the pack's install.sh on every run
//
// Zero-dep (node: builtins). Bootstrap/pack-time tool: it runs from the keel source
// tree, not from the installed project. In-project edits are ordinary markdown edits.
//
// Usage:
//   node inject-section.mjs set        <file> <id> <content-file>
//   node inject-section.mjs carry-over <from> <to>
//   node inject-section.mjs ids        <file>
import { existsSync, readFileSync, writeFileSync } from "node:fs";

const ID_RE = /^[a-z0-9][a-z0-9-]*$/;
const begin = (id) => `<!-- BEGIN:keel:${id} -->`;
const end = (id) => `<!-- END:keel:${id} -->`;

const die = (msg) => {
  process.stderr.write(`[keel:inject-section] ${msg}\n`);
  process.exit(2);
};

const blockRe = (id) => new RegExp(`${begin(id)}[\\s\\S]*?${end(id)}`);

// Upsert: replace the block's whole span when present, otherwise append it at the end.
// Appending keeps keel's core body first and the accumulated blocks together below it.
function upsert(text, id, body) {
  const block = `${begin(id)}\n${body.trim()}\n${end(id)}`;
  const re = blockRe(id);
  if (re.test(text)) return text.replace(re, block);
  return `${text.replace(/\s+$/, "")}\n\n${block}\n`;
}

function blockIds(text) {
  return [...text.matchAll(/<!-- BEGIN:keel:([a-z0-9][a-z0-9-]*) -->/g)].map((m) => m[1]);
}

// Inner content of a block, without the markers.
function blockBody(text, id) {
  const m = text.match(blockRe(id));
  if (!m) return null;
  return m[0].slice(begin(id).length, m[0].length - end(id).length).trim();
}

const [cmd, ...rest] = process.argv.slice(2);

if (cmd === "set") {
  const [file, id, contentFile] = rest;
  if (!file || !id || !contentFile) die("usage: set <file> <id> <content-file>");
  if (!ID_RE.test(id)) die(`invalid block id: ${id} (expected [a-z0-9-])`);
  if (!existsSync(file)) die(`no such file: ${file}`);
  if (!existsSync(contentFile)) die(`no such content file: ${contentFile}`);
  const out = upsert(readFileSync(file, "utf8"), id, readFileSync(contentFile, "utf8"));
  writeFileSync(file, out);
  process.stdout.write(`[keel:inject-section] set keel:${id} in ${file}\n`);
} else if (cmd === "carry-over") {
  // Copy every keel block found in <from> into <to>. Used when bootstrap --force
  // rewrites CLAUDE.md from the template: the core body is refreshed, the project's
  // own blocks are carried across. Packs run afterwards and re-render their own,
  // so a pack update still wins over the carried copy.
  const [from, to] = rest;
  if (!from || !to) die("usage: carry-over <from> <to>");
  if (!existsSync(from) || !existsSync(to)) die("both files must exist");
  const src = readFileSync(from, "utf8");
  let dst = readFileSync(to, "utf8");
  const ids = blockIds(src);
  for (const id of ids) dst = upsert(dst, id, blockBody(src, id) ?? "");
  writeFileSync(to, dst);
  process.stdout.write(`[keel:inject-section] carried over ${ids.length} block(s) into ${to}\n`);
} else if (cmd === "ids") {
  const [file] = rest;
  if (!file || !existsSync(file)) die("usage: ids <file>");
  process.stdout.write(blockIds(readFileSync(file, "utf8")).join("\n") + "\n");
} else {
  die("unknown command (expected: set | carry-over | ids)");
}
