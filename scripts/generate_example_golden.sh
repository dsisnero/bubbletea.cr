#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage: $0 <example-file> [model-class]

Examples:
  $0 examples/canvas.cr
  $0 canvas.cr CanvasModel

Generates: testdata/examples/<example-name>.golden
USAGE
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 1
fi

example_input="$1"
if [[ -f "$example_input" ]]; then
  example_file="$example_input"
elif [[ -f "examples/$example_input" ]]; then
  example_file="examples/$example_input"
else
  echo "error: example file not found: $example_input" >&2
  exit 1
fi

example_name="$(basename "$example_file" .cr)"

if [[ $# -eq 2 ]]; then
  model_class="$2"
else
  # Convert snake_case example name to CamelCaseModel.
  IFS='_' read -r -a parts <<< "$example_name"
  model_class=""
  for part in "${parts[@]}"; do
    [[ -z "$part" ]] && continue
    first="$(printf '%s' "${part:0:1}" | tr '[:lower:]' '[:upper:]')"
    rest="${part:1}"
    model_class+="${first}${rest}"
  done
  model_class+="Model"
fi

out_dir="testdata/examples"
out_file="$out_dir/$example_name.golden"
mkdir -p "$out_dir"

cache_dir="${CRYSTAL_CACHE_DIR:-$PWD/.crystal-cache}"
mkdir -p "$cache_dir"

# This expects the example file to define a model class with a zero-arg ctor
# and to guard executable code with: if PROGRAM_NAME == __FILE__
CRYSTAL_CACHE_DIR="$cache_dir" crystal eval "require \"./$example_file\"; model = $model_class.new; print model.view.content" > "$out_file"

echo "wrote $out_file from $example_file using $model_class"
