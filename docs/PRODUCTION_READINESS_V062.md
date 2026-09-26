# v0.62 Production Readiness

v0.62 is the final non-AI consolidation checkpoint for the current Anna's Diary roadmap.

## Scope

- No generative-AI or AI-dependent feature is introduced.
- Existing agenda, diary, Noi ♡, lifecycle, backup, sync, notification and media engines remain the source of truth.
- Global Material interaction defaults keep padded touch targets and standard visual density.
- The application shell uses reading-order focus traversal so keyboard and accessibility focus follow the rendered hierarchy.
- No new persistence layer, cloud table or product dependency is added.

## Required release gates

The release is mergeable only after the v0.62 pull request reports success for:

1. Development checks: locked dependencies, Flutter analyze, full tests and Web release build.
2. GitHub Pages Web deployment/build validation.
3. Android production-equivalent ARM64 size audit.
4. AppLab Production Gate, including Trusted Verify runtime/visual validation.

Any failed or pending required gate blocks merge.

## Production contract

- Flutter remains pinned to the repository release toolchain.
- Android signing, obfuscation, split debug symbols, ABI packaging and AAB/universal outputs remain unchanged.
- Backup/restore and Data Safety continue to use the existing integrity and rollback contracts.
- README and roadmap must describe the exact merged release state.
