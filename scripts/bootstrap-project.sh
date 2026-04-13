#!/usr/bin/env sh
set -eu

target="."
force="0"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      force="1"
      ;;
    -h|--help)
      printf '%s\n' "Usage: sh scripts/bootstrap-project.sh [target-dir] [--force]"
      exit 0
      ;;
    *)
      target="$1"
      ;;
  esac
  shift
done

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(dirname "$script_dir")
template_root="$repo_root/templates/project"
docs_template_root="$template_root/docs"
full_agents_template="$template_root/AGENTS.md"
append_agents_template="$template_root/AGENTS.memory.md"
marker="opencode-memory-kit:start"

if [ ! -d "$target" ]; then
  printf '%s\n' "Target directory does not exist: $target" >&2
  exit 1
fi

target=$(CDPATH= cd -- "$target" && pwd)
target_agents="$target/AGENTS.md"

if [ -f "$target_agents" ]; then
  if grep -q "$marker" "$target_agents"; then
    printf '%s\n' "Skipped AGENTS.md (memory workflow already present)"
  else
    printf '\n\n' >> "$target_agents"
    cat "$append_agents_template" >> "$target_agents"
    printf '%s\n' "Updated AGENTS.md (appended memory workflow block)"
  fi
else
  cp "$full_agents_template" "$target_agents"
  printf '%s\n' "Created AGENTS.md"
fi

find "$docs_template_root" -type f | sort | while IFS= read -r source_path; do
  relative_path=${source_path#"$template_root/"}
  destination="$target/$relative_path"
  destination_dir=$(dirname "$destination")

  mkdir -p "$destination_dir"

  if [ -f "$destination" ] && [ "$force" != "1" ]; then
    printf '%s\n' "Skipped $relative_path"
    continue
  fi

  if [ -f "$destination" ]; then
    cp "$source_path" "$destination"
    printf '%s\n' "Updated $relative_path"
  else
    cp "$source_path" "$destination"
    printf '%s\n' "Created $relative_path"
  fi
done

printf '\n'
printf '%s\n' "Project memory workflow is ready in $target"
printf '%s\n' "Next steps:"
printf '%s\n' "  1. Open the project in OpenCode"
printf '%s\n' "  2. Build as usual"
printf '%s\n' "  3. Run /remember-feature <slug> when a feature is accepted"
printf '%s\n' "  4. Run /recall-feature <query> in future sessions"
printf '%s\n' "  5. Run /review-memory [scope] after large refactors or removals"
