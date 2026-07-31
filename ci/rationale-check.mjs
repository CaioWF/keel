#!/usr/bin/env node
// Server-side rationale check for the keel repo itself.
//
// keel's phase-gate hook (core/claude/hooks/phase-gate.mjs) refuses code edits
// until an approved plan exists — but hooks live in .claude/ on one machine and
// only fire inside Claude Code. Anything pushed from a plain git client, another
// machine, or the GitHub web UI bypasses every gate keel ships. This is the
// server-side half: it runs in CI, where nobody can skip it.
//
// keel does not bootstrap itself, so there is no specs/<feature>/plan.md to key
// on. The repo's real convention is docs/{design-notes,plans,specs} — 15 design
// notes and counting. So the rule is that convention, enforced: a change to the
// shipped payload must arrive with the reasoning that justifies it.
//
// Deliberately NOT in core/gates/: bootstrap copies that tree into every project
// and this check only makes sense for keel's own layout. Shipping it there would
// plant the same dead seam as ts-clean-arch (bootstrap.sh:169-178).
//
// Usage:
//   node ci/rationale-check.mjs --base <ref> --head <ref> [--labels a,b]
//   node ci/rationale-check.mjs --files <path>  [--messages <path>] [--labels a,b]
//
// --files/--messages take precedence over git and make the rules testable
// without a repository. Exit 0 = pass, 1 = missing rationale.

import { existsSync, readFileSync } from "node:fs";
import { execFileSync } from "node:child_process";

// Paths whose change is a change to what keel ships.
const WATCHED = ["core/", "lib/", "bootstrap.sh"];
// Paths that record why. Any one of them satisfies the check.
const RATIONALE = ["docs/design-notes/", "docs/plans/", "docs/specs/"];
// The declared door, in both forms the repo's two flows can express.
const TRIVIAL_LABEL = "trivial";
const TRIVIAL_TRAILER = "[trivial]";

function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith("--")) out[a.slice(2)] = argv[i + 1]?.startsWith("--") ? "" : (argv[++i] ?? "");
  }
  return out;
}

function readList(path) {
  if (!path || !existsSync(path)) return [];
  return readFileSync(path, "utf8").split("\n").map((s) => s.trim()).filter(Boolean);
}

function git(args, dir) {
  return execFileSync("git", args, { cwd: dir, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] });
}

// A ref git cannot resolve is not a violation. First push of a branch sends an
// all-zero "before", and a force-push leaves one unreachable — failing there
// would block on CI plumbing rather than on discipline, which is how a gate
// teaches people to ignore it.
function resolvable(ref, dir) {
  if (!ref || /^0{7,40}$/.test(ref)) return false;
  try {
    git(["cat-file", "-e", `${ref}^{commit}`], dir);
    return true;
  } catch {
    return false;
  }
}

const args = parseArgs(process.argv.slice(2));
const dir = args.dir || process.cwd();
const labels = (args.labels || "").split(",").map((s) => s.trim().toLowerCase()).filter(Boolean);

let files = readList(args.files);
let messages = args.messages ? readList(args.messages).join("\n") : "";

if (!args.files) {
  const { base, head = "HEAD" } = args;
  if (!resolvable(base, dir)) {
    console.log(`rationale: base ref '${base || "(none)"}' not resolvable — skipping (no diff to judge)`);
    process.exit(0);
  }
  files = git(["diff", "--name-only", `${base}...${head}`], dir).split("\n").map((s) => s.trim()).filter(Boolean);
  messages = git(["log", "--format=%B", `${base}..${head}`], dir);
}

const touched = files.filter((f) => WATCHED.some((w) => f.startsWith(w)));
if (touched.length === 0) {
  console.log("rationale: no shipped-payload change — nothing to justify");
  process.exit(0);
}

const rationale = files.filter((f) => RATIONALE.some((r) => f.startsWith(r)));
if (rationale.length > 0) {
  const shown = rationale.slice(0, 3).join(", ");
  const rest = rationale.length > 3 ? ` (+${rationale.length - 3} more)` : "";
  console.log(`rationale: ${touched.length} payload file(s) changed, justified by ${shown}${rest}`);
  process.exit(0);
}
if (labels.includes(TRIVIAL_LABEL)) {
  console.log(`rationale: '${TRIVIAL_LABEL}' label present — declared trivial, allowed`);
  process.exit(0);
}
if (messages.includes(TRIVIAL_TRAILER)) {
  console.log(`rationale: '${TRIVIAL_TRAILER}' in a commit message — declared trivial, allowed`);
  process.exit(0);
}

// Announce the door. A hatch nobody knows about is a hatch that does not exist
// (measured in docs/design-notes/over-constraint-audit.md).
console.error(`rationale: keel payload changed with no recorded reasoning.

Changed:
${touched.map((f) => `  ${f}`).join("\n")}

Add one of:
${RATIONALE.map((r) => `  ${r}<note>.md`).join("\n")}

Or declare it trivial:
  pull request -> add the '${TRIVIAL_LABEL}' label
  direct push  -> put ${TRIVIAL_TRAILER} in a commit message`);
process.exit(1);
