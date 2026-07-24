// AI client adapters (zero-dep, node: builtins only). Claude Code is the canonical
// SOURCE (CLAUDE.md + .claude/skills); the other clients are "views" generated from
// it. Non-Claude views are ADVISORY: they carry instructions and skills (as commands/rules),
// but NOT the mechanical enforcement (gates/hooks only run in Claude Code).
//
// Map (instructions · skills):
//   Claude   CLAUDE.md                        .claude/skills/<n>/SKILL.md   (canônico, verbatim)
//   Codex    AGENTS.md                        .agents/skills/<n>/SKILL.md   (skill-dir, = Claude)
//   Cursor   .cursor/rules/sdd.mdc            .cursor/commands/<n>.md       (flat)
//   Copilot  .github/copilot-instructions.md  .github/prompts/<n>.prompt.md (flat)
//   Gemini   GEMINI.md                        .gemini/commands/<n>.toml     (flat, toml)
//   Windsurf .windsurf/rules/sdd.md           .windsurf/workflows/<n>.md    (flat)

const ADVISORY =
  "> View generated from the Claude Code canonical source. The SDD here is **advisory**: the\n" +
  "> mechanical enforcement (gates, phase-gate, precommit) only runs in Claude Code. Do not edit by hand —\n" +
  "> regenerate from the source (`bootstrap.sh --force --agent=...`).\n\n";

// Strips the YAML frontmatter block, returning only the body.
export function stripFrontmatter(text) {
  if (!text.startsWith("---")) return text;
  const end = text.indexOf("\n---", 3);
  if (end === -1) return text;
  return text.slice(end + 4).replace(/^\s*\n/, "");
}

// Reads a SKILL.md → { name, description, body }.
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

// Pointer note for flat clients: companion files don't become commands, they live in the Claude source.
function companionPointer(name, companions) {
  if (!companions.length) return "";
  const list = companions.map((c) => `\`${c.filename}\``).join(", ");
  return `\n\n> Companion prompts for this skill (${list}) live in the Claude canonical source:\n` +
    `> \`.claude/skills/${name}/\`.\n`;
}

// Skill transforms (receive the already-prepared body, return the client's final file).
const skillAsIs = (raw) => raw; // plain .md — frontmatter is harmless
// Strips a layer of quotes surrounding the whole value (frontmatter descriptions already come
// quoted in some skills) before escaping — avoids duplicated quotes in the toml.
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

// Content of an adapter's instructions file, derived from the canonical CLAUDE.md:
// frontmatter strip (no-op on our CLAUDE.md), advisory banner, and re-aimed skill refs.
export function emitInstructions(adapter, claudeMd) {
  const body = adapter.instructions.frontmatter === "strip" ? stripFrontmatter(claudeMd) : claudeMd;
  const reaimed = body.split(".claude/skills").join(adapter.skills.dir);
  return ADVISORY + reaimed;
}

// Emission plan for ONE extra adapter: list of { rel, content } to write.
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
