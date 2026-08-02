<#
.SYNOPSIS
    Creates a branch for a GitHub issue, based on dev, and checks it out.

.DESCRIPTION
    Wraps `gh issue develop`. The branch is named automatically from the issue
    number and title, is created from `dev` rather than from the default branch
    `main`, and is registered as a linked branch on the issue so it shows up in
    the issue's "Development" section.

    This exists because creating a branch from the GitHub issues page always
    bases the branch on the default branch (`main`), with no way to choose a
    different source. Changes belong on `dev`; only releases go to `main`.

    A branch created this way also records `dev` as its base, so `gh pr create`
    targets `dev` without being told.

.PARAMETER Issue
    The issue number, e.g. 1102.

.PARAMETER Base
    Branch to create from. Defaults to dev; you should not normally change it.

.EXAMPLE
    .\branch-for-issue.ps1 1102

    Creates e.g. `1102-replace-automated-release-action` from dev and checks it out.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'GitHub issue number, e.g. 1102')]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $Issue,

    [Parameter(Position = 1)]
    [string] $Base = 'dev'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error @'
The GitHub CLI (gh) is not installed or not on your PATH.

Install it with:
    winget install --id GitHub.cli -e

then restart your shell and run:
    gh auth login
'@
    exit 1
}

# `gh issue develop` needs to know which repo it is acting on, and it infers that from the
# CURRENT directory -- not from where this script happens to live. So test the current
# directory, and fail early with a clear message rather than letting gh fail confusingly.
git rev-parse --git-dir 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Run this script from inside the scadnano working copy (the current directory is not a git repository)."
    exit 1
}

Write-Host "Creating a branch for issue #$Issue based on '$Base'..."

# --checkout leaves you on the new branch locally; GitHub Desktop picks it up.
gh issue develop $Issue --base $Base --checkout
if ($LASTEXITCODE -ne 0) {
    Write-Error "gh issue develop failed (exit $LASTEXITCODE). Does issue #$Issue exist, and are you authenticated (gh auth status)?"
    exit $LASTEXITCODE
}

$branch = (git rev-parse --abbrev-ref HEAD)
Write-Host ""
Write-Host "Now on branch '$branch' (based on '$Base')." -ForegroundColor Green
Write-Host "When you are done, open a pull request into '$Base'."
