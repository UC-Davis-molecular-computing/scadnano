#!/usr/bin/env bash
# Creates a branch for a GitHub issue, based on dev, and checks it out.
#
# Wraps `gh issue develop`. The branch is named automatically from the issue
# number and title, is created from `dev` rather than from the default branch
# `main`, and is registered as a linked branch on the issue so it shows up in
# the issue's "Development" section.
#
# This exists because creating a branch from the GitHub issues page always bases
# the branch on the default branch (`main`), with no way to choose a different
# source. Changes belong on `dev`; only releases go to `main`.
#
# A branch created this way also records `dev` as its base, so `gh pr create`
# targets `dev` without being told.
#
# Usage:  ./branch-for-issue.sh 1102 [base-branch]
# Example: ./branch-for-issue.sh 1102
#          -> creates e.g. 1102-replace-automated-release-action from dev

set -euo pipefail

issue=${1:-}
base=${2:-dev}

if [ -z "$issue" ]; then
  echo "usage: $0 <issue-number> [base-branch]" >&2
  echo "example: $0 1102" >&2
  exit 2
fi

if ! [[ "$issue" =~ ^[0-9]+$ ]]; then
  echo "error: issue number must be a positive integer (got '$issue')" >&2
  exit 2
fi

if ! command -v gh > /dev/null 2>&1; then
  cat >&2 <<'EOF'
error: the GitHub CLI (gh) is not installed or not on your PATH.

Install it from https://cli.github.com/ (or `winget install --id GitHub.cli -e`
on Windows, `brew install gh` on macOS), then run:
    gh auth login
EOF
  exit 1
fi

# `gh issue develop` infers the repository from the current directory.
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "error: run this script from inside the scadnano working copy." >&2
  exit 1
fi

echo "Creating a branch for issue #$issue based on '$base'..."

# --checkout leaves you on the new branch locally.
gh issue develop "$issue" --base "$base" --checkout

echo
echo "Now on branch '$(git rev-parse --abbrev-ref HEAD)' (based on '$base')."
echo "When you are done, open a pull request into '$base'."
