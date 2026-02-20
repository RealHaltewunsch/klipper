#!/usr/bin/env bash
set -euo pipefail

TARGET_BRANCH="${TARGET_BRANCH:-master}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-master}"
T5UID1_SOURCE_BRANCH="${T5UID1_SOURCE_BRANCH:-master}"
FILELIST="${FILELIST:-.github/t5uid1-sync-files.txt}"
UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
T5UID1_SOURCE_REMOTE="${T5UID1_SOURCE_REMOTE:-t5uid1}"

if [[ ! -f "$FILELIST" ]]; then
  echo "File list not found: $FILELIST" >&2
  exit 1
fi

if ! git show-ref --verify --quiet "refs/remotes/$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"; then
  git fetch "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH"
fi

SOURCE_REF="$T5UID1_SOURCE_REMOTE/$T5UID1_SOURCE_BRANCH"
if ! git show-ref --verify --quiet "refs/remotes/$SOURCE_REF"; then
  git fetch "$T5UID1_SOURCE_REMOTE" "$T5UID1_SOURCE_BRANCH"
fi

if ! git show-ref --verify --quiet "refs/remotes/$SOURCE_REF"; then
  echo "Missing source reference: $SOURCE_REF" >&2
  exit 1
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
