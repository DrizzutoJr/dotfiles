#!/bin/bash

set -e

# shellcheck source=_helpers/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_helpers/common.sh"

test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

source_file="$test_root/source"
target="$test_root/target"
printf 'managed\n' > "$source_file"
ln -s "$source_file" "$target"

before_inode="$(stat -f '%i' "$target")"
create_symlink "$source_file" "$target"
after_inode="$(stat -f '%i' "$target")"

if [[ "$before_inode" != "$after_inode" ]]; then
    echo "An already-correct symlink was replaced" >&2
    exit 1
fi

file_target="$test_root/file-target"
printf 'user-data\n' > "$file_target"
printf 'older-backup\n' > "${file_target}.bak"
create_symlink "$source_file" "$file_target"

if [[ "$(cat "${file_target}.bak")" != "older-backup" ]]; then
    echo "An existing backup was overwritten" >&2
    exit 1
fi
if [[ ! -L "$file_target" || "$(readlink "$file_target")" != "$source_file" ]]; then
    echo "A conflicting file was not replaced with the managed link" >&2
    exit 1
fi
backed_up_file="$(rg -l --no-ignore --glob '*' '^user-data$' "$test_root" || true)"
if [[ ! -f "$backed_up_file" || "$backed_up_file" == "$file_target" ]]; then
    echo "The displaced file was not preserved" >&2
    exit 1
fi

source_dir="$test_root/source-dir"
dir_target="$test_root/dir-target"
mkdir "$source_dir" "$dir_target" "${dir_target}.bak"
printf 'user-directory\n' > "$dir_target/content"
printf 'older-directory-backup\n' > "${dir_target}.bak/prior"
create_dir_symlink "$source_dir" "$dir_target"

if [[ ! -L "$dir_target" || "$(readlink "$dir_target")" != "$source_dir" ]]; then
    echo "A conflicting directory was not replaced with the managed link" >&2
    exit 1
fi
if [[ "$(ls -A "${dir_target}.bak")" != "prior" ]]; then
    echo "An existing directory backup was changed" >&2
    exit 1
fi
backed_up_dir_file="$(rg -l --no-ignore --glob '*' '^user-directory$' "$test_root" || true)"
if [[ ! -f "$backed_up_dir_file" || "$backed_up_dir_file" == "$dir_target/content" ]]; then
    echo "The displaced directory was not preserved" >&2
    exit 1
fi

fake_bin="$test_root/fake-bin"
mkdir "$fake_bin"
printf '#!/bin/bash\nexit 1\n' > "$fake_bin/ln"
chmod +x "$fake_bin/ln"
failure_target="$test_root/failure-target"
printf 'restore-me\n' > "$failure_target"
if PATH="$fake_bin:$PATH" create_symlink "$source_file" "$failure_target"; then
    echo "A failed link was reported as successful" >&2
    exit 1
fi
if [[ ! -f "$failure_target" || "$(cat "$failure_target")" != "restore-me" ]]; then
    echo "A failed link did not restore the original target" >&2
    exit 1
fi

failure_dir="$test_root/failure-dir"
mkdir "$failure_dir"
printf 'restore-directory\n' > "$failure_dir/content"
if PATH="$fake_bin:$PATH" create_dir_symlink "$source_dir" "$failure_dir"; then
    echo "A failed directory link was reported as successful" >&2
    exit 1
fi
if [[ ! -f "$failure_dir/content" || "$(cat "$failure_dir/content")" != "restore-directory" ]]; then
    echo "A failed directory link did not restore the original target" >&2
    exit 1
fi

missing_source="$test_root/missing-source"
missing_target="$test_root/missing-target"
printf 'keep-missing-target\n' > "$missing_target"
if create_symlink "$missing_source" "$missing_target"; then
    echo "A missing source was reported as a successful link" >&2
    exit 1
fi
if [[ "$(cat "$missing_target")" != "keep-missing-target" ]]; then
    echo "A missing source displaced the original target" >&2
    exit 1
fi

missing_dir="$test_root/missing-directory"
missing_dir_target="$test_root/missing-directory-target"
mkdir "$missing_dir_target"
printf 'keep-directory-target\n' > "$missing_dir_target/content"
if create_dir_symlink "$missing_dir" "$missing_dir_target"; then
    echo "A missing directory source was reported as a successful link" >&2
    exit 1
fi
if [[ "$(cat "$missing_dir_target/content")" != "keep-directory-target" ]]; then
    echo "A missing directory source displaced the original target" >&2
    exit 1
fi

other_source="$test_root/other-source"
other_target="$test_root/other-target"
printf 'other\n' > "$other_source"
ln -s "$other_source" "$other_target"
create_symlink "$source_file" "$other_target"
other_backups=("${other_target}".bak.*/original)
if [[ ${#other_backups[@]} -ne 1 || ! -L "${other_backups[0]}" || "$(readlink "${other_backups[0]}")" != "$other_source" ]]; then
    echo "An unrelated symlink was not preserved" >&2
    exit 1
fi

printf '#!/bin/bash\nexit 1\n' > "$fake_bin/mv"
chmod +x "$fake_bin/mv"
backup_failure_target="$test_root/backup-failure-target"
printf 'preserve-on-backup-failure\n' > "$backup_failure_target"
if PATH="$fake_bin:$PATH" create_symlink "$source_file" "$backup_failure_target"; then
    echo "A failed backup was reported as successful" >&2
    exit 1
fi
if [[ "$(cat "$backup_failure_target")" != "preserve-on-backup-failure" ]]; then
    echo "A failed backup discarded the original target" >&2
    exit 1
fi

echo "Symlink setup tests passed"
