#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$REPORT_DIR"
cmd=("$WIZCLI_PATH" tag "$INPUT_IMAGE" --digest "$INPUT_IMAGE_DIGEST" --no-color --no-style)
[[ -n "$INPUT_PROJECTS" ]] && cmd+=(--projects "$INPUT_PROJECTS")

"${cmd[@]}" 2>&1 | tee "$REPORT_DIR/wizcli-tag.log"
echo "tagged=true" >> "$GITHUB_OUTPUT"
{
  echo
  echo "### Wiz Trusted Image Database"
  echo
  echo "- Image added with \`wizcli tag\`: \`$INPUT_IMAGE\`"
  echo "- Digest: \`$INPUT_IMAGE_DIGEST\`"
} >> "$GITHUB_STEP_SUMMARY"
