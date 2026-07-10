#!/usr/bin/env node
// OKF bundle visualizer: reads .md files with `type:` frontmatter and renders
// an interactive force-directed graph as self-contained HTML (zero external deps).
// Usage: node okf-visualize.mjs <bundleDir> [--out <file>]

import { existsSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { join, relative, basename, dirname, resolve } from "node:path";

const bundleDir = process.argv[2];
const outIdx = process.argv.indexOf("--out");
const outFile = outIdx >= 0 ? process.argv[outIdx + 1] : null;

if (!bundleDir) {
  console.error("Usage: node okf-visualize.mjs <bundleDir> [--out <file>]");
  process.exit(1);
}

const SKIP = new Set([".git", "node_modules", ".specify", ".agents", ".cursor"]);
const RESERVED = new Set(["index.md", "log.md"]);

// Minimal frontmatter parse: extract key: value lines from --- ... --- block
function parseFrontmatter(text) {
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

// Recursive walk: yield all .md files
function* walk(dir) {
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const e of entries) {
    if (e.isDirectory()) {
      if (SKIP.has(e.name)) continue;
      yield* walk(join(dir, e.name));
    } else if (e.name.endsWith(".md")) {
      yield join(dir, e.name);
    }
  }
}

// Resolve a link target relative to a source file to bundle-relative posix path
function resolveLink(sourcePath, target, bundleDir) {
  try {
    const sourceDir = dirname(sourcePath);
    const resolved = resolve(sourceDir, target);
    const bundleResolved = resolve(bundleDir);

    // Must be within bundle
    if (!resolved.startsWith(bundleResolved)) return null;

    // Normalize to posix bundle-relative path
    const rel = relative(bundleResolved, resolved).replace(/\\/g, "/");
    return rel.endsWith(".md") ? rel : rel + ".md";
  } catch {
    return null;
  }
}

// Extract node IDs from markdown links ](<target>) and wiki-links [[<name>]]
function extractLinks(text, sourceId, nodes, bundleDir, sourceFilePath) {
  const edges = [];
  const nodeMap = new Map();

  // Build lookup map: id -> node, label -> node, basename -> node
  for (const node of nodes) {
    nodeMap.set(node.id, node);
    if (node.label) nodeMap.set(node.label, node);
    const baseName = node.id.split("/").pop().replace(/\.md$/, "");
    nodeMap.set(baseName, node);
  }

  // Markdown links: ](<target>)
  for (const m of text.matchAll(/\]\(([^)]+)\)/g)) {
    const target = m[1].trim().split("#")[0]; // strip anchor
    if (!target || /^(https?:|mailto:|ftp:)/.test(target)) continue; // skip absolute URLs
    const resolved = resolveLink(sourceFilePath, target, bundleDir);
    if (resolved && nodeMap.has(resolved) && resolved !== sourceId) {
      edges.push([sourceId, resolved]);
    }
  }

  // Wiki-links: [[<name>]]
  for (const m of text.matchAll(/\[\[([^\]]+)\]\]/g)) {
    const name = m[1].trim();
    if (nodeMap.has(name)) {
      const targetNode = nodeMap.get(name);
      if (targetNode.id !== sourceId) {
        edges.push([sourceId, targetNode.id]);
      }
    }
  }

  return edges;
}

// Main: collect nodes and edges
const bundleResolved = resolve(bundleDir);
if (!existsSync(bundleResolved)) {
  console.error(`Bundle directory not found: ${bundleDir}`);
  process.exit(1);
}

const nodes = [];
const nodeMap = new Map(); // id -> node

// First pass: collect all concepts
for (const path of walk(bundleResolved)) {
  if (RESERVED.has(basename(path))) continue;

  let text;
  try {
    text = readFileSync(path, "utf8");
  } catch {
    continue;
  }

  const fm = parseFrontmatter(text);
  if (!fm || !fm.type) continue;

  const id = relative(bundleResolved, path).replace(/\\/g, "/");
  const label = fm.title || basename(path).replace(/\.md$/, "");
  const description = fm.description || "";

  const node = { id, label, type: fm.type, description };
  nodes.push(node);
  nodeMap.set(id, node);
}

// Second pass: extract edges
const edgeSet = new Set();
for (const path of walk(bundleResolved)) {
  if (RESERVED.has(basename(path))) continue;

  let text;
  try {
    text = readFileSync(path, "utf8");
  } catch {
    continue;
  }

  const fm = parseFrontmatter(text);
  if (!fm || !fm.type) continue;

  const id = relative(bundleResolved, path).replace(/\\/g, "/");
  const links = extractLinks(text, id, nodes, bundleResolved, path);

  for (const [source, target] of links) {
    // Dedup and skip self-edges
    if (source === target) continue;
    const edgeKey = source < target ? `${source}|${target}` : `${target}|${source}`;
    edgeSet.add(edgeKey);
  }
}

const edges = Array.from(edgeSet).map(key => {
  const [source, target] = key.split("|");
  return { source, target };
});

// Determine output file
const out = outFile || join(bundleResolved, "okf-graph.html");

// Generate self-contained HTML
const colorPalette = [
  "#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8",
  "#F7DC6F", "#BB8FCE", "#85C1E2", "#F8B88B", "#52C0A1",
];

// Build type -> color map (sorted by type name for determinism)
const typeList = [...new Set(nodes.map(n => n.type))].sort();
const typeToColor = {};
for (let i = 0; i < typeList.length; i++) {
  typeToColor[typeList[i]] = colorPalette[i % colorPalette.length];
}

const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>OKF Graph - ${basename(bundleResolved)}</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: #f5f5f5;
      color: #333;
    }
    @media (prefers-color-scheme: dark) {
      body { background: #1a1a1a; color: #e0e0e0; }
      #info { background: #2a2a2a; border-color: #444; }
      #legend { background: #2a2a2a; border-color: #444; }
    }
    .container {
      display: flex;
      height: 100vh;
    }
    #canvas {
      flex: 1;
      background: #ffffff;
      cursor: grab;
    }
    @media (prefers-color-scheme: dark) {
      #canvas { background: #222; }
    }
    #sidebar {
      width: 280px;
      overflow-y: auto;
      background: #fafafa;
      border-left: 1px solid #ddd;
      display: flex;
      flex-direction: column;
    }
    @media (prefers-color-scheme: dark) {
      #sidebar { background: #1a1a1a; border-color: #444; }
    }
    #info {
      padding: 16px;
      background: #f0f0f0;
      border-bottom: 1px solid #ddd;
      flex-shrink: 0;
    }
    @media (prefers-color-scheme: dark) {
      #info { background: #2a2a2a; border-color: #444; }
    }
    #info h2 { font-size: 14px; margin-bottom: 8px; }
    #info p { font-size: 12px; line-height: 1.4; }
    #legend {
      padding: 16px;
      background: #f0f0f0;
      border-bottom: 1px solid #ddd;
      font-size: 12px;
      max-height: 200px;
      overflow-y: auto;
      flex-shrink: 0;
    }
    @media (prefers-color-scheme: dark) {
      #legend { background: #2a2a2a; border-color: #444; }
    }
    .legend-item {
      display: flex;
      align-items: center;
      margin-bottom: 6px;
    }
    .legend-color {
      width: 12px;
      height: 12px;
      border-radius: 2px;
      margin-right: 8px;
      flex-shrink: 0;
    }
    .empty { text-align: center; padding: 20px; color: #999; }
  </style>
</head>
<body>
  <div class="container">
    <canvas id="canvas"></canvas>
    <div id="sidebar">
      <div id="legend">
        <strong>Types:</strong>
      </div>
      <div id="info">
        <p class="empty">Click or hover a node</p>
      </div>
    </div>
  </div>

  <script>
    // Embedded data
    const DATA = {
      nodes: ${JSON.stringify(nodes)},
      edges: ${JSON.stringify(edges)},
      typeToColor: ${JSON.stringify(typeToColor)},
    };

    const canvas = document.getElementById('canvas');
    const ctx = canvas.getContext('2d');
    const infoPane = document.getElementById('info');
    const legend = document.getElementById('legend');

    // Set canvas size
    function resizeCanvas() {
      canvas.width = canvas.offsetWidth;
      canvas.height = canvas.offsetHeight;
    }
    resizeCanvas();
    window.addEventListener('resize', resizeCanvas);

    // Simple physics simulation
    const sim = {
      nodes: DATA.nodes.map(n => ({
        ...n,
        x: Math.random() * canvas.width,
        y: Math.random() * canvas.height,
        vx: 0,
        vy: 0,
      })),
      edges: DATA.edges,
      friction: 0.99,
      repulsion: 100,
      springK: 0.1,
      springLen: 100,
    };

    let selectedNodeId = null;

    function step() {
      const nodes = sim.nodes;

      // Reset forces
      for (const n of nodes) { n.fx = 0; n.fy = 0; }

      // Repulsion between all nodes
      for (let i = 0; i < nodes.length; i++) {
        for (let j = i + 1; j < nodes.length; j++) {
          const a = nodes[i], b = nodes[j];
          const dx = b.x - a.x || 0.01;
          const dy = b.y - a.y || 0.01;
          const dist = Math.hypot(dx, dy);
          const force = sim.repulsion / (dist * dist + 1);
          const fx = (dx / dist) * force;
          const fy = (dy / dist) * force;
          a.fx -= fx; a.fy -= fy;
          b.fx += fx; b.fy += fy;
        }
      }

      // Springs on edges
      for (const edge of sim.edges) {
        const a = nodes.find(n => n.id === edge.source);
        const b = nodes.find(n => n.id === edge.target);
        if (!a || !b) continue;
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        const dist = Math.hypot(dx, dy);
        const spring = sim.springK * (dist - sim.springLen);
        const fx = (dx / (dist + 0.01)) * spring;
        const fy = (dy / (dist + 0.01)) * spring;
        a.fx += fx; a.fy += fy;
        b.fx -= fx; b.fy -= fy;
      }

      // Light centering
      const cx = canvas.width / 2;
      const cy = canvas.height / 2;
      for (const n of nodes) {
        n.fx -= (n.x - cx) * 0.01;
        n.fy -= (n.y - cy) * 0.01;
      }

      // Integrate
      for (const n of nodes) {
        n.vx = (n.vx + n.fx) * sim.friction;
        n.vy = (n.vy + n.fy) * sim.friction;
        n.x += n.vx;
        n.y += n.vy;

        // Bounds
        n.x = Math.max(20, Math.min(canvas.width - 20, n.x));
        n.y = Math.max(20, Math.min(canvas.height - 20, n.y));
      }
    }

    function render() {
      ctx.fillStyle = getComputedStyle(canvas).backgroundColor;
      ctx.fillRect(0, 0, canvas.width, canvas.height);

      // Draw edges
      ctx.strokeStyle = getComputedStyle(document.documentElement).color;
      ctx.globalAlpha = 0.2;
      ctx.lineWidth = 1;
      for (const edge of sim.edges) {
        const a = sim.nodes.find(n => n.id === edge.source);
        const b = sim.nodes.find(n => n.id === edge.target);
        if (!a || !b) continue;
        ctx.beginPath();
        ctx.moveTo(a.x, a.y);
        ctx.lineTo(b.x, b.y);
        ctx.stroke();
      }
      ctx.globalAlpha = 1;

      // Draw nodes
      const nodeRadius = 8;
      for (const n of sim.nodes) {
        ctx.fillStyle = DATA.typeToColor[n.type] || '#999';
        ctx.beginPath();
        ctx.arc(n.x, n.y, nodeRadius, 0, Math.PI * 2);
        ctx.fill();

        if (n.id === selectedNodeId) {
          ctx.strokeStyle = '#333';
          ctx.lineWidth = 2;
          ctx.stroke();
        }
      }

      // Draw labels
      ctx.fillStyle = getComputedStyle(document.documentElement).color;
      ctx.font = '11px sans-serif';
      ctx.textAlign = 'left';
      for (const n of sim.nodes) {
        ctx.fillText(n.label, n.x + nodeRadius + 4, n.y + 3);
      }
    }

    function findNodeAt(x, y, radius = 12) {
      for (const n of sim.nodes) {
        const dx = n.x - x, dy = n.y - y;
        if (Math.hypot(dx, dy) <= radius) return n.id;
      }
      return null;
    }

    canvas.addEventListener('mousemove', (e) => {
      const rect = canvas.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      const nodeId = findNodeAt(x, y);
      canvas.style.cursor = nodeId ? 'pointer' : 'grab';
    });

    canvas.addEventListener('click', (e) => {
      const rect = canvas.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      const nodeId = findNodeAt(x, y);
      if (nodeId) {
        selectedNodeId = nodeId;
        const node = sim.nodes.find(n => n.id === nodeId);
        infoPane.innerHTML = \`
          <h2>\${node.label}</h2>
          <p><strong>Type:</strong> \${node.type}</p>
          <p><strong>ID:</strong> \${node.id}</p>
          \${node.description ? \`<p><strong>Description:</strong></p><p>\${node.description}</p>\` : '<p class="empty">No description</p>'}
        \`;
      }
    });

    // Build legend
    const typeList = Object.keys(DATA.typeToColor).sort();
    let legendHtml = '<strong>Types:</strong>';
    for (const type of typeList) {
      legendHtml += \`
        <div class="legend-item">
          <div class="legend-color" style="background: \${DATA.typeToColor[type]}"></div>
          \${type}
        </div>
      \`;
    }
    legend.innerHTML = legendHtml;

    // Animation loop
    setInterval(() => {
      step();
      render();
    }, 30);

    render();
  </script>
</body>
</html>`;

try {
  writeFileSync(out, html, "utf8");
  console.log(`✓ wrote ${out} (${nodes.length} nodes, ${edges.length} edges)`);
} catch (err) {
  console.error(`Failed to write ${out}: ${err.message}`);
  process.exit(1);
}
