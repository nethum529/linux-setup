---
name: deepseek-delegate
description: Use ONLY when the user invokes /deepseek-delegate to delegate an engineering task through a complete DeepSeek implementation and verification loop.
---

# DeepSeek Delegate

The leading model is the orchestrator. It delegates implementation and performs only a light final review.

1. Inspect the repository, current state, instructions, and user acceptance criteria.
2. Launch DeepSeek with `deepseek/deepseek-v4-flash` and variant `max` in the target worktree.
3. Require its first output line to state `model: deepseek/deepseek-v4-flash | effort: max`.
4. Give DeepSeek the original task, discovered context, constraints, and commands that prove completion.
5. Require this worker cycle:
   - INVESTIGATE: reproduce real behavior and identify the responsible code.
   - PLAN: map the smallest robust change to every acceptance criterion.
   - IMPLEMENT: write production code, tests, documentation, and configuration.
   - VERIFY: run focused tests, full tests, lint, formatting, types, and realistic smoke checks.
   - REPAIR: fix every discovered defect and repeat verification until clean.
   - HANDOFF: report findings, changes, evidence, residual risks, and exact check results.
6. Resume the same DeepSeek session for repair rounds; do not discard its context.
7. For test-heavy or high-risk work, launch `openai/gpt-5.6-luna` at `max` to add deterministic adversarial tests.
8. Return Luna failures to DeepSeek, then require the same failing tests to pass without weakened assertions.
9. Do not duplicate delegated implementation. Track progress, resolve blockers, and keep workers focused.
10. After handoff, inspect the focused diff and run a light independent verification of load-bearing claims.
11. If review finds a defect, send it back to DeepSeek and repeat the repair loop.
12. Commit, push, merge, or create a pull request only when the user requested that delivery action.

Completion requires clean checks, satisfied acceptance criteria, no unresolved critical findings, and a concise evidence-based report.
