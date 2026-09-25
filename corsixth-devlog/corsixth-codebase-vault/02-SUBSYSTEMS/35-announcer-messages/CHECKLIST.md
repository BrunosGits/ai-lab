# Safety Gate — Announcer / Fax Changes

> Check all before touching `announcer.lua`, `bottom_panel.lua`, `message.lua`, `fax.lua`, `adviser.lua`.

## Announcer

- [ ] `pop()` still returns Critical→Low in order; `count` stays consistent on push/pop?
- [ ] Dedup still refreshes `created_date` and drops the new entry (no double-queue)?
- [ ] Non-Critical still blocked without staffed reception desk at both enqueue AND drain?
- [ ] Decay defaults unchanged (Crit never, High 31d, Normal 7d, Low 3d); custom `decay_hours` honored?
- [ ] Paused game plays ONLY Critical; unpaused drains all (skipping decayed)?
- [ ] `playing` flag serializes (no overlap); `_onPlayed` fires `played_callback` after `played_callback_delay`?
- [ ] `rand*.wav` wildcard still resolves; volume uses `announcement_volume`; subtitle queued?
- [ ] `play_announcements` off still drains queue silently (no stuck entries)?

## Fax / bottom panel

- [ ] `canQueueFax` still forbids epidemy+emergency co-queue; loser cancelled correctly?
- [ ] Max 5 icons, one visible per type; door animation + `NewFax.wav` intact?
- [ ] `timeout` → `default_choice` fires on `onWorldTick`; owner-bound messages (`epidemic=self`) cleared on cancel?
- [ ] Single-choice faxes dismissible; multi-choice plays `wrong2.wav` on dismiss attempt?
- [ ] `strike` still bypasses `UIFax` → `UIStaffRise`?
- [ ] `UIFax:choice` strings unchanged (`accept_vip/refuse_vip/declare_epidemic/cover_up_epidemic/...`); ends with `removeMessage+close`?
- [ ] Fax still pauses game; toggle state re-synced via `adjustToggle`?
- [ ] Save/load: `afterLoad` bumps for fax/adviser/bottom-panel still migrate old saves?

## Adviser

- [ ] `adviser_disabled` config still suppresses; duplicates still dropped unless `override_current`?
- [ ] Priority pick in `talk()` still selects max priority, FIFO within equal?
- [ ] History capped at 20, re-add moves to top?

## Consumers

- [ ] VIP: `personality` fax choices carry `additionalInfo.name`; default accept; `vip_declined` override path preserved?
- [ ] Epidemic: initial fax default = cover-up (index 2); declare path applies fine+rep with NO result fax; cover-up chains to result `report` fax?
