#!/usr/bin/env bash
set -euo pipefail

TARGET_BRANCH="${TARGET_BRANCH:-master}"
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

SOURCE_REF="$ORIGIN_REMOTE/$T5UID1_SOURCE_BRANCH"
if ! git show-ref --verify --quiet "refs/remotes/$SOURCE_REF"; then
  if git ls-remote --exit-code --heads "$ORIGIN_REMOTE" "$T5UID1_SOURCE_BRANCH" >/dev/null 2>&1; then
    git fetch "$ORIGIN_REMOTE" "$T5UID1_SOURCE_BRANCH"
  else
    echo "Warning: missing $ORIGIN_REMOTE/$T5UID1_SOURCE_BRANCH - falling back to $TARGET_BRANCH" >&2
    SOURCE_REF="$ORIGIN_REMOTE/$TARGET_BRANCH"
    if ! git show-ref --verify --quiet "refs/remotes/$SOURCE_REF"; then
      git fetch "$ORIGIN_REMOTE" "$TARGET_BRANCH"
    fi
  fi
fi

# Rebase local sync branch state onto current upstream branch
if ! git merge --ff-only "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"; then
  git merge --no-edit "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
fi

while IFS= read -r path; do
  [[ -z "$path" || "$path" =~ ^# ]] && continue
  git checkout "$SOURCE_REF" -- "$path"
done < "$FILELIST"

echo "T5UID1 sync applied from $SOURCE_REF on top of $UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
