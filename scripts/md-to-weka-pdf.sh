#!/usr/bin/env bash
# Render a markdown doc to a WEKA-styled PDF (brand colors + code/table styling),
# keeping technical content (code blocks, tables, ASCII diagrams) intact.
# This is the technical-doc path — distinct from the sales weka-doc-builder skill,
# which uses the marketing template and can't render multi-line code blocks.
#
# Usage: scripts/md-to-weka-pdf.sh <input.md> <output.pdf>
set -euo pipefail

IN="${1:?usage: md-to-weka-pdf.sh <input.md> <output.pdf>}"
OUT="${2:?usage: md-to-weka-pdf.sh <input.md> <output.pdf>}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CSS="$REPO/docs/weka-doc.css"

CHROME="$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || true)"
[ -n "$CHROME" ] || { echo "no Chrome/Chromium found for PDF rendering" >&2; exit 1; }
command -v pandoc >/dev/null || { echo "pandoc not found" >&2; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
HEADER="$TMP/header.html"; printf '<style>\n%s\n</style>\n' "$(cat "$CSS")" > "$HEADER"

pandoc "$IN" -f gfm -t html5 --standalone --toc --toc-depth=2 \
  --metadata pagetitle="$(basename "$IN" .md)" \
  --include-in-header "$HEADER" \
  -o "$TMP/doc.html"

"$CHROME" --headless=new --disable-gpu --no-sandbox --no-pdf-header-footer \
  --run-all-compositor-stages-before-draw --virtual-time-budget=10000 \
  --print-to-pdf="$OUT" "file://$TMP/doc.html" >/dev/null 2>&1

echo "Wrote: $OUT"
