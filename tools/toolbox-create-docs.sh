#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="${1:-.}"
OUTPUT_FILE="${2:-bashdoc.md}"

TMP_JSON="$(mktemp)"
trap 'rm -f "$TMP_JSON"' EXIT

python3 - "$SOURCE_DIR" "$OUTPUT_FILE" <<'PY'
import os
import re
import sys

source_dir = sys.argv[1]
output_file = sys.argv[2]

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
                pending_doc.append(stripped[1:].strip())
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
                })

                pending_doc = []
                in_doc = False
                continue

            if stripped and in_doc:
                pending_doc = []
                in_doc = False


def md_escape(text):
    return text.replace("|", "\\|")


with open(output_file, "w", encoding="utf-8") as md:
    md.write("# Bash Library Documentation\n\n")
    md.write("Generated from Doxygen-style Bash comments.\n\n")

    md.write("## Table of Contents\n\n")

    current_file = None

    for item in sorted(docs, key=lambda x: (x["file"], x["function"])):
        if item["file"] != current_file:
            current_file = item["file"]
            md.write(f"- **{current_file}**\n")

        anchor = item["function"].lower().replace("::", "").replace("_", "-")
        md.write(f"  - [{item['function']}](#{anchor})\n")

    md.write("\n---\n\n")

    current_file = None

    for item in sorted(docs, key=lambda x: (x["file"], x["function"])):
        if item["file"] != current_file:
            current_file = item["file"]
            md.write(f"## {current_file}\n\n")

        md.write(f"### {item['function']}\n\n")
        md.write(f"**File:** `{item['file']}`  \n")
        md.write(f"**Line:** `{item['line']}`\n\n")

        if item["doc"]:
            md.write("```text\n")
            md.write(item["doc"])
            md.write("\n```\n\n")
        else:
            md.write("_No documentation found._\n\n")

    md.write("---\n\n")
    md.write(f"Total documented functions: {len(docs)}\n")

print(f"Markdown documentation created: {output_file}")
PY
