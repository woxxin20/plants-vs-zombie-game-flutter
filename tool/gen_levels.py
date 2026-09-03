#!/usr/bin/env python3
"""Generate assets/levels/1..20.json from the progression table in
LIGHT_vs_SHADOW_Prism_Defense_Flame_Spec.md section 9.

This is a build-time authoring tool, not shipped code. Re-run it after editing
the BANDS table; it overwrites the level files deterministically (fixed seed),
so the same input always produces the same levels and a diff is reviewable.

    python tool/gen_levels.py
"""

import json
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "levels")

BASE = ["bulb", "beam", "wall"]

# (level range, flags, par time, tools, unlock reward on the LAST level of the
# band, enemy pool) -- spec section 9.
BANDS = [
    (range(1, 3),   1,  45.0, BASE,                                              None,     ["basic"]),
    (range(3, 5),   1,  60.0, BASE + ["frost"],                                  None,     ["basic"]),
    (range(5, 8),   2,  75.0, BASE + ["mirror"],                                 "mirror", ["basic", "bucket"]),
    (range(8, 12),  2,  90.0, BASE + ["mirror", "frost"],                        "frost",  ["basic", "bucket", "jumper"]),
    (range(12, 16), 3, 110.0, BASE + ["mirror", "frost", "prism", "bomb"],       "prism",  ["basic", "bucket", "jumper", "fog"]),
    (range(16, 19), 3, 130.0, BASE + ["mirror", "frost", "prism", "bomb", "twin"], "twin", ["basic", "bucket", "jumper", "fog", "giant"]),
    (range(19, 21), 3, 150.0, BASE + ["mirror", "frost", "prism", "bomb", "twin"], None,   ["basic", "bucket", "jumper", "fog", "giant"]),
]

NAMES = {
    1: "First Light", 2: "Steady Glow", 3: "Hold the Line", 4: "Shade Block",
    5: "Helm Shade", 6: "Two Fronts", 7: "Reflected", 8: "The Leaper",
    9: "Over the Wall", 10: "Cold Snap", 11: "Frostbite", 12: "Veil",
    13: "Through the Fog", 14: "Spectrum", 15: "Split Light", 16: "Colossus",
    17: "Twin Suns", 18: "Overload", 19: "Last Stand", 20: "Total Eclipse",
}

# The 12 flags in a run are what create the spec's "peace -> waves -> huge wave"
# rhythm. Non-flag waves are small probes; flag waves are the full-lane pushes.
def build_waves(level, flags, pool, rng):
    total = flags + 2 + min(level // 4, 3)  # 3..8 waves, growing with level
    flag_slots = set()
    # Flag waves are always the last `flags` waves, so pressure ends the level.
    for i in range(total - flags, total):
        flag_slots.add(i)

    waves = []
    # Spec section 3: 20s of peace before the first shadow on early levels.
    t = 12.0 if level <= 2 else max(8.0, 14.0 - level * 0.2)
    for i in range(total):
        is_flag = i in flag_slots
        # Wave size grows with level and doubles on a flag wave.
        size = 1 + level // 5
        if is_flag:
            size = min(5, size * 2 + 1)
        lanes = [rng.randrange(0, 3) for _ in range(size)]
        # A flag wave always touches every lane at least once.
        if is_flag:
            lanes = [0, 1, 2] + lanes[3:]
        shadows = []
        for lane in lanes:
            # Tougher enemies only appear once they have been introduced, and
            # a flag wave leans on the heaviest available type.
            weights = [1.0] * len(pool)
            if is_flag and len(pool) > 1:
                weights[-1] = 2.5
            sid = rng.choices(pool, weights=weights, k=1)[0]
            shadows.append({"id": sid, "lane": lane})
        w = {"delay": round(t, 1), "shadows": shadows}
        if is_flag:
            w = {"flag": True, **w}
        waves.append(w)
        t += (18.0 if is_flag else 12.0) + rng.uniform(-2.0, 2.0)
    return waves


def main():
    os.makedirs(OUT, exist_ok=True)
    for band in BANDS:
        levels, flags, par, tools, reward, pool = band
        last = levels[-1]
        for lvl in levels:
            rng = random.Random(1000 + lvl)  # deterministic per level
            data = {
                "id": lvl,
                "name": NAMES.get(lvl, f"Level {lvl}"),
                "flags": flags,
                "startGlow": 50 if lvl < 8 else 75,
                "parTime": par,
                "availableTools": tools,
                "unlockReward": reward if lvl == last else None,
                "waves": build_waves(lvl, flags, pool, rng),
            }
            path = os.path.join(OUT, f"{lvl}.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2)
                f.write("\n")
    print(f"wrote 20 levels to {OUT}")


if __name__ == "__main__":
    main()
