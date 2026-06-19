#!/usr/bin/env node
// SessionStart hook: inject the project constitution as additional context.
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { readEvent } from "./_lib.mjs";

const ev = await readEvent();
const cwd = ev.cwd || process.cwd();
const path = join(cwd, ".specify", "memory", "constitution.md");
if (!existsSync(path)) process.exit(0);
const text = readFileSync(path, "utf8");
process.stdout.write(
  JSON.stringify({
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: text,
    },
  }),
);
