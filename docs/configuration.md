# Configuration Guide

This document explains how to configure BMAD Ralph Loop for your project.

## Table of Contents

- [Sprint Status File](#sprint-status-file)
- [Environment Variables](#environment-variables)
- [Directory Structure](#directory-structure)
- [Customizing Workflows](#customizing-workflows)

---

## Sprint Status File

The sprint status file (`sprint-status.yaml`) is the core configuration that drives BMAD Ralph Loop.

### Location

Default location:
```
your-project/
└── _bmad-output/
    └── implementation-artifacts/
        └── sprint-status.yaml
```

Override with environment variable:
```bash
export RALPH_SPRINT_STATUS="/path/to/your/sprint-status.yaml"
```

### Format

```yaml
# Required: Sprint metadata
sprint_info:
  sprint_number: 1
  sprint_goal: "Your sprint goal"

# Required: Development status tracking
development_status:
  epic-1: "in-progress"    # Epic status
  1-1: "done"              # Story status
  1-2: "ready-for-dev"
  1-3: "backlog"
```

### Status Values

| Status | Description | What happens |
|--------|-------------|--------------|
| `backlog` | Story not started | Runs `create-story` workflow |
| `ready-for-dev` | Story file exists | Runs `dev-story` workflow |
| `review` | Implementation done | Runs `code-review` workflow |
| `done` | Story completed | Skipped |
| `blocked` | Story blocked | Skipped |
| `in-progress` | For epics only | Shows epic is active |

### Story Key Format

Stories use the format `{epic}-{story}`:
- `1-1` = Epic 1, Story 1
- `2-3` = Epic 2, Story 3
- `10-5` = Epic 10, Story 5

Epics use the format `epic-{number}`:
- `epic-1` = Epic 1
- `epic-2` = Epic 2

### Optional Fields

```yaml
# Story point estimates
story_points:
  1-1: 3
  1-2: 5

# Dependencies
dependencies:
  1-3: ["1-1", "1-2"]  # 1-3 depends on 1-1 and 1-2

# Notes and blockers
notes:
  1-4: "Waiting for API credentials"

# Retrospective tracking
retrospectives:
  epic-1-retrospective: "pending"
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RALPH_PROJECT_ROOT` | Current directory | Project root path |
| `RALPH_SPRINT_STATUS` | `_bmad-output/implementation-artifacts/sprint-status.yaml` | Sprint status file path |
| `RALPH_LOG_DIR` | `logs/` | Directory for log files |
| `RALPH_CODEX_FULL_AUTO` | `true` | Use `--full-auto` with Codex exec |
| `RALPH_CODEX_SANDBOX` | *(empty)* | Codex sandbox mode (e.g., `danger-full-access`) |
| `RALPH_CODEX_MODEL` | *(empty)* | Codex model override |
| `RALPH_CODEX_SEARCH` | `false` | Enable `codex --search` |

Codex-specific options apply when running `codex-ralph-loop`.

### Setting Environment Variables

Temporary (current session):
```bash
export RALPH_PROJECT_ROOT="/path/to/project"
export RALPH_SPRINT_STATUS="/custom/path/sprint.yaml"
export RALPH_LOG_DIR="/var/log/ralph"
```

Permanent (add to `~/.bashrc` or `~/.zshrc`):
```bash
echo 'export RALPH_PROJECT_ROOT="/path/to/project"' >> ~/.bashrc
source ~/.bashrc
```

### Using a `.env` File

Create a `.env` file in your project root:
```bash
# .env
RALPH_PROJECT_ROOT=/path/to/project
RALPH_SPRINT_STATUS=config/sprint-status.yaml
RALPH_LOG_DIR=.logs
RALPH_CODEX_SANDBOX=danger-full-access
```

Load it before running:
```bash
source .env && claude-ralph-loop
```

---

## Directory Structure

### Expected BMAD Structure

```
your-project/
├── _bmad-output/
│   ├── planning-artifacts/
│   │   ├── epic-1.md
│   │   ├── epic-2.md
│   │   └── ...
│   └── implementation-artifacts/
│       ├── sprint-status.yaml
│       ├── 1-1.md              # Story files
│       ├── 1-2.md
│       └── ...
├── src/                        # Your source code
├── logs/                       # Ralph logs
└── ...
```

### Minimal Structure

At minimum, you need:
```
your-project/
├── _bmad-output/
│   └── implementation-artifacts/
│       └── sprint-status.yaml
└── ...
```

Story and epic files will be created by the selected agent during workflow execution.

---

## Customizing Workflows

### Available Workflows

| Workflow | Agent | Description |
|----------|-------|-------------|
| `create-story` | SM | Creates story file from epic |
| `dev-story` | DEV | Implements the story |
| `code-review` | DEV | Reviews implementation |
| `sprint-planning` | SM | Creates sprint status |
| `retrospective` | SM | Runs epic retrospective |

### Skipping Workflows

Skip code review:
```bash
claude-ralph-loop --skip-review
```

### Custom Workflow Order

The default workflow order is:
1. `create-story` (backlog → ready-for-dev)
2. `dev-story` (ready-for-dev → review)
3. `code-review` (review → done)

To change this, modify the `process_story()` function in the script.

### Custom Agents

BMAD Ralph Loop uses BMAD agents (`SM` and `DEV`). These agents are loaded through the BMAD agent system.

To use custom agents:
1. Define your agents in your project's BMAD configuration
2. Modify the `run_agent_workflow()` calls in `ralph-loop-core.sh`

---

## Advanced Configuration

### Parallel Processing

Currently, stories are processed sequentially. For parallel processing, you would need to:
1. Fork the script
2. Modify the main loop to use background processes
3. Handle concurrent YAML updates carefully

### Custom Commit Messages

Modify the `commit_story_changes()` function:

```bash
git commit -m "$(cat <<EOF
feat(epic-$epic_num): implement $story_key

Your custom message format here

Automated by BMAD Ralph Loop
EOF
)"
```

### Integration with CI/CD

Example GitHub Actions workflow:

```yaml
# .github/workflows/ralph.yml
name: BMAD Ralph Loop

on:
  workflow_dispatch:
    inputs:
      epic:
        description: 'Epic number to process'
        required: false

jobs:
  implement:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Agent CLI
        run: echo "Install Claude Code CLI or OpenAI Codex CLI"

      - name: Setup yq
        run: sudo snap install yq

      - name: Run BMAD Ralph Loop
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          LOOP_CMD="./claude-ralph-loop.sh"
          # For Codex, use:
          # LOOP_CMD="./codex-ralph-loop.sh"
          if [ -n "${{ inputs.epic }}" ]; then
            $LOOP_CMD --epic ${{ inputs.epic }}
          else
            $LOOP_CMD
          fi
```

---

## Troubleshooting Configuration

### Status not updating

Check file permissions:
```bash
ls -la _bmad-output/implementation-artifacts/sprint-status.yaml
```

Verify yq can write to the file:
```bash
yq -i '.test = "value"' sprint-status.yaml
yq '.test' sprint-status.yaml  # Should output: value
yq -i 'del(.test)' sprint-status.yaml
```

### Stories not being found

Verify your status format:
```bash
yq '.development_status' sprint-status.yaml
```

Check for correct key format:
```yaml
# Correct
development_status:
  1-1: "backlog"

# Incorrect (will not be found)
development_status:
  story-1-1: "backlog"
  "1.1": "backlog"
```

### Logs location

Check where logs are being written:
```bash
# Default location
ls -la logs/

# Or check the log path printed at startup
claude-ralph-loop --verbose 2>&1 | head -20
```
