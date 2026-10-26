# Autonomous AI Coding Agent System + pstack (English Guide)

> 🌐 [**Read Bilingual README (English / ภาษาไทย)**](./README.md)

An **Auto-Orchestrator & Control Center** that turns **Antigravity**, **Cursor**, **Claude Code**, **Codex**, and **VS Code (GitHub Copilot)** into a full **Autonomous AI Coding Agent System** powered by **[pstack (`poteto-mode`)](https://github.com/backnotprop/pstack)**—automatically routing engineering tasks through rigorous playbooks and multi-agent workflows without requiring manual `/poteto-mode` slash commands on every prompt.

---

## ✨ Key Features

- **Zero-Slash-Command Auto-Routing:** Evaluates every prompt automatically. Software engineering tasks (features, bug fixes, refactors, architecture, code reviews) automatically activate `poteto-mode`, select the matching playbook, and spawn specialized subagents. Casual questions receive direct, concise answers (`unslop`).
- **Multi-IDE & Multi-Harness Support:** Syncs all 52 skills and always-on rules across **Antigravity**, **Cursor**, **Claude Code**, **Codex**, and **VS Code (GitHub Copilot)** in a single command.
- **Auto-Install Upstream `pstack`:** If `pstack` is not found on a machine, `install` automatically clones `backnotprop/pstack` into `./vendor/pstack` and generates default role-to-model settings.
- **Background Auto-Update Scheduler:** Automatically pulls upstream `pstack` updates in the background (daily and at logon via Windows Task Scheduler / Startup or macOS/Linux Cron), conflict-free and offline-safe.
- **Cross-Platform & Zero Hardcoded Paths:** Works out of the box on **Windows (`pstack-ctl.ps1`)** and **macOS / Linux (`pstack-ctl.sh`)**.
- **Built-in `deslop` Custom Skill:** Ships with a ready-to-use `deslop` skill to strip AI code slop, dead code, and redundant comments before committing.

---

## 🚀 Quick Start

### 1. Clone the repository
```bash
git clone https://github.com/souklaos8899-lgtm/Autonomous-AI-Coding-Agent-System-Pstack.git
cd Autonomous-AI-Coding-Agent-System-Pstack
```

### 2. Run the 1-command installer

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File .\pstack-ctl.ps1 install
```

**macOS / Linux / Git Bash:**
```bash
chmod +x ./pstack-ctl.sh
./pstack-ctl.sh install
```

---

## 🛠️ CLI Commands (`pstack-ctl`)

| Windows (PowerShell) | macOS / Linux | Description |
| :--- | :--- | :--- |
| `.\pstack-ctl.ps1 install` | `./pstack-ctl.sh install` | First-time setup: clones `pstack` if missing, links all 52 skills, enables auto-mode, and registers background auto-update. |
| `.\pstack-ctl.ps1 status` | `./pstack-ctl.sh status` | Check skill symlinks, IDE auto-rules, model budget, and auto-update scheduler status. |
| `.\pstack-ctl.ps1 update` | `./pstack-ctl.sh update` | Pull latest upstream `pstack` updates without Git conflicts, re-link skills, and re-apply auto-invocation. |
| `.\pstack-ctl.ps1 enable-autoupdate` | `./pstack-ctl.sh enable-autoupdate` | Enable silent background auto-updates (daily & at logon). |
| `.\pstack-ctl.ps1 disable-autoupdate` | `./pstack-ctl.sh disable-autoupdate` | Disable background auto-updates. |
| `.\pstack-ctl.ps1 enable-auto` | `./pstack-ctl.sh enable-auto` | Enable automatic `pstack` orchestration across all projects. |
| `.\pstack-ctl.ps1 disable-auto` | `./pstack-ctl.sh disable-auto` | Disable auto-mode (revert to manual `/poteto-mode` invocation). |
| `.\pstack-ctl.ps1 sync` | `./pstack-ctl.sh sync` | Sync changes after editing `rules/auto-orchestrator.md` or adding skills in `custom-skills/`. |
| `.\pstack-ctl.ps1 init-project <Path>` | `./pstack-ctl.sh init-project <Path>` | Copy `AGENTS.md`, `CLAUDE.md`, and `.github/copilot-instructions.md` into a specific project directory. |

---

## 💡 Example Workflows

Once installed, simply prompt your IDE in plain language—no slash commands needed:

1. **Feature Development:**
   > *"Add a 90-day password expiration policy with a 7-day warning banner."*
   - Automatically selects `feature.md` -> inspects impact with `/how` and `/blast-radius` -> defines the data shape (`principle-model-the-domain`) -> implements with `/tdd` -> verifies runtime proof (`principle-prove-it-works`).
2. **Root-Cause Bug Fixing:**
   > *"Rapidly switching tabs on the dashboard sometimes shows stale data from the previous tab. Fix it."*
   - Automatically selects `bug-fix.md` -> traces the race condition via `/figure-it-out` and `/why` (`principle-fix-root-causes`) -> fixes the root cause and verifies with tests.
3. **Adversarial Security Review & Parallel Testing:**
   > *"Audit the payment transfer module for vulnerabilities and add unit tests across all services."*
   - Spawns adversarial reviewers via `/interrogate` -> fans out parallel test writers via `/swarm` -> strips unnecessary comments and slop via `/no-comments` and `/deslop`.

---

## ⚙️ Customization Guide

1. **Customize Auto-Routing Rules:** Edit [`rules/auto-orchestrator.md`](./rules/auto-orchestrator.md) and run `.\pstack-ctl.ps1 sync`.
2. **Configure Per-Role Models:** Edit `~/.agents/pstack-models.md` or run `/setup-pstack` in your IDE chat.
3. **Add Custom Skills:** Create `custom-skills/<skill-name>/SKILL.md` and run `.\pstack-ctl.ps1 sync`.

---

## 📄 License
MIT
