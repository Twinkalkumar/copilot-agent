#!/usr/bin/env bash

set -u

RETENTION_DAYS=30
DELETE=false

LOG_PATHS=(
  "/var/log"
  "/opt/myapp/logs"
  "/var/log/myapp"
)

usage() {
  echo "Usage: $0 [--delete] [--days N]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --delete)
      DELETE=true
      shift
      ;;
    --days)
      [[ $# -ge 2 ]] || usage
      RETENTION_DAYS="$2"
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if ! [[ "$RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
  echo "Retention days must be a non-negative integer." >&2
  exit 1
fi

for log_path in "${LOG_PATHS[@]}"; do
  if [[ ! -d "$log_path" ]]; then
    echo "Warning: directory does not exist: $log_path" >&2
    continue
  fi

  while IFS= read -r -d '' file; do
    if [[ "$DELETE" == true ]]; then
      if rm -f -- "$file"; then
        echo "Deleted: $file"
      else
        echo "Warning: could not delete: $file" >&2
      fi
    else
      echo "[DRY RUN] Would delete: $file"
    fi
  done < <(
    find "$log_path" \
      -type f \
      -mtime "+$RETENTION_DAYS" \
      \( -name "*.log" -o -name "*.log.*" \) \
      -print0
  )
done
