#!/usr/bin/env sh
set -eu

config_dir="${HOME}/.config/opencode"
force="0"
archive_url="${OPENCODE_MEMORY_KIT_ARCHIVE_URL:-https://codeload.github.com/alejodevelop/opencode-memory-kit/tar.gz/refs/heads/main}"
source_dir="${OPENCODE_MEMORY_KIT_SOURCE_DIR:-}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      force="1"
      ;;
    --config-dir)
      shift
      config_dir="$1"
      ;;
    -h|--help)
      printf '%s\n' "Usage: sh install.sh [--config-dir DIR] [--force]"
      exit 0
      ;;
    *)
      printf '%s\n' "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
  shift
done

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf '%s\n' "Missing required command: $1" >&2
    exit 1
  fi
}

repo_dir=""

if [ -n "$source_dir" ]; then
  repo_dir="$source_dir"
else
  require_command curl
  require_command tar

  tmp_dir=$(mktemp -d)
  archive_path="$tmp_dir/opencode-memory-kit.tar.gz"
  extract_dir="$tmp_dir/extract"

  cleanup() {
    rm -rf "$tmp_dir"
  }

  trap cleanup EXIT HUP INT TERM

  mkdir -p "$extract_dir"

  printf '%s\n' "Downloading OpenCode memory kit..."
  curl -fsSL "$archive_url" -o "$archive_path"
  tar -xzf "$archive_path" -C "$extract_dir"

  for path in "$extract_dir"/*; do
    if [ -d "$path" ]; then
      repo_dir="$path"
      break
    fi
  done
fi

if [ -z "$repo_dir" ]; then
  printf '%s\n' "Could not locate extracted kit contents." >&2
  exit 1
fi

install_script="$repo_dir/scripts/install-global.sh"

if [ ! -f "$install_script" ]; then
  printf '%s\n' "Could not locate install-global.sh in the downloaded kit." >&2
  exit 1
fi

if [ "$force" = "1" ]; then
  sh "$install_script" --config-dir "$config_dir" --force
else
  sh "$install_script" --config-dir "$config_dir"
fi
