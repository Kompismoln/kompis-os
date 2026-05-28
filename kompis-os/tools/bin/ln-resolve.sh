#!/usr/bin/env bash

# Ensure a file path was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_symlink>" >&2
    exit 1
fi

TARGET_LINK="$1"

# 1. Check if the path exists
if [ ! -e "$TARGET_LINK" ] && [ ! -L "$TARGET_LINK" ]; then
    echo "Error: '$TARGET_LINK' does not exist." >&2
    exit 1
fi

# 2. Verify it is actually a symbolic link
if [ ! -L "$TARGET_LINK" ]; then
    echo "Error: '$TARGET_LINK' is not a symbolic link." >&2
    exit 1
fi

# 3. Find the target file the symlink points to
# 'readlink -f' resolves nested symlinks to the ultimate source file
SOURCE_FILE=$(readlink -f "$TARGET_LINK")

if [ -z "$SOURCE_FILE" ] || [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: Could not resolve symlink to a valid file." >&2
    exit 1
fi

# 4. Create a secure temporary file in the same directory as the symlink
# (This ensures 'mv' is an atomic operation on the same filesystem)
DIR=$(dirname "$TARGET_LINK")
TEMP_FILE=$(mktemp "$DIR/symlink_resolve.XXXXXX")

# Ensure temp file cleanup if the script exits unexpectedly
trap 'rm -f "$TEMP_FILE"' EXIT

# 5. Copy the contents of the source file to the temp file
if ! cp "$SOURCE_FILE" "$TEMP_FILE"; then
    echo "Error: Failed to copy contents to temporary file." >&2
    exit 1
fi

# 6. Remove the original symlink
if ! rm "$TARGET_LINK"; then
    echo "Error: Failed to remove the symlink." >&2
    exit 1
fi

# 7. Move the temp file into the original symlink's place
if ! mv "$TEMP_FILE" "$TARGET_LINK"; then
    echo "Error: Failed to move temp file to destination." >&2
    # Disarm the trap since the file didn't move successfully or needs manual intervention
    trap - EXIT
    exit 1
fi

# Success! Disarm the trap so it doesn't try to delete the now-moved file
trap - EXIT
echo "Successfully resolved symlink '$TARGET_LINK' into a regular file."
