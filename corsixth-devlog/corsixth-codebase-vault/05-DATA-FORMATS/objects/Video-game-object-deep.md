# Video game — thob 57 — vanilla-parity deep note

> Resolves the thob-57 clash: `video_game.lua:23` owns thob 57; `lecture_chair.lua:23` is thob 36. Full-repo thob scan shows one 57, one 36 (only dup is thob 28 shield+b). `base_config.lua:256` = 36 Lecture Chair vs `:277` = 57 Video Game; strings `:160` vs `:181` distinct; training needs chair while staff-room uses video_game. Doc error only — no code change. Fix W4/catalog 57-dup lines to 36.

Scope: video_game (thob 57). Read-only; repo at `~/CorsixTH`, original data at `~/game_data/HOSP`.

## 1. CorsixTH definition — Documented fact

- `id="video_game"` :22, `thob=57` :23; `ticks=false` :26; preview `5106` :27
- idle north `3696`, south aliased; comment: Doctor+Nurse anims only, Handyman none; unused Doctor 3692 standing still
- `usage_animations` north + south-dup: `in_use Doctor=3700 Nurse=4764`. No begin/finish, no east/west block.
- `orientations` N+E: north `{0,0 complete},{0,1 only_passable}`, `use="passable"`, animate-from-use; east `{0,0},{1,0}`, same
- `rooms/staff_room.lua:29` additional (optional; needed = sofa)
- Cost `base_config.lua:277`: StartCost 200, avail 0 (research/late unlock), strength 10
- Active-use wiring: `use_staffroom.lua:51-55` 20% video_game (Doctor/Nurse only); `:63-71` use time 2-15; `:74-78` relaxation 0.05; `:111` forced prolonged (no begin/end); `:158-162` UseObject+Walk
- Happiness `staff.lua:94-99`: recreation 0.08 (vs pool 0.074, sofa 0.05)

## 2. Original TH data — Documented fact

- Base row + tooltip (`S[2][58]`, `S[40][58]`) match (proxy). Contrast thob 36 chair (cost 50, avail 1) — distinct.
- Game data present; no thob-57 decode; LUT tiles-only.

## 3. Comparison verdict

| Attribute | Verdict | Evidence |
|---|---|---|
| thob 57 (sole owner) | match (proxy) | `video_game.lua:23` + scan |
| cost 200 / avail 0 | match (proxy) | `base_config.lua:277` |
| 1+1 N/E footprint | unverified | `:53-64` |
| idle/use anims, Doctor/Nurse only | unverified | `:29-51` + `use_staffroom.lua:53` |
| no-clash | confirmed | thob scan + base + strings |

## 4. Footprint-compare [Inference]

- `use="passable"` → first `only_passable`; nearest solid d=1 → single-dir; pre==post. E/W via mirror + idle fallback.

## 5. Behavior checklist

- Passable-use both orients, forced prolonged (no begin/finish). No slave/crash/smoke/`early_list`. Handyman exclusion + 3692 anim need TH confirm. Soak/save pending.

## 6. Strict / minimal + next + pass/fail

- strict/minimal: unfiled. Next: overlay; `original_cells` vs SAM; disassemble thob-57; Handyman/3692 confirm; soak + save/load + `busted`/`luacheck`; fix 57-dup doc lines.
- Result: FAIL (pending).
