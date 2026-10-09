#!/bin/bash

set -e

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT
fake_bin="$test_root/bin"
mkdir "$fake_bin"
cp "$repo_dir/tests/fixtures/fake_codex.sh" "$fake_bin/codex"
chmod +x "$fake_bin/codex"
fake_log="$test_root/codex.log"
fake_installed="$test_root/installed"
fake_marketplace="$test_root/marketplace"
export FAKE_CODEX_LOG="$fake_log"
export FAKE_CODEX_INSTALLED="$fake_installed"
export FAKE_CODEX_MARKETPLACE="$fake_marketplace"

run_setup() {
    HOME="$1" PATH="$fake_bin:$PATH" bash "$repo_dir/ai/macos_setup.sh" "${@:2}"
}

home_dir="$test_root/home"
mkdir "$home_dir"

run_setup "$home_dir" --non-interactive

pin="$(yq -r '.plugins[0].ref' "$repo_dir/ai/plugins.yaml")"
if ! rg -F -q "plugin marketplace add https://github.com/mattpocock/skills.git --ref $pin --json" "$fake_log"; then
    echo "Fresh unattended setup did not select the pinned plugin ref" >&2
    exit 1
fi
if ! rg -F -q 'plugin add mattpocock-skills@mattpocock --json' "$fake_log"; then
    echo "Fresh setup did not install the declared plugin" >&2
    exit 1
fi

codex_instructions="$home_dir/.codex/AGENTS.md"
claude_instructions="$home_dir/.claude/CLAUDE.md"
if [[ ! -L "$codex_instructions" || ! -L "$claude_instructions" ]]; then
    echo "Fresh setup did not link both global instruction files" >&2
    exit 1
fi
if [[ "$(readlink "$codex_instructions")" != "$(readlink "$claude_instructions")" ]]; then
    echo "Agents do not share one global instruction source" >&2
    exit 1
fi
if [[ "$(readlink "$codex_instructions")" != "$repo_dir/ai/AGENTS.md" ]]; then
    echo "Global instructions do not point to ai/AGENTS.md" >&2
    exit 1
fi
if [[ ! -s "$codex_instructions" ]]; then
    echo "Shared global instructions are empty" >&2
    exit 1
fi

migration_home="$test_root/migration-home"
fake_installed="$test_root/migration-installed"
fake_marketplace="$test_root/migration-marketplace"
export FAKE_CODEX_INSTALLED="$fake_installed"
export FAKE_CODEX_MARKETPLACE="$fake_marketplace"
: > "$fake_installed"
: > "$fake_marketplace"
: > "$fake_log"
mkdir -p "$migration_home/.claude" "$migration_home/.codex"
mkdir "$migration_home/.codex/marketplace-root"
printf '[marketplaces.mattpocock]\nsource_type = "git"\nsource = "https://github.com/mattpocock/skills.git"\nref = "%s"\n' "$pin" > "$migration_home/.codex/config.toml"
printf 'user-codex-instructions\n' > "$migration_home/.codex/AGENTS.md"
printf 'keep-local-state\n' > "$migration_home/.claude/local-state"
ln -s "$repo_dir/claude_code/CLAUDE.md" "$migration_home/.claude/CLAUDE.md"
ln -s "$repo_dir/claude_code/skills" "$migration_home/.claude/skills"
ln -s "$repo_dir/claude_code/commands" "$migration_home/.claude/commands"

run_setup "$migration_home" --non-interactive

if rg -q 'plugin (marketplace (add|upgrade)|add)' "$fake_log"; then
    echo "Pinned rerun modified an already installed plugin" >&2
    exit 1
fi

if [[ ! -d "$migration_home/.claude/skills" || -L "$migration_home/.claude/skills" ]]; then
    echo "The legacy skills directory link was not retired" >&2
    exit 1
fi
if [[ -L "$migration_home/.claude/commands" ]]; then
    echo "The legacy commands link was not retired" >&2
    exit 1
fi
if [[ "$(cat "$migration_home/.claude/local-state")" != "keep-local-state" ]]; then
    echo "Migration changed local app state" >&2
    exit 1
fi
backed_up_instructions="$(rg -l --no-ignore --glob '*' '^user-codex-instructions$' "$migration_home/.codex" || true)"
if [[ ! -f "$backed_up_instructions" ]]; then
    echo "Migration did not preserve prior Codex instructions" >&2
    exit 1
fi

backup_count_before="$(find "$migration_home" -type d -name '*.bak.*' | wc -l)"
run_setup "$migration_home" --non-interactive
backup_count_after="$(find "$migration_home" -type d -name '*.bak.*' | wc -l)"
if [[ "$backup_count_before" != "$backup_count_after" ]]; then
    echo "Rerunning setup created unnecessary backups" >&2
    exit 1
fi

: > "$fake_log"
printf 'latest\n' | run_setup "$migration_home"
if ! rg -F -q 'plugin marketplace remove mattpocock --json' "$fake_log" || ! rg -F -q 'plugin marketplace add https://github.com/mattpocock/skills.git --json' "$fake_log" || ! rg -F -q 'plugin add mattpocock-skills@mattpocock --json' "$fake_log"; then
    echo "Latest selection did not switch the marketplace and install the plugin" >&2
    exit 1
fi
if [[ "$(yq -p=toml -oy -r '.marketplaces.mattpocock.ref // ""' "$migration_home/.codex/config.toml")" != '' ]]; then
    echo "Latest marketplace still uses the pinned ref" >&2
    exit 1
fi
if [[ "$(yq -r '.plugins[0].ref' "$repo_dir/ai/plugins.yaml")" != "$pin" ]]; then
    echo "Latest selection modified the manifest pin" >&2
    exit 1
fi

: > "$fake_log"
printf 'latest\n' | run_setup "$migration_home"
if ! rg -F -q 'plugin marketplace upgrade mattpocock --json' "$fake_log"; then
    echo "Latest rerun did not refresh the marketplace" >&2
    exit 1
fi

export FAKE_CODEX_FAIL_ON='plugin marketplace upgrade'
if printf 'latest\n' | run_setup "$migration_home"; then
    echo "Marketplace refresh failure did not fail setup" >&2
    exit 1
fi
if [[ ! -d "$migration_home/.codex/marketplace-root" || ! -f "$fake_installed" ]]; then
    echo "Marketplace refresh failure lost existing plugin state" >&2
    exit 1
fi
unset FAKE_CODEX_FAIL_ON

export FAKE_CODEX_FAIL_ON='plugin marketplace add'
if run_setup "$migration_home" --non-interactive; then
    echo "Marketplace transition failure did not fail setup" >&2
    exit 1
fi
if [[ "$(yq -p=toml -oy -r '.marketplaces.mattpocock.ref // ""' "$migration_home/.codex/config.toml")" != '' ]]; then
    echo "Marketplace transition failure did not restore the prior ref" >&2
    exit 1
fi
if [[ ! -d "$migration_home/.codex/marketplace-root" || ! -f "$fake_installed" ]]; then
    echo "Marketplace transition failure lost the prior plugin state" >&2
    exit 1
fi
unset FAKE_CODEX_FAIL_ON
: > "$fake_marketplace"

export FAKE_CODEX_FAIL_ON='plugin add'
if run_setup "$migration_home" --non-interactive; then
    echo "Plugin install failure did not fail setup" >&2
    exit 1
fi
if [[ "$(yq -p=toml -oy -r '.marketplaces.mattpocock.ref // ""' "$migration_home/.codex/config.toml")" != '' || ! -d "$migration_home/.codex/marketplace-root" ]]; then
    echo "Plugin install failure did not restore the prior marketplace" >&2
    exit 1
fi
unset FAKE_CODEX_FAIL_ON

missing_home="$test_root/missing-home"
missing_bin="$test_root/missing-bin"
mkdir "$missing_home" "$missing_bin"
ln -s "$(command -v yq)" "$missing_bin/yq"
if HOME="$missing_home" PATH="$missing_bin:/usr/bin:/bin" /bin/bash "$repo_dir/ai/macos_setup.sh" --non-interactive > "$test_root/missing.out" 2>&1; then
    echo "Missing Codex command did not fail setup" >&2
    exit 1
fi
if ! rg -F -q 'Codex CLI is required' "$test_root/missing.out"; then
    echo "Missing Codex command did not report the cause" >&2
    exit 1
fi

failure_home="$test_root/failure-home"
mkdir "$failure_home"
fake_installed="$test_root/failure-installed"
fake_marketplace="$test_root/failure-marketplace"
export FAKE_CODEX_INSTALLED="$fake_installed"
export FAKE_CODEX_MARKETPLACE="$fake_marketplace"
export FAKE_CODEX_FAIL_ON='plugin marketplace add'
if run_setup "$failure_home" --non-interactive; then
    echo "Marketplace failure did not fail setup" >&2
    exit 1
fi
if [[ ! -L "$failure_home/.claude/CLAUDE.md" || ! -L "$failure_home/.codex/AGENTS.md" ]]; then
    echo "Marketplace failure removed instruction links" >&2
    exit 1
fi
unset FAKE_CODEX_FAIL_ON

echo "AI setup tests passed"
