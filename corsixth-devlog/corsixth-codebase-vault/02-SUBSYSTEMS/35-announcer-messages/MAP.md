# Announcer + Message/Fax Flow — MAP

> All paths `CorsixTH/Lua/...`. Verified via `ssh vps "cat|grep|sed"`.

| Claim | File:lines |
|---|---|
| Priority enum `Critical..Low`, global export | `announcer.lua:24-32` |
| Default priority `Normal`; decay table (Crit -1, High 31d, Normal 7d, Low 3d) | `announcer.lua:34-42` |
| `AnnouncementQueue` ctor (4 buckets + count) | `announcer.lua:44-60` |
| `push` / `pop` (priority-order scan) / `isEmpty` | `announcer.lua:66-88` |
| `checkForDuplicates` (match `name`, refresh `created_date`) | `announcer.lua:93-106` |
| `AnnouncementEntry` fields (`name,priority,created_date,decay_hours,callbacks`) | `announcer.lua:109-124` |
| `Announcer` ctor (`playing=false`, random target) | `announcer.lua:134-142` |
| `playAnnouncement` (dup check, decay default, desk-or-Critical gate) | `announcer.lua:150-182` |
| `onTick` (random `rand*.wav` Low, desk gate, decay skip, pause→Critical only) | `announcer.lua:186-223` |
| `_setRandomAnnouncementTarget` (3333 ticks/min, 4–6 min) | `announcer.lua:225-236` |
| `_play` (wildcard resolve, `playSound` announcement, subtitle, reset ticks) | `announcer.lua:238-244` |
| `_onPlayed` (clear `playing`, fire callback) | `announcer.lua:248-254` |
| `GameUI` owns announcer; `playAnnouncement` wrapper; `playRandomAnnouncement`; tick pump; save-restore | `game_ui.lua:113,861-863,846-859,944,1350-1360` |
| `Audio:playSound` (`is_announcement`→`announcement_volume`); wildcard resolve | `audio.lua:329-356,420-426` |
| Staffed-desk predicate | `hospital.lua:1033-1041` |
| `UIFax` ctor (choice buttons, close/cancel/validate, keypad `Fax_*.wav`) | `dialogs/fullscreen/fax.lua:30-91` |
| `mustPause → true` | `dialogs/fullscreen/fax.lua:93-95` |
| `choice` dispatch (emergency, VIP, epidemic, win/level) + `removeMessage+close` | `dialogs/fullscreen/fax.lua:135-245` |
| VIP refuse-override (`vip_declined>2` + coin flip) | `dialogs/fullscreen/fax.lua:191-199` |
| Fax cheat keypad (`24328`, `112`→Critical, `fax_yes/no.wav`) | `dialogs/fullscreen/fax.lua:258-291` |
| `queueMessage` (+ first-fax adviser hint) | `dialogs/bottom_panel.lua:438-462` |
| Drawer-icon factory + `onClose` shift-left | `dialogs/bottom_panel.lua:472-502` |
| `canQueueFax` (epidemy↔emergency exclusion); `cancelFax` | `dialogs/bottom_panel.lua:504-550` |
| `_findMessageToShow` (max 5, one type visible); `_showMessageIcon` (`NewFax.wav`); `_messageDoorTick` | `dialogs/bottom_panel.lua:562-580,627-643,669-687` |
| `deleteMessage` (queue vs windows) | `dialogs/bottom_panel.lua:593-625` |
| `UIMessage` ctor (type→sprite, `can_dismiss`, siren rotator) | `dialogs/message.lua:27-80` |
| `openMessage` (`fax_in.wav`, strike→`UIStaffRise`, else `UIFax`) | `dialogs/message.lua:107-130` |
| `removeMessage` / `dismissMessage` (single-choice only) / `onWorldTick` (timeout→default, rotator) | `dialogs/message.lua:132-163,190-207` |
| `UIAdviser:say` (disabled/dedup/queue/override) | `dialogs/adviser.lua:200-232` |
| `talk` (best-priority pick, balloon sizing) | `dialogs/adviser.lua:121-159` |
| Adviser dedup + history | `dialogs/adviser.lua:186-193,75-99` |
| VIP producer: `createVip` (`personality`, 20d, default 1); result `report` fax; emergency faxes | `hospitals/player_hospital.lua:735-745,758-788,700-731` |
| VIP spawn + scheduling | `world.lua:480-502,1327-1341,1071-1076` |
| Epidemic: `sendInitialFax` (`epidemy`, owner self, 480h, default 2) | `epidemic.lua:330-345` |
| `resolveDeclaration` (fine+rep, nil epidemic) / `startCoverUp` (watch timer) / result `report` fax | `epidemic.lua:371-378,396-407,439-546` |
