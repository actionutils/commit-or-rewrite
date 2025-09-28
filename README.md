# Commit or Rewrite (Signed) Action

A GitHub Action that creates signed/verified commits or intelligently rewrites existing ones based on git trailer detection. This action uses the GitHub API to create commits, which means commits will be properly signed and verified when using GitHub's default `GITHUB_TOKEN` or GitHub App tokens - no GPG key setup required!

## Features

- **Signed/Verified Commits**: When using `GITHUB_TOKEN` or GitHub App tokens, commits are automatically signed and show as "Verified" on GitHub
- **Smart Commit Rewriting**: Automatically detects and rewrites previous commits with the same trailer ID
- **Git Trailer Support**: Uses git trailers (X-Commit-Rewrite-ID) to identify rewritable commits
- **Flexible File Selection**: Commit all changes or specific files
- **No GPG Setup Required**: Leverages GitHub API for commit signing

## How It Works

1. **Change Detection**: Checks for changes in the repository
2. **Trailer Check**: Looks for a matching `X-Commit-Rewrite-ID` trailer in the HEAD commit
3. **Smart Rewrite**: If a matching trailer is found, resets to the parent commit
4. **API Commit**: Creates a new commit using GitHub API (which provides automatic signing)
5. **Local Sync**: Synchronizes local git state with the remote

## Signed Commits with GitHub API

This action uses the GitHub API to create commits instead of traditional git commands. When using:
- **`GITHUB_TOKEN`** (default): Commits are signed by GitHub Actions bot
- **GitHub App tokens**: Commits are signed by your GitHub App
- **Personal Access Tokens**: Commits are signed by the token owner

All these methods result in verified commits without requiring GPG key configuration!

## Usage

### Basic Usage

```yaml
- name: Commit changes
  uses: actionutils/commit-or-rewrite@v1
  with:
    commit_message: 'Update dependencies'
    trailer_id: 'deps-update'
    # branch is optional - auto-detects current branch if not specified
```

### Commit Specific Files

```yaml
- name: Commit specific files
  uses: actionutils/commit-or-rewrite@v1
  with:
    commit_message: |
      Update documentation

      - Added API examples
      - Fixed typos
    trailer_id: 'docs-update'
    branch: 'main'
    files: |
      README.md
      docs/api.md
```

### With Custom GitHub Token

```yaml
- name: Commit with GitHub App token
  uses: actionutils/commit-or-rewrite@v1
  with:
    commit_message: 'Automated update'
    trailer_id: 'auto-update'
    branch: 'main'
    github_token: ${{ secrets.GITHUB_APP_TOKEN }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `commit_message` | Commit message (can be multiline) | Yes | - |
| `trailer_id` | Unique identifier for the trailer (e.g., `changelog-update`) | Yes | - |
| `branch` | Target branch (auto-detects current branch if not specified) | No | `''` (auto-detect) |
| `files` | Files to commit (newline-separated). If empty, commits all changes | No | `''` (all changes) |
| `github_token` | GitHub token for API operations | No | `${{ github.token }}` |

## Trailer System

This action uses git trailers to identify commits that can be rewritten. Each commit created includes a trailer:

```
X-Commit-Rewrite-ID: <your-trailer-id>
```

When the action runs again with the same `trailer_id`:
1. If the HEAD commit has this trailer → Rewrites that commit
2. If the HEAD commit doesn't have this trailer → Creates a new commit

This is perfect for:
- Automated dependency updates
- Generated documentation
- Build artifacts
- Any repeated automated commits

## Example Workflow

### Auto-update Dependencies

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

      - name: Update npm dependencies
        run: |
          npx npm-check-updates -u
          npm install

      - name: Commit updates
        uses: actionutils/commit-or-rewrite@v1
        with:
          commit_message: 'chore: update npm dependencies'
          trailer_id: 'npm-deps-weekly'
          branch: 'main'
          files: |
            package.json
            package-lock.json
```

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

      - name: Generate API docs
        run: npm run generate-docs

      - name: Commit documentation
        uses: actionutils/commit-or-rewrite@v1
        with:
          commit_message: 'docs: update API documentation'
          trailer_id: 'api-docs-auto'
          branch: 'main'
          files: 'docs/api/'
```

## Why Use This Action?

### Traditional Git Commits in Actions
- Require GPG key setup for signed commits
- Show as "unverified" without proper configuration
- Complex setup for bot commits

### This Action
- ✅ Automatic commit signing via GitHub API
- ✅ Shows as "Verified" on GitHub
- ✅ Smart rewriting prevents commit spam
- ✅ No GPG configuration needed
- ✅ Works with default `GITHUB_TOKEN`

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
