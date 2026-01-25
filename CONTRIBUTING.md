# Contributing to BMAD Ralph Loop

Thank you for your interest in contributing to BMAD Ralph Loop! This document provides guidelines and information about contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features](#suggesting-features)
  - [Pull Requests](#pull-requests)
- [Development Setup](#development-setup)
- [Style Guidelines](#style-guidelines)
- [Commit Messages](#commit-messages)

## Code of Conduct

This project follows a simple code of conduct: be respectful, be constructive, and be helpful. We're all here to build something useful together.

## How Can I Contribute?

### Reporting Bugs

Before creating a bug report, please check existing issues to avoid duplicates.

When creating a bug report, include:

1. **Clear title** - Summarize the issue
2. **Environment details**
   - OS and version
   - Bash version (`bash --version`)
   - Claude Code CLI version (`claude --version`) or OpenAI Codex CLI version (from `codex` output)
   - yq version (`yq --version`)
3. **Steps to reproduce** - List the exact steps
4. **Expected behavior** - What should happen
5. **Actual behavior** - What actually happens
6. **Logs** - Include relevant log output (use `--verbose` flag)

Example:

```markdown
## Bug: Story status not updating after implementation

### Environment
- macOS 14.2
- Bash 5.2.15
- Claude Code CLI 1.0.0
- yq 4.35.1

### Steps to Reproduce
1. Run `claude-ralph-loop --story 1-1`
2. Wait for implementation to complete
3. Check sprint-status.yaml

### Expected
Status should be "review"

### Actual
Status remains "ready-for-dev"

### Logs
[Attach log file from logs/ directory]
```

### Suggesting Features

Feature requests are welcome! Please include:

1. **Problem statement** - What problem does this solve?
2. **Proposed solution** - How should it work?
3. **Alternatives considered** - What other approaches did you think of?
4. **Additional context** - Screenshots, examples, etc.

### Pull Requests

1. **Fork** the repository
2. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/my-feature
   # or
   git checkout -b fix/bug-description
   ```
3. **Make your changes**
4. **Test thoroughly**
5. **Commit** with clear messages (see [Commit Messages](#commit-messages))
6. **Push** to your fork
7. **Open a Pull Request**

#### PR Checklist

- [ ] Code follows the [style guidelines](#style-guidelines)
- [ ] Self-reviewed the changes
- [ ] Tested with `--dry-run` flag
- [ ] Tested actual execution
- [ ] Updated documentation if needed
- [ ] Added examples if introducing new features

## Development Setup

1. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/claude-ralph-loop.git
   cd claude-ralph-loop
   ```

2. Make the scripts executable:
   ```bash
   chmod +x ralph-loop-core.sh claude-ralph-loop.sh codex-ralph-loop.sh
   ```

3. Test locally:
   ```bash
   ./claude-ralph-loop.sh --help
   ./claude-ralph-loop.sh --dry-run
   # or, using Codex
   ./codex-ralph-loop.sh --help
   ```

4. Run shellcheck for linting:
   ```bash
   # Install shellcheck
   brew install shellcheck  # macOS
   # or
   apt install shellcheck   # Linux

   # Run checks
   shellcheck ralph-loop-core.sh claude-ralph-loop.sh codex-ralph-loop.sh
   ```

## Style Guidelines

### Shell Script Style

We follow Google's Shell Style Guide with some modifications:

1. **Indentation**: 4 spaces (no tabs)
2. **Line length**: 100 characters max
3. **Quoting**: Always quote variables: `"$var"` not `$var`
4. **Functions**: Use lowercase with underscores: `my_function_name`
5. **Constants**: Use uppercase: `MY_CONSTANT`
6. **Comments**: Use `#` with a space after

Example:

```bash
# Good
my_function() {
    local my_var="$1"

    if [[ -n "$my_var" ]]; then
        echo "Variable is set: $my_var"
    fi
}

# Bad
myFunction() {
    local myVar=$1
    if [ -n $myVar ]; then
        echo "Variable is set: $myVar"
    fi
}
```

### Shellcheck Compliance

All code must pass shellcheck without warnings:

```bash
shellcheck ralph-loop-core.sh claude-ralph-loop.sh codex-ralph-loop.sh
```

If you need to disable a specific check, document why:

```bash
# shellcheck disable=SC2034  # Variable used in sourced file
UNUSED_VAR="value"
```

### Documentation Style

- Use clear, concise language
- Include code examples
- Keep markdown files well-formatted
- Use proper headings hierarchy

## Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, no code change
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```
feat(workflow): add support for parallel story processing

fix(status): correctly update epic status on completion

docs(readme): add troubleshooting section

refactor(logging): simplify log function for better readability
```

## Questions?

Feel free to open an issue with the `question` label if you need clarification on anything.

---

Thank you for contributing!
