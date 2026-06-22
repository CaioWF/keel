#!/usr/bin/env node
// Auditoria estrutural da documentação SDD (zero-dep, só builtins node:).
// Regras determinísticas (serve de gate; exit 1 em qualquer violação):
//   • toda skill (.claude/skills/ * /SKILL.md) tem frontmatter com `name` e `description`
//   • toda pasta specs/NNNN-* tem spec.md
//   • links relativos em .md não apontam para arquivo inexistente
// NÃO exige frontmatter em todo .md (CLAUDE.md, README, ADRs não têm) — só nas skills.
// Uso: node audit-structure.mjs [dir]   (default: ".")
import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join, dirname, relative, resolve, extname, basename } from "node:path";

const ROOT = resolve(process.argv[2] || ".");
// Dirs de views geradas (clientes não-Claude) são artefatos derivados da fonte canônica
// (.claude/ + CLAUDE.md) — auditar a fonte basta e evita falso-positivo.
const IGNORE = new Set(["node_modules", ".git", ".specify", ".agents", ".cursor", ".gemini", ".windsurf"]);
// Arquivos de instruções gerados (fora de um dir próprio) que também são views derivadas.
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

// Só o SKILL.md de cada skill exige frontmatter; arquivos companheiros (prompts,
// anti-patterns, refs) ficam ao lado e não são skills.
const isSkill = (f) => f.replace(/\\/g, "/").includes("/.claude/skills/") && basename(f) === "SKILL.md";
const files = walk(ROOT).filter((f) => !isGenerated(f));

// 1) skills precisam de frontmatter name + description
for (const f of files) {
  if (!isSkill(f)) continue;
  const fm = parseFrontmatter(readFileSync(f, "utf8"));
  if (!fm) { err(f, "skill sem frontmatter"); continue; }
  if (!fm.name) err(f, "skill sem `name`");
  if (!fm.description) err(f, "skill sem `description`");
}

// 2) toda specs/NNNN-* precisa de spec.md
const specsDir = join(ROOT, "specs");
if (existsSync(specsDir)) {
  for (const n of readdirSync(specsDir)) {
    if (/^\d{4}-/.test(n) && !existsSync(join(specsDir, n, "spec.md")))
      err(join(specsDir, n), "feature sem `spec.md`");
  }
}

// 3) links relativos quebrados
const linkRe = /\]\(([^)]+)\)/g;
for (const f of files) {
  const text = readFileSync(f, "utf8");
  let m;
  while ((m = linkRe.exec(text))) {
    let target = m[1].trim();
    if (/^(https?:|mailto:|#)/.test(target)) continue;
    if (/[<>]|XXXX|NNNN|NNN|\s/.test(target)) continue; // placeholders dos templates
    target = target.split("#")[0];
    if (!target) continue;
    if (!existsSync(resolve(dirname(f), target))) err(f, `link quebrado → ${target}`);
  }
}

if (errors.length) {
  console.error(`\n✗ Auditoria estrutural: ${errors.length} problema(s)\n`);
  for (const e of errors) console.error(`  • ${e}`);
  console.error("");
  process.exit(1);
}
console.log(`✓ Auditoria estrutural: ${files.length} docs OK (skills, specs, links).`);
