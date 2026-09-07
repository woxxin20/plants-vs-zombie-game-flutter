# STATE — prism-defense

<!-- AGENT-OWNED. Whole-file rewrite only, never patched.
     Humans edit HUMAN NOTES only. Rules: .ai/STATE-PROTOCOL.md -->

CYCLE:   14 (closed)
UPDATED: 2026-09-07T18:35+05:30
BY:      lead:GameDesigner
BRANCH:  main
COMMIT:  bbcd08a
STATUS:  BLOCKED

## NEXT ACTION
Remove `game.pauseEngine()` at `lib/game/worlds/battle_world.dart:646`, `:672`
and `:684` — `update` already gates the sim at `:358`, and these three calls are
what stop the render loop before the overlay mounts (`TASK-046`/`AUD-024`).

## PROJECT
Type:    Flutter 3.47 + Flame 1.38 landscape game, offline, no backend
Phase:   PH-02 blocked on AUD-024; PH-04 gate 2/5; PH-05 ads deferred
Success: 20 playable levels, 60fps on low-end 720p Android, airplane-mode clean

## GOAL — this branch
Repurpose this repo from the old Plants-vs-Zombie widget game into LIGHT vs
SHADOW — Prism Defense, per LIGHT_vs_SHADOW_Prism_Defense_Flame_Spec.md.
Done when:
- [x] project-governance-kit deployed and all 8 docs filled, zero placeholders
- [x] pubspec retargeted, `flutter pub get` green, old lib/ removed
- [x] pure rules (optics, placement, waves, scoring) written and unit-tested
- [x] `flutter analyze` clean across lib/ (re-verified c14)
- [x] 8 SFX + bgm.mp3 generated into assets/audio/, 375,607 bytes, in budget
- [ ] a level is playable start to win/lose on a device (blocked by AUD-024)

## BROKEN NOW
- AUD-024 (High, open, deterministic): Pause/Win/Lose stop the render loop
  before the queued overlay mounts. Reproduce: launch level 1, tap Pause during
  wave 1 — no `PAUSED` overlay, frame stops changing.
- AUD-023 (High, open): levels 1-3 are WON by doing nothing.
- AUD-027 (Medium, open): `GameAudio.startBgm()` has zero call sites; bgm.mp3
  is 321KB preloaded and never played, while PRD-FR-021 claims it ships.
- AUD-025 (Medium, open): `pubspec.yaml` bundles 3,496,763 bytes of
  `assets/images/` that no Dart code references.
- AUD-018 reopened (Low): the code fix is right, nothing observes it — in every
  `flutter test` host `_ready` is false, so the changed lines never execute.

## DECISIONS / DO NOT TOUCH
- Pure gameplay rules stay in lib/data/{optics,rules}.dart without Flame/Flutter imports.
- hive_ce_flutter replaces hive_flutter (ADR-004); no google_fonts (ADR-005); no Riverpod state layer (ADR-007) — BattleWorld owns sim state, SaveStore is the only persistence seam.
- assets/levels/*.json come from tool/gen_levels.py and assets/audio/*.mp3 from tool/generate_audio.py, both seeded — never hand-edit either.
- Vector2 has no const constructor (AUD-013); TapCallbacks consumers import package:flame/events.dart directly (AUD-011); hand-painted OpacityEffect targets use FadeableRender (AUD-014); the loadout tray is min(kTrayLimit + bonus, tools the level offers) (ADR-008/AUD-020).
- game.world is NOT camera.world. swapWorld assigns the camera's, so FlameGame.world stays the default World forever — reading it caused AUD-017 and AUD-022. Always camera.world.
- HUD is per-screen and lives on camera.viewport: swapWorld clears it FIRST, each world mounts its own from onLoad. Clearing last deleted the incoming HUD (AUD-021).
- go_router's ShellRoute child is a FULL-SIZE Navigator and must stay wrapped in IgnorePointer, or the whole game becomes untappable (AUD-019).
- GameAudio.setSoundEnabled must never call audioCache.clearAll() — that evicts the cache init() just filled (AUD-018).
- google_mobile_ads + in_app_purchase are commented out in pubspec: 6.0.0 breaks Gradle 9.3.1. Restore lib/core/monetization.dart from git when monetization resumes.

## NEEDS HUMAN
- [ ] AUD-027: does BGM stay in scope? Wire `startBgm()` at a real call site, or
      delete it + bgm.mp3 and strike the music clause from PRD-FR-021.
- [ ] AUD-023: how hard should levels 1-3 be? Fixing it means retuning
      tool/gen_levels.py and regenerating all 20 levels — a balance call.
- [ ] Native bundle id + app label: applicationId, android:label and the iOS
      bundle id are all still `plants_vs_zombie` (ARCH-Q-003/AUD-005). Only the
      launcher icon changed at c13.
- [ ] Font licensing for Orbitron / Inter / JetBrains Mono (ARCH-Q-001).
- [ ] Keystore / signing identity — blocks PH-06's release builds.
- [ ] Do PRD-FR-016/017/018 (ads, IAP) stay `Must` for v1, or are they
      withdrawn? They read `Must` while being descoped. Blocks PH-05 closing.

## COST NOTES
- Never read build/ or .dart_tool/ — generated and high-volume.
- A regression test that has never failed proves nothing. Break the production path and confirm the test fails behaviourally before trusting it.
- A test that passes identically with the feature absent is not evidence. The c13 audio test passes against an empty assets/audio/ — it only stats files.
- Never let a test helper repair the production transition it checks (`_flushLifecycle` masked AUD-024).
- Assert on what only play can produce — unspent sweeps, not GameState.won.
- codegraph is indexed on main and gitignored. `codegraph index` fails while the MCP server holds the db — use `codegraph sync`.
- RuFlo: reach it with `ruflo mcp exec -t <name> -p '<json>'` FROM BASH (PowerShell mangles the JSON). agent_spawn takes `agentType`, not `type`. A spawned RuFlo agent executes nothing — back it with a real subagent.
- Device loop: `flutter build apk --debug`, `adb install -r`, `adb shell am start -n com.example.plants_vs_zombie/.MainActivity`, ADB taps/screenshots.
- .claude-flow/ and .swarm/ (2.1 MB of tool state) are untracked and NOT gitignored — do not `git add -A`.

## HUMAN NOTES
(free text — agent copies this block through byte-for-byte)

## LOG
- 2026-09-07 | c14 | Git-drift review of the uncommitted c13 tree, then committed both. analyze clean, 72/72, codegraph 86/1416/3339. Demoted PRD-FR-021/022 Tested→Built, reverted 3 unearned PH-04 gate boxes (2/5), reopened AUD-018. Logged AUD-025 (3.5MB dead images), AUD-027 (BGM never played); fixed AUD-026 (invalid Xcode boolean). c13 committed as baa71f6, corrections as bbcd08a.
- 2026-09-07 | c13 | Audio + image generation. 8 SFX + bgm.mp3 via tool/generate_audio.py; clearAll() dropped from setSoundEnabled; launcher icons built. Docs overclaimed the result — corrected at c14.
- 2026-09-07 | c11 | Force-stop/cold-start twice. Pause froze without overlay; idle level 1 froze at terminal without Win. Delayed frames byte-identical, logcat clean. AUD-024 deterministic.
- 2026-09-07 | c10 | Debug APK cold-launched on SM-S711B. Home→Loadout→Battle, HUD, placement, Glow and waves work. Found AUD-024. PH-02-G2 done, G1 blocked.
- 2026-09-07 | c9 | First tests that PLAY a level: level 1 won with all sweeps unspent, level 4 lost idle. Negative-controlled. Found AUD-023.
