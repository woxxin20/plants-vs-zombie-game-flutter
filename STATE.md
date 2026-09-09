# STATE — prism-defense

<!-- AGENT-OWNED. Whole-file rewrite only, never patched.
     Humans edit HUMAN NOTES only. Rules: .ai/STATE-PROTOCOL.md -->

CYCLE:   15 (closed)
UPDATED: 2026-09-09T10:05+05:30
BY:      lead:GameDesigner
BRANCH:  main
COMMIT:  7a48bed
STATUS:  NEEDS-REVIEW

## NEXT ACTION
Run `flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk`,
then launch `com.rdx.prismdefense.flame/.MainActivity` and play level 1 to a
VICTORY overlay — the AUD-024 device retest that closes `PH-02-G1`.

## PROJECT
Type:    Flutter 3.47 + Flame 1.38 landscape game, offline, no backend
Phase:   PH-02 device retest pending; PH-04 gate 2/5; PH-05 rescoped, no monetisation
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
- [ ] a level is playable start to win/lose ON A DEVICE — code fixed, unproven

## BROKEN NOW
- nothing known broken in code. `flutter analyze` clean, `flutter test` 79/79.
- Unproven, not broken: AUD-024's fix has never run on hardware. The last device
  run (c11) predates it. Reproduce the old failure to confirm it is gone:
  launch level 1, tap Pause during wave 1, expect a PAUSED overlay.
- AUD-018 (Low, open): no test host has the audio plugin, so `_ready` is always
  false and no test can hear a cue. Closes on a device, not in CI.

## DECISIONS / DO NOT TOUCH
- Pure gameplay rules stay in lib/data/{optics,rules}.dart without Flame/Flutter imports.
- hive_ce_flutter replaces hive_flutter (ADR-004); no google_fonts, fonts are bundled TTFs (ADR-005); no Riverpod state layer (ADR-007) — BattleWorld owns sim state, SaveStore is the only persistence seam.
- assets/levels/*.json come from tool/gen_levels.py and assets/audio/*.mp3 from tool/generate_audio.py, both seeded — never hand-edit either.
- game.world is NOT camera.world. swapWorld assigns the camera's, so FlameGame.world stays the default World forever (AUD-017, AUD-022). Always camera.world.
- HUD is per-screen and lives on camera.viewport: swapWorld clears it FIRST, each world mounts its own from onLoad (AUD-021).
- go_router's ShellRoute child is a FULL-SIZE Navigator and must stay wrapped in IgnorePointer (AUD-019).
- AUD-024: do NOT call pauseEngine() to freeze a battle. `update` gates on `state != playing`; a paused engine only stops the renderer, so queued overlays never mount. Only the lifecycle background path may pause the engine.
- GameAudio.setSoundEnabled must never call audioCache.clearAll() (AUD-018).
- assets/images/ is deliberately NOT in the pubspec asset manifest — nothing loads it (AUD-025).
- Level 1 is unloseable on purpose (onboarding). Levels 2+ must punish idling (AUD-023).
- PRD-FR-016/017/018 (ads, IAP) are Won't for v1. Do not re-add google_mobile_ads or in_app_purchase.

## NEEDS HUMAN
- [ ] Keystore / signing identity — blocks PH-06's release builds.
- [ ] Review the c15 diff before more work: `git diff 7a48bed..HEAD`.

## COST NOTES
- Never read build/ or .dart_tool/ — generated and high-volume.
- A regression test that has never failed proves nothing. Revert the production path and confirm the test fails before trusting it. Done for AUD-024 (0/5) and AUD-023.
- A test that passes identically with the feature absent is not evidence.
- Never let a test helper repair the production transition it checks. `_flushLifecycle` in ph02_exit_gate_test.dart resumes the engine and is why AUD-024 survived a green suite — never copy that pattern.
- In flutter test there is no audio plugin, so GameAudio._ready is always false and every `if (!_ready) return;` body is unreachable. Audio cannot be asserted in CI.
- codegraph: `codegraph index` fails while the MCP server holds the db — use `codegraph sync`.
- RuFlo: `ruflo mcp exec -t <name> -p '<json>'` FROM BASH (PowerShell mangles the JSON). agent_spawn takes `agentType`, not `type`. A RuFlo agent executes nothing — back it with a real subagent.
- Device loop: `flutter build apk --debug`, `adb install -r`, `adb shell am start -n com.rdx.prismdefense.flame/.MainActivity`. Bundle id changed at c15 — uninstall the old com.example build first, its save data will not carry over.
- .claude-flow/ and .swarm/ are gitignored as of c14. Do not un-ignore them.

## HUMAN NOTES
(free text — agent copies this block through byte-for-byte)

## LOG
- 2026-09-09 | c15 | Applied 7 owner decisions. Closed AUD-024 (removed 3 redundant pauseEngine calls + fixed the lifecycle-resume deadlock; negative-controlled 0/5 -> 5/5) and AUD-023 (levels 2-3 to 5/6 waves, L1 stays unloseable). Wired BGM, unbundled 3.5MB of images, renamed to com.rdx.prismdefense.flame, bundled 3 OFL fonts, withdrew ads/IAP from v1. 79/79, analyze clean. Device retest outstanding.
- 2026-09-07 | c14 | Git-drift review of the uncommitted c13 tree, then committed both. Demoted PRD-FR-021/022 Tested->Built, reverted 3 unearned PH-04 gate boxes, reopened AUD-018. Logged AUD-025/026/027; fixed AUD-026.
- 2026-09-07 | c13 | Audio + image generation. 8 SFX + bgm.mp3; clearAll() dropped; launcher icons built. Docs overclaimed the result — corrected at c14.
- 2026-09-07 | c11 | Two cold starts reproduced AUD-024. Delayed frames byte-identical, logcat clean. Deterministic.
- 2026-09-07 | c10 | Debug APK on SM-S711B. Home->Loadout->Battle, HUD, placement, waves work. Found AUD-024.
