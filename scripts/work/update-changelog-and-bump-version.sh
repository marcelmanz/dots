#!/usr/bin/env bash

# Usage:
#   update_changelog.sh [major|minor|patch] [changed|fixed|added] "Updated something to something else"

branch_name=""
commit="update changelog and bump version"

# Uncomment if needed:
# if [ ! -f "requirements/development.txt" ]; then
#   echo "This is not a python service, skipping..."
#   exit 0
# fi
#
# if [ "$(git rev-parse --abbrev-ref HEAD)" != "$branch_name" ]; then
#     echo "This is not the correct branch, skipping..."
#     exit 0
# fi
#
# if git log --oneline | grep -q "$commit"; then
#     echo "Commit '$commit' already exists. Exiting..."
#     exit 0
# fi

RELEASE_TYPE="${1:-patch}" # major|minor|patch (default=patch)
ENTRY_TYPE="${2:-changed}" # changed|fixed|added, etc. (default=changed)
ENTRY_MESSAGE="${3:-N/A}"  # The actual text for the bullet

OLD_VERSION=$(grep -m1 -oP '^##\s*\[?\K\d+\.\d+\.\d+(?=\]?)' CHANGELOG.md)
if [ -z "$OLD_VERSION" ]; then
	echo "ERROR: Could not find a version number in CHANGELOG.md"
	exit 1
fi
VERSION_LINE=$(grep -m1 "^##.*$OLD_VERSION" CHANGELOG.md)
if [[ "$VERSION_LINE" =~ ^##\ *\[$OLD_VERSION\] ]]; then
	USE_BRACKETS=1
else
	USE_BRACKETS=0
fi

IFS='.' read -r MAJOR MINOR PATCH <<<"$OLD_VERSION"

case "$RELEASE_TYPE" in
major)
	((MAJOR++))
	MINOR=0
	PATCH=0
	;;
minor)
	((MINOR++))
	PATCH=0
	;;
patch)
	((PATCH++))
	;;
*)
	echo "ERROR: Unknown release type: $RELEASE_TYPE"
	exit 1
	;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
TODAY=$(date +%Y-%m-%d)

case "$ENTRY_TYPE" in
changed) ENTRY_HEADING="## Changed" ;;
fixed) ENTRY_HEADING="## Fixed" ;;
added) ENTRY_HEADING="## Added" ;;
*) ENTRY_HEADING="## Changed" ;;
esac

if [ $USE_BRACKETS -eq 1 ]; then
	NEW_VERSION_HEADER="## [$NEW_VERSION] - $TODAY"
else
	NEW_VERSION_HEADER="## $NEW_VERSION - $TODAY"
fi

NEW_BLOCK="$NEW_VERSION_HEADER\n$ENTRY_HEADING\n- $ENTRY_MESSAGE\n"

# Insert changelog block above the first occurrence of OLD_VERSION.
if [ -n "$OLD_VERSION" ]; then
	sed -i "0,/^##.*$OLD_VERSION/ s//${NEW_BLOCK}&/" CHANGELOG.md
else
	sed -i "1i $NEW_BLOCK" CHANGELOG.md
fi

echo "Changelog updated from $OLD_VERSION to $NEW_VERSION."

# Check if any package*.json files exist in the root folder.
if ls package*.json 1>/dev/null 2>&1; then
	echo "package*.json file(s) found – updating version only in package.json and package-lock.json..."

	# Update package.json: Only update the first occurrence of the root "version" field.
	if [ -f "package.json" ]; then
		sed -i.bak "0,/\"version\":\s*\"$OLD_VERSION\"/ s//\"version\": \"$NEW_VERSION\"/" package.json
		echo "Updated package.json"
	fi

	# Update package-lock.json.
	if [ -f "package-lock.json" ]; then
		# Update the root "version" field (first occurrence in the file).
		sed -i.bak -E "0,/\"version\":\s*\"$OLD_VERSION\"/ s//\"version\": \"$NEW_VERSION\"/" package-lock.json

		# Update the version in the packages block for the root package, identified by the empty key ("").
		# This regex allows for an optional "name" field before "version".
		perl -0777 -pi.bak -e 's/("":\s*\{\s*(?:(?:"name":\s*".*?",\s*)?)"version":\s*")\Q'"$OLD_VERSION"'\E(")/$1'"$NEW_VERSION"'$2/si' package-lock.json

		echo "Updated package-lock.json"
	fi

	# Optionally remove backup files.
	rm -f package.json.bak package-lock.json.bak
else
	echo "No package*.json files found – performing global version update (except in CHANGELOG.md)..."
	ESCAPED_OLD_VERSION=$(echo "$OLD_VERSION" | sed 's/\./\\./g')
	ESCAPED_NEW_VERSION=$(echo "$NEW_VERSION" | sed 's/\./\\./g')
	grep -Rl "$OLD_VERSION" . --exclude="CHANGELOG.md" --exclude-dir=".git" |
		xargs sed -i "s/$ESCAPED_OLD_VERSION/$ESCAPED_NEW_VERSION/g"
fi

~/scripts/git/default-git-diff.sh

read -p "Do you want to commit and push the changes? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "Exiting without committing or pushing..."
	exit 0
fi

git add .
git commit -m "$commit"
# git push
