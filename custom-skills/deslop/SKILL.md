---
name: deslop
description: Clean up AI-generated code slop before committing or finishing a task. Removes redundant abstractions, dead code, unnecessary defensive checks inside trusted boundaries, verbose comments, and formatting noise. Use for /deslop or before finalizing code changes.
---

# Deslop (Code Cleanliness & Anti-Slop Pass)

Run this pass on your diff before declaring a coding task complete or committing changes.

## Checklist

1. **Boundary Discipline (`principle-boundary-discipline`):**
   - Keep input validation and parsing at system boundaries (API handlers, CLI args, external I/O).
   - Remove redundant `if (!x)` or `typeof` guards inside internal functions whose TypeScript/static types already guarantee the shape.
2. **Laziness Protocol & Minimize Reader Load (`principle-laziness-protocol`, `principle-minimize-reader-load`):**
   - Collapse one-caller helper functions or pass-through wrappers that add indirection without clarity.
   - Delete unused imports, dead variables, commented-out code blocks, and leftover debug logs (`console.log`, `print`).
3. **Type System Discipline (`principle-type-system-discipline`):**
   - Replace `any` or unsafe type casts (`as unknown as ...`) with proper narrowed types or discriminated unions.
4. **No Slop Comments (`no-comments`):**
   - Strip phase-narrating comments (`// Step 1: ...`, `// Fetch user`) and obvious restatements of the code. Keep only non-obvious *why* explanations or external constraints.
5. **Verify (`principle-prove-it-works`):**
   - Re-run the typechecker, linter, or test suite after cleaning up to confirm nothing broke.

