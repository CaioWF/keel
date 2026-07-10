#!/usr/bin/env node
// okf-build-index — Generate and validate OKF bundle index.md files
// Zero-dependency: node: builtins only. Never throws uncaught.
import { existsSync, readFileSync, writeFileSync, readdirSync } from "node:fs";
import { join, relative, posix } from "node:path";

// Minimal frontmatter parse: key:value lines inside the leading --- ... --- block.
function frontmatter(text) {
  if (!text.startsWith("---")) return null;
  const end = text.indexOf("\n---", 3);
  if (end < 0) return null;
  const fm = {};
  for (const line of text.slice(3, end).split("\n")) {
    const m = line.match(/^([A-Za-z0-9_-]+):\s*(.+?)\s*$/);
    if (m) fm[m[1]] = m[2].replace(/^["']|["']$/g, "");
  }
  return fm;
}

// Recursive walk for .md files
function* walk(dir) {
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const e of entries) {
    if (e.isDirectory()) {
      if ([".git", "node_modules"].includes(e.name)) continue;
      yield* walk(join(dir, e.name));
    } else if (e.name.endsWith(".md")) {
      yield join(dir, e.name);
    }
  }
}

// Generate the exact index.md contents for a bundle
function generate(bundleDir) {
  const concepts = [];

  // Walk bundleDir for typed .md files (skip index.md and log.md)
  for (const filePath of walk(bundleDir)) {
    const fileName = filePath.split("/").pop();
    if (fileName === "index.md" || fileName === "log.md") continue;

    let text;
    try {
      text = readFileSync(filePath, "utf8");
    } catch {
      continue;
    }

    const fm = frontmatter(text);
    if (!fm || !fm.type) continue;

    // Extract relative path with posix separators
    const relPath = posix.normalize(relative(bundleDir, filePath).replace(/\\/g, "/"));
    const title = fm.title || fm.name || relPath.replace(/\.md$/, "");
    const description = fm.description || "";

    concepts.push({
      type: fm.type,
      title,
      description,
      path: relPath,
    });
  }

  // Sort by type, then by path
  concepts.sort((a, b) => {
    if (a.type !== b.type) return a.type.localeCompare(b.type);
    return a.path.localeCompare(b.path);
  });

  // Build index.md string
  const lines = [];
  lines.push("---");
  lines.push('okf_version: "0.1"');
  lines.push("---");
  lines.push("");

  // Group by type
  const byType = {};
  for (const c of concepts) {
    if (!byType[c.type]) byType[c.type] = [];
    byType[c.type].push(c);
  }

  // Emit sections in sorted type order
  const sortedTypes = Object.keys(byType).sort();
  for (const type of sortedTypes) {
    lines.push(`# ${type}`);
    for (const c of byType[type]) {
      if (c.description) {
        lines.push(`* [${c.title}](${c.path}) - ${c.description}`);
      } else {
        lines.push(`* [${c.title}](${c.path})`);
      }
    }
    lines.push("");
  }

  // Join with newlines; ensure exactly one trailing newline
  return lines.join("\n");
}

// Commands
async function main() {
  const [mode, bundleDir] = process.argv.slice(2);

  if (!mode || !bundleDir) {
    console.error("Usage: okf-build-index.mjs <build|check> <bundleDir>");
    process.exit(2);
  }

  if (mode === "build") {
    const indexPath = join(bundleDir, "index.md");
    const content = generate(bundleDir);
    try {
      writeFileSync(indexPath, content, "utf8");
      // Count concepts (lines that start with *)
      const conceptCount = content.split("\n").filter((l) => l.startsWith("*")).length;
      console.log(`✓ wrote ${bundleDir}/index.md (${conceptCount} concepts)`);
      process.exit(0);
    } catch (err) {
      console.error(`✗ failed to write ${indexPath}: ${err.message}`);
      process.exit(1);
    }
  } else if (mode === "check") {
    const indexPath = join(bundleDir, "index.md");

    // Check if index.md exists and has okf_version
    if (!existsSync(indexPath)) {
      console.log(`okf-index: ${bundleDir} not an OKF bundle (no index.md w/ okf_version) — skipping`);
      process.exit(0);
    }

    let indexContent;
    try {
      indexContent = readFileSync(indexPath, "utf8");
    } catch {
      console.log(`okf-index: ${bundleDir} not an OKF bundle (no index.md w/ okf_version) — skipping`);
      process.exit(0);
    }

    const indexFm = frontmatter(indexContent);
    if (!indexFm || !indexFm.okf_version) {
      console.log(`okf-index: ${bundleDir} not an OKF bundle (no index.md w/ okf_version) — skipping`);
      process.exit(0);
    }

    // Compare byte-for-byte
    const expected = generate(bundleDir);
    if (indexContent === expected) {
      console.log(`✓ ${bundleDir}/index.md up to date`);
      process.exit(0);
    } else {
      console.log(`✗ ${bundleDir}/index.md is stale — run: node core/gates/okf-build-index.mjs build ${bundleDir}`);
      process.exit(1);
    }
  } else {
    console.error("Usage: okf-build-index.mjs <build|check> <bundleDir>");
    process.exit(2);
  }
}

main().catch((err) => {
  console.error(`Unexpected error: ${err.message}`);
  process.exit(1);
});
