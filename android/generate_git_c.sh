#!/usr/bin/env bash
# Writes generated/git.c and generated/git.h, which the desktop build gets from
# cmake-git-version-tracking, so the Android build reports its version the same way.
# Usage: generate_git_c.sh <cmake-git-version-tracking source folder>
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
out="$here/generated"
mkdir -p "$out"
cp "$1/git.h" "$out/git.h"

cd "$here/.."
escape() { sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk 'BEGIN { ORS = "" } NR > 1 { print "\\n\\\n" } { print }'; }
dirty=false
git diff --quiet HEAD -- || dirty=true

cat > "$out/git.c" <<EOF
#include "git.h"

bool git_IsPopulated() { return true; }
bool git_AnyUncommittedChanges() { return $dirty; }
const char *git_AuthorName() { return "$(git log -1 --format=%an | escape)"; }
const char *git_AuthorEmail() { return "$(git log -1 --format=%ae | escape)"; }
const char *git_CommitSHA1() { return "$(git rev-parse HEAD)"; }
const char *git_CommitDate() { return "$(git log -1 --format=%ci)"; }
const char *git_CommitSubject() { return "$(git log -1 --format=%s | escape)"; }
const char *git_CommitBody() { return ""; }
const char *git_Describe() { return "$(git describe --tags --always)"; }
const char *git_Branch() { return "$(git rev-parse --abbrev-ref HEAD)"; }
EOF
echo "wrote generated/git.c ($(git describe --tags --always), uncommitted changes: $dirty)"
