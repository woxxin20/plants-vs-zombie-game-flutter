---
document: Architecture Blueprint
authority: System boundaries, stack, data, interfaces, dependency direction, technical decisions
status: Active
owner: "Solo developer (repo owner)"
last_updated: "2026-09-03"
---

# Architecture — LIGHT vs SHADOW: Prism Defense

This document defines **how the system is shaped** to satisfy the approved PRD.
It must trace decisions to product or non-functional requirements. It does not
add product scope.

> `docs/prd.md` has not been filled in with numbered `PRD-FR-*`/`PRD-NFR-*` rows
> yet. Every driver below cites the authoritative source that exists today —
> `LIGHT_vs_SHADOW_Prism_Defense_Flame_Spec.md` (cited as `Spec §N`) — instead of
> a fabricated requirement ID. When `prd.md` is completed, replace these
> citations with the matching `PRD-FR-*`/`PRD-NFR-*` IDs; do not renumber ADRs
> to do so.

## 1. Architecture goals and drivers

| Driver | Source | Architectural consequence |
| --- | --- | --- |
| 100% offline, no backend, no login | `Spec §1`, `§20` | No network client layer, no auth module; Hive is the only durable store; ad/IAP SDKs are the only network-touching code and are optional/best-effort |
| Landscape-only, 60fps on low-end Android, ≤50 draw calls/frame | `Spec §24` | Flame component tree with pooled particles/beams (§15/§18 of the spec) instead of a widget-per-frame rebuild; `dt` spike clamp in the tick |
| "Real environment, not an app" diorama feel (parallax, ambient particles, glow) | `Spec §2` pillar 6, `§14` | `CameraComponent` viewfinder/viewport split; manual motion-parallax layers instead of Flutter widget layering |
| Solo developer, 4-5 week build budget | `Spec §1`, `§25` | Small, fixed tool/shadow roster (8/5) driven by bundled JSON, not a content pipeline or CMS; single shared `GameWidget` reused across all screens (`ADR-003`) |
| Zero Material/Cupertino anywhere | `Spec` — WHY FLAME section | `WidgetsApp` root, hand-painted `render(Canvas)` per component, no `ThemeData` (`ADR-006`) |
| Monetization without a backend (ads + one IAP) | `Spec §20` | `google_mobile_ads` and `in_app_purchase` are client-only integrations; no receipt-validation server; trust boundary documented in §11 |

### Non-goals

- No multiplayer, no live-ops, no server-authoritative anything — this is a single-player, single-device offline game.
- No user accounts, no cloud save/sync, no cross-device progress.
- No CMS or remote-config for levels/tools/shadows — content is bundled JSON shipped with the app binary and only changes via an app update.
- No analytics/telemetry pipeline for MVP (see §13) — not scoped in the spec.
- No plugin system or moddable content.

## 2. System context

### Actors and external systems

| Actor/system | Role | Trust boundary | Protocol/SDK | Owner/SLA |
| --- | --- | --- | --- | --- |
| Player | Sole user, plays offline on one device | Untrusted input (taps/drags), trusted local device | Local touch/OS events | N/A |
| Hive local store (`hive_ce_flutter`) | Durable save (coins, stars, unlocks, settings) | Trusted at rest on-device, but a rooted/jailbroken device or file editor can tamper with it (see §11) | Local file I/O (box file in app sandbox) | N/A — bundled library, no vendor SLA |
| Bundled JSON assets (`assets/data/tools.json`, `assets/data/shadows.json`, `assets/levels/1..20.json`) | Static, read-only game content (tool/shadow stats, level/wave definitions) | Trusted — compiled into the app bundle, not user- or network-writable | Asset bundle read at boot | Repo owner (source-controlled) |
| Google Mobile Ads SDK (`google_mobile_ads`) | Serves banner/interstitial/rewarded ads | Untrusted third party; runs its own network calls and collects device/ad data outside this app's control | Google Play Services / platform ad SDK | Google (best-effort, no app-level SLA) |
| Platform store billing (`in_app_purchase`) | Processes the single non-consumable "Remove Ads" purchase | Trusted purchase result from Apple/Google, but no server-side receipt validation exists (see `ADR §11`) | `StoreKit` (iOS) / Play Billing (Android) via `in_app_purchase` | Apple / Google |
| Flutter engine / OS | Rendering, input, lifecycle (background/foreground), orientation lock | Trusted platform layer | Flutter SDK 3.47.0 stable | Google/Apple platform teams |

### Context flow

```text
[Player] -> [Flutter/Flame client: GameWidget + WidgetsApp root]
              -> [Bundled JSON assets]        (read-only content, load at boot)
              -> [Hive local box "save"]       (read/write, every screen transition + win/lose)
              -> [google_mobile_ads SDK]       (best-effort, degrades to "no ad" on failure)
              -> [in_app_purchase / store billing] (only on Shop screen purchase/restore tap)
```

There is no application server, no REST/GraphQL API, and no database beyond the
local Hive box. Every external system above either has no failure mode that
blocks play (ads: skip silently) or is used at a single, narrow point (IAP: Shop
screen only).

## 3. Chosen stack

Resolved versions below are copied verbatim from `pubspec.lock` — they are
facts, not proposals. Package policy detail (forbidden alternatives) lives in
`rules.md`.

| Layer | Choice + version policy | Why | Alternatives rejected | Source/ADR |
| --- | --- | --- | --- | --- |
| Client/framework | Flutter 3.47.0 (stable) + Flame `1.38.2` component engine | Spec requires camera/parallax/particles/collision that Flame provides natively; pure-widget rebuild would need to hand-roll all of it | Pure Flutter widgets + `AnimationController` (original v1.0 spec) | `ADR-001` |
| Language/runtime | Dart, `sdk: '>=3.11.1 <4.0.0'` | Matches installed Flutter 3.47.0 toolchain | N/A (Flutter mandates Dart) | `ADR-001` |
| State management | `flutter_riverpod` `2.6.1`, bridged into Flame via `flame_riverpod` `5.4.21` | Cross-screen/save state (glow HUD value, wave index, coins/stars) needs a widget-observable store; per-frame simulation state does not | Bloc/Provider (rejected — no project reason to diverge from Riverpod); routing all per-frame state through Riverpod (rejected — too slow, spec explicitly warns against it, `Spec §13`) | `ADR-002` |
| Navigation | `go_router` `16.3.0` | One route per screen (Home/Map/Loadout/Battle/Shop/Settings), each hosting the same `GameWidget` with a different `World` swapped in | Flutter `Navigator` 1.0 imperative routes (rejected — no deep-link/back-button benefit here, spec assumes go_router) | `ADR-003` |
| Backend/API | N/A — no project backend | Spec §20: "Monetization — No Backend"; 100% offline | Any REST/GraphQL backend | N/A |
| Database | `hive_ce_flutter` `2.3.4` (+ `hive_ce` core) | Spec originally names `hive_flutter`, which is unmaintained/discontinued; `hive_ce_flutter` is the maintained community fork with the same API surface | `hive_flutter` (spec's literal choice — discontinued, deliberately deviated from); `sqflite`/`isar` (rejected — overkill for one small object) | `ADR-004` |
| Authentication | N/A | No accounts, no login, single local player | N/A | N/A |
| File/object storage | N/A beyond bundled `assets/` + the single Hive box | No user-generated files, no uploads | N/A | N/A |
| Analytics/observability | None wired | Not scoped by the spec; see §13 for what dev-only tooling exists (Flame's built-in FPS counter, used only in profile builds) | N/A | N/A |
| Deployment/hosting | Google Play (AAB) + Apple App Store (IPA); no server hosting | Store distribution is the only "hosting" a fully offline, client-only game needs | N/A | N/A |

Also pinned: `flame_audio` `2.12.2` (pooled SFX via `FlameAudio`), `google_mobile_ads` `6.0.0`, `in_app_purchase` `3.3.0`.

## 4. Repository and folder structure

The spec (`Spec §21`) places `assets/` under `lib/`. That is wrong for this repo
and has been corrected below: Flutter resolves `pubspec.yaml`'s `assets:` list
relative to the **repository root**, and this project's `pubspec.yaml` already
declares `assets/data/`, `assets/levels/`, `assets/audio/` at repo root — not
`lib/assets/`. The tree below reflects the folders actually created on disk
today (`lib/core`, `lib/game/worlds`, `lib/game/components/{tools,hud}`,
`lib/game/particles`, `lib/state`, `lib/data`), each currently empty pending
implementation.

```text
/
├── AGENTS.md / AGENT.md / CLAUDE.md
├── docs/                            # this governance kit
├── pubspec.yaml / pubspec.lock
├── assets/                          # REPO ROOT, not lib/ — declared in pubspec.yaml
│   ├── data/
│   │   ├── tools.json               # ToolDef[] — 8 tools, Spec §22
│   │   └── shadows.json             # ShadowDef[] — 5 shadows, Spec §22
│   ├── levels/
│   │   └── 1.json … 20.json         # Level + Wave[] per level, Spec §22
│   └── audio/
│       └── place.mp3, collect.mp3, shoot.mp3, hit.mp3, explosion.mp3,
│           win.mp3, lose.mp3, sweep.mp3   # Spec §23
├── lib/
│   ├── main.dart                    # lock landscape, Hive.init, WidgetsApp root, GameWidget
│   ├── core/                        # theme.dart (color/text tokens, no ThemeData),
│   │                                 # router.dart (go_router routes), hive.dart, audio.dart
│   ├── game/
│   │   ├── light_vs_shadow_game.dart  # FlameGame root: CameraComponent + HUD wiring
│   │   ├── worlds/                  # HomeWorld, MapWorld, LoadoutWorld, BattleWorld,
│   │   │                             # ShopWorld, SettingsWorld — one World per screen
│   │   ├── components/
│   │   │   ├── tools/               # Bulb/BeamLamp/Mirror/Prism/FrostLens/Wall/Bomb/TwinBulb
│   │   │   └── hud/                 # TopBar, RightPanel, TraySlot, Button, Toast, overlays
│   │   │       # (grid/tile/shadow/beam/glow-orb/wave-manager components live directly
│   │   │       # under game/components/ per the spec's BattleWorld layer list, Spec §13)
│   │   └── particles/               # particle_definitions.dart (Spec §18.1 inventory),
│   │                                 # effect_pool.dart (Spec §18.3 pooling helper)
│   ├── state/
│   │   └── battle_notifier.dart     # Notifier<BattleState>, bridged via flame_riverpod
│   └── data/
│       ├── models.dart              # ToolDef, ShadowDef, Level, Wave, SaveState
│       └── levels_loader.dart       # loads assets/data/*.json + assets/levels/*.json
└── test/                            # currently empty; see §15
```

### Dependency direction

`game/worlds` + `game/components` (presentation + per-frame simulation)
`-> state` (Riverpod notifiers, cross-screen/save bridge)
`-> data` (models + JSON loaders)

`lib/data` must not import `flame`, `flutter/material.dart`, or
`flutter/cupertino.dart` — it is plain Dart models (`ToolDef`, `ShadowDef`,
`Level`, `Wave`, `SaveState`) and `dart:convert`-based JSON loading, reusable
without the engine.

Per-frame simulation state (tool/shadow positions, HP, active beam paths,
cooldown timers) lives **natively on the Flame components themselves** —
`ShadowComponent.update(dt)`, `BattleWorld.update(dt)`, `WaveManagerComponent`
— because Flame already calls `update(dt)` on every component in the tree
every frame; funneling that through Riverpod would be slow and unidiomatic
(`Spec §13` "State bridge to Riverpod" paragraph). `BattleNotifier extends
Notifier<BattleState>` (in `lib/state/`) exists only for state other
screens/widgets need to *observe*: the Glow count shown in the HUD, the wave
index, and save-relevant totals (coins/stars) once a battle result is
committed. `flame_riverpod`'s `RiverpodAwareGameMixin` /
`RiverpodComponentMixin` is how components read/write that bridge without
importing `game/` back into `state/`.

Any exception to this direction (e.g. a component reading `lib/data` directly
for static defs, which is expected and allowed) is not a violation — `data/` is
the lowest layer and everything may depend on it. What is forbidden is
`data/` depending upward on `game/` or `state/`, and `state/` depending on
`game/`.

## 5. Component/module boundaries

| Module | Owns | Public interface | May depend on | Must not depend on |
| --- | --- | --- | --- | --- |
| `lib/data` | `ToolDef`, `ShadowDef`, `Level`, `Wave`, `SaveState` models; JSON loading (`levels_loader.dart`) | Plain Dart classes + `Future<T> load...()` functions | `dart:convert`, `flutter/services.dart` (asset bundle only) | `flame`, `flutter/material.dart`, `flutter/cupertino.dart`, `lib/state`, `lib/game` |
| `lib/state` | `BattleNotifier`/`BattleState` (glow, wave index, coins, stars, save mirror) | Riverpod `Notifier`/provider | `lib/data`, `flutter_riverpod`, `hive_ce` (via `lib/core/hive.dart`) | `lib/game` (components must depend on state, not the reverse), `flame` |
| `lib/core` | App bootstrap (`main.dart`), theme tokens, `go_router` route table, Hive box init, `FlameAudio` pool setup | `theme.dart` constants, `router.dart` `GoRouter` instance, `hive.dart` init function | `lib/data`, `lib/state`, `lib/game` (composition root wires everything) | Nothing below it — this is the composition root |
| `lib/game/worlds` | One `World` subclass per screen (Home/Map/Loadout/Battle/Shop/Settings); `BattleWorld` owns `WaveManagerComponent` | `World` subclasses consumed by `LightVsShadowGame`/`GameWidget` | `lib/game/components`, `lib/game/particles`, `lib/state`, `lib/data` | Other worlds' internals directly (a world never reaches into another world's component tree) |
| `lib/game/components/tools` | The 8 `ToolComponent` subclasses (Bulb, BeamLamp, Mirror, Prism, FrostLens, Wall, Bomb, TwinBulb) | `ToolComponentFactory.create(id, row, col, ...)` | `lib/data` (ToolDef), `lib/game/particles` | `lib/game/worlds` (tools don't know which world hosts them) |
| `lib/game/components/hud` | `TopBarComponent`, `RightPanelComponent`, `TraySlotComponent`, `ButtonComponent`, `ToastComponent`, pause/win/lose overlays — all live on `camera.viewport` | Flame components added to `camera.viewport` | `lib/state` (reads `BattleNotifier` for display values), `lib/core/theme.dart` | Direct grid/shadow internals — HUD reads state, never simulation objects |
| `lib/game/particles` | `particle_definitions.dart` (the 9-particle inventory, `Spec §18.1`), `effect_pool.dart` (pooling helper, `Spec §18.3`) | Factory functions returning `ParticleSystemComponent` | `flame` | `lib/state`, `lib/data` |
| `assets/` (data+levels+audio) | Bundled read-only content | JSON schema (§8 below), audio files | — (not code) | Never written to at runtime |

Rules:

- Every domain concept has one owning module (grid/tile/shadow/beam
  components not yet split into their own subfolders live under
  `lib/game/components/` directly, per the on-disk layout — this is a flat,
  intentionally small module, not an omission).
- Cross-module access uses public contracts (`ToolComponentFactory`,
  `BattleNotifier`, model classes), never another module's private fields.
- Cyclic dependencies are forbidden — `data -> state -> game` is one-directional.
- A new top-level module (e.g. splitting `game/components` further) requires
  updating this table.

## 6. Frontend/client architecture

- **Composition/root:** `lib/main.dart` — lock orientation to
  `landscapeLeft`/`landscapeRight` (immersiveSticky system UI), `Hive.init` +
  register the `Save` adapter, then `runApp(WidgetsApp(...))`. **No
  `MaterialApp`.** `WidgetsApp.builder` returns a single `GameWidget` wrapped
  by `go_router`'s shell.
- **Navigation:** `go_router` `16.3.0`, one route per screen
  (Home/Map/Loadout/Battle/Shop/Settings). Every route renders the **same**
  `GameWidget`/`LightVsShadowGame` instance with a different `World` swapped
  into `camera.world` (`ADR-003`) — not six separate `GameWidget`s — so the
  engine, camera, and HUD scaffolding are created once.
- **State model:** Per-frame simulation state (positions, HP, active beams,
  cooldowns) is owned by Flame components and lives only as long as
  `BattleWorld` is mounted. Cross-screen/save state (glow for the HUD, wave
  index, coins, stars, unlocked tools, settings) lives in `BattleNotifier`
  (Riverpod), which is itself a thin in-memory mirror of the Hive `save` box —
  Hive is the source of truth, `BattleNotifier` is the observable cache other
  components/HUD read (§4, §8).
- **Rendering/UI:** Every screen is Flame components rendering vector shapes
  via `render(Canvas)`, or (for the ad banner only) a plain Flutter widget
  composited in a `Stack` **outside** the `GameWidget` — `Container`,
  `CustomPaint`, `GestureDetector` only. Zero `Material`/`Cupertino` widgets
  anywhere (`ADR-006`). Design tokens are plain Dart constants in
  `lib/core/theme.dart` (`AppColors`, `TextPaint` builders), not `ThemeData`.
- **Forms/validation:** The only "form" is tool placement. `tryPlace(toolId,
  row, col)` runs the 7 ordered checks from `Spec §17` (state==playing, grid
  bounds, tile occupied, glow≥cost, cooldown elapsed, twin-needs-bulb,
  prism-row-limit) inside `GridComponent`/`BattleWorld`, invoked from
  `TileComponent`'s `TapCallbacks`/`DragCallbacks` — first failing check wins
  and drives the fail-UI (shake, toast, cost-pulse) named in that table.
- **Async states:** A single `GameState` enum (`loading, ready, playing,
  paused, won, lost`, `Spec §16`) gates `update(dt)`. `loading` covers JSON
  (tool/shadow/level defs) and audio preload (`FlameAudio.audioCache.loadAll`)
  before any gameplay component ticks; there is no network "stale/partial"
  state because there is no network dependency in the critical path.
- **Offline/cache:** Bundled JSON (`assets/data/`, `assets/levels/`) is the
  single, immutable source of tool/shadow/level content — no caching or
  invalidation logic needed since it never changes without an app update.
  Hive is the single source of truth for player progress; there is no
  server copy to conflict with.
- **Platform adapters:** `SystemChrome.setPreferredOrientations` (landscape
  lock) and `setSystemUIOverlayStyle` in `main.dart`; haptics gated by
  `save.haptics` through a `Haptic` helper; `didChangeAppLifecycleState ==
  paused -> game.pauseEngine()` (Flame's built-in pause) for app
  backgrounding (`Spec §24` edge case #10).

## 7. Backend/service architecture

`N/A — no project backend.`

This is a fully offline, client-only game (`Spec §1`, §20). There is no
application server, no API the client calls, and no server-side state.
The only network-capable code paths are third-party SDKs the client links
directly: `google_mobile_ads` (fetches ad creatives from Google's ad network)
and `in_app_purchase` (talks to Google Play Billing / Apple StoreKit to
process the one non-consumable purchase). Both degrade gracefully with no
network: ads simply fail to load and are skipped (banner hidden, interstitial
not shown, rewarded button stays disabled via `OpacityEffect` to 0.4 per
`Spec §20`); IAP purchase/restore taps that fail leave `save.removeAds`
unchanged and the player can retry. Neither path blocks gameplay, saving, or
progression — all of which are 100% local (Hive + bundled JSON).

## 8. Data architecture

### Ownership and source of truth

| Entity/data set | Owner | Authoritative store | Cache/replicas | Retention | Classification |
| --- | --- | --- | --- | --- | --- |
| `ToolDef` (8 tools) | `lib/data` | `assets/data/tools.json` (bundled, read-only) | In-memory list loaded once at boot | Lifetime of app version | Public (ships in binary) |
| `ShadowDef` (5 shadows) | `lib/data` | `assets/data/shadows.json` (bundled, read-only) | In-memory list loaded once at boot | Lifetime of app version | Public |
| `Level` + `Wave[]` (20 levels) | `lib/data` | `assets/levels/1.json`…`20.json` (bundled, read-only) | In-memory, loaded per level on entering `LoadoutWorld`/`BattleWorld` | Lifetime of app version | Public |
| `SaveState` (`Save extends HiveObject`) | `lib/state` (`BattleNotifier`) writes through to Hive | Hive box `save`, single object | `BattleNotifier`'s in-memory `BattleState` mirror (read-mostly cache for HUD) | Until app uninstall/user clears data | Internal — coins/stars/settings only, no PII |

### Entity contract template

#### `ToolDef`

- **Purpose / requirement:** Defines the 8 placeable tools' stats; drives
  `ToolComponentFactory` and the tray UI (`Spec §6`, `§22`).
- **Identifier:** `id` (String) — one of `bulb, beam, mirror, prism, frost,
  wall, bomb, twin`; fixed set, immutable at runtime.
- **Fields and invariants:** `cost:int, hp:int, cooldown:int(seconds),
  dmg:double`. All non-negative. `id` must be unique within `tools.json`.
- **Relationships:** Referenced by `Level.availableTools[]` (by `id` string)
  and by `Save.unlocked` (`Set<String>`). No foreign-key enforcement beyond a
  loader-time lookup — an unknown `id` in level/save data is a content bug,
  not a runtime state to recover from.
- **Indexes/query patterns:** Loaded once into a `Map<String, ToolDef>` at
  boot; looked up by `id` when placing a tool or rendering the tray.
- **Lifecycle:** Read-only for the app's lifetime; changes only ship via an
  app update to `tools.json`.
- **Auditability:** N/A — static content, source-controlled.

#### `ShadowDef`

- **Purpose / requirement:** Defines the 5 enemy types' base stats; drives
  `ShadowComponent` spawn behavior (`Spec §7`, `§22`).
- **Identifier:** `id` — one of `basic, bucket, jumper, fog, giant`.
- **Fields and invariants:** `hp:int, speed:int, eat:int`, all positive.
- **Relationships:** Referenced by `Wave.shadows[].id`.
- **Indexes/query patterns:** Loaded once into `Map<String, ShadowDef>`.
- **Lifecycle:** Read-only; content-only changes.
- **Auditability:** N/A.

#### `Level` / `Wave`

- **Purpose / requirement:** Defines the 20-level campaign — flags, par time,
  available tools, wave timing/composition, unlock reward (`Spec §9`, `§22`).
- **Identifier:** `Level.id` (1-20, matches filename `N.json` and the
  `save.stars` array index `id-1`).
- **Fields and invariants:** `name, flags:int, startGlow:int, parTime:int,
  availableTools:String[], unlockReward:String?, waves:Wave[]`. Each `Wave`:
  `delay:double(seconds from level start), flag:bool?, shadows:{id, lane}[]`.
  `lane` ∈ {0,1,2}. Waves are consumed in array order — the 50% rule
  (`Spec §8`) gates *when* the next wave may spawn, not the order.
- **Relationships:** `waves[].shadows[].id` -> `ShadowDef.id`;
  `availableTools[]` / `unlockReward` -> `ToolDef.id`.
- **Indexes/query patterns:** Loaded per level on demand (`Loadout`/`Battle`
  entry), not all 20 at boot.
- **Lifecycle:** Read-only; content-only changes.
- **Auditability:** N/A.

#### `SaveState` (Hive `Save`, `@HiveType(typeId: 0)`)

- **Purpose / requirement:** The entire player-progress record — the one
  piece of mutable, durable state in the whole app (`Spec §19`).
- **Identifier:** Single object, stored under a fixed key (e.g. `'main'`) in
  the `save` Hive box — there is exactly one save, no multi-profile support.
- **Fields and invariants:**

  | Field | HiveField | Type | Notes |
  | --- | --- | --- | --- |
  | `coins` | 0 | `int` | ≥ 0, clamps handled at write time |
  | `stars` | 1 | `List<int>` (len 20) | per-level stars 0-3, index = `levelId - 1` |
  | `unlocked` | 2 | `Set<String>` | `ToolDef.id`s; starts `{"bulb","beam","wall"}` |
  | `removeAds` | 3 | `bool` | set true on successful non-consumable IAP |
  | `sound` | 4 | `bool` | settings toggle |
  | `haptics` | 5 | `bool` | settings toggle |
  | `maxUnlocked` | 6 | `int` | highest level index reachable (progression gate) |
  | `totalPlays` | 7 | `int` | play counter |
  | *(daily reward)* | — | derived, not stored | `dailyId = (DateTime.now().dayOfYear % 20) + 1` computed on read, same formula for every device — deterministic, no persisted "day of year" field needed (`Spec §19`) |

- **Relationships:** `stars[i]`/`unlocked` reference `Level`/`ToolDef` by
  index/id, not by object reference.
- **Indexes/query patterns:** Single-object read on boot into
  `BattleNotifier`; single-object write-through on: win (stars/coins/unlock),
  IAP success (`removeAds`), settings toggle, tray-slot purchase.
- **Lifecycle:** Created with defaults on first launch (`Hive.box.get(key,
  defaultValue: Save())`); updated in place; never deleted except by the
  player uninstalling or clearing app data.
- **Auditability:** None — no audit trail is warranted for a single local
  player's own save file.

### Hive box/key layout

- Box name: `save` (opened once in `lib/core/hive.dart` at boot, before
  `runApp`).
- Adapter: `SaveAdapter` (generated or hand-written for `@HiveType(typeId: 0)
  class Save extends HiveObject`), registered via `Hive.registerAdapter`
  before `Hive.openBox('save')`.
- Key: one fixed key (e.g. `'main'`) holds the single `Save` object. No other
  boxes or keys exist — this app has exactly one durable record.

### Migrations and compatibility

- Adding a `HiveField` requires the next unused field index (never reuse or
  renumber an existing index — that is how Hive keeps binary compatibility
  across app versions with old save data still on-device) and a sensible
  default so existing saves deserialize without loss.
- Removing a field: stop reading it, but do not reuse its field index for a
  new field with a different type — old installs may still have that byte
  written.
- `assets/data/*.json` and `assets/levels/*.json` are not migrated — they are
  replaced wholesale on app update. If a saved `stars`/`unlocked` value
  references a level or tool `id` no longer present in a new content set, the
  loader must tolerate the unknown id (skip/ignore) rather than crash.
- Seed data (`tools.json`, `shadows.json`, `levels/*.json`) is deterministic,
  source-controlled, and contains no personal data.

## 9. Authentication and authorization

- **Identity source:** N/A — there is no user identity. The "player" is
  whoever holds the device; progress is tied to the app install, not an
  account.
- **Session/token lifecycle:** N/A — no sessions or tokens exist anywhere in
  this app.
- **Authorization model:** N/A — there are no roles or permissions to
  enforce; every player has full access to their own local save.
- **Roles/capabilities:** N/A.
- **Unauthenticated behavior:** The entire app is "unauthenticated" by
  design — Home/Map/Loadout/Battle/Shop/Settings are all reachable with no
  login step.
- **Account recovery/deletion:** Uninstalling the app (or clearing app data
  on Android) deletes the Hive `save` box permanently — there is no recovery
  path because there is no server copy. This is disclosed as the game's data
  retention behavior (§11).
- **Threats addressed:** None of the classic auth threats (enumeration,
  replay, token theft, confused deputy, privilege escalation) apply — there
  is no auth surface to attack. The real, non-auth threats for this app are
  covered in the threat model in §11 (local save tampering, IAP spoofing, ad
  SDK data collection).

## 10. Data flow and failure behavior

### Flow: Battle tick (`Spec §16`)

1. `BattleWorld.update(dt)` (and the headless `WaveManagerComponent`) runs
   every frame once `state == playing`, called automatically by Flame's
   component tree — no manual `Ticker`.
2. Glow economy: a `GlowOrbComponent` falls every 8s (capped at 2 on screen);
   each `bulb`/`twin` `ToolComponent` generates glow every 10s (25/50),
   clamped to 999.
3. Wave spawn: `WaveManagerComponent.canSpawnNext()` applies the 50% rule
   (`Spec §8`) — next wave may start once its `delay` has elapsed **and**
   either ≥50% of the previous wave's total HP is dead or 20s have passed
   since the last wave, whichever comes first. This is a pacing gate, not a
   network call — no timeout/retry semantics apply.
4. Per-shadow simulation (movement, eating a blocking tool, jumper leap,
   giant split-on-half-HP) lives on `ShadowComponent.update(dt)` itself, not
   in the central tick — the tick only aggregates terminal-state checks.
5. Sweep: the first shadow to reach `x <= 12` in a lane with `sweep[lane] ==
   true` clears every shadow in that lane once, consuming that lane's single
   sweep.
6. Beam re-trace: `retraceAllBeamsIfDirty()` re-runs the beam trace (next
   flow) only when placement/removal/death changed the grid topology — not
   every frame unconditionally.
7. Dead shadows play their own dissolve effect + particle burst, then call
   `removeFromParent()` themselves when it finishes.
8. Terminal check: **Win** when `waveIndex >= level.waves.length` and no
   `ShadowComponent`s remain. **Lose** when any shadow reaches `x <= 0` in a
   lane whose sweep is already spent.

- **Timeout:** N/A (no I/O) — the only "timeout" concept is the wave
  20s-since-last-wave fallback above, which is gameplay pacing, not a fault.
- **Retry:** N/A — there is nothing to retry; this is deterministic local
  simulation.
- **Idempotency/duplication:** The `dt` spike guard (edge case `Spec §24`
  #18: clamp `dt` on resume after backgrounding, on top of Flame's own
  timestep handling) prevents a large elapsed-time jump from teleporting
  shadows or double-triggering wave spawns/timers.
- **Partial failure:** None applicable — a mid-tick exception would be a
  bug, not an expected partial-failure state; no compensation logic exists
  by design (small, fully local simulation).
- **User recovery:** On Lose, the player gets "Try Again" (instant restart,
  `Spec §2` pillar 5 — zero downtime). On app kill mid-battle, the battle
  itself is not saved (only committed win results persist) — the player
  restarts the level, which is the intended offline-game behavior, not a
  bug to fix with autosave.
- **Telemetry:** None wired (§13) — no events/logs are emitted for this flow
  in the current stack.

### Flow: Beam trace (`Spec §15`)

1. Each active beam source (a `beam`/`twin`/`frost` lamp) seeds a `Ray {start,
   dir, dmg, color, lane}` — a plain data class, not a component.
2. `trace(ray, depth, visited)` recurses: **hard-stop at `depth > 3`**
   (max 3 bounces/splits) and **loop-guard via a `Set<String> visited`** keyed
   on `"${start.dx},${start.dy},${dir}"` — if that key was already visited in
   this trace, return immediately. Both guards exist specifically to make
   mirror-loop configurations (`Spec §24` edge case #7) terminate instead of
   recursing forever.
3. At each step: find the nearest occupied tile (`findNextOccupied`, grid
   scan) and the nearest shadow in the ray's path (via Flame
   `CollisionCallbacks`/`RectangleHitbox` intersection, not manual rect math),
   and take whichever is closer.
4. Shadow hit: apply `dmg * dt` (×0.7 for `fog`), apply slow if the beam is
   the frost color, update/create the rendered `BeamComponent` for that
   segment, spawn a pooled `SparkParticleComponent`, and stop this branch.
5. Mirror: redirect (down/up based on tile row, or alternating by trace
   depth for the middle row) and recurse once (`depth+1`).
6. Prism: split into 3 new rays (right/up/down, each at 0.6× damage, distinct
   colors) and recurse 3 times (`depth+1` each).
7. Any other blocking tool (wall, etc.) or open air: terminate the beam
   segment there (draw to the tile or to the grid edge) with no further
   recursion.
8. `BeamComponent`s are updated in place per active path rather than
   destroyed/recreated every frame, keeping the concurrent-segment count near
   the spec's target of ≤9 (3 lanes × depth-3).

- **Timeout:** N/A (pure computation); the `depth > 3` cap is the functional
  equivalent of a timeout for this recursive algorithm.
- **Retry:** N/A.
- **Idempotency/duplication:** The `visited` set is exactly the
  duplicate-prevention mechanism — without it, a mirror pair facing each
  other would recurse infinitely and hang the frame.
- **Partial failure:** If `findFirstShadowInRay`/`findNextOccupied` finds
  nothing, the ray simply terminates at the grid edge — not an error state
  (edge cases #5/#6, mirror/prism with no incoming beam, must idle without
  crashing).
- **User recovery:** N/A — this is invisible engine-internal logic; the only
  player-visible outcome is the rendered beam path.
- **Telemetry:** None.

## 11. Security and privacy architecture

This is an offline, single-player, no-account game with no server. There is
no untrusted network input to validate, no server-side authorization boundary
to enforce, and no transport to encrypt for gameplay data. Rather than invent
server-shaped threats that do not exist here, this section names the three
threats that are actually real for this architecture: local save tampering,
IAP receipt spoofing, and third-party ad SDK data collection.

- **Untrusted input:** The only "untrusted input" is player taps/drags on the
  Flame canvas, already bounds/state-checked by the 7-step `tryPlace`
  validation (`Spec §17`, §6 above) — this is gameplay-integrity validation,
  not a security boundary (a player "cheating" only affects their own
  single-player save).
- **Authorization boundary:** N/A — no server, no multi-tenant data; see §9.
- **Transport encryption:** N/A for gameplay (no network calls in the
  critical path). Ad SDK and store-billing traffic use their vendors' own
  TLS — not something this app configures.
- **At-rest protection:** The Hive `save` box is stored unencrypted in the
  app's private sandboxed storage (standard OS app-data protection, not
  additional app-level encryption) — proportionate for coins/stars/settings
  with zero PII and no real-money value stored client-side.
- **Secrets:** No API keys or secrets are needed for gameplay. Ad unit IDs
  and store product IDs are not secrets (they are public identifiers baked
  into any build) but are still open per `ARCH-Q-002`/`ARCH-Q-003` (§17)
  pending real IDs.
- **Logs/crash reports/analytics redaction:** N/A — no logging or crash
  reporting pipeline is wired (§13); nothing to redact yet, and nothing
  should be added without first deciding what "redact" needs to mean for a
  future addition.
- **Dependency scanning/patch cadence:** Solo-dev process, not tooling: run
  `flutter pub outdated` before each store release; update `pubspec.yaml`
  pins deliberately (never blind `^` auto-upgrades right before a release).
- **File uploads:** N/A — the app never accepts files from the player.

### Threat model

| Threat | Asset | Entry point | Control | Residual risk | Verification |
| --- | --- | --- | --- | --- | --- |
| Local save tampering (editing the Hive `save` box on a rooted/jailbroken device to grant unlimited coins/stars/unlocks) | `SaveState` (coins, stars, unlocked tools, `removeAds` flag) | Device filesystem access to the app's private Hive box file | None enforced beyond OS app-sandbox isolation — deliberately not adding obfuscation/checksums, since tampering only affects the tamperer's own single-player game, not other players or any shared economy | Accepted, low — no competitive/shared stakes; a player who edits their own save only cheats themselves | None automated; would be caught by manual QA if save-file format changes unexpectedly |
| IAP receipt spoofing (faking a "purchased" `remove_ads` result without paying, e.g. via a modified client or intercepted platform call) | The `remove_ads $2.99` non-consumable entitlement | `in_app_purchase` `purchaseStatus == purchased` callback, trusted without server-side receipt validation (`Spec §20`: "no validation server needed") | None — this is a deliberate, spec-mandated trade-off for a solo no-backend project; `restorePurchases()` is the only legitimacy check available (relies on the platform store, not this app) | Accepted — worst case is one ad-free player who didn't pay; no server infra exists to validate against, and building one is explicitly out of scope | None; would require a backend to close, which is a non-goal (§1) |
| Ad SDK data collection (`google_mobile_ads` collects device/advertising-ID/usage data per Google's own policies, outside this app's control) | Player device identifiers/usage data exposed to Google's ad network | Any screen showing a banner/interstitial/rewarded ad (Home, Map, post-Win) | App-level: ATT (iOS)/consent flow is **not yet wired** — flagged as an open item; scope is limited to Home/Map banners + post-win interstitial + one rewarded ad per battle, never during Battle itself, keeping exposure surface as small as the spec allows | Real, but bounded by the ad SDK's own compliance (COPPA/GDPR consent flows are the vendor's responsibility to expose, this app's responsibility to invoke correctly before showing ads) | Manual verification against Google's current AdMob integration checklist before store submission; not automated in this repo |

## 12. Performance, reliability, and scale

| Requirement | Budget/SLO | Design response | Measurement |
| --- | --- | --- | --- |
| Frame rate | 60fps on low-end Android at 720p (`Spec §24`) | Flame component-level dirty/visibility culling instead of a single `shouldRepaint` flag; pooled particles/beams; `dt` clamp on spikes | Flame's built-in FPS counter component, used during `flutter run --profile` |
| Draw calls | < 50 draw calls/frame (`Spec §24`) | `BeamComponent`s reused/updated in place, not destroyed+recreated; particle pooling via `EffectPool<T>` (`Spec §18.3`); concurrent beam segments capped near 9 (3 lanes × depth-3) | Manual profiling pass per build (no automated draw-call assertion exists) |
| Session length | 2-3 min/level target (`Spec §1`) | Level pacing (wave delays, 50% rule) tuned per level JSON, not an engineering concern | Manual playtest |
| App size/content | 20 levels, 8 tools, 5 shadows — fixed, bundled | All content is static JSON + a handful of `.mp3` files bundled in `assets/`; no dynamic content growth path | N/A |

- **Expected load:** Single player, single device, no concurrency — "load" in
  the server sense does not apply. The only real ceiling is per-frame
  component count during the largest battles (level 16-20, up to 3
  simultaneous `giant` shadows plus their spawned splits, `Spec §9`).
- **Capacity limits:** Glow is clamped to 999 (`Spec §24` #17); glow orbs on
  screen capped at 2; rewarded boost capped at 1/battle; interstitial capped
  at 1/3 wins (`Spec §20`) — all explicit gameplay caps that double as
  resource-growth caps.
- **Caching:** Bundled JSON is loaded once at the relevant screen's boot and
  held in memory for that session — no TTL/invalidation needed since it's
  immutable build content.
- **Pagination/streaming:** N/A — 20 levels and 8/5 defs are small enough to
  load whole.
- **Resilience:** No circuit breaking/retry infra exists or is needed for a
  fully local simulation; the only "degrade gracefully" paths are ads/IAP
  (§7, §11) failing silently without blocking gameplay.
- **Backups/recovery:** None — the Hive `save` box has no backup/restore
  mechanism (no cloud save is in scope, §1 non-goals). This is disclosed
  player-facing risk, not a gap to silently fix: uninstalling the app loses
  progress permanently.

## 13. Observability and operations

- **Logs:** None wired for MVP. Development relies on Flutter/Dart's default
  console output and IDE debugger; no structured logging package is in
  `pubspec.yaml`.
- **Metrics:** None wired. The only runtime instrumentation in the stack is
  Flame's built-in FPS counter component, used manually during profiling
  (`Spec §24`) — not a persisted metric.
- **Traces/correlation:** N/A — no cross-boundary flows exist to correlate
  (no network calls in the critical path).
- **Crash/error reporting:** None wired. Uncaught Flutter errors fall through
  to the default `FlutterError.onError`/`PlatformDispatcher.onError` console
  output. Adding a crash reporter (e.g. Firebase Crashlytics/Sentry) is not
  in the current dependency set and would need its own ADR + privacy review
  before adoption, since it would be the first third-party data-collection
  surface beyond the ad SDK.
- **Alerts:** N/A — no operations team, no backend, nothing to page.
- **Runbooks:** N/A for an offline client app; the closest equivalent is the
  manual QA checklist already in the spec (`Spec §24`, 20 edge cases the
  build must pass before each release).
- **Feature flags/config:** None. All tunables (costs, cooldowns, HP,
  speeds, wave timing) live in the bundled JSON and change only via an app
  update — there is no remote-config or runtime flag system, by design
  (no backend, §1 non-goals).

## 14. Environments and delivery

| Environment | Purpose | Data policy | Access | Deployment trigger |
| --- | --- | --- | --- | --- |
| Local | Development (`flutter run`) | Synthetic Hive save on the dev device/emulator, freely wiped | Developer only | Manual |
| Test/preview | Manual QA against the `Spec §24` edge-case checklist; internal test tracks (Play Console internal testing, TestFlight) | Real app build, no seeded/anonymized data needed (no PII exists) | Repo owner (+ any invited testers) | Manual build upload before a release candidate |
| Production | Public Google Play / App Store listing | Each install starts with a fresh local `Save` default — no shared/governed data since there is no backend | Public (least privilege is N/A — there's no privileged access to restrict) | Manual store submission by the repo owner |

Build reproducibility: standard Flutter build (`flutter build appbundle` /
`flutter build ipa`), version bump via `pubspec.yaml`'s `version:` field
(`0.1.0+1` currently). No environment-variable injection is needed (no API
base URLs, no per-env secrets) since there is no backend to point at.
Configuration is entirely the bundled JSON + compiled-in ad unit/store
product IDs (§17 open questions covers sourcing real ones). There are no
database migrations to run at deploy time — only the Hive `HiveField`
append-only discipline in §8. Rollback is "ship a previous version's
build" via the store consoles; there is no server-side state to roll back.

## 15. Testing architecture

| Layer | Tests | Boundary replaced | Required coverage/critical cases |
| --- | --- | --- | --- |
| Domain (`lib/data`) | Unit tests on `ToolDef`/`ShadowDef`/`Level`/`Wave`/`SaveState` JSON (de)serialization | None — pure Dart, no I/O to fake | Every field round-trips; malformed/missing JSON keys fail loudly at load, not silently at runtime |
| Simulation logic | Unit tests on pure-logic pieces extractable from components — beam `trace()` depth/visited-set behavior (`Spec §15`), 50% wave rule (`Spec §8`) | Flame component tree (test the algorithm as a plain function where possible) | Mirror-loop terminates at depth 3 (edge case #7); `canSpawnNext()` respects both the half-dead and 20s-timeout conditions |
| Component/integration | Flame `flame_test` component tests for placement validation (`tryPlace`'s 7 ordered checks, `Spec §17`) and `ShadowComponent` walk/eat/leap/split behavior | Real Flame component tree, no mocks needed (no external I/O) | Each of the 7 placement failure conditions triggers its documented fail-UI; jumper leaps exactly once per wall; giant splits exactly once at ≤50% HP |
| Product (manual E2E) | The 20-item edge-case checklist in `Spec §24` (occupied tile, insufficient glow, cooldown, background/foreground pause, rotate, Hive persistence across app kill, world-swap cleanup, etc.) | None — run against a real build | All 20 edge cases pass before each store release |

`test/` is currently empty (confirmed on disk) — none of the above exists
yet. This table records the intended shape; `docs/implementation_plan.md`
should turn each row into `TASK-*` entries as the corresponding code is
written. Exact `flutter test`/`flutter drive` commands belong in `AGENTS.md`
once the test suite exists, not here.

## 16. Architecture decision records

### `ADR-001` — Flame component architecture over pure Flutter widgets

- **Status:** Accepted
- **Date/owner:** 2026-09-03, Solo developer (repo owner)
- **Drivers:** `Spec` — WHY FLAME section; `Spec §2` pillar 6 (diorama feel); `Spec §24` (60fps/draw-call budget)
- **Context:** The original v1.0 spec was pure Flutter widgets with hand-rolled `AnimationController`s. Flame does not supply an art style (that's still 100% `Spec §4`), but it supplies `CameraComponent`/`World` for real parallax depth, `ParticleSystemComponent` for pooled particles, the `Effects` API for juice instead of hand-rolled animation controllers, and `CollisionCallbacks` for beam-hits-shadow detection — all of which the "real environment, not an app" pillar and the performance budget need.
- **Options considered:** (a) Pure Flutter widgets + `AnimationController`s (original spec, v1.0). (b) Full Flame component architecture (this ADR). (c) A third-party 2D engine outside the Flutter ecosystem (rejected without discussion — no Dart interop benefit, throws away Flutter's build/deploy pipeline).
- **Decision:** Full Flame component architecture per `Spec §13` (component tree), `§14` (camera/parallax), `§18` (particles/effects).
- **Consequences:** Accept +1 week of solo build time for the component architecture, camera/parallax rig, and effects wiring versus the pure-widget version (`Spec` — WHY FLAME section, explicitly costed). Benefit: pooled particles/beams and Flame's dirty-checking are what make the ≤50-draw-call/60fps budget (§12) achievable at all on low-end Android; hand-rolled widget rebuilds would not hit that budget.
- **Migration/rollback:** N/A — greenfield choice, no prior Flame-less implementation exists in this repo to migrate from.
- **Rules created/changed:** Package policy in `rules.md` should pin `flame`/`flame_audio`/`flame_riverpod` as the approved rendering/animation stack and forbid `flutter_animate`/hand-rolled `AnimationController`s inside the game view (the spec explicitly drops `flutter_animate`, `Spec §21`).
- **Supersedes / superseded by:** N/A.

### `ADR-002` — Riverpod for cross-screen state only, not the game loop

- **Status:** Accepted
- **Date/owner:** 2026-09-03, Solo developer (repo owner)
- **Drivers:** `Spec §13` "State bridge to Riverpod" paragraph; `Spec §21` `BattleNotifier` paragraph
- **Context:** Flame already calls `update(dt)` on every component every frame; routing every position/HP change through Riverpod's provider-rebuild machinery would be slow (extra indirection per frame) and unidiomatic for a real-time simulation.
- **Options considered:** (a) Route all state — including per-frame simulation — through Riverpod. (b) Keep per-frame simulation natively on Flame components; use Riverpod (via `flame_riverpod`'s `RiverpodAwareGameMixin`/`RiverpodComponentMixin`) only as the bridge for cross-screen/save state (glow HUD display, wave index, coins/stars). (c) No state-management package at all, plain `InheritedWidget`/callbacks.
- **Decision:** (b) — `BattleNotifier extends Notifier<BattleState>` holds only what other screens/widgets need to observe; simulation state (positions, HP, active beams, cooldowns) lives on the components themselves.
- **Consequences:** Keeps the hot per-frame path fast and simple (direct field mutation on components). Cost: two sources of "current state" exist (component fields vs. `BattleState`) and code must be deliberate about which one is authoritative for what — this is documented in §4/§10 to prevent drift.
- **Migration/rollback:** N/A — greenfield.
- **Rules created/changed:** `RULE-*` should forbid writing per-frame simulation fields (position/HP/active-beam data) into a Riverpod provider.
- **Supersedes / superseded by:** N/A.

### `ADR-003` — go_router with a single shared GameWidget and swapped Worlds

- **Status:** Accepted
- **Date/owner:** 2026-09-03, Solo developer (repo owner)
- **Drivers:** `Spec §13` (World swappable per screen via router); `Spec §21` (`router.dart // go_router 7 routes, each hosting the shared GameWidget with a different World swapped in`)
- **Context:** Six screens (Home/Map/Loadout/Battle/Shop/Settings) all render through Flame. Standing up six separate `GameWidget`/`FlameGame` instances would re-init the engine, camera, and asset caches on every navigation.
- **Options considered:** (a) One `GameWidget`/`FlameGame` per route, each a fresh engine instance. (b) One shared `GameWidget`/`LightVsShadowGame`, `go_router` routes swap `camera.world` to the relevant `World` subclass. (c) No router — a single `Navigator` with manual imperative pushes.
- **Decision:** (b) — a single long-lived `LightVsShadowGame`, `go_router` `16.3.0` for the 6 named routes, each route's builder swaps `camera.world`.
- **Consequences:** Engine/camera/audio-pool init happens once; navigation is just a `World` swap, which is cheap. Requires deliberate world-teardown discipline (edge case `Spec §24` #20 — confirm the previous `World` and its components, especially generator `ParticleSystemComponent`s, are fully disposed on swap) to avoid leaking off-screen ticking components.
- **Migration/rollback:** N/A — greenfield.
- **Rules created/changed:** `RULE-*` should require every `World.onRemove()` (or equivalent) to explicitly stop/remove any ambient generator components it owns.
- **Supersedes / superseded by:** N/A.

### `ADR-004` — `hive_ce_flutter` instead of the spec's `hive_flutter`

- **Status:** Accepted
- **Date/owner:** 2026-09-03, Solo developer (repo owner)
- **Drivers:** `Spec §21` names `hive_flutter: ^1.1`; `Spec §19` (persistence design, engine-agnostic)
- **Context:** `hive_flutter` (and core `hive`) is unmaintained/discontinued upstream. This is a deliberate, recorded deviation from the literal spec text, not an oversight — `pubspec.lock` already resolves `hive_ce_flutter: 2.3.4` and `hive_ce: (core)`.
- **Options considered:** (a) `hive_flutter`/`hive` as literally named in the spec (rejected — discontinued, no security/bugfix path forward). (b) `hive_ce`/`hive_ce_flutter`, the maintained community fork with the same API surface (chosen). (c) A different local KV/object store (`shared_preferences`, `sqflite`, `isar`) — rejected, all are a heavier or worse-fit tool for one small typed object than a drop-in Hive fork.
- **Decision:** `hive_ce` `+` `hive_ce_flutter` `2.3.4`, same `@HiveType`/`@HiveField`/`Box` API as `hive_flutter`, so `Spec §19`'s persistence design applies unchanged.
- **Consequences:** No functional change to the persistence design in the spec — only the package name/import changes. Gets ongoing maintenance the original package no longer receives.
- **Migration/rollback:** N/A — no prior `hive_flutter` code exists in this repo to migrate from; this was the first and only Hive choice made.
- **Rules created/changed:** `rules.md` should list `hive_ce`/`hive_ce_flutter` as the approved persistence package and explicitly forbid adding `hive`/`hive_flutter`.
- **Supersedes / superseded by:** N/A.

### `ADR-005` — No `google_fonts` dependency at runtime; bundle fonts as assets (open)

- **Status:** Proposed / open
- **Date/owner:** 2026-09-03, Solo developer (repo owner)
- **Drivers:** `Spec §10.2` (typeface table: Orbitron/Inter/JetBrainsMono); `Spec §1` "100% Offline"
- **Context:** The spec's own bootstrap snippet (`Spec §26`) and typeface table name `google_fonts` (`GoogleFonts.orbitron()`, `GoogleFonts.inter()`) as the way to get Orbitron/Inter/JetBrainsMono. `google_fonts` fetches font files from Google's CDN over the network **at runtime** on first use (with local caching after) — that is a live network dependency baked into an app whose entire premise (`Spec §1`, §1/§7 above) is 100% offline-first. It is not in `pubspec.yaml` today and is not one of the resolved dependencies. This is a genuine spec inconsistency: §1 mandates offline-first, but §10.2/§26 assume a fonts package with a network-fetch-on-first-use model.
- **Options considered:** (a) Add `google_fonts` as specified — rejected outright, contradicts offline-first (a fresh install with no connectivity would render with a fallback system font until it can fetch, which is exactly the failure mode offline-first exists to prevent). (b) Bundle the actual Orbitron/Inter/JetBrainsMono TTF files as local assets declared in `pubspec.yaml`'s `fonts:` section and reference them by family name in `TextPaint`/`TextStyle` — correct fix, but the TTF files are not yet sourced/licensed into this repo. (c) Use the platform default font family everywhere until (b) is done.
- **Decision:** (c) for now, as an explicit interim state: ship with the platform default font family, no `google_fonts` dependency, no runtime font fetching. (b) is the target end state once the TTF files are sourced.
- **Consequences:** Typography will not match the spec's exact Orbitron/Inter/JetBrainsMono look until the fonts are bundled. No offline-first violation in the meantime. Flagged as an open task, not silently dropped.
- **Migration/rollback:** Once TTFs are sourced (see `ARCH-Q-001`, §17), add them under e.g. `assets/fonts/`, declare a `fonts:` block in `pubspec.yaml`, and swap the `fontFamily` references in `lib/core/theme.dart` — no `google_fonts` dependency is ever added.
- **Rules created/changed:** `rules.md` should explicitly forbid `google_fonts` (or any runtime font-fetching package) as a forbidden alternative under the typography rule, citing this ADR.
- **Supersedes / superseded by:** N/A.

### `ADR-006` — `WidgetsApp` root, zero Material/Cupertino anywhere

- **Status:** Accepted
- **Date/owner:** 2026-09-03, Solo developer (repo owner)
- **Drivers:** `Spec` — WHY FLAME section ("Zero Material3 / Cupertino anywhere"); `Spec §26` bootstrap snippet
- **Context:** The spec is explicit and non-negotiable on this: every screen is either Flame components or plain Flutter widgets (`Container`, `CustomPaint`, `GestureDetector`) — never `MaterialApp`, `Scaffold`, `ElevatedButton`, `Icon(Icons.*)`, or any Material/Cupertino widget. The app root uses `WidgetsApp`.
- **Options considered:** (a) `MaterialApp` root with Material widgets for HUD/dialogs (rejected — spec's art direction, §4, requires a fully custom hand-drawn look that Material's default styling would fight against, and pulls in the Material icon font this project deliberately excludes, `pubspec.yaml`: `uses-material-design: false`). (b) `WidgetsApp` root, all visuals either Flame `render(Canvas)` or bare Flutter primitives (chosen).
- **Decision:** `WidgetsApp` root (`lib/main.dart`), per `Spec §26`'s bootstrap snippet; the one sanctioned exception is the ad `AdWidget` composited outside the `GameWidget` (`Spec §20`) since it is platform-rendered content, not part of the Flame render tree or a styling choice.
- **Consequences:** No Material theming/localization delegates, no Material `Icon`/`Text` conveniences — every visual element (buttons, toggles, dialogs, toasts) must be hand-built as a Flame component or bare widget. More upfront component work; consistent with the "real environment, not an app" pillar (`Spec §2`).
- **Migration/rollback:** N/A — greenfield choice mandated by the spec from the start.
- **Rules created/changed:** `rules.md` must list `MaterialApp`, `CupertinoApp`, and any `material.dart`/`cupertino.dart` widget import as forbidden, with `AdWidget` as the sole documented exception.
- **Supersedes / superseded by:** N/A.

## 17. Open architecture questions

| ID | Question | Options | Impact | Owner | Due/blocks |
| --- | --- | --- | --- | --- | --- |
| `ARCH-Q-001` | Where do the licensed Orbitron/Inter/JetBrainsMono TTF files come from (Google Fonts static download vs. another licensed source), and under what license terms for commercial app distribution? | (a) Download static TTFs from Google Fonts (all three are open-licensed there) and bundle under `assets/fonts/`. (b) Source an alternative licensed typeface if any of the three has a distribution issue. | Blocks closing `ADR-005`; until resolved, typography ships as platform-default, diverging from `Spec §10.2` | Solo developer | Blocks the visual-polish pass (`Spec §25` Phase 6) |
| `ARCH-Q-002` | What are the real AdMob ad unit IDs (banner, interstitial, rewarded) for Android and iOS, and has ATT (iOS)/UMP consent been wired before any ad SDK initialization? | Create real ad units in the AdMob console per platform; add ATT prompt (iOS 14.5+) and Google's UMP consent flow before `MobileAds.instance.initialize()` | Blocks real ad monetization (`Spec §20`) and App Store review (ATT is a hard requirement) — currently no ad unit IDs exist in this repo | Solo developer | Blocks store submission |
| `ARCH-Q-003` | What is the final iOS/Android bundle identifier? `android/app/build.gradle`'s `applicationId`/`namespace` is still `com.example.plants_vs_zombie`, and iOS is presumably still the Flutter-template default | Choose and reserve a real bundle id (e.g. `com.<dev>.lightvsshadow`) on both App Store Connect and Google Play Console before any store listing is created | Blocks store listing creation and, if changed after any test build is uploaded, requires a fresh app record on both stores | Solo developer | Blocks store submission |
| `ARCH-Q-004` | What are the store listing assets/copy (name, description, screenshots at required sizes, privacy policy URL — required once ads/IAP are present) for Google Play and the App Store? | Draft listing copy; landscape screenshots per `Spec §11` layout; a privacy policy page covering the ad SDK's data collection (§11 threat model) | Blocks store submission; a privacy policy URL is mandatory once `google_mobile_ads` is live, independent of this being an offline game | Solo developer | Blocks store submission |
| `ARCH-Q-005` | Should the `remove_ads` IAP be validated at all (e.g. lightweight on-device receipt sanity check), given `ADR §11` accepts spoofing risk as-is? | (a) Leave as-is, trust `purchaseStatus == purchased` per spec. (b) Add on-device receipt parsing (still spoofable without a server, marginal benefit). (c) Add a lightweight server later if piracy becomes a measured problem | Low urgency — informs whether `ADR §11`'s accepted risk should be revisited post-launch based on real data | Solo developer | Not blocking; revisit post-launch if warranted |

## 18. Change log

| Date | ADR/sections | Reason | PRD/rule/plan links | Owner |
| --- | --- | --- | --- | --- |
| 2026-09-03 | All sections; `ADR-001`–`ADR-006` | Filled the architecture blueprint from `LIGHT_vs_SHADOW_Prism_Defense_Flame_Spec.md` (§§13-22, 24, 26) and the resolved `pubspec.yaml`/`pubspec.lock` versions, replacing all `[REQUIRED: ...]` placeholders | `docs/GOVERNANCE.md` ID scheme; `docs/prd.md` (not yet completed — cited by spec section instead of `PRD-*` IDs pending its completion) | Solo developer (repo owner) |
