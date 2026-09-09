# STATE — prism-defense

<!-- AGENT-OWNED. Whole-file rewrite only, never patched.
     Humans edit HUMAN NOTES only. Rules: .ai/STATE-PROTOCOL.md -->

CYCLE:   16 (closed)
UPDATED: 2026-09-09T12:50+05:30
BY:      lead:GameDesigner
BRANCH:  main
COMMIT:  0db6b15
STATUS:  NEEDS-REVIEW

## NEXT ACTION
Investigate `AUD-028` in `lib/game/components/hud/right_panel_component.dart`:
determine whether a column-7 tile is TAPPABLE on a 2424x1080 viewport, since the
panel covers 38% of it and hit-tests in a different coordinate space.

## PROJECT
Type:    Flutter 3.47 + Flame 1.38 landscape game, offline, no backend
Phase:   PH-02 closed; PH-04 gate 2/5; PH-05 rescoped, no monetisation
Success: 20 playable levels, 60fps on low-end 720p Android, airplane-mode clean

## GOAL — this branch
Repurpose this repo from the old Plants-vs-Zombie widget game into LIGHT vs
SHADOW — Prism Defense, per LIGHT_vs_SHADOW_Prism_Defense_Flame_Spec.md.
Done when:
- [x] project-governance-kit deployed and all 8 docs filled, zero placeholders
- [x] pubspec retargeted, `flutter pub get` green, old lib/ removed
- [x] pure rules (optics, placement, waves, scoring) written and unit-tested
- [x] `flutter analyze` clean across lib/
- [x] 8 SFX + bgm.mp3 ship and BGM plays; fonts bundled; native identity renamed
- [x] Pause/Win/Lose overlays mount (AUD-024) and levels 2-3 punish idling (AUD-023)
- [x] a level is playable start to win/lose ON A DEVICE — level 1 to VICTORY on
      emulator-5554, progress persisted (c16). PH-02-G1 passed.

## BROKEN NOW
- AUD-028 (Medium, open): the right HUD panel covers 38% of the board's 7th tile
  column on a 2424x1080 viewport. Panel left edge measures 1554 px; column 7
  spans 1414-1633. `BattleLayout` is self-consistent and predicts a 24-unit gap
  — the board is in world space, the panel in camera.viewport space, and they
  disagree once the camera letterboxes a non-baseline aspect ratio.
  Reproduce: start any battle on a display whose aspect is not 812:375.
  **Untested and more important: is a column-7 tile still tappable?**
- AUD-018 (Low, open): no test host has the audio plugin, so `_ready` is always
  false and no test can hear a cue. Closes on a device, by listening.

## DECISIONS / DO NOT TOUCH
- Pure gameplay rules stay in lib/data/{optics,rules}.dart without Flame/Flutter imports.
- hive_ce_flutter replaces hive_flutter (ADR-004); no google_fonts, fonts are bundled TTFs (ADR-005); no Riverpod state layer (ADR-007) — BattleWorld owns sim state, SaveStore is the only persistence seam.
- assets/levels/*.json come from tool/gen_levels.py and assets/audio/*.mp3 from tool/generate_audio.py, both seeded — never hand-edit either.
- game.world is NOT camera.world. swapWorld assigns the camera's, so FlameGame.world stays the default World forever (AUD-017, AUD-022). Always camera.world.
- HUD is per-screen and lives on camera.viewport: swapWorld clears it FIRST, each world mounts its own from onLoad (AUD-021).
- go_router's ShellRoute child is a FULL-SIZE Navigator and must stay wrapped in IgnorePointer (AUD-019).
- AUD-024: do NOT call pauseEngine() to freeze a battle. `update` gates on `state != playing`; a paused engine only stops the renderer, so queued overlays never mount. Only the lifecycle background path may pause the engine, and its resumed branch must always resumeEngine().
- GameAudio.setSoundEnabled must never call audioCache.clearAll() (AUD-018).
- assets/images/ is deliberately NOT in the pubspec asset manifest (AUD-025).
- Level 1 is unloseable on purpose (onboarding). Levels 2+ must punish idling (AUD-023).
- PRD-FR-016/017/018 (ads, IAP) are Won't for v1. Do not re-add google_mobile_ads or in_app_purchase.
- AUD-028: do NOT fix the panel overlap by shrinking S.rightPanelW until one device looks right. Find the viewport's real coordinate space first.

## NEEDS HUMAN
- [ ] Keystore / signing identity — blocks PH-06's release builds.
- [ ] Review the c15+c16 diff: `git diff 7a48bed..HEAD`.

## COST NOTES
- Never read build/ or .dart_tool/ — generated and high-volume.
- A regression test that has never failed proves nothing. Revert the production path and confirm the test fails first. Done for AUD-024 (0/5) and AUD-023.
- Never let a test helper perform the transition it asserts. `_flushLifecycle` in ph02_exit_gate_test.dart resumes the engine and is why AUD-024 survived four cycles of a green suite.
- In flutter test there is no audio plugin, so GameAudio._ready is always false and every `if (!_ready) return;` body is unreachable.
- Device evidence: compare FRAME HASHES over time, not single screenshots. A frozen renderer gives byte-identical frames (c11); a healthy one never repeats (c16, 24/24 distinct).
- Measure layout defects from pixels, not from the screenshot's look. Sample a scanline, derive the camera scale from tile pitch, compare against BattleLayout.
- codegraph: `codegraph index` fails while the MCP server holds the db — use `codegraph sync`.
- RuFlo: `ruflo mcp exec -t <name> -p '<json>'` FROM BASH (PowerShell mangles the JSON). agent_spawn takes `agentType`, not `type`.
- Device loop: `flutter build apk --debug` (~137s), `adb install -r`, `adb shell am start -n com.rdx.prismdefense.flame/.MainActivity`. Screenshot with `adb exec-out screencap -p > f.png`; `shell screencap -p /path` then pull is fine too but exec-out is one call.
- .claude-flow/ and .swarm/ are gitignored as of c14. Do not un-ignore them.

## HUMAN NOTES
(free text — agent copies this block through byte-for-byte)

## LOG
- 2026-09-09 | c16 | Device retest on emulator-5554 (Android 17, 2424x1080). Cold launch 12.3s, Home->Loadout->Battle, Pause mounted PAUSED, RESUME resumed, level 1 ran to VICTORY 1 STAR +30 COINS, star/coins/unlock persisted. 24/24 frames distinct, logcat clean. AUD-024 closed, PH-02-G1 passed, PH-02 closed. Found AUD-028 (panel covers 38% of column 7).
- 2026-09-09 | c15 | Applied 7 owner decisions. Closed AUD-024 in code (removed 3 redundant pauseEngine calls + lifecycle-resume deadlock; negative-controlled 0/5 -> 5/5) and AUD-023 (levels 2-3 to 5/6 waves). Wired BGM, unbundled 3.5MB of images, renamed to com.rdx.prismdefense.flame, bundled 3 OFL fonts, withdrew ads/IAP. 79/79.
- 2026-09-07 | c14 | Git-drift review of the uncommitted c13 tree, then committed both. Demoted PRD-FR-021/022 Tested->Built, reverted unearned PH-04 gate boxes, reopened AUD-018. Logged AUD-025/026/027.
- 2026-09-07 | c13 | Audio + image generation. Docs overclaimed the result — corrected at c14.
- 2026-09-07 | c11 | Two cold starts reproduced AUD-024. Frames byte-identical, logcat clean. Deterministic.
