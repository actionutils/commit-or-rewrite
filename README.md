# Commit or Rewrite (Pseudo-Amend) Action

A GitHub Action that intelligently creates or **pseudo-amends** commits using signed GitHub API commits. Perfect for automated commits that should update in-place rather than creating new commits every time.

## 🎯 Key Feature: Pseudo-Amend

This action implements a **pseudo-amend** functionality:

- **First run**: Creates a new commit with your specified ID
- **Subsequent runs with same ID**: If HEAD commit has the same ID, it **rewrites/amends** that commit
- **Different ID or no matching ID**: Creates a new commit

This prevents commit spam from automated tasks while maintaining a clean git history!

### How Pseudo-Amend Works

1. Each commit includes a hidden trailer: `X-Commit-Rewrite-ID: <your-id>`
2. When the action runs, it checks if HEAD has this exact trailer
3. **If HEAD has matching ID** → Rewrites that commit (pseudo-amend)
4. **If HEAD has different/no ID** → Creates a new commit

**Important**: The pseudo-amend ONLY happens when the HEAD commit has the matching ID. If there are other commits on top, a new commit will be created.

## ✨ Signed Commits via GitHub API

Using the GitHub API for commits provides automatic signing:
- **`GITHUB_TOKEN`** (default): Signed by GitHub Actions bot
- **GitHub App tokens**: Signed by your GitHub App
- **Fine-grained PATs**: Signed by the token owner

No GPG key configuration required - commits appear as "Verified" automatically!

## Usage

### Basic Usage (Auto-Amend Pattern)

```yaml
- name: Update generated files
  uses: actionutils/commit-or-rewrite@v1
  with:
    commit_message: 'chore: update generated files'
    id: 'generated-files-update'
    # Omit branch to auto-detect current branch
```

Running this multiple times will keep amending the same commit as long as it's the HEAD commit.

### Specific Files

```yaml
- name: Update changelog
  uses: actionutils/commit-or-rewrite@v1
  with:
    commit_message: 'docs: update changelog'
    id: 'changelog-auto-update'
    files: |
      CHANGELOG.md
      docs/releases.md
```

### With Custom Branch

```yaml
- name: Update on specific branch
  uses: actionutils/commit-or-rewrite@v1
  with:
    commit_message: 'chore: automated update'
    id: 'auto-update'
    branch: 'automation-branch'
    github_token: ${{ secrets.GITHUB_APP_TOKEN }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `commit_message` | Commit message (can be multiline) | Yes | - |
| `id` | Unique identifier for pseudo-amend | Yes | - |
| `branch` | Target branch (auto-detects if not specified) | No | `''` (auto-detect) |
| `files` | Files to commit (newline-separated). If empty, commits all changes | No | `''` (all changes) |
| `github_token` | GitHub token for API operations | No | `${{ github.token }}` |

## Real-World Examples

### Automated Dependency Updates (Weekly)

```yaml
name: Update Dependencies
on:
  schedule:
    - cron: '0 0 * * MON'  # Every Monday
  workflow_dispatch:

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2  # Need HEAD and its parent for pseudo-amend

      - name: Update npm dependencies
        run: |
          npx npm-check-updates -u
          npm install

      - name: Commit updates (pseudo-amends if run again)
        uses: actionutils/commit-or-rewrite@v1
        with:
          commit_message: 'chore: weekly dependency update'
          id: 'npm-deps-weekly'
          files: |
            package.json
            package-lock.json
```

If you run this workflow multiple times in the same week, it will keep updating the same commit instead of creating multiple "weekly update" commits.

### Generated Documentation

```yaml
name: Generate Docs
on:
  push:
    branches: [main]
    paths: ['src/**']

jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2

      - name: Generate API docs
        run: npm run generate-docs

      - name: Update docs (amends if regenerating)
        uses: actionutils/commit-or-rewrite@v1
        with:
          commit_message: 'docs: auto-generated API documentation'
          id: 'api-docs-auto'
          files: 'docs/api/'
```

### Build Artifacts

```yaml
- name: Build and commit dist
  run: npm run build

- name: Commit built files
  uses: actionutils/commit-or-rewrite@v1
  with:
    commit_message: 'build: update dist files'
    id: 'build-dist'
    files: 'dist/'
```

## When Does Pseudo-Amend Happen?

Pseudo-amend **ONLY** occurs when:
1. The HEAD commit has the trailer `X-Commit-Rewrite-ID: <your-id>`
2. You run the action with the same `id` value

Pseudo-amend **DOES NOT** occur when:
- HEAD commit has a different ID
- HEAD commit has no ID trailer
- There are other commits after the commit with matching ID

This ensures predictable behavior and prevents accidental rewrites of unrelated commits.

## Why Use This Action?

### Without This Action
- Multiple automated commits clutter history
- "Update dependencies" × 10 commits
- Manual squashing/rebasing needed
- Complex GPG setup for verified commits

### With This Action
- ✅ Clean history with pseudo-amend
- ✅ Automatic verified/signed commits
- ✅ No commit spam from automation
- ✅ No GPG configuration needed
- ✅ Predictable rewrite behavior

## Requirements

- The workflow must have write permissions to the repository (`contents: write`)
- When using custom tokens:
  - Fine-grained PATs: Need `contents: write` permission
  - GitHub Apps: Need `contents: write` permission
  - Classic PATs: Need `repo` scope

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and feature requests, please use the [GitHub Issues](https://github.com/actionutils/commit-or-rewrite/issues) page.
