#!/usr/bin/env node
// Validador estrutural de blocos Mermaid em arquivos .md (zero-dep, só builtins node:).
// Não renderiza — pega os erros que mais quebram o render e que o agente mais comete:
//   • bloco vazio                              (fatal)
//   • tipo de diagrama ausente/desconhecido    (fatal)
//   • aspas duplas desbalanceadas              (fatal)
//   • (), [] ou {} desbalanceados              (aviso — shapes assimétricos `>...]` dão falso-positivo)
// Sai 1 em erro fatal. Serve de gate. Uso: node validate-mermaid.mjs [dir]   (default: ".")
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, resolve, extname, relative } from "node:path";

const ROOT = resolve(process.argv[2] || ".");
const IGNORE_DIRS = new Set(["node_modules", ".git", ".specify"]);

const TYPES = new Set([
  "flowchart", "graph", "sequenceDiagram", "classDiagram", "classDiagram-v2",
  "stateDiagram", "stateDiagram-v2", "erDiagram", "journey", "gantt", "pie",
  "mindmap", "timeline", "gitGraph", "quadrantChart", "requirementDiagram",
  "C4Context", "C4Container", "C4Component", "C4Dynamic", "C4Deployment",
  "sankey-beta", "xychart-beta", "block-beta", "packet-beta", "architecture-beta",
  "kanban", "radar", "zenuml",
]);

function walk(dir) {
  const out = [];
  for (const name of readdirSync(dir)) {
    if (IGNORE_DIRS.has(name) || name.startsWith(".tmp")) continue;
    const full = join(dir, name);
    let st;
    try { st = statSync(full); } catch { continue; }
    if (st.isDirectory()) out.push(...walk(full));
    else if (extname(full) === ".md") out.push(full);
  }
  return out;
}

function mermaidBlocks(text) {
  const lines = text.split(/\r?\n/);
  const blocks = [];
  let cur = null;
  for (let i = 0; i < lines.length; i++) {
    if (cur === null) {
      if (/^\s*```\s*mermaid\s*$/i.test(lines[i])) cur = { start: i + 1, body: [] };
    } else if (/^\s*```\s*$/.test(lines[i])) {
      blocks.push(cur); cur = null;
    } else {
      cur.body.push(lines[i]);
    }
  }
  return blocks;
}

const stripComments = (body) =>
  body.map((l) => { const i = l.indexOf("%%"); return i === -1 ? l : l.slice(0, i); }).join("\n");

const errors = [];
const warns = [];

for (const f of walk(ROOT)) {
  const rel = relative(ROOT, f) || f;
  let blocks;
  try { blocks = mermaidBlocks(readFileSync(f, "utf8")); } catch { continue; }

  blocks.forEach((b, n) => {
    const where = `${rel} (bloco mermaid #${n + 1}, linha ${b.start})`;

    let i = 0;
    while (i < b.body.length && b.body[i].trim() === "") i++;
    if (i < b.body.length && b.body[i].trim() === "---") {
      i++;
      while (i < b.body.length && b.body[i].trim() !== "---") i++;
      i++;
    }
    while (i < b.body.length && (b.body[i].trim() === "" || b.body[i].trim().startsWith("%%"))) i++;
    const first = i < b.body.length ? b.body[i].trim() : "";
    if (!first) { errors.push(`${where}: bloco mermaid vazio`); return; }
    const kw = (first.match(/^([A-Za-z][\w-]*)/) || [])[1] || "";
    if (!TYPES.has(kw)) errors.push(`${where}: tipo de diagrama ausente/desconhecido ("${first.slice(0, 30)}")`);

    const stripped = stripComments(b.body);
    const quotes = (stripped.match(/"/g) || []).length;
    if (quotes % 2 !== 0) errors.push(`${where}: aspas duplas desbalanceadas (${quotes})`);

    let outside = "", inQ = false;
    for (const ch of stripped) {
      if (ch === '"') inQ = !inQ;
      else if (!inQ) outside += ch;
    }
    for (const [op, cl, label] of [["(", ")", "()"], ["[", "]", "[]"], ["{", "}", "{}"]]) {
      const o = outside.split(op).length - 1;
      const c = outside.split(cl).length - 1;
      if (o !== c) warns.push(`${where}: ${label} possivelmente desbalanceado (${o} aberto / ${c} fechado)`);
    }
  });
}

if (warns.length) {
  console.log(`\n⚠ Avisos Mermaid (${warns.length}) — confira (shapes assimétricos \`>…]\` podem ser falso-positivo):`);
  for (const w of warns) console.log(`  • ${w}`);
}
if (errors.length) {
  console.error(`\n✗ Validação Mermaid: ${errors.length} erro(s)\n`);
  for (const e of errors) console.error(`  • ${e}`);
  console.error("");
  process.exit(1);
}
console.log(`✓ Validação Mermaid: blocos OK (tipo, aspas, delimitadores).`);
