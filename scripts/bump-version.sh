#!/usr/bin/env bash
# bump-version.sh — Increments MARKETING_VERSION patch by 1
# and increments CURRENT_PROJECT_VERSION (build number) by 1 in project.yml.
# Optionally mirrors values into JustPlay/Config/Generated-Info.plist if present.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_YML="$REPO_ROOT/project.yml"
PLIST_MAC="$REPO_ROOT/JustPlay/Config/Generated-Info.plist"
BUDDY=/usr/libexec/PlistBuddy

if [[ ! -f "$PROJECT_YML" ]]; then
    echo "Error: project.yml not found at $PROJECT_YML"
    exit 1
fi

current_version=$(grep -E '^[[:space:]]*MARKETING_VERSION:' "$PROJECT_YML" | awk -F': ' '{print $2}')
current_build=$(grep -E '^[[:space:]]*CURRENT_PROJECT_VERSION:' "$PROJECT_YML" | awk -F': ' '{print $2}')

if [[ -z "$current_version" || -z "$current_build" ]]; then
    echo "Error: Could not read MARKETING_VERSION/CURRENT_PROJECT_VERSION from project.yml"
    exit 1
fi

IFS='.' read -r major minor patch <<< "$current_version"
patch=$(( patch + 1 ))
new_version="${major}.${minor}.${patch}"
new_build=$(( current_build + 1 ))

tmp_file="${PROJECT_YML}.tmp"
awk -v new_version="$new_version" -v new_build="$new_build" '
    /^[[:space:]]*MARKETING_VERSION:/ {
        sub(/MARKETING_VERSION:.*/, "MARKETING_VERSION: " new_version)
    }
    /^[[:space:]]*CURRENT_PROJECT_VERSION:/ {
        sub(/CURRENT_PROJECT_VERSION:.*/, "CURRENT_PROJECT_VERSION: " new_build)
    }
    { print }
' "$PROJECT_YML" > "$tmp_file"
mv "$tmp_file" "$PROJECT_YML"

echo "Bumped project.yml: $current_version -> $new_version  (build $current_build -> $new_build)"

if [[ -f "$PLIST_MAC" ]]; then
    "$BUDDY" -c "Set :CFBundleShortVersionString '$new_version'" "$PLIST_MAC"
    "$BUDDY" -c "Set :CFBundleVersion $new_build" "$PLIST_MAC"
    echo "Synced $PLIST_MAC"
else
    echo "Skipping plist sync (not found): $PLIST_MAC"
fi

echo "New version: $new_version"
