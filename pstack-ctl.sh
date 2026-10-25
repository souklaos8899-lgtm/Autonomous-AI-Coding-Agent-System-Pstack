#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-status}"
TARGET_PATH="${2:-}"

AUTO_AI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DEV_ROOT="$(dirname "$AUTO_AI_ROOT")"
CUSTOM_SKILLS_ROOT="$AUTO_AI_ROOT/custom-skills"
MASTER_RULE_FILE="$AUTO_AI_ROOT/rules/auto-orchestrator.md"

if [[ -n "${PSTACK_PATH:-}" && -d "${PSTACK_PATH}/skills" ]]; then
  PSTACK_ROOT="$(cd "$PSTACK_PATH" && pwd)"
elif [[ -d "$PARENT_DEV_ROOT/skills/pstack/skills" ]]; then
  PSTACK_ROOT="$(cd "$PARENT_DEV_ROOT/skills/pstack" && pwd)"
else
  PSTACK_ROOT="$AUTO_AI_ROOT/vendor/pstack"
fi
PSTACK_SKILLS_ROOT="$PSTACK_ROOT/skills"

AGY_CONFIG_DIR="$HOME/.gemini/config"
AGY_SKILLS_DIR="$AGY_CONFIG_DIR/skills"
AGY_SKILLS_JSON="$AGY_CONFIG_DIR/skills.json"
AGY_GEMINI_MD="$AGY_CONFIG_DIR/GEMINI.md"
AGY_AGENTS_MD="$AGY_CONFIG_DIR/AGENTS.md"

AGENTS_DIR="$HOME/.agents"
AGENTS_SKILLS_DIR="$AGENTS_DIR/skills"
PSTACK_MODELS_MD="$AGENTS_DIR/pstack-models.md"

CURSOR_RULES_DIR="$HOME/.cursor/rules"
CURSOR_SKILLS_DIR="$HOME/.cursor/skills"
CURSOR_AUTO_RULE="$CURSOR_RULES_DIR/pstack-auto-orchestrator.mdc"
CURSOR_MODELS_RULE="$CURSOR_RULES_DIR/pstack-models.mdc"

CLAUDE_DIR="$HOME/.claude"
CLAUDE_SKILLS_DIR="$CLAUDE_DIR/skills"
CLAUDE_GLOBAL_MD="$CLAUDE_DIR/CLAUDE.md"

CODEX_DIR="$HOME/.codex"
CODEX_SKILLS_DIR="$CODEX_DIR/skills"
CODEX_GLOBAL_MD="$CODEX_DIR/AGENTS.md"

DEV_ROOT_AGENTS_MD="$PARENT_DEV_ROOT/AGENTS.md"
DEV_ROOT_CLAUDE_MD="$PARENT_DEV_ROOT/CLAUDE.md"
LOCAL_AGENTS_MD="$AUTO_AI_ROOT/AGENTS.md"
LOCAL_CLAUDE_MD="$AUTO_AI_ROOT/CLAUDE.md"

ensure_pstack_installed() {
  if [[ ! -d "$PSTACK_SKILLS_ROOT" ]]; then
    echo "[0/3] pstack not found locally. Cloning backnotprop/pstack into $AUTO_AI_ROOT/vendor/pstack..."
    mkdir -p "$(dirname "$AUTO_AI_ROOT/vendor/pstack")"
    git clone https://github.com/backnotprop/pstack.git "$AUTO_AI_ROOT/vendor/pstack"
    PSTACK_ROOT="$AUTO_AI_ROOT/vendor/pstack"
    PSTACK_SKILLS_ROOT="$PSTACK_ROOT/skills"
  fi

  mkdir -p "$AGENTS_DIR" "$CURSOR_RULES_DIR"
  if [[ ! -f "$PSTACK_MODELS_MD" ]]; then
    cat > "$PSTACK_MODELS_MD" << 'EOF'
# pstack model configuration. One line per role. Delete a line to fall back to the skill default.
# Strictly uses only Gemini models (`pro` = Gemini Pro / Argon, `flash` = Gemini Flash). Do NOT use Claude models.
# budget: large (xhigh)
feature, refactoring: flash
bug-fix: flash
perf-issue: pro
hillclimb: flash
judgment and prose: pro
hardest tasks: pro
how explorer: flash
how explainer: pro
why investigators: flash
why synthesizer: pro
reflect tooling: flash
reflect judgment, divergent, synthesizer: pro
arena runners: pro, flash
arena cross-judge pool: pro, flash
swarm workers: flash
architect runners: pro, flash
interrogate reviewers: pro, flash
EOF
  fi
}

render_rule_body() {
  sed \
    -e "s|{{PSTACK_ROOT_URI}}|file://${PSTACK_ROOT}|g" \
    -e "s|{{PSTACK_ROOT_PATH}}|${PSTACK_ROOT}|g" \
    -e "s|{{MODELS_CONFIG_URI}}|file://${PSTACK_MODELS_MD}|g" \
    -e "s|{{MODELS_CONFIG_PATH}}|${PSTACK_MODELS_MD}|g" \
    "$MASTER_RULE_FILE"
}

sync_skills() {
  ensure_pstack_installed
  echo "[1/3] Syncing pstack & custom skill symlinks..."
  for dest in "$AGY_SKILLS_DIR" "$AGENTS_SKILLS_DIR" "$CURSOR_SKILLS_DIR" "$CLAUDE_SKILLS_DIR" "$CODEX_SKILLS_DIR"; do
    [[ -L "$dest" ]] && rm -f "$dest"
    mkdir -p "$dest"
    for skill_dir in "$PSTACK_SKILLS_ROOT"/*; do
      [[ -d "$skill_dir" ]] || continue
      ln -sfn "$skill_dir" "$dest/$(basename "$skill_dir")"
    done
    if [[ -d "$CUSTOM_SKILLS_ROOT" ]]; then
      for custom_dir in "$CUSTOM_SKILLS_ROOT"/*; do
        [[ -d "$custom_dir" && -f "$custom_dir/SKILL.md" ]] || continue
        ln -sfn "$custom_dir" "$dest/$(basename "$custom_dir")"
      done
    fi
  done

  mkdir -p "$AGY_CONFIG_DIR"
  cat > "$AGY_SKILLS_JSON" << EOF
{
  "entries": [
    { "path": "${PSTACK_SKILLS_ROOT}" },
    { "path": "${CUSTOM_SKILLS_ROOT}" }
  ]
}
EOF
  echo "  -> Linked all pstack & custom skills across Antigravity, Cursor, Claude Code, and Codex."
}

sync_rules() {
  echo "[2/3] Syncing Always-On Auto-Orchestrator rules..."
  mkdir -p "$AGY_CONFIG_DIR" "$CURSOR_RULES_DIR" "$CLAUDE_DIR" "$CODEX_DIR"

  render_rule_body > "$LOCAL_AGENTS_MD"
  render_rule_body > "$DEV_ROOT_AGENTS_MD"
  render_rule_body > "$AGY_GEMINI_MD"
  render_rule_body > "$AGY_AGENTS_MD"
  render_rule_body > "$CLAUDE_GLOBAL_MD"
  render_rule_body > "$DEV_ROOT_CLAUDE_MD"
  render_rule_body > "$LOCAL_CLAUDE_MD"
  render_rule_body > "$CODEX_GLOBAL_MD"

  {
    echo "---"
    echo "description: Autonomous AI Coding Agent + pstack Auto-Orchestrator (always active)"
    echo "alwaysApply: true"
    echo "---"
    render_rule_body
  } > "$CURSOR_AUTO_RULE"

  echo "  -> Updated rules for Antigravity, Cursor, Claude Code, and Codex."
}

set_model_invocation() {
  local mode="$1"
  for skill_file in "$PSTACK_SKILLS_ROOT"/*/SKILL.md; do
    [[ -f "$skill_file" ]] || continue
    [[ "$(basename "$(dirname "$skill_file")")" == "setup-pstack" ]] && continue
    if [[ "$mode" == "enable" ]]; then
      sed -i.bak '/^disable-model-invocation:[[:space:]]*true/d' "$skill_file" && rm -f "${skill_file}.bak"
    fi
  done
  echo "[3/3] Updated model auto-invocation ($mode)."
}

show_status() {
  echo ""
  echo "============================================================"
  echo "  Autonomous AI Coding Agent + pstack Control Center Status"
  echo "============================================================"
  echo "[0] pstack Source Location : $PSTACK_ROOT"
  echo "[1] Antigravity Rule       : $([[ -f "$AGY_GEMINI_MD" ]] && echo "ACTIVE" || echo "INACTIVE")"
  echo "[2] Cursor Rule            : $([[ -f "$CURSOR_AUTO_RULE" ]] && echo "ACTIVE" || echo "INACTIVE")"
  echo "[3] Claude Code Rule       : $([[ -f "$CLAUDE_GLOBAL_MD" ]] && echo "ACTIVE" || echo "INACTIVE")"
  echo "[4] Codex Rule             : $([[ -f "$CODEX_GLOBAL_MD" ]] && echo "ACTIVE" || echo "INACTIVE")"
  echo "[5] Model Config           : $PSTACK_MODELS_MD"
  echo ""
}

case "$ACTION" in
  status|help)
    show_status
    ;;
  sync)
    sync_skills
    sync_rules
    show_status
    ;;
  install|enable-auto)
    sync_skills
    sync_rules
    set_model_invocation "enable"
    show_status
    ;;
  disable-auto)
    rm -f "$DEV_ROOT_AGENTS_MD" "$DEV_ROOT_CLAUDE_MD" "$AGY_GEMINI_MD" "$AGY_AGENTS_MD" "$CURSOR_AUTO_RULE" "$CLAUDE_GLOBAL_MD" "$CODEX_GLOBAL_MD"
    show_status
    ;;
  init-project)
    [[ -z "$TARGET_PATH" ]] && { echo "Usage: ./pstack-ctl.sh init-project <path>"; exit 1; }
    mkdir -p "$TARGET_PATH/.github"
    render_rule_body > "$TARGET_PATH/AGENTS.md"
    render_rule_body > "$TARGET_PATH/CLAUDE.md"
    render_rule_body > "$TARGET_PATH/.github/copilot-instructions.md"
    echo "Installed AGENTS.md, CLAUDE.md, and .github/copilot-instructions.md to $TARGET_PATH"
    ;;
esac
