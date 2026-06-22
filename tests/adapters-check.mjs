// Assert runner for lib/adapters.mjs — invoked by tests/test-adapters.sh.
// Prints "ADAPTERS OK" and exits 0 on success; prints FAIL lines and exits 1 otherwise.
import { ADAPTERS, EXTRA_AGENTS, isValidAgent, emitInstructions, emitFor, parseSkill, stripFrontmatter } from "../lib/adapters.mjs";

let failed = 0;
const ok = (cond, msg) => { if (!cond) { console.error(`FAIL: ${msg}`); failed++; } };

const SKILL = "---\nname: foo\ndescription: does \"foo\"\n---\nbody line\n";
const COMP = { filename: "impl-prompt.md", raw: "# impl\nprompt body\n" };

// registry shape
ok(EXTRA_AGENTS.length === 5, "5 extra agents");
ok(isValidAgent("gemini") && !isValidAgent("bogus"), "isValidAgent");
ok(ADAPTERS.claude.canonical === true, "claude is canonical");

// stripFrontmatter / parseSkill
ok(stripFrontmatter(SKILL).startsWith("body line"), "stripFrontmatter drops fm");
const ps = parseSkill(SKILL);
ok(ps.name === "foo" && ps.description.includes("foo") && ps.body.startsWith("body line"), "parseSkill fields");

// emitInstructions: advisory banner + reaimed skill refs, codex
const ins = emitInstructions(ADAPTERS.codex, "# inst\nsee .claude/skills/foo for x\n");
ok(/advisory/i.test(ins), "instructions carry advisory banner");
ok(ins.includes(".agents/skills/foo"), "instructions reaim skill refs to client dir");
ok(!ins.includes(".claude/skills"), "instructions drop .claude/skills refs");

// emitFor codex (skill-dir): SKILL.md + companion both emitted verbatim
const codex = emitFor(ADAPTERS.codex, "# i\n", [{ name: "foo", skillRaw: SKILL, companions: [COMP] }]);
const codexRels = codex.map((e) => e.rel);
ok(codexRels.includes(".agents/skills/foo/SKILL.md"), "codex emits SKILL.md");
ok(codexRels.includes(".agents/skills/foo/impl-prompt.md"), "codex copies companion");
ok(codex.find((e) => e.rel === ".agents/skills/foo/SKILL.md").content === SKILL, "codex SKILL.md verbatim");

// emitFor gemini (flat toml): single command file, companion dropped + pointer, valid-ish toml
const gem = emitFor(ADAPTERS.gemini, "# i\n", [{ name: "foo", skillRaw: SKILL, companions: [COMP] }]);
ok(gem.length === 2, "gemini emits instructions + 1 command only (companion not a file)");
const gcmd = gem.find((e) => e.rel === ".gemini/commands/foo.toml");
ok(!!gcmd, "gemini command path is toml");
ok(gcmd.content.startsWith('description = "'), "gemini toml has description");
ok(gcmd.content.includes('prompt = """'), "gemini toml has prompt block");
ok(gcmd.content.includes('\\"foo\\"'), "gemini toml escapes quotes in description");
ok(/companheiros/.test(gcmd.content), "gemini flat carries companion pointer");

// gemini toml: a frontmatter description already wrapped in quotes is not doubled
const QSKILL = '---\nname: bar\ndescription: "You MUST do bar"\n---\nbody\n';
const gem2 = emitFor(ADAPTERS.gemini, "# i\n", [{ name: "bar", skillRaw: QSKILL, companions: [] }]);
const g2 = gem2.find((e) => e.rel === ".gemini/commands/bar.toml").content;
ok(g2.includes('description = "You MUST do bar"'), "gemini toml unwraps a quoted description");
ok(!g2.includes('\\"You MUST'), "gemini toml does not double-quote a wrapped description");

// emitFor cursor (flat md, as-is)
const cur = emitFor(ADAPTERS.cursor, "# i\n", [{ name: "foo", skillRaw: SKILL, companions: [] }]);
ok(cur.some((e) => e.rel === ".cursor/commands/foo.md"), "cursor command path is md");
ok(cur.find((e) => e.rel === ".cursor/rules/sdd.mdc"), "cursor instructions path");

if (failed) { console.error(`\n${failed} adapter assertion(s) failed`); process.exit(1); }
console.log("ADAPTERS OK");
