#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="${1:-.}"
OUTPUT_FILE="${2:-readme.html}"

TMP_JSON="$(mktemp)"
trap 'rm -f "$TMP_JSON"' EXIT

python3 - "$SOURCE_DIR" "$TMP_JSON" <<'PY'
import os, re, sys, json, html

source_dir = sys.argv[1]
out_json = sys.argv[2]

func_re = re.compile(r'^\s*([a-zA-Z_][a-zA-Z0-9_:]*)\s*\(\)\s*\{')
docs = []

for root, _, files in os.walk(source_dir):
    for name in sorted(files):
        if not name.endswith((".sh", ".bash", ".lib.sh")):
            continue

        path = os.path.join(root, name)
        rel = os.path.relpath(path, source_dir)

        try:
            lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
        except Exception:
            continue

        pending_doc = []
        in_doc = False

        for i, line in enumerate(lines, start=1):
            stripped = line.strip()

            if stripped.startswith("##"):
                in_doc = True
                pending_doc = []
                continue

            if in_doc and stripped.startswith("#"):
                text = stripped[1:].strip()
                pending_doc.append(text)
                continue

            match = func_re.match(line)

            if match:
                func = match.group(1)
                raw_doc = "\n".join(pending_doc).strip()

                docs.append({
                    "file": rel,
                    "function": func,
                    "line": i,
                    "doc": raw_doc,
                    "search": f"{rel} {func} {raw_doc}".lower()
                })

                pending_doc = []
                in_doc = False
                continue

            if stripped and in_doc:
                pending_doc = []
                in_doc = False

with open(out_json, "w", encoding="utf-8") as f:
    json.dump(docs, f, indent=2)
PY

DOC_JSON="$(cat "$TMP_JSON")"

cat > "$OUTPUT_FILE" <<HTML
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>Bash Library Documentation</title>
<style>
body {
    font-family: Arial, sans-serif;
    margin: 0;
    display: flex;
    height: 100vh;
}
#sidebar {
    width: 360px;
    overflow: auto;
    border-right: 1px solid #ccc;
    padding: 15px;
    background: #f7f7f7;
}
#content {
    flex: 1;
    overflow: auto;
    padding: 25px;
}
input {
    width: 100%;
    padding: 8px;
    margin-bottom: 15px;
}
.file {
    font-weight: bold;
    margin-top: 12px;
}
.func {
    margin-left: 18px;
    cursor: pointer;
    color: #0645ad;
    padding: 3px;
}
.func:hover {
    text-decoration: underline;
}
.card {
    border-bottom: 1px solid #ddd;
    padding: 18px 0;
}
pre {
    background: #f0f0f0;
    padding: 12px;
    white-space: pre-wrap;
}
small {
    color: #666;
}
.hidden {
    display: none;
}
</style>
</head>
<body>

<div id="sidebar">
    <h2>Bash Docs</h2>
    <input id="search" placeholder="Search function, file, description...">
    <div id="tree"></div>
</div>

<div id="content">
    <h1>Bash Library Documentation</h1>
    <div id="details"></div>
</div>

<script>
const docs = $DOC_JSON;

const tree = document.getElementById("tree");
const details = document.getElementById("details");
const search = document.getElementById("search");

function render(filter = "") {
    tree.innerHTML = "";
    details.innerHTML = "";

    const filtered = docs.filter(d => d.search.includes(filter.toLowerCase()));
    const grouped = {};

    filtered.forEach(d => {
        if (!grouped[d.file]) grouped[d.file] = [];
        grouped[d.file].push(d);
    });

    Object.keys(grouped).sort().forEach(file => {
        const fileDiv = document.createElement("div");
        fileDiv.className = "file";
        fileDiv.textContent = file;
        tree.appendChild(fileDiv);

        grouped[file].forEach(d => {
            const funcDiv = document.createElement("div");
            funcDiv.className = "func";
            funcDiv.textContent = d.function;
            funcDiv.onclick = () => showFunction(d);
            tree.appendChild(funcDiv);
        });
    });

    filtered.forEach(d => addCard(d));
}

function showFunction(d) {
    details.innerHTML = "";
    addCard(d);
}

function addCard(d) {
    const card = document.createElement("div");
    card.className = "card";

    card.innerHTML = \`
        <h2>\${escapeHtml(d.function)}</h2>
        <small>\${escapeHtml(d.file)} : line \${d.line}</small>
        <pre>\${escapeHtml(d.doc || "No documentation found.")}</pre>
    \`;

    details.appendChild(card);
}

function escapeHtml(value) {
    return value
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;");
}

search.addEventListener("input", () => render(search.value));

render();
</script>

</body>
</html>
HTML

echo "Documentation created: $OUTPUT_FILE"
