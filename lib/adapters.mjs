// Adapters de cliente de IA (zero-dep, só builtins node:). O Claude Code é a FONTE
// canônica (CLAUDE.md + .claude/skills); os demais clientes são "views" geradas a partir
// dele. Views não-Claude são ADVISORY: levam instruções e skills (como commands/rules),
// mas NÃO o enforcement mecânico (gates/hooks só rodam no Claude Code).
//
// Mapa (instruções · skills):
//   Claude   CLAUDE.md                        .claude/skills/<n>/SKILL.md   (canônico, verbatim)
//   Codex    AGENTS.md                        .agents/skills/<n>/SKILL.md   (skill-dir, = Claude)
//   Cursor   .cursor/rules/sdd.mdc            .cursor/commands/<n>.md       (flat)
//   Copilot  .github/copilot-instructions.md  .github/prompts/<n>.prompt.md (flat)
//   Gemini   GEMINI.md                        .gemini/commands/<n>.toml     (flat, toml)
//   Windsurf .windsurf/rules/sdd.md           .windsurf/workflows/<n>.md    (flat)

const ADVISORY =
  "> View gerada da fonte canônica do Claude Code. O SDD aqui é **advisory**: a aplicação\n" +
  "> mecânica (gates, phase-gate, precommit) só roda no Claude Code. Não edite à mão —\n" +
  "> regenere pela fonte (`bootstrap.sh --force --agent=...`).\n\n";

// Remove o bloco de frontmatter YAML, devolvendo só o corpo.
export function stripFrontmatter(text) {
  if (!text.startsWith("---")) return text;
  const end = text.indexOf("\n---", 3);
  if (end === -1) return text;
  return text.slice(end + 4).replace(/^\s*\n/, "");
}

// Lê um SKILL.md → { name, description, body }.
export function parseSkill(text) {
  const out = { name: "", description: "", body: text };
  if (!text.startsWith("---")) return out;
  const end = text.indexOf("\n---", 3);
  if (end === -1) return out;
  const fm = text.slice(3, end);
  out.body = text.slice(end + 4).replace(/^\s*\n/, "");
  const n = fm.match(/^\s*name\s*:\s*(.+)$/m);
  const d = fm.match(/^\s*description\s*:\s*(.+)$/m);
  if (n) out.name = n[1].trim();
  if (d) out.description = d[1].trim();
  return out;
}

// Nota-ponteiro p/ clientes flat: companheiros não viram commands, vivem na fonte Claude.
function companionPointer(name, companions) {
  if (!companions.length) return "";
  const list = companions.map((c) => `\`${c.filename}\``).join(", ");
  return `\n\n> Prompts companheiros desta skill (${list}) vivem na fonte canônica do Claude:\n` +
    `> \`.claude/skills/${name}/\`.\n`;
}

// Transforms de skill (recebem o corpo já pronto, devolvem o arquivo final do cliente).
const skillAsIs = (raw) => raw; // .md simples — frontmatter é inofensivo
// Tira uma camada de aspas que cerque todo o valor (descrições de frontmatter já vêm
// citadas em algumas skills) antes de escapar — evita aspas duplicadas no toml.
const unwrapQuotes = (s) =>
  s.length >= 2 && ((s[0] === '"' && s.at(-1) === '"') || (s[0] === "'" && s.at(-1) === "'")) ? s.slice(1, -1) : s;
const skillAsToml = (raw) => {
  const { name, description, body } = parseSkill(raw);
  const desc = unwrapQuotes(description || name).replace(/\\/g, "\\\\").replace(/"/g, '\\"');
  const prompt = body.replace(/\\/g, "\\\\").replace(/"""/g, '\\"\\"\\"');
  return `description = "${desc}"\nprompt = """\n${prompt}\n"""\n`;
};

export const ADAPTERS = {
  claude: { id: "claude", label: "Claude Code", canonical: true, hint: "CLAUDE.md + .claude/" },
  codex: {
    id: "codex", label: "OpenAI Codex",
    instructions: { to: "AGENTS.md", frontmatter: "strip" },
    skills: { dir: ".agents/skills", layout: "skill-dir" },
  },
  cursor: {
    id: "cursor", label: "Cursor",
    instructions: { to: ".cursor/rules/sdd.mdc", frontmatter: "strip" },
    skills: { dir: ".cursor/commands", layout: "flat", ext: "md", transform: skillAsIs },
  },
  copilot: {
    id: "copilot", label: "GitHub Copilot",
    instructions: { to: ".github/copilot-instructions.md", frontmatter: "strip" },
    skills: { dir: ".github/prompts", layout: "flat", ext: "prompt.md", transform: skillAsIs },
  },
  gemini: {
    id: "gemini", label: "Gemini CLI",
    instructions: { to: "GEMINI.md", frontmatter: "strip" },
    skills: { dir: ".gemini/commands", layout: "flat", ext: "toml", transform: skillAsToml },
  },
  windsurf: {
    id: "windsurf", label: "Windsurf",
    instructions: { to: ".windsurf/rules/sdd.md", frontmatter: "strip" },
    skills: { dir: ".windsurf/workflows", layout: "flat", ext: "md", transform: skillAsIs },
  },
};

export const ALL_AGENTS = Object.values(ADAPTERS);
export const EXTRA_AGENTS = ALL_AGENTS.filter((a) => !a.canonical);
export const isValidAgent = (id) => Object.prototype.hasOwnProperty.call(ADAPTERS, id);

// Conteúdo do arquivo de instruções de um adapter, a partir do CLAUDE.md canônico:
// strip de frontmatter (no-op no nosso CLAUDE.md), banner advisory e refs de skills reapontadas.
export function emitInstructions(adapter, claudeMd) {
  const body = adapter.instructions.frontmatter === "strip" ? stripFrontmatter(claudeMd) : claudeMd;
  const reaimed = body.split(".claude/skills").join(adapter.skills.dir);
  return ADVISORY + reaimed;
}

// Plano de emissão de UM adapter extra: lista de { rel, content } a gravar.
// `skills` = [{ name, skillRaw, companions: [{ filename, raw }] }].
export function emitFor(adapter, claudeMd, skills) {
  const out = [{ rel: adapter.instructions.to, content: emitInstructions(adapter, claudeMd) }];
  for (const { name, skillRaw, companions = [] } of skills) {
    if (adapter.skills.layout === "skill-dir") {
      out.push({ rel: `${adapter.skills.dir}/${name}/SKILL.md`, content: skillRaw });
      for (const c of companions) out.push({ rel: `${adapter.skills.dir}/${name}/${c.filename}`, content: c.raw });
    } else {
      const body = skillRaw + companionPointer(name, companions);
      out.push({ rel: `${adapter.skills.dir}/${name}.${adapter.skills.ext}`, content: adapter.skills.transform(body) });
    }
  }
  return out;
}
