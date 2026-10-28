---
name: self-learning
description: Continuous Self-Learning & Machine-Local Memory system (~/.agents/learned-lessons.md). Automatically records lessons when Reviewer Subagent catches bugs or when the user corrects the agent, and reads past lessons before coding so mistakes are never repeated. Isolated per machine and never leaked to GitHub.
---

# Continuous Self-Learning & Local Memory (`self-learning`)

Maintain a machine-local, private cumulative memory file at `~/.agents/learned-lessons.md` so the agent continuously gets smarter on this machine without leaking private project context to GitHub.

---

## 1. Reading Memory Before Coding (Pre-Flight Check)

Before implementing a feature, fixing a bug, or running `pair-review`:
- Read `~/.agents/learned-lessons.md` if it exists.
- Apply any recorded stack conventions, user preferences, and bug-prevention rules relevant to the current task.

---

## 2. When to Record a New Lesson Automatically

Append or update a concise rule in `~/.agents/learned-lessons.md` whenever:
1. **`pair-review` Catches a Defect (`CHANGES_REQUESTED`):**
   - If the Reviewer Subagent catches a real logic bug, security flaw, or architectural mistake, record the root cause and the prevention rule so future tasks pass on the first try.
2. **User Correction or Preference:**
   - Whenever the user corrects a mistake, rejects an approach, or states a standing preference (e.g., preferred libraries, naming conventions, language, or workflow).
3. **Hard-Won Debugging Insight (`figure-it-out` / `bug-fix`):**
   - When a subtle environment, framework, or build gotcha took multiple steps to diagnose.

*(Also invoke `pstack`'s `/correct` skill when the lesson can be enforced structurally via a type, lint rule, or test in the target project.)*

---

## 3. Memory File Format & Hygiene (`~/.agents/learned-lessons.md`)

Keep `~/.agents/learned-lessons.md` compact, deduplicated, and organized under these 4 sections (maximum 1–2 lines per bullet):

```markdown
# Local Learned Lessons (Private Per-Machine Memory)

## 1. User Preferences & Workflow
- [Date] Rule -> Reason/Context

## 2. Architecture & Tech Stack Conventions
- [Date] Rule -> Reason/Context

## 3. Bug & Pitfall Prevention (Caught by Pair Review / Debugging)
- [Date] Mistake to avoid -> Correct pattern to use instead

## 4. Security & Boundary Rules
- [Date] Vulnerability pattern -> Required guard/validation
```

### Hygiene Rules:
- **Never duplicate:** If a similar lesson already exists, refine the existing bullet instead of adding a duplicate.
- **No secrets:** Never write API keys, passwords, or tokens into `learned-lessons.md`.
- **Keep it portable-safe:** This file lives in `~/.agents/learned-lessons.md` (user home directory), never inside the public Git repository.

