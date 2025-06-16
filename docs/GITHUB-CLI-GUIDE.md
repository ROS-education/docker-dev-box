# GitHub CLI (gh) Command Guide

## What is GitHub CLI?

GitHub CLI (`gh`) is the official command-line tool for GitHub that brings GitHub functionality to your terminal. It allows you to interact with GitHub repositories, issues, pull requests, actions, and more without leaving your command line.

## Installation

The GitHub CLI is now included in your Docker dev environment. After rebuilding your container, you'll have access to `gh`.

### Manual Installation (if needed)
```bash
# On Ubuntu/Debian
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh
```

## Authentication

### First-time setup
```bash
# Authenticate with GitHub
gh auth login

# Check authentication status
gh auth status

# List available authentication tokens
gh auth token
```

### Authentication options
- **Web browser flow** (recommended)
- **Personal access token**
- **SSH key authentication**

## Core Commands

### Repository Management
```bash
# Clone a repository
gh repo clone owner/repo-name

# Create a new repository
gh repo create my-new-repo
gh repo create my-org/my-new-repo --public
gh repo create my-new-repo --private --description "My description"

# View repository information
gh repo view
gh repo view owner/repo-name

# Fork a repository
gh repo fork owner/repo-name

# List your repositories
gh repo list
gh repo list owner-name

# Delete a repository
gh repo delete owner/repo-name
```

### Pull Requests
```bash
# Create a pull request
gh pr create
gh pr create --title "My PR" --body "Description of changes"
gh pr create --draft  # Create as draft PR

# List pull requests
gh pr list
gh pr list --state open
gh pr list --author @me

# View a pull request
gh pr view 123
gh pr view --web 123  # Open in browser

# Checkout a pull request locally
gh pr checkout 123

# Review a pull request
gh pr review 123 --approve
gh pr review 123 --request-changes --body "Please fix..."
gh pr review 123 --comment --body "Looks good but..."

# Merge a pull request
gh pr merge 123
gh pr merge 123 --squash
gh pr merge 123 --rebase

# Close a pull request
gh pr close 123
```

### Issues
```bash
# Create an issue
gh issue create
gh issue create --title "Bug report" --body "Description"

# List issues
gh issue list
gh issue list --state open
gh issue list --assignee @me

# View an issue
gh issue view 456
gh issue view --web 456

# Close an issue
gh issue close 456

# Reopen an issue
gh issue reopen 456
```

### GitHub Actions
```bash
# List workflow runs
gh run list

# View a specific run
gh run view 12345

# Watch a running workflow
gh run watch

# Rerun a workflow
gh run rerun 12345

# List workflows
gh workflow list

# Trigger a workflow
gh workflow run workflow-name.yml
```

### Releases
```bash
# Create a release
gh release create v1.0.0
gh release create v1.0.0 --title "Version 1.0.0" --notes "Release notes"

# List releases
gh release list

# View a release
gh release view v1.0.0

# Download release assets
gh release download v1.0.0
```

### Gists
```bash
# Create a gist
gh gist create file.txt
gh gist create file.txt --public
gh gist create --desc "My gist description" file1.txt file2.txt

# List your gists
gh gist list

# View a gist
gh gist view gist-id

# Edit a gist
gh gist edit gist-id

# Clone a gist
gh gist clone gist-id
```

## Advanced Features

### Aliases
```bash
# Create custom aliases
gh alias set co 'pr checkout'
gh alias set pv 'pr view --web'

# List aliases
gh alias list

# Use aliases
gh co 123  # Same as 'gh pr checkout 123'
```

### Extensions
```bash
# List available extensions
gh extension list

# Install an extension
gh extension install owner/gh-extension-name

# Search for extensions
gh search repos gh-extension
```

### API Access
```bash
# Make API requests
gh api /user
gh api /repos/owner/repo/issues
gh api --method POST /repos/owner/repo/issues --field title="Issue title"
```

## Configuration

### Configuration files
- Global config: `~/.config/gh/config.yml`
- Host-specific config: `~/.config/gh/hosts.yml`

### Common configuration
```bash
# Set default editor
gh config set editor vim

# Set default protocol
gh config set git_protocol ssh

# View current configuration
gh config list
```

## Common Workflows

### Contributing to a project
```bash
# 1. Fork the repository
gh repo fork original-owner/repo-name

# 2. Clone your fork
gh repo clone your-username/repo-name

# 3. Create a branch and make changes
git checkout -b feature-branch

# 4. Push changes and create PR
git push origin feature-branch
gh pr create --title "Add new feature"
```

### Project management
```bash
# View project overview
gh repo view --web

# Check CI status
gh run list --limit 5

# Review pending PRs
gh pr list --review-requested @me
```

### Release management
```bash
# Create and publish a release
gh release create v1.2.0 \
  --title "Version 1.2.0" \
  --notes "$(git log --oneline $(git describe --tags --abbrev=0)..HEAD)" \
  dist/*
```

## Tips and Best Practices

1. **Use `--web` flag** to open things in browser when needed
2. **Set up aliases** for frequently used commands
3. **Use templates** for consistent PR and issue creation
4. **Leverage tab completion** for better UX
5. **Use `gh status`** to see repository overview

## Integration with VS Code

GitHub CLI works great with VS Code:
- Use `gh repo clone` to clone repositories
- Use `gh pr checkout` to review PRs locally
- Use `gh issue create` to quickly create issues

## Troubleshooting

### Common issues
```bash
# Check authentication
gh auth status

# Re-authenticate
gh auth login --web

# Check version
gh --version

# Get help for any command
gh <command> --help
```

The GitHub CLI is an essential tool for modern Git workflows and will be available in your dev container after rebuilding!
