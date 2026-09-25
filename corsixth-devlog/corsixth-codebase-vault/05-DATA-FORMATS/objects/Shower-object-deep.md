# Shower Object Deep — thob 54 (Decontamination)

Legend: [F] Documented fact / [I] Inference / [H] Hypothesis. Strict/minimal per VANILLA_METHOD.

## 1. Identity
- [F] `id="shower"`, thob 54 — `Lua/objects/machines/shower.lua:22-23`; cure, fallback 6 (`:24-25`); ticks false, town_map true; preview 5100; `default_strength=10`, crashed 3380, smoke 3448 (`:28-33`).
- [F] Name/desc: `S[2][55]` / `S[40][55]` no description (`original_strings.lua:178,1824`).

## 2. Footprint (pre-shift, as written)
- [F] North: use `{-1,1}` (`:64-65`); 10 tiles (`:66-69`): `{-2,-2 c},{-1,-2 c},{0,-2},{-2,-1 c},{-1,-1 c},{0,-1 c},{-2,0 c},{-1,0 c},{0,0 c},{-1,1 p}` (c=complete, p=only_passable).
- [F] East: use `{1,-1}` (`:73-74`); 10 tiles (`:75-78`).
- [F] Only north+east defined; idle north 2014 + `copy_north_to_south`; usage north only.
- [I] Post-shift: north use→`{0,1}` (nearest solid `{-1,0}`); east use→`{1,0}` (nearest solid `{0,-1}`). Single-dir `pathfind_allowed_dirs`.
- [I] Asymmetric corners (north `{0,-2}`, east `{-2,0}` non-complete) still block via `coordinatesAreInFootprint`.

## 3. Use / crash / smoke
- [F] Patient anims Male 2018/2150/2026, Female 2852/2856/2860, Handyman 3534/3538/3542 (`:44-58`).
- [F] `render_attach_position={-1,0}` both; `smoke_position={0,0}` both.
- [I] Handyman tile = use tile (no override); post-shift `{0,1}` N / `{1,0}` E.
- [F] No slave/secondary/finish/`early_list`.

## 4. Room + costs + flow
- [F] `rooms/decontamination.lua:22,24-25,30,35-41`: id decontamination, level 30, DecontaminationRoom, needs `{shower=1,console=1}`, min 5, blue/19, Doctor=1, preview 5100.
- [F] Shower `StartCost=6500, StartStrength=10` (`base_config.lua:274`); matches `default_strength` 10. Room `[30] Cost=5500`. Cure price 1800 (`serious_radiation.lua:29`).
- [F] Sole treatment for serious_radiation (`:64-66`, `requires_machine`); doctor→console, patient→shower, `shower_ready` sync loop; duration `rand()*3-skill`.
- [I] Patient only enters shower; doctor only console; handyman repair-only.

## 5. Verdict + next
- Verdict: FAIL (incomplete) — T+C present, V missing. No strict/minimal PASS.
- Next: TH screenshot north+east + save; `original_cells` vs SAM dump; file masks; 5000-tick soak + save/load + handyman reachability.
