#!/usr/bin/env node
// Gera as views de clientes extras a partir da fonte canônica JÁ INSTALADA no target
// (CLAUDE.md + .claude/skills/<n>/, incl. arquivos companheiros). Zero-dep.
// Uso: node emit-views.mjs --dir <target> --agents codex,cursor[,...] [--version <v>]
import { readFileSync, writeFileSync, readdirSync, statSync, lstatSync, existsSync, mkdirSync, unlinkSync } from "node:fs";
import { join, dirname } from "node:path";
import { ADAPTERS, isValidAgent, emitFor } from "./adapters.mjs";

function parseArgs(argv) {
  const out = { dir: ".", agents: [], version: "" };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--dir") out.dir = argv[++i];
    else if (argv[i] === "--agents") out.agents = (argv[++i] || "").split(",").map((s) => s.trim()).filter(Boolean);
    else if (argv[i] === "--version") out.version = argv[++i] || "";
  }
  return out;
}

// Lê as skills canônicas do target: [{ name, skillRaw, companions: [{ filename, raw }] }].
function readSkills(dir) {
  const base = join(dir, ".claude", "skills");
  if (!existsSync(base)) return [];
  const out = [];
  for (const name of readdirSync(base)) {
    const skillDir = join(base, name);
    if (!statSync(skillDir).isDirectory()) continue;
    const skillFile = join(skillDir, "SKILL.md");
    if (!existsSync(skillFile)) continue;
    const companions = [];
    for (const f of readdirSync(skillDir)) {
      if (f === "SKILL.md") continue;
      const full = join(skillDir, f);
      if (statSync(full).isFile()) companions.push({ filename: f, raw: readFileSync(full, "utf8") });
    }
    out.push({ name, skillRaw: readFileSync(skillFile, "utf8"), companions });
  }
  return out;
}

// Grava destruindo symlink se houver (p/ não escrever ATRAVÉS do AGENTS.md → CLAUDE.md).
function writeOut(dir, rel, content) {
  const dest = join(dir, rel);
  mkdirSync(dirname(dest), { recursive: true });
  try { if (lstatSync(dest).isSymbolicLink()) unlinkSync(dest); } catch {}
  writeFileSync(dest, content);
}

const { dir, agents, version } = parseArgs(process.argv.slice(2));
const claudeMd = join(dir, "CLAUDE.md");
if (!existsSync(claudeMd)) { console.error(`[emit-views] sem CLAUDE.md em ${dir} — rode o install core antes.`); process.exit(1); }

const claudeText = readFileSync(claudeMd, "utf8");
const skills = readSkills(dir);

const selected = [...new Set(agents.filter(isValidAgent))];
const extras = selected.filter((id) => id !== "claude");
let written = 0;
for (const id of extras) {
  for (const { rel, content } of emitFor(ADAPTERS[id], claudeText, skills)) {
    writeOut(dir, rel, content);
    written++;
  }
}

// Manifesto: registra todos os clientes do projeto (claude sempre presente como fonte).
const manifestAgents = [...new Set(["claude", ...selected])];
writeOut(dir, ".specify/clients.json", JSON.stringify({ version, agents: manifestAgents }, null, 2) + "\n");

console.log(`[emit-views] ${written} arquivo(s) de view gerados para: ${extras.join(", ") || "(nenhum extra)"}`);
