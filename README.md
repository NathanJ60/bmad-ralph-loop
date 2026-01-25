# BMAD Ralph Loop

[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)
[![Claude Code](https://img.shields.io/badge/For-Claude%20Code-blueviolet)](https://claude.ai)
[![BMAD Method](https://img.shields.io/badge/BMAD-Method-orange)](https://github.com/bmad-method)

> **Automate your BMAD development workflow with Claude Code CLI or OpenAI Codex CLI**

BMAD Ralph Loop is a CLI automation tool that orchestrates development cycles using Claude Code CLI or OpenAI Codex CLI and the BMAD Method agents. It manages the complete story lifecycle: from story creation by the Scrum Master agent, through implementation by the Developer agent, to code review — all running autonomously.

![Demo](docs/assets/demo.gif)
*Demo placeholder - Record your own workflow!*

---

## Features

- **Autonomous Development Loop** — Runs the full cycle: create-story → dev-story → code-review
- **BMAD Method Integration** — Built for the BMAD (BMad Agile Development) methodology
- **Multi-Agent Orchestration** — Coordinates SM (Scrum Master) and DEV (Developer) agents
- **Sprint Status Tracking** — YAML-based status management with automatic updates
- **Intelligent Story Processing** — Handles backlog, ready-for-dev, review, and done states
- **Epic Management** — Automatic epic completion detection and retrospectives
- **Dry-Run Mode** — Preview all actions before execution
- **Selective Processing** — Target specific epics or individual stories
- **Auto-Commit** — Commits changes with proper conventional commit messages
- **Verbose Logging** — Detailed logs for debugging and audit trails

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/NathanJ60/bmad-ralph-loop.git
cd claude-ralph-loop

# 2. Install
./install.sh

# 3. Run in your project
cd /path/to/your/project
claude-ralph-loop
# or, using Codex
codex-ralph-loop
```

---

## Installation

### Prerequisites

- **Claude Code CLI** — [Install from claude.ai](https://claude.ai)
- **OpenAI Codex CLI** — [Install from OpenAI docs](https://developers.openai.com/codex/cli)
- **yq** — YAML processor
- **Bash 4+** — Modern bash shell

Install at least one provider CLI (Claude or Codex).

### Via Install Script (Recommended)

```bash
git clone https://github.com/NathanJ60/bmad-ralph-loop.git
cd claude-ralph-loop
./install.sh
```

### Manual Installation

```bash
# Clone
git clone https://github.com/NathanJ60/bmad-ralph-loop.git

# Make executable
chmod +x claude-ralph-loop/claude-ralph-loop.sh claude-ralph-loop/codex-ralph-loop.sh

# Add to PATH (choose one). Keep the core and wrappers together.
sudo cp claude-ralph-loop/ralph-loop-core.sh /usr/local/bin/ralph-loop-core.sh
sudo cp claude-ralph-loop/claude-ralph-loop.sh /usr/local/bin/claude-ralph-loop
sudo cp claude-ralph-loop/codex-ralph-loop.sh /usr/local/bin/codex-ralph-loop
# OR (user-only)
cp claude-ralph-loop/ralph-loop-core.sh ~/bin/ralph-loop-core.sh
cp claude-ralph-loop/claude-ralph-loop.sh ~/bin/claude-ralph-loop
cp claude-ralph-loop/codex-ralph-loop.sh ~/bin/codex-ralph-loop
```

### Install Dependencies

```bash
# macOS
brew install yq

# Linux (Debian/Ubuntu)
sudo apt install yq

# Linux (snap)
sudo snap install yq
```

---

## Usage

```bash
claude-ralph-loop [OPTIONS]
# or
codex-ralph-loop [OPTIONS]
```

### Options

| Flag | Description |
|------|-------------|
| `--dry-run` | Preview actions without executing |
| `--epic N` | Process only stories from epic N |
| `--story X-Y` | Process a specific story (e.g., `1-2`) |
| `--skip-review` | Skip the code-review step |
| `--verbose` | Show detailed agent output |
| `--help` | Display help message |

### Examples

```bash
# Process all pending stories
claude-ralph-loop

# Preview what would happen
claude-ralph-loop --dry-run

# Process only Epic 2 stories
claude-ralph-loop --epic 2

# Process a single story
claude-ralph-loop --story 1-3

# Fast mode: skip code review
claude-ralph-loop --skip-review

# Debug mode: see all output
claude-ralph-loop --verbose

# Use Codex instead of Claude
codex-ralph-loop
```

### Choose Your CLI

Use `claude-ralph-loop` for Claude Code CLI or `codex-ralph-loop` for OpenAI Codex CLI.

---

## Configuration

### Sprint Status File

BMAD Ralph Loop expects a `sprint-status.yaml` file in your project. Default location:

```
your-project/
└── _bmad-output/
    └── implementation-artifacts/
        └── sprint-status.yaml
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RALPH_PROJECT_ROOT` | Auto-detected | Project root directory |
| `RALPH_SPRINT_STATUS` | `_bmad-output/implementation-artifacts/sprint-status.yaml` | Path to sprint status |
| `RALPH_LOG_DIR` | `scripts/logs` | Directory for log files |

### Sprint Status Format

```yaml
# sprint-status.yaml
sprint_info:
  sprint_number: 1
  sprint_goal: "MVP Implementation"

development_status:
  epic-1: "in-progress"
  1-1: "done"
  1-2: "ready-for-dev"
  1-3: "backlog"
  epic-2: "backlog"
  2-1: "backlog"
  2-2: "backlog"
```

See [examples/sprint-status.example.yaml](examples/sprint-status.example.yaml) for a complete example.

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                    BMAD Ralph Loop                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐  │
│   │ BACKLOG │ ──▶ │ READY   │ ──▶ │ REVIEW  │ ──▶ │  DONE   │  │
│   │         │     │ FOR DEV │     │         │     │         │  │
│   └─────────┘     └─────────┘     └─────────┘     └─────────┘  │
│        │               │               │               │        │
│        ▼               ▼               ▼               ▼        │
│   ┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐  │
│   │   SM    │     │   DEV   │     │   DEV   │     │  AUTO   │  │
│   │ create  │     │  dev    │     │  code   │     │ COMMIT  │  │
│   │ -story  │     │ -story  │     │ -review │     │         │  │
│   └─────────┘     └─────────┘     └─────────┘     └─────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Workflow Steps

1. **Story Creation (SM Agent)**
   - Reads epic requirements from planning artifacts
   - Creates detailed story file with acceptance criteria
   - Updates status: `backlog` → `ready-for-dev`

2. **Story Implementation (DEV Agent)**
   - Reads story file and implements requirements
   - Writes code, tests, and documentation
   - Updates status: `ready-for-dev` → `review`

3. **Code Review (DEV Agent)**
   - Reviews implementation against story requirements
   - Auto-fixes issues found
   - Updates status: `review` → `done`

4. **Auto-Commit**
   - Commits all changes with conventional commit format
   - Message: `feat(epic-N): implement X-Y`

---

## BMAD Method Integration

BMAD Ralph Loop **automates Step 3: Build Your Project** from the [BMAD Method](https://github.com/bmad-method/BMAD-METHOD) — a structured approach to AI-assisted software development.

### Where BMAD Ralph Loop Fits

```
BMAD Method Workflow:
├── Phase 1: Discovery (BA Agent)
├── Phase 2: Planning (PM Agent)
├── Phase 3: Solutioning (Architect + PM Agents)
└── Step 3: Build Your Project ◀── CLAUDE RALPH LOOP AUTOMATES THIS
    │
    ├── Sprint Planning (SM Agent)
    └── Build Cycle (repeated for each story):
        ├── create-story (SM Agent)
        ├── dev-story (DEV Agent)
        └── code-review (DEV Agent)
```

### The Build Cycle

In the BMAD Method, each story goes through this cycle:

| Step | Agent | Workflow | Purpose |
|------|-------|----------|---------|
| 1 | SM | `create-story` | Create story file from epic |
| 2 | DEV | `dev-story` | Implement the story |
| 3 | DEV | `code-review` | Quality validation |

**BMAD Ralph Loop automates this entire cycle**, running each workflow autonomously in sequence for every pending story.

### Prerequisites

Before using BMAD Ralph Loop, complete the BMAD planning phases:
1. **Phase 1**: Run BA agent workflows (discovery, analysis)
2. **Phase 2**: Run PM agent workflows (PRD creation)
3. **Phase 3**: Run Architect + PM workflows (architecture, epics & stories)
4. **Initialize Sprint**: Run SM agent `sprint-planning` workflow

Then let BMAD Ralph Loop handle the implementation automation.

### Expected Artifacts

The tool expects BMAD-style artifacts:
- Epic definitions in `_bmad-output/planning-artifacts/`
- Story templates following BMAD conventions
- Sprint status tracking in `sprint-status.yaml`

---

## Requirements

| Requirement | Version | Notes |
|-------------|---------|-------|
| Claude Code CLI | Latest | Install from [claude.ai](https://claude.ai) |
| OpenAI Codex CLI | Latest | Install from [OpenAI docs](https://developers.openai.com/codex/cli) |
| yq | 4.x+ | YAML processor |
| Bash | 4.0+ | Modern bash features |
| Git | 2.x+ | For auto-commit feature |

### Check Your Setup

```bash
# Verify all dependencies (use the provider you selected)
claude --version  # Claude Code CLI
codex             # OpenAI Codex CLI (if using codex-ralph-loop)
yq --version
bash --version
git --version
```

---

## Troubleshooting

### "Claude Code CLI not found"

Install Claude Code CLI from [claude.ai](https://claude.ai)

### "Codex CLI not found"

Install OpenAI Codex CLI from [OpenAI docs](https://developers.openai.com/codex/cli)

### "yq not found"

```bash
# macOS
brew install yq

# Linux
sudo snap install yq
```

### "sprint-status.yaml not found"

Run sprint planning first or create the file manually. See [examples/sprint-status.example.yaml](examples/sprint-status.example.yaml).

### "Story file NOT created"

The SM agent failed to create the story. Check:
1. Epic definitions exist in `_bmad-output/planning-artifacts/`
2. Agent CLI has necessary permissions
3. Run with `--verbose` for detailed output

---

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Contribution Guide

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Credits

**Author:** Nathan Jacas

**Built for:** [BMAD Method](https://github.com/bmad-method/BMAD-METHOD)

---

## Star History

If you find this useful, please star the repo!

```
         ⭐ Star this repo to support the project! ⭐
```
