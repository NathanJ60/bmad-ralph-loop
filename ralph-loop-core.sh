#!/bin/bash
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║   ██████╗██╗      █████╗ ██╗   ██╗██████╗ ███████╗                        ║
# ║  ██╔════╝██║     ██╔══██╗██║   ██║██╔══██╗██╔════╝                        ║
# ║  ██║     ██║     ███████║██║   ██║██║  ██║█████╗                          ║
# ║  ██║     ██║     ██╔══██║██║   ██║██║  ██║██╔══╝                          ║
# ║  ╚██████╗███████╗██║  ██║╚██████╔╝██████╔╝███████╗                        ║
# ║   ╚═════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝                        ║
# ║                                                                           ║
# ║  ██████╗  █████╗ ██╗     ██████╗ ██╗  ██╗    ██╗      ██████╗  ██████╗ ██████╗  ║
# ║  ██╔══██╗██╔══██╗██║     ██╔══██╗██║  ██║    ██║     ██╔═══██╗██╔═══██╗██╔══██╗ ║
# ║  ██████╔╝███████║██║     ██████╔╝███████║    ██║     ██║   ██║██║   ██║██████╔╝ ║
# ║  ██╔══██╗██╔══██║██║     ██╔═══╝ ██╔══██║    ██║     ██║   ██║██║   ██║██╔═══╝  ║
# ║  ██║  ██║██║  ██║███████╗██║     ██║  ██║    ███████╗╚██████╔╝╚██████╔╝██║      ║
# ║  ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝    ╚══════╝ ╚═════╝  ╚═════╝ ╚═╝      ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# BMAD Ralph Loop - Autonomous Development Workflow Automation
# ==============================================================
# Automates the development loop: SM create-story -> DEV dev-story -> DEV code-review
#
# Usage:
#   claude-ralph-loop              # Process all pending stories
#   codex-ralph-loop               # Same workflow using Codex
#   claude-ralph-loop --dry-run    # Preview without executing
#   claude-ralph-loop --epic 1     # Process only epic 1
#   claude-ralph-loop --story 1-1  # Process specific story
#
# Repository: https://github.com/NathanJ60/bmad-ralph-loop
# License: MIT
#

set -e

# =============================================================================
# Configuration
# =============================================================================

# Auto-detect project root (can be overridden with RALPH_PROJECT_ROOT)
if [[ -n "$RALPH_PROJECT_ROOT" ]]; then
    PROJECT_ROOT="$RALPH_PROJECT_ROOT"
else
    PROJECT_ROOT="$(pwd)"
fi

# Output directories (BMAD-compatible structure)
BMAD_OUTPUT="$PROJECT_ROOT/_bmad-output"
PLANNING_ARTIFACTS="$BMAD_OUTPUT/planning-artifacts"
IMPLEMENTATION_ARTIFACTS="$BMAD_OUTPUT/implementation-artifacts"

# Sprint status file (can be overridden with RALPH_SPRINT_STATUS)
if [[ -n "$RALPH_SPRINT_STATUS" ]]; then
    SPRINT_STATUS="$RALPH_SPRINT_STATUS"
else
    SPRINT_STATUS="$IMPLEMENTATION_ARTIFACTS/sprint-status.yaml"
fi

# Logging
LOG_DIR="${RALPH_LOG_DIR:-$PROJECT_ROOT/logs}"
LOG_FILE="$LOG_DIR/ralph-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Flags
DRY_RUN=false
SPECIFIC_EPIC=""
SPECIFIC_STORY=""
SKIP_CODE_REVIEW=false
VERBOSE=false

# Provider selection (claude|codex)
PROVIDER="${PROVIDER:-claude}"

# Codex options (only used when PROVIDER=codex)
CODEX_FULL_AUTO="${RALPH_CODEX_FULL_AUTO:-true}"
CODEX_SANDBOX="${RALPH_CODEX_SANDBOX:-}"
CODEX_MODEL="${RALPH_CODEX_MODEL:-}"
CODEX_SEARCH="${RALPH_CODEX_SEARCH:-false}"

# =============================================================================
# Helper Functions
# =============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Ensure log directory exists
    mkdir -p "$LOG_DIR"

    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    # Log to console with colors
    case "$level" in
        INFO)  echo -e "${BLUE}[i]${NC} $message" ;;
        OK)    echo -e "${GREEN}[+]${NC} $message" ;;
        WARN)  echo -e "${YELLOW}[!]${NC} $message" ;;
        ERROR) echo -e "${RED}[x]${NC} $message" ;;
        STEP)  echo -e "${CYAN}[>]${NC} $message" ;;
    esac
}

banner() {
    echo ""
    echo -e "${MAGENTA}"
    echo "  ____        _         _       _"
    echo " |  _ \\ __ _ | |_ __ _ | |__   | |    ___   ___  _ __"
    echo " | |_) / _\` || | '_ \` || '_ \  | |   / _ \\ / _ \\| '_ \\"
    echo " |  _ < (_| || | |_) || | | | | |__| (_) | (_) | |_) |"
    echo " |_| \\_\\__,_||_| .__/ |_| |_| |_____\\___/ \\___/| .__/"
    echo "               |_|                             |_|"
    echo -e "${NC}"
    echo -e "${CYAN}  Autonomous Development Workflow Automation${NC}"
    echo ""
}

usage() {
    local cli_name
    cli_name="$(basename "$0")"
    echo "Usage: $cli_name [OPTIONS]"
    echo ""
    case "$PROVIDER" in
        claude)
            echo "Automate your BMAD development workflow with Claude Code CLI."
            ;;
        codex)
            echo "Automate your BMAD development workflow with OpenAI Codex CLI."
            ;;
        *)
            echo "Automate your BMAD development workflow with the selected agent CLI."
            ;;
    esac
    echo "Orchestrates the full story lifecycle: create -> implement -> review"
    echo ""
    echo "Options:"
    echo "  --dry-run           Preview actions without executing"
    echo "  --epic N            Process only stories from epic N"
    echo "  --story X-Y         Process specific story (e.g., 1-1)"
    echo "  --skip-review       Skip code-review step"
    echo "  --verbose           Show detailed agent output"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $cli_name                # Process all pending stories"
    echo "  $cli_name --dry-run      # Preview what would happen"
    echo "  $cli_name --epic 1       # Process only Epic 1 stories"
    echo "  $cli_name --story 1-2    # Process only story 1-2"
    echo ""
    echo "Environment Variables:"
    echo "  RALPH_PROJECT_ROOT    Project root directory (default: current dir)"
    echo "  RALPH_SPRINT_STATUS   Path to sprint-status.yaml"
    echo "  RALPH_LOG_DIR         Directory for log files"
    if [[ "$PROVIDER" == "codex" ]]; then
        echo "  RALPH_CODEX_FULL_AUTO Use --full-auto with codex exec (default: true)"
        echo "  RALPH_CODEX_SANDBOX   Codex sandbox mode (e.g., danger-full-access)"
        echo "  RALPH_CODEX_MODEL     Codex model override (optional)"
        echo "  RALPH_CODEX_SEARCH    Enable codex --search (default: false)"
    fi
    echo ""
    echo "Documentation: https://github.com/NathanJ60/bmad-ralph-loop"
    echo ""
}

normalize_provider() {
    PROVIDER="$(echo "$PROVIDER" | tr '[:upper:]' '[:lower:]')"
}

validate_provider() {
    case "$PROVIDER" in
        claude|codex) return 0 ;;
        *)
            log ERROR "Unsupported provider: $PROVIDER (use claude or codex)"
            exit 1
            ;;
    esac
}

check_dependencies() {
    log INFO "Checking dependencies..."

    local missing=()

    # Check provider CLI
    case "$PROVIDER" in
        claude)
            if ! command -v claude &> /dev/null; then
                missing+=("claude (Claude Code CLI)")
            fi
            ;;
        codex)
            if ! command -v codex &> /dev/null; then
                missing+=("codex (OpenAI Codex CLI)")
            fi
            ;;
    esac

    # Check if yq is available (for YAML parsing)
    if ! command -v yq &> /dev/null; then
        missing+=("yq (YAML processor)")
    fi

    # Check bash version
    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
        log WARN "Bash version ${BASH_VERSION} detected. Version 4+ recommended."
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log ERROR "Missing dependencies:"
        for dep in "${missing[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo "Install with:"
        if [[ "$PROVIDER" == "claude" ]]; then
            echo "  Claude Code CLI: Install from https://claude.ai"
        else
            echo "  OpenAI Codex CLI: Install from OpenAI documentation"
        fi
        echo "  yq:     brew install yq (macOS) or snap install yq (Linux)"
        exit 1
    fi

    log OK "All dependencies found"
}

check_sprint_status() {
    if [[ ! -f "$SPRINT_STATUS" ]]; then
        log WARN "sprint-status.yaml not found at: $SPRINT_STATUS"
        echo ""
        echo -e "${YELLOW}Sprint status file doesn't exist yet.${NC}"
        echo "You need to run sprint-planning first or create it manually."
        echo ""
        echo "Options:"
        echo "  1) Run sprint-planning now (requires SM agent)"
        echo "  2) Exit and create manually"
        echo ""
        read -p "Choose [1/2]: " choice

        case "$choice" in
            1)
                log STEP "Running sprint-planning workflow..."
                run_agent_workflow "SM" "sprint-planning" "Initialize sprint status"

                if [[ ! -f "$SPRINT_STATUS" ]]; then
                    log ERROR "sprint-status.yaml still not found after running sprint-planning"
                    exit 1
                fi
                ;;
            *)
                log INFO "Exiting. Create sprint-status.yaml manually or run sprint-planning."
                echo ""
                echo "See: examples/sprint-status.example.yaml"
                exit 0
                ;;
        esac
    fi

    log OK "Found sprint-status.yaml"
}

# =============================================================================
# Core Functions
# =============================================================================

run_agent_workflow() {
    local agent="$1"
    local workflow="$2"
    local description="$3"
    local extra_context="${4:-}"

    log STEP "[$agent] Running: $workflow"
    log INFO "Description: $description"

    if [[ "$DRY_RUN" == "true" ]]; then
        log WARN "[DRY-RUN] Would execute: $PROVIDER with /$agent -> $workflow"
        return 0
    fi

    # Build the prompt for the agent
    local prompt="Load the $agent agent and execute the $workflow workflow. $extra_context

CRITICAL: Run in fully autonomous mode. Do NOT ask questions or wait for user input. Auto-fix any issues found. Choose reasonable defaults when options are presented. Complete the entire workflow without stopping for confirmations."

    local exit_code=0

    # Run provider with the workflow
    case "$PROVIDER" in
        claude)
            if [[ "$VERBOSE" == "true" ]]; then
                claude --print --dangerously-skip-permissions "$prompt" 2>&1 | tee -a "$LOG_FILE"
            else
                claude --print --dangerously-skip-permissions "$prompt" >> "$LOG_FILE" 2>&1
            fi
            exit_code=$?
            ;;
        codex)
            local codex_args=("exec")

            if [[ "$CODEX_FULL_AUTO" == "true" ]]; then
                codex_args+=("--full-auto")
            fi

            if [[ "$CODEX_SEARCH" == "true" ]]; then
                codex_args+=("--search")
            fi

            if [[ -n "$CODEX_SANDBOX" ]]; then
                codex_args+=("--sandbox" "$CODEX_SANDBOX")
            fi

            if [[ -n "$CODEX_MODEL" ]]; then
                codex_args+=("--model" "$CODEX_MODEL")
            fi

            if [[ "$VERBOSE" == "true" ]]; then
                codex "${codex_args[@]}" "$prompt" 2>&1 | tee -a "$LOG_FILE"
            else
                codex "${codex_args[@]}" "$prompt" >> "$LOG_FILE" 2>&1
            fi
            exit_code=$?
            ;;
    esac

    if [[ $exit_code -eq 0 ]]; then
        log OK "Workflow completed: $workflow"
    else
        log ERROR "Workflow failed: $workflow (exit code: $exit_code)"
        return $exit_code
    fi
}

verify_story_file_created() {
    local story_key="$1"
    local story_file="$IMPLEMENTATION_ARTIFACTS/${story_key}.md"

    if [[ -f "$story_file" ]]; then
        log OK "Story file verified: $story_file"
        return 0
    else
        log ERROR "Story file NOT created: $story_file"
        log ERROR "create-story workflow failed silently!"
        return 1
    fi
}

verify_implementation() {
    local story_key="$1"

    # Check git status for recent changes
    local changes=$(cd "$PROJECT_ROOT" && git status --porcelain 2>/dev/null | grep -E '^\s*[AM]' | wc -l)

    if [[ "$changes" -gt 0 ]]; then
        log OK "Implementation verified: $changes file(s) modified"
        return 0
    else
        log WARN "No file changes detected for implementation"
        return 0
    fi
}

commit_story_changes() {
    local story_key="$1"
    local epic_num="$2"

    log STEP "Committing changes for $story_key..."

    if [[ "$DRY_RUN" == "true" ]]; then
        log WARN "[DRY-RUN] Would commit changes for $story_key"
        return 0
    fi

    cd "$PROJECT_ROOT"

    # Get list of modified files for commit message
    local modified_files=$(git status --porcelain 2>/dev/null | grep -E '^[AM\?]' | awk '{print $2}' | head -10 | tr '\n' ', ' | sed 's/,$//')

    # Add all modified/new files
    git add -A

    # Check if there are changes to commit
    if git diff --cached --quiet; then
        log WARN "No changes to commit for $story_key"
        return 0
    fi

    # Create commit with story info
    git commit -m "$(cat <<EOF
feat(epic-$epic_num): implement $story_key

Files: $modified_files
EOF
)"

    if [[ $? -eq 0 ]]; then
        log OK "Committed: $story_key"
    else
        log ERROR "Commit failed for $story_key"
        return 1
    fi
}

update_story_status() {
    local story_key="$1"
    local new_status="$2"

    log INFO "Updating status: $story_key -> $new_status"

    if [[ "$DRY_RUN" == "true" ]]; then
        log WARN "[DRY-RUN] Would update $story_key to $new_status"
        return 0
    fi

    # Use yq to update the YAML file
    yq -i ".development_status.\"$story_key\" = \"$new_status\"" "$SPRINT_STATUS"

    log OK "Status updated: $story_key = $new_status"
}

get_story_status() {
    local story_key="$1"
    yq ".development_status.\"$story_key\"" "$SPRINT_STATUS" 2>/dev/null || echo "unknown"
}

get_pending_stories() {
    # Get all stories with status: backlog or ready-for-dev
    # Filter out epic entries and retrospectives
    yq '.development_status | to_entries | .[] | select(.value == "backlog" or .value == "ready-for-dev") | select(.key | test("^[0-9]+-[0-9]+")) | .key' "$SPRINT_STATUS" 2>/dev/null
}

get_epic_for_story() {
    local story_key="$1"
    # Extract epic number from story key (e.g., "1-2" -> "1")
    echo "$story_key" | cut -d'-' -f1
}

process_story() {
    local story_key="$1"
    local epic_num=$(get_epic_for_story "$story_key")
    local current_status=$(get_story_status "$story_key")

    echo ""
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${GREEN}  Processing Story: $story_key${NC} (Epic $epic_num)"
    echo -e "${CYAN}============================================================${NC}"
    log INFO "Current status: $current_status"

    # Update epic status to in-progress if not already
    local epic_key="epic-$epic_num"
    local epic_status=$(get_story_status "$epic_key")
    if [[ "$epic_status" == "backlog" ]]; then
        update_story_status "$epic_key" "in-progress"
    fi

    # Step 1: Create Story (SM agent)
    if [[ "$current_status" == "backlog" ]]; then
        log STEP "[1/3] Creating story file..."
        run_agent_workflow "SM" "create-story" "Create story file for $story_key" "The story to create is $story_key from Epic $epic_num."

        # Verify story file was actually created
        if ! verify_story_file_created "$story_key"; then
            log ERROR "Aborting: Story file verification failed for $story_key"
            return 1
        fi

        update_story_status "$story_key" "ready-for-dev"
        current_status="ready-for-dev"
    else
        log INFO "[1/3] Story file already exists, skipping create-story"
    fi

    # Step 2: Implement Story (DEV agent)
    if [[ "$current_status" == "ready-for-dev" ]]; then
        log STEP "[2/3] Implementing story..."
        run_agent_workflow "DEV" "dev-story" "Implement story $story_key" "The story to implement is $story_key."

        verify_implementation "$story_key"

        update_story_status "$story_key" "review"
        current_status="review"
    else
        log INFO "[2/3] Story already implemented, skipping dev-story"
    fi

    # Step 3: Code Review (DEV agent)
    if [[ "$current_status" == "review" && "$SKIP_CODE_REVIEW" == "false" ]]; then
        log STEP "[3/3] Running code review..."
        run_agent_workflow "DEV" "code-review" "Review implementation for story $story_key" "Review the changes made for story $story_key."
        update_story_status "$story_key" "done"
    elif [[ "$SKIP_CODE_REVIEW" == "true" ]]; then
        log WARN "[3/3] Skipping code review (--skip-review flag)"
        update_story_status "$story_key" "done"
    fi

    # Step 4: Commit changes
    commit_story_changes "$story_key" "$epic_num"

    log OK "Story $story_key completed!"
    echo ""
}

check_epic_completion() {
    local epic_num="$1"
    local epic_key="epic-$epic_num"

    # Count stories in this epic that are not done
    local pending=$(yq ".development_status | to_entries | .[] | select(.key | test(\"^${epic_num}-\")) | select(.value != \"done\") | .key" "$SPRINT_STATUS" 2>/dev/null | wc -l)

    if [[ "$pending" -eq 0 ]]; then
        log OK "Epic $epic_num completed! All stories are done."
        update_story_status "$epic_key" "done"

        # Prompt for retrospective
        echo ""
        echo -e "${YELLOW}Would you like to run the retrospective for Epic $epic_num?${NC}"
        read -p "[y/N]: " run_retro

        if [[ "$run_retro" =~ ^[Yy] ]]; then
            run_agent_workflow "SM" "retrospective" "Run retrospective for Epic $epic_num"
            update_story_status "${epic_key}-retrospective" "done"
        fi
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --epic)
                SPECIFIC_EPIC="$2"
                shift 2
                ;;
            --story)
                SPECIFIC_STORY="$2"
                shift 2
                ;;
            --skip-review)
                SKIP_CODE_REVIEW=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                log ERROR "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Setup
    normalize_provider
    validate_provider
    banner
    mkdir -p "$LOG_DIR"

    log INFO "Project root: $PROJECT_ROOT"
    log INFO "Provider: $PROVIDER"
    log INFO "Log file: $LOG_FILE"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}  [DRY-RUN MODE] No changes will be made${NC}"
        echo ""
    fi

    # Pre-flight checks
    check_dependencies
    check_sprint_status

    # Get stories to process
    local stories=()

    if [[ -n "$SPECIFIC_STORY" ]]; then
        stories=("$SPECIFIC_STORY")
        log INFO "Processing single story: $SPECIFIC_STORY"
    elif [[ -n "$SPECIFIC_EPIC" ]]; then
        stories=()
        while IFS= read -r line; do
            [[ -n "$line" ]] && stories+=("$line")
        done < <(yq ".development_status | to_entries | .[] | select(.key | test(\"^${SPECIFIC_EPIC}-\")) | select(.value == \"backlog\" or .value == \"ready-for-dev\" or .value == \"review\") | .key" "$SPRINT_STATUS" 2>/dev/null)
        log INFO "Processing Epic $SPECIFIC_EPIC stories: ${#stories[@]} found"
    else
        stories=()
        while IFS= read -r line; do
            [[ -n "$line" ]] && stories+=("$line")
        done < <(get_pending_stories)
        log INFO "Processing all pending stories: ${#stories[@]} found"
    fi

    if [[ ${#stories[@]} -eq 0 ]]; then
        log OK "No pending stories to process!"
        echo ""
        echo "All stories are either completed or in progress."
        echo "Check sprint-status.yaml for current state."
        exit 0
    fi

    # Show plan
    echo ""
    echo -e "${CYAN}Stories to process:${NC}"
    for story in "${stories[@]}"; do
        local status=$(get_story_status "$story")
        echo "  - $story ($status)"
    done
    echo ""

    if [[ "$DRY_RUN" == "false" ]]; then
        read -p "Proceed with implementation? [Y/n]: " confirm
        if [[ "$confirm" =~ ^[Nn] ]]; then
            log INFO "Aborted by user"
            exit 0
        fi
    fi

    # Process each story
    local processed=0
    local failed=0
    local current_epic=""

    for story in "${stories[@]}"; do
        local epic_num=$(get_epic_for_story "$story")

        # Track epic changes for retrospective
        if [[ "$current_epic" != "$epic_num" && -n "$current_epic" ]]; then
            check_epic_completion "$current_epic"
        fi
        current_epic="$epic_num"

        if process_story "$story"; then
            ((processed++))
        else
            ((failed++))
            log ERROR "Failed to process story: $story"

            echo ""
            read -p "Continue with next story? [Y/n]: " cont
            if [[ "$cont" =~ ^[Nn] ]]; then
                break
            fi
        fi
    done

    # Final epic check
    if [[ -n "$current_epic" ]]; then
        check_epic_completion "$current_epic"
    fi

    # Summary
    echo ""
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${GREEN}                  Implementation Summary${NC}"
    echo -e "${CYAN}============================================================${NC}"
    echo ""
    echo -e "  ${GREEN}[+] Processed:${NC} $processed stories"
    if [[ $failed -gt 0 ]]; then
        echo -e "  ${RED}[x] Failed:${NC}    $failed stories"
    fi
    echo -e "  ${BLUE}[i] Log:${NC}       $LOG_FILE"
    echo ""

    if [[ $failed -gt 0 ]]; then
        exit 1
    fi
}
