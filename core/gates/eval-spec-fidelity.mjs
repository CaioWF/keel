#!/usr/bin/env node
// Eval de fidelidade spec→implementação (zero-dep, só builtins node:).
// Para cada specs/NNNN-*/ que JÁ TEM tasks.md: cada AC-N declarado na spec precisa estar
// coberto por uma task (token AC-N em tasks.md). AC sem task => rastreabilidade quebrada (exit 1).
// AC sem referência em código/teste (token AC-N no código) => aviso, não bloqueia.
// Features ainda na fase de spec (sem tasks.md) são puladas — o gate só vale após o tasks-writer.
// SPEC_DEVIATION no código é contado e reportado (marcador de divergência consciente).
// Uso: node eval-spec-fidelity.mjs [dir]   (default: ".")
import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join, resolve, extname } from "node:path";

const ROOT = resolve(process.argv[2] || ".");
const SKIP = new Set(["node_modules", ".git", ".claude", ".specify", "specs", "docs", "scripts"]);
const CODE_EXT = new Set([".js", ".mjs", ".cjs", ".ts", ".tsx", ".jsx", ".py", ".go", ".java", ".rb", ".php", ".cs", ".rs", ".kt", ".swift", ".sql", ".feature"]);

function walkCode(dir) {
  const out = [];
  for (const n of readdirSync(dir)) {
    if (SKIP.has(n) || n.startsWith(".tmp")) continue;
    const f = join(dir, n);
    let st;
    try { st = statSync(f); } catch { continue; }
    if (st.isDirectory()) out.push(...walkCode(f));
    else if (CODE_EXT.has(extname(f))) out.push(f);
  }
  return out;
}

const acTokens = (s) => new Set(s.match(/AC-\d+/g) || []);

const specsDir = join(ROOT, "specs");
if (!existsSync(specsDir)) { console.log("Sem specs/ — nada a avaliar."); process.exit(0); }

let codeBlob = "";
try { for (const f of walkCode(ROOT)) codeBlob += "\n" + readFileSync(f, "utf8"); } catch {}
const codeACs = acTokens(codeBlob);
const deviations = (codeBlob.match(/SPEC_DEVIATION/g) || []).length;

let hardFail = 0;
const rows = [];
for (const name of readdirSync(specsDir)) {
  if (!/^\d+-/.test(name)) continue; // aceita NNN- (skills) e NNNN- (qualquer nº de dígitos)
  const dir = join(specsDir, name);
  if (!existsSync(join(dir, "spec.md"))) continue;
  const acs = [...acTokens(readFileSync(join(dir, "spec.md"), "utf8"))].sort();
  if (!acs.length) continue;
  if (!existsSync(join(dir, "tasks.md"))) { rows.push({ name, acs, pending: true }); continue; }
  const taskACs = acTokens(readFileSync(join(dir, "tasks.md"), "utf8"));
  const uncovered = acs.filter((ac) => !taskACs.has(ac));
  const noTest = acs.filter((ac) => !codeACs.has(ac));
  hardFail += uncovered.length;
  rows.push({ name, acs, byTask: acs.length - uncovered.length, byTest: acs.length - noTest.length, uncovered, noTest });
}

console.log("\nEval de fidelidade spec→implementação\n");
for (const r of rows) {
  console.log(`  ${r.name}`);
  if (r.pending) { console.log(`    AC: ${r.acs.length} · sem tasks.md ainda (fase de spec) — rastreabilidade não exigida`); continue; }
  console.log(`    AC: ${r.acs.length} · por task: ${r.byTask}/${r.acs.length} · em código/teste: ${r.byTest}/${r.acs.length}`);
  if (r.uncovered.length) console.log(`    ✗ AC sem task (rastreabilidade): ${r.uncovered.join(", ")}`);
  if (r.noTest.length) console.log(`    ⚠ AC sem referência em código/teste: ${r.noTest.join(", ")}`);
}
console.log(`\n  SPEC_DEVIATION abertos no código: ${deviations}`);

if (hardFail) {
  console.error(`\n✗ ${hardFail} AC sem cobertura de task — rastreabilidade quebrada.\n`);
  process.exit(1);
}
console.log(`\n✓ Rastreabilidade spec→task OK (referência em teste é aviso até implementar).\n`);
