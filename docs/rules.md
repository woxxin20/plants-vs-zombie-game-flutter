---
document: Engineering and AI Rules
authority: Non-negotiable implementation constraints, allowed and forbidden tools/patterns
status: Active
owner: "Solo developer (repo owner)"
last_updated: "2026-09-03"
---

# Rules — LIGHT vs SHADOW — Prism Defense

These rules convert product, architecture, security, and design decisions into
enforceable implementation boundaries. Use `MUST`, `MUST NOT`, `SHOULD`, and
`MAY` deliberately. Every hard rule has a stable ID and a verification method.

Source spec: `LIGHT_vs_SHADOW_Prism_Defense_Flame_Spec.md` ("the game spec").

## 1. Rule hierarchy and exceptions

- Product scope comes from `prd.md`.
- System structure and approved decisions come from `architecture.md`.
- Visual behavior comes from `design.md`.
- This file is authoritative for implementation constraints.
- A rule cannot be bypassed because an implementation is faster or already exists.
- A temporary exception requires an owner, reason, affected IDs, risk, expiry date,
  and cleanup task in `implementation_plan.md`.

### Exception record

None active. When a temporary exception is needed, add a row here before
merging the code that relies on it:

| Exception | Rule | Reason | Risk | Owner | Expires | Cleanup task |
| --- | --- | --- | --- | --- | --- | --- |
| `EX-001` | `RULE-___` | [Reason] | [Risk] | [Owner] | [Date] | `TASK-___` |

## 2. Approved baseline

### Why Flame (rationale for the Framework row below)

Flame is not chosen for an art style — none of the tokens or visual language
in `design.md` come from the engine. It is chosen because it earns its keep on
four concrete things this game needs: `CameraComponent` + `World` for real
depth (desk background → dust motes → grid → foreground vignette, `design.md`
§ Layout), `ParticleSystemComponent` for pooled embers/sparks/glow trails
(game spec §18), the `Effects` API for placement/HP/cooldown juice instead of
hand-rolled `AnimationController`s (game spec §18.2), and `CollisionCallbacks`
+ `RectangleHitbox` for beam-vs-shadow hit detection (game spec §15). The
accepted cost is +1 week of solo build time for the component architecture
versus a pure-widget rebuild (game spec §21, §25) — already budgeted into the
phase plan and not up for re-litigation mid-build.

| Concern | Approved choice | Version policy | Forbidden alternatives | Source |
| --- | --- | --- | --- | --- |
| Framework | Flutter `3.47.0` (stable channel) + Flame `1.38.2` | Pin exact versions in `pubspec.yaml`; bump only via a new ADR plus a full regression pass | Any other game engine (Unity, Godot, raw `CustomPainter`-only rebuild); reverting to the pure-widget v1.0 spec | `ADR-001` |
| Language | Dart, SDK constraint `>=3.11.1 <4.0.0` | Track whatever Dart ships with the pinned Flutter stable version; never widen below the constraint | N/A | `ADR-001` |
| UI system | Flame `PositionComponent` hierarchy rendered via `Canvas`/`TextPaint`; app root is `WidgetsApp` | New screens are new `World`s under `lib/game/worlds/`; new visuals are new components under `lib/game/components/` (game spec §21 structure) | `MaterialApp`, `CupertinoApp`, `Scaffold`, `Icon(Icons.*)`, `Card`, `ElevatedButton`, `ThemeData` | `ADR-001`, `RULE-FORBID-001` |
| Styling | Design tokens as plain Dart constants (`lib/core/theme.dart`), consumed by each component's `render()`/`TextPaint` | Token values change in `docs/design.md` first, then `theme.dart`, per the Governance change-propagation order | Hard-coded hex/px/duration literals inside a component; `ThemeData` | `RULE-UI-001`, `DS-*` in `design.md` |
| State | `flutter_riverpod` `2.6.1` + `flame_riverpod` `5.4.21` bridge (`RiverpodAwareGameMixin`) | Pin exact; per-frame simulation state (positions, HP, active beams) stays native to component `update(dt)` — never routed through a `Notifier` | `provider`, `bloc`/`flutter_bloc`, `get_it` + `GetX`, `MobX`, or any second state package | `ADR-002`, `RULE-FORBID-006` |
| Navigation | `go_router` `16.3.0`; one shared `GameWidget` with a swappable `World` per route | 7 route entries: `/`, `/home`, `/map`, `/loadout/:levelId`, `/battle/:levelId`, `/shop`, `/settings` | `Navigator` 1.0 imperative-only routing, `auto_route`, or any second router package | `ADR-003` |
| Networking | None. Zero network calls on any gameplay path | No `http`, `dio`, `connectivity_plus`, or any remote-config/analytics SDK dependency | Any HTTP/socket client reachable from `lib/game/` or `lib/data/` | `RULE-FORBID-005` |
| Persistence | `hive_ce_flutter` `2.3.4`; single `Save` box/object (game spec §19 schema) | Schema changes are additive `@HiveField` appends only; a field index is never reused or renumbered | `shared_preferences` for save data, `sqflite`, any cloud-synced store | `ADR-004` |
| Audio | `flame_audio` `2.12.2`, preloaded via `FlameAudio.audioCache.loadAll([...])` at boot | Pin exact; sounds triggered only from component event handlers | `audioplayers` direct use, `just_audio`, `soundpool` | `RULE-FORBID-002` |
| Monetization | `google_mobile_ads` `6.0.0` (banner/interstitial/rewarded) + `in_app_purchase` `3.3.0` (`remove_ads` non-consumable, no backend) | Pin exact; banner ad composited outside `GameWidget` (game spec §20), never inside the Flame render tree | A second ad mediation SDK, a second IAP plugin, any server-side receipt validation | `ADR-005` |
| Fonts | Orbitron, Inter, JetBrains Mono bundled as static files under `assets/fonts/`, declared in `pubspec.yaml` `fonts:` | Referenced via local `TextStyle(fontFamily: ...)` inside each `TextPaint`. If the `google_fonts` package is ever added instead, `GoogleFonts.config.allowRuntimeFetching` MUST be set `false` before first use | `google_fonts` with runtime (network) font fetching enabled — this would silently violate `RULE-FORBID-005` | `RULE-FORBID-005` |
| Testing | `flutter_test` (bundled with the Flutter SDK) + `flutter_lints` `5.0.0` for static analysis | Both run locally before every commit that touches `lib/`; no version drift from the pinned `dev_dependencies` | A second test framework, project-wide lint suppression | Architecture §15 |

Examples are not defaults. Do not mix ecosystems or add a second solution for
the same concern without an approved ADR.

## 3. Core engineering rules

| ID | Rule | Level | Verification |
| --- | --- | --- | --- |
| `RULE-001` | Code MUST follow the dependency direction and module ownership in `architecture.md`. | MUST | Static analysis + review |
| `RULE-002` | A feature MUST map to an approved `PRD-FR-*` and `TASK-*` before substantial implementation. | MUST | Plan/audit traceability |
| `RULE-003` | Public behavior MUST be covered by the smallest appropriate automated test mapped to its requirement. | MUST | Test names/metadata + CI |
| `RULE-004` | Source MUST pass the format, lint, type, test, and build commands applicable in `AGENTS.md`. | MUST | CI/local evidence |
| `RULE-005` | Errors MUST be explicit, actionable, safely logged, and recoverable where the PRD requires recovery. | MUST | Tests + review |
| `RULE-006` | Hard-coded secrets, tokens, private endpoints, credentials, or real personal data MUST NOT enter source, tests, docs, or logs. | MUST NOT | Secret scan + review |
| `RULE-007` | New dependencies MUST pass the package policy in §4. | MUST | Dependency review |
| `RULE-008` | Shared code MUST have at least two real consumers or a clear stable platform role. | MUST | Review |
| `RULE-009` | Dead code, commented-out implementations, ignored failures, and unexplained TODOs MUST NOT be committed. | MUST NOT | Lint + review |
| `RULE-010` | User-visible behavior MUST define loading, empty, error, retry, and permission/offline states when applicable. | MUST | Acceptance/UI tests |
| `RULE-011` | Data/schema/API changes MUST follow compatibility and migration rules in `architecture.md`. | MUST | Migration/contract tests |
| `RULE-012` | Documentation updates required by `README.md` MUST ship with the change. | MUST | PR/change checklist |

## 4. Dependency and package policy

Before adding a package, document:

1. Requirement and task IDs it enables.
2. Why the framework/platform cannot reasonably provide it.
3. Maintenance activity, license, security posture, release maturity, binary/bundle impact.
4. Platform support and transitive dependencies.
5. Exit/replacement strategy for critical packages.
6. Approval through an `ADR-*` when the package shapes architecture or public APIs.

### Forbidden dependency classes

- Abandoned or unmaintained packages without an owned fork/exit plan.
- Packages with incompatible or unclear licenses.
- Packages that duplicate an approved framework capability without measured need.
- Packages that require unsafe permissions or collect undeclared data.
- Packages that bypass type safety, TLS, authorization, or platform security controls.
- Multiple packages solving the same architectural concern.
- Project-specific forbidden packages: `audioplayers` (direct use — `flame_audio` only),
  `flutter_animate`, `provider`, `flutter_bloc`/`bloc`, `get_it` + `GetX`, `mobx`
  (any second state-management package alongside Riverpod), any Material- or
  Cupertino-dependent widget kit, `google_fonts` unless runtime fetching is
  disabled (§2), and any HTTP/network client (`http`, `dio`, `chopper`, etc.).

All dependencies MUST be pinned according to the approved version policy and
reviewed through lockfile changes. Automated major upgrades require explicit
review and relevant test evidence.

## 5. Code organization and style

- One module owns each domain concept; cross-feature imports use public contracts.
- Domain/business logic MUST remain independent of UI, storage, network, analytics,
  and platform SDKs.
- Files and symbols MUST use `snake_case.dart` filenames; class/component names
  are `UpperCamelCase` and end in the Flame role they play (`...Component`,
  `...World`); `Notifier` classes end in `Notifier`; token maps use
  `lowerCamelCase` constant names (no `SCREAMING_SNAKE_CASE`).
- Maximum file/function complexity: a single `render()`/`update()` method
  exceeding ~60 lines, or a file exceeding ~300 lines, triggers a
  split-and-review (extract a child component or a private draw helper) before
  merge.
- Prefer composition and explicit data flow over hidden global state.
- Mutable global state is forbidden unless approved and encapsulated by architecture.
- Public functions/types require documentation when their contract is not obvious.
- Comments explain intent, constraints, or trade-offs—not restate code.
- Generated code MUST live in documented paths and MUST NOT be manually edited.
- Localization-ready products MUST NOT hard-code user-facing strings outside the
  approved localization system.

## 6. UI and styling rules

| ID | Rule | Verification |
| --- | --- | --- |
| `RULE-UI-001` | UI MUST use tokens from `design.md`; arbitrary colors, spacing, radii, shadows, type sizes, and animation timings are forbidden. | Lint/review/visual test |
| `RULE-UI-002` | Reuse or extend approved primitives before creating a new component. | Component inventory review |
| `RULE-UI-003` | Responsive behavior MUST follow the breakpoints/layout modes in `design.md`, not device-name checks. | Viewport/device tests |
| `RULE-UI-004` | Interactive controls MUST expose semantic labels, focus/keyboard behavior where applicable, sufficient target size, and visible states. | Accessibility tests/review |
| `RULE-UI-005` | UI MUST respect reduced motion, text scaling, contrast, and safe areas according to `design.md`. | Accessibility/visual tests |
| `RULE-UI-006` | Screens MUST NOT rely on color alone to communicate status. | Review/accessibility tests |

This project's approved stack is Flame components, not shadcn/Tailwind or
Material `ThemeData`: centralize every value through `lib/core/theme.dart`
(sourced from `design.md`'s `DS-*` tokens) and shared component classes; do
not scatter literal styles across `World`s or components (`RULE-FORBID-003`).

## 7. Data, API, and security rules

- Validate input at every untrusted boundary; client validation is usability,
  not a security boundary.
- Authorization MUST be enforced at the trusted data/service boundary for every operation.
- Use parameterized queries or approved ORM/query builders; string-built queries are forbidden.
- Public APIs MUST return stable safe error codes; internal stack traces and secrets MUST NOT be exposed.
- Network calls MUST define timeouts; retries require bounded attempts, backoff, and idempotency analysis.
- Logs/analytics MUST be allow-listed and redact sensitive values.
- Collect only PRD-approved data for a declared purpose and retention period.
- Sensitive values MUST use approved platform/server secure storage; ordinary preferences/local storage are not secure storage.
- Destructive actions require explicit confirmation proportional to impact and a recovery strategy where feasible.
- File uploads, URLs, redirects, and deep links MUST be validated against explicit allow-lists and size/type limits.

This project has no server and no accounts, so most rows above reduce to: the
only "untrusted boundary" is the bundled level/tool/shadow JSON and the local
Hive save file. `levels_loader.dart` MUST validate parsed JSON against the
expected schema (game spec §22) and fail closed (refuse to start the level,
not crash) on a malformed file. IAP purchase results (`RULE §20`) are trusted
only after `purchaseStatus == purchased` from the platform billing client —
no separate validation server exists or is needed.

## 8. Testing rules

- Every `Must` acceptance criterion requires automated coverage unless the audit
  records why automation is infeasible and defines repeatable manual evidence.
- Unit tests cover domain rules and edge cases; integration tests cover real
  boundaries; E2E tests cover only critical user journeys.
- Tests MUST be deterministic, isolated, and independent of execution order.
- Do not use real production services, credentials, or personal data in tests.
- A bug fix MUST include a failing regression test first when technically feasible.
- Snapshots/goldens MUST assert intentional stable output, not replace behavioral tests.
- Skipped/flaky tests require an audit finding, owner, and expiry/repair task.

**Coverage policy (critical-path, not a percentage target):** this project
does not use a fixed coverage threshold. Instead, the following logic paths
are pure/headless (no rendering required) and MUST ship with unit tests
before merge, because they are the paths a wrong build fails silently on:

1. **Beam optics** — mirror 90° reflect, prism 3-way split with 60% damage
   falloff, depth-3 recursion cap, `visited` loop guard (game spec §15).
2. **Placement validation** — `tryPlace()`'s 7 ordered checks, including the
   `twin`-requires-`bulb` rule and the first-failure-wins order (game spec §17).
3. **Wave system / 50% rule** — `canSpawnNext()` half-dead-OR-20s-timeout logic
   and flag-wave sequencing (game spec §8).
4. **Stars, coins, and unlock calculation on win** — `stars[levelId-1]`,
   coin delta formula, `maxUnlocked` increment, reward-tool unlock (game spec §19).
5. **Hive persistence** — `Save` read/write round-trip and additive-field
   migration safety (game spec §19).

Everything else (rendering, particle timing, `Effect` curves, audio/haptic
triggers) is verified through manual QA against the edge-case checklist in
§8.1 below, not unit tests, because it is not meaningfully testable without a
running renderer.

### 8.1 Critical edge-case regression checklist

Sourced from the game spec §24; every row MUST be manually re-verified before
each release build and MUST NOT regress silently:

| # | Edge case | Required behavior |
| --- | --- | --- |
| 1 | Tap an occupied tile | Shake + "Occupied" toast, no glow deducted |
| 2 | Insufficient glow | Cost text pulses red, no placement |
| 3 | Tool on cooldown | Cooldown number shown, no placement |
| 4 | `twin` on a non-`bulb` tile | "Need Bulb" toast |
| 5 | Mirror with no incoming beam | Idle, no crash, no trace |
| 6 | Prism with no incoming beam | Idle |
| 7 | Multiple mirrors form a loop | `visited` set stops it; depth capped at 3 |
| 8 | Shadow eats a tool to 0 HP | Tool removed with a destroy `Effect` + puff particle; shadow resumes walking next frame |
| 9 | Two shadows share a tile | Both take beam damage in the same tick |
| 10 | App backgrounded | `game.pauseEngine()` halts all `update(dt)` calls |
| 11 | Back button while playing | Pauses instead of popping; pops to Map only when not playing |
| 12 | No sweep left, shadow reaches `x<=0` | Immediate loss |
| 13 | All waves spawned and no shadows remain | Win fires even if the level clock is still running |
| 14 | App killed and relaunched | Stars/coins persist via Hive |
| 15 | Device rotated to portrait | Rotate-prompt component shown, `game.pauseEngine()` |
| 16 | Bomb explosion at a grid edge | 3x3 blast clamps to grid bounds, no index error |
| 17 | Glow exceeds 999 | Clamped to 999 |
| 18 | A frame delta spikes above 32ms | Clamped in `update(dt)` to prevent teleporting entities |
| 19 | A component finishes its death/destroy `Effect` | `removeFromParent()` is always called — no orphaned components leaking frame time |
| 20 | World swap (Home→Map→Battle) | The previous `World` and all its generators (e.g. dust-mote `ParticleSystemComponent`) are fully disposed, none tick off-screen |

## 9. Performance and accessibility budgets

| Budget | Threshold | Requirement | Verification |
| --- | --- | --- | --- |
| Frame rate (Battle, low-end Android, 720p) | Sustained 60 FPS, hard floor 30 FPS | Playable feel per game spec §24 | Flame's built-in FPS counter component + `flutter run --profile` |
| Draw calls per frame (Battle) | < 50 | Keeps low-end Android smooth (game spec §18.3, §24) | DevTools raster/performance overlay during profile run |
| Cold start to first interactive frame (Home) | < 3s on a mid-tier device | Session target is 2-3 min/level; startup should not eat into it | Manual stopwatch against `flutter run --profile` |
| Contrast | WCAG 2.2 AA — 4.5:1 body text, 3:1 large text (≥18px)/essential icons | `design.md` §14 | Manual contrast check of each `color.text.*`/`color.surface.*` token pair before release |
| Touch/click target | Minimum 48x48 logical px hitbox on every interactive component | `design.md` §8 / game spec §11 | Component `size`/hitbox review + widget test asserting the value |

Do not optimize without measurement, but do not merge a known budget regression
without an approved exception.

## 10. Configuration and environments

- Environment behavior MUST come from typed/validated configuration, not scattered conditionals.
- Production-safe defaults are required; missing required configuration MUST fail clearly.
- Development mocks/debug menus MUST be impossible or explicitly protected in production builds.
- Feature flags MUST have owner, safe default, creation date, expiry/removal task, and analytics only if approved.
- Environment-specific endpoints and identifiers MUST NOT be inferred from branch names in application code.

This project ships no server config: the only "environment" difference is ad
unit IDs (test vs production `google_mobile_ads` IDs) and build mode. Test ad
unit IDs MUST NOT ship in a release build; gate them by `kDebugMode`/build
flavor, never by a branch-name check.

## 11. Change and review rules

- Keep changes focused; unrelated refactors require separate tasks.
- Preserve user-authored/unrelated work.
- Commit/change descriptions SHOULD state requirement IDs, behavior, risk, and evidence.
- Public API, schema, framework, major dependency, security, cost, or privacy changes require an ADR and explicit review.
- Generated/binary assets require source, license/ownership, size, optimization, and accessibility metadata where applicable.
- Do not report completion while required checks fail or remain unrun.

## 12. Documentation rules

- One fact has one authoritative home; other docs link by ID.
- Dates use `YYYY-MM-DD`; status values use the enums defined in each file.
- Stable IDs are never renumbered or reused.
- Deprecated decisions remain discoverable and link to replacements.
- `memory.md` is capped at 200 lines; archive old session notes rather than letting it become a second specification.
- Audit evidence includes command/test name, date, environment, and outcome.

### 12.1 Verification commands

Run these locally before every commit that touches `lib/`, and treat any
non-zero exit as blocking:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

`flutter build apk --debug` is the cheapest real build-integrity check
available without signing config; it also produces the artifact used to
manually measure the bundle-size trend referenced in §9.

## 13. Project-specific forbidden actions

- `RULE-FORBID-001`: `lib/` MUST NOT import `package:flutter/material.dart` or
  `package:flutter/cupertino.dart` anywhere. The app root MUST be `WidgetsApp`,
  never `MaterialApp`. `Scaffold`, `ElevatedButton`, `Icon(Icons.*)`, `Card`,
  and `ThemeData` MUST NOT appear in the codebase.
- `RULE-FORBID-002`: `audioplayers` MUST NOT be used directly — all audio goes
  through `flame_audio`. `flutter_animate` MUST NOT be used. No hand-rolled
  `AnimationController` MUST be created inside the game view — use Flame
  `Effect` classes (`ScaleEffect`, `MoveByEffect`, `OpacityEffect`,
  `SizeEffect`, `ColorEffect`, `SequenceEffect`) exclusively.
- `RULE-FORBID-003`: Components MUST NOT contain hard-coded color, spacing,
  radius, or duration literals — every such value MUST come from the design
  tokens in `lib/core/theme.dart` (sourced from `design.md`'s `DS-*` ids).
- `RULE-FORBID-004`: Portrait orientation MUST NOT be supported. Landscape
  lock (`landscapeLeft` + `landscapeRight`, immersive sticky) is mandatory at
  boot and MUST be re-asserted on resume.
- `RULE-FORBID-005`: No network call MUST occur on any gameplay path. The game
  MUST be fully playable in airplane mode; this also forbids runtime font
  fetching (see the Fonts row in §2) and any analytics/remote-config SDK that
  phones home during play.
- `RULE-FORBID-006`: A second state-management package MUST NOT be added
  alongside Riverpod (`flutter_riverpod` + `flame_riverpod`) — see §2, §4.
- `RULE-FORBID-007`: Code under `lib/data/` MUST NOT import `package:flame/*`
  or any Flutter widget package. Domain models (`ToolDef`, `ShadowDef`,
  `Level`, `Wave`, `Save`) stay engine-agnostic and renderer-agnostic.

## 14. Rules change log

| Date | Rule IDs | Change/reason | Source ADR/PRD/design | Owner |
| --- | --- | --- | --- | --- |
| 2026-09-03 | `RULE-FORBID-001`..`007`, §2 baseline table, §8 coverage policy, §8.1, §9 budgets, §12.1 | Initial rules filled in from the Flame game spec and the project's resolved `pubspec.yaml`/`pubspec.lock` versions; zero `[REQUIRED: ...]` placeholders remain | `ADR-001` | Solo developer (repo owner) |
