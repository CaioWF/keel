#!/usr/bin/env node
// Partição e verificação de file-scope para dispatch-parallel (zero-dep, só builtins node:).
//
// Dois modos:
//
//   partition <tasks.md>
//     Lê as linhas de checklist de tasks.md, extrai o `[scope: glob, glob]` de cada task e
//     agrupa em batches CONSECUTIVOS onde os scopes são disjuntos par-a-par (nenhum par toca o
//     mesmo arquivo). Task sem scope, ou com glob amplo (prefixo vazio, ex.: `**`, `**/*.ts`),
//     roda sozinha (batch de um). Imprime os batches em ordem. Determinístico, informativo
//     (exit 0), exceto scope malformado → exit 1.
//     Tamanho máximo do batch: env KEEL_PARALLEL_MAX (default 4).
//
//   check "<glob, glob>" <arquivo>...
//     Verifica que TODO arquivo alterado casa ao menos um glob do scope declarado. Qualquer
//     arquivo fora do scope → exit 1 (write out-of-scope pode colidir com uma task irmã).
//     Todos dentro → exit 0.
//
// Disjunção é conservadora (whitelist): na dúvida, trata como sobreposto e serializa. Nunca
// declara disjunto o que pode colidir.
import { readFileSync } from "node:fs";

const MAX = Math.max(1, parseInt(process.env.KEEL_PARALLEL_MAX || "4", 10) || 4);
const WILDCARD = /[*?[\]{}]/;

// Segmentos literais de um glob: prefixo de path antes do primeiro segmento com wildcard.
// `src/auth/**` -> ["src","auth"] · `src/*.ts` -> ["src"] · `**/*.ts` -> [] (amplo, casa tudo).
function litSegs(glob) {
  const segs = [];
  for (const seg of glob.split("/")) {
    if (WILDCARD.test(seg)) break;
    segs.push(seg);
  }
  return segs;
}

const isSegPrefix = (a, b) => a.length <= b.length && a.every((s, i) => s === b[i]);

// Dois globs sobrepõem se um prefixo literal é seg-prefixo do outro (ou igual). Prefixo vazio
// (glob amplo) é seg-prefixo de qualquer coisa → sobrepõe tudo.
function globsOverlap(gA, gB) {
  const a = litSegs(gA), b = litSegs(gB);
  return isSegPrefix(a, b) || isSegPrefix(b, a);
}

// Scope = lista de globs. Dois scopes sobrepõem se algum par de globs sobrepõe.
function scopesOverlap(sA, sB) {
  for (const a of sA) for (const b of sB) if (globsOverlap(a, b)) return true;
  return false;
}

const isBroad = (scope) => scope.length === 0 || scope.some((g) => litSegs(g).length === 0);

function parseScope(raw) {
  return raw.split(",").map((s) => s.trim()).filter(Boolean);
}

// glob -> RegExp ancorado. `**/`->(?:.*/)?  `**`->.*  `*`->[^/]*  `?`->[^/]
function globToRe(glob) {
  let re = "";
  for (let i = 0; i < glob.length; i++) {
    const c = glob[i];
    if (c === "*") {
      if (glob[i + 1] === "*") {
        if (glob[i + 2] === "/") { re += "(?:.*/)?"; i += 2; } else { re += ".*"; i += 1; }
      } else re += "[^/]*";
    } else if (c === "?") re += "[^/]";
    else if (".+^${}()|[]\\".includes(c)) re += "\\" + c;
    else re += c;
  }
  return new RegExp("^" + re + "$");
}

const norm = (f) => f.replace(/^\.\//, "");
const fileInScope = (file, scope) => scope.some((g) => globToRe(g).test(norm(file)));

// --- tasks.md parsing ---
// Linha de checklist top-level: `- [ ] Task N: ... [scope: a, b]` (ou `- [x] ...`).
function parseTasks(md) {
  const tasks = [];
  for (const line of md.split("\n")) {
    const m = line.match(/^- \[[ xX]\]\s+(.*)$/);
    if (!m) continue;
    const text = m[1];
    const label = (text.match(/^(Task\s+\d+)/i) || [, text.slice(0, 40)])[1];
    const open = text.indexOf("[scope:");
    if (open !== -1 && text.indexOf("]", open) === -1) {
      throw new Error(`scope malformado (sem ']') em: ${line.trim()}`);
    }
    const sm = text.match(/\[scope:\s*([^\]]*)\]/i);
    tasks.push({ label, scope: sm ? parseScope(sm[1]) : [] });
  }
  return tasks;
}

function partition(tasksPath) {
  let md;
  try { md = readFileSync(tasksPath, "utf8"); }
  catch { console.error(`✗ não consegui ler ${tasksPath}`); process.exit(1); }

  let tasks;
  try { tasks = parseTasks(md); }
  catch (e) { console.error(`✗ ${e.message}`); process.exit(1); }

  if (!tasks.length) { console.log("Sem tasks de checklist em tasks.md — nada a particionar."); process.exit(0); }

  const batches = [];
  let cur = null;
  for (const t of tasks) {
    if (isBroad(t.scope)) { cur = null; batches.push([t]); continue; } // solo
    if (cur && cur.length < MAX && cur.every((o) => !scopesOverlap(o.scope, t.scope))) cur.push(t);
    else { cur = [t]; batches.push(cur); }
  }

  console.log("\nPartição de tasks para dispatch-parallel\n");
  let parallel = 0;
  batches.forEach((b, i) => {
    const tag = b.length > 1 ? `paralelo ×${b.length}` : "sozinho";
    if (b.length > 1) parallel++;
    console.log(`  Batch ${i + 1} (${tag}): ${b.map((t) => t.label).join(", ")}`);
    for (const t of b) console.log(`      ${t.label}: ${t.scope.length ? t.scope.join(", ") : "(sem scope)"}`);
  });
  console.log(`\n  ${batches.length} batch(es), ${parallel} paralelizável(is) (max ${MAX}/batch).`);
  if (!parallel) console.log("  Nenhum batch >1 — sem ganho paralelo; use dispatch sequencial.");
  console.log("");
  process.exit(0);
}

function check(scopeRaw, files) {
  const scope = parseScope(scopeRaw);
  if (!scope.length) { console.error("✗ check exige um scope não-vazio como 1º argumento"); process.exit(1); }
  const outside = files.map(norm).filter((f) => !fileInScope(f, scope));
  if (outside.length) {
    console.error(`\n✗ ${outside.length} arquivo(s) fora do scope declarado [${scope.join(", ")}]:`);
    for (const f of outside) console.error(`    ${f}`);
    console.error("");
    process.exit(1);
  }
  console.log(`✓ ${files.length} arquivo(s) dentro do scope [${scope.join(", ")}].`);
  process.exit(0);
}

const [mode, ...rest] = process.argv.slice(2);
if (mode === "partition") partition(rest[0] || "tasks.md");
else if (mode === "check") check(rest[0] || "", rest.slice(1));
else {
  console.error("uso: validate-parallel-scope.mjs partition <tasks.md>");
  console.error("     validate-parallel-scope.mjs check \"<glob, glob>\" <arquivo>...");
  process.exit(2);
}
