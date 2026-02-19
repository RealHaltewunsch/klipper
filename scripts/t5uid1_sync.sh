#!/usr/bin/env bash
set -euo pipefail

TARGET_BRANCH="${TARGET_BRANCH:-main}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-main}"
T5UID1_SOURCE_BRANCH="${T5UID1_SOURCE_BRANCH:-t5uid1-port}"
FILELIST="${FILELIST:-.github/t5uid1-sync-files.txt}"
UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
ORIGIN_REMOTE="${ORIGIN_REMOTE:-origin}"

if [[ ! -f "$FILELIST" ]]; then
  echo "File list not found: $FILELIST" >&2
  exit 1
fi

if ! git show-ref --verify --quiet "refs/remotes/$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"; then
  git fetch "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH"
fi
if ! git show-ref --verify --quiet "refs/remotes/$ORIGIN_REMOTE/$T5UID1_SOURCE_BRANCH"; then
  git fetch "$ORIGIN_REMOTE" "$T5UID1_SOURCE_BRANCH"
fi

# Rebase local sync branch state onto current upstream branch
if ! git merge --ff-only "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"; then
  git merge --no-edit "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
fi

while IFS= read -r path; do
  [[ -z "$path" || "$path" =~ ^# ]] && continue
  git checkout "$ORIGIN_REMOTE/$T5UID1_SOURCE_BRANCH" -- "$path"
done < "$FILELIST"

echo "T5UID1 sync applied from $ORIGIN_REMOTE/$T5UID1_SOURCE_BRANCH on top of $UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
