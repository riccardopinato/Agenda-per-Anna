# Anna's Diary — AppLab v5.9 Atomic Journey Adoption

Status: **IMPLEMENTED — exact-head runtime evidence pending**

## Baselines

- App Factory: `ed6466e774a28e95f9f371cd56bbf7278428776a`
- Anna main at branch creation: `c428f54b67b5a6fc00cacc5072db4ba7b71a9228`
- AppLab v5.9: `730dfafecc59871365812f4d7d138b43151fdcc5`

## Runtime architecture

The existing `.maestro/applab-smoke.yaml` remains the legacy fail-safe primary
flow. It is deliberately not weakened. AppLab v5.9B uses the journey catalog
only when the trusted plan is enforcement-eligible and no runtime path is
unmatched.

The atomic catalog contains:

1. `core-shell`
2. `onboarding`
3. `navigation-critical`
4. `memories-critical`
5. `settings-critical`
6. `vault-create`
7. `vault-wrong-password`
8. `vault-correct-unlock`
9. `vault-restart-unlock`

The four Vault behaviors are separate deep journeys. The non-create flows can
bootstrap the minimum Vault state on a pristine runtime, while serial execution
may reuse deterministic state created by `vault-create`.

## Trust boundary

- FAST may enforce a subset only when AppLab proves complete path coverage.
- FULL and CERTIFICATION select the complete declared catalog.
- Unsafe/incomplete selection falls back to the legacy primary flow.
- v5.9C sharding authority remains central in AppLab. Anna is admitted in
  shadow mode and cannot promote itself to authoritative sharding.
- Build Once / exact-artifact identity is preserved.
- Physical-device, Play and store evidence remain separate and fail-closed.

## Path mapping

- shell/navigation: root app shell and navigation files;
- memories: diary/memory projection plus people/life-archive references;
- settings: More / Settings / Privacy hub;
- Vault: Private Vault UI, Vault service and security/storage code.

Unmatched runtime paths intentionally prevent selective enforcement rather than
silently reducing coverage.

## Historical baseline

- AppLab serial total: ~43m57
- Trusted Verify: ~33m05
- primary Anna Maestro: ~20m
- Vault/crypto Maestro: ~16m13
- v5.9D fresh build: ~6m45

Actual v5.9 selected-journey, shard and timing evidence is recorded only after a
real workflow execution. No synthetic PASS or timing is accepted.
