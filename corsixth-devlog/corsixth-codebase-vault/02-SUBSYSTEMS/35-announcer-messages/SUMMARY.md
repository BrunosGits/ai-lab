# Announcer + Message/Fax Flow — Summary

> Vault: `35-announcer-messages` · Map: [[35-announcer-messages/MAP]] · Gate: [[35-announcer-messages/CHECKLIST]] · Template: [[35-announcer-messages/SCAFFOLD]]
> Consumers: VIP fax [[30-vip-inspection/MAP]] · Epidemic fax [[11-epidemic-system/MAP]]
> Legend: **[Fact]** = read in source · **[Inference]** = implied by code · **[Hypothesis]** = needs runtime confirm

## 1. Overview

- **[Fact]** Three parallel player-notification channels: `Announcer` (audio PA), `UIAdviser` (talking head), `UIBottomPanel → UIMessage → UIFax` (fax drawer).
- **[Fact]** `GameUI` owns `Announcer` and `Subtitles`; `Announcer:onTick()` is driven from `GameUI:onTick()`.
- **[Fact]** Fax dialogs pause the game (`UIFax:mustPause() → true`).
- **[Inference]** Design intent: audio is ephemeral + gated on staffed desk; fax is durable + choice-bearing; adviser is transient hint text.

## 2. Lifecycle / Flow

### A. Announcement (sound) path

1. **[Fact]** Caller → `GameUI:playAnnouncement(name, priority, ...)` → `Announcer:playAnnouncement(...)`.
2. **[Fact]** Dedup: `AnnouncementQueue:checkForDuplicates(name, date)` refreshes `created_date`, drops new entry.
3. **[Fact]** Gate: push only if `hasReceptionDesk(true)` OR `priority == Critical`.
4. **[Fact]** `Announcer:onTick()`: pops highest priority first; skips decayed entries (`decay_hours == -1` = never); drains queue even when `play_announcements` off.
5. **[Fact]** `_play()`: `resolveFilenameWildcard` → `Audio:playSound(..., is_announcement=true, ...)` → `subtitles:queueSubtitle(name)`; `playing=true` serializes; `_onPlayed()` clears + fires `played_callback`.

### B. Fax (choice) path

1. **[Fact]** Producer → `UIBottomPanel:queueMessage(type, message, owner, timeout, default_choice, callback)` → `canQueueFax()` → `message_queue` + prebuilt `UIMessage` drawer icon.
2. **[Fact]** `_messageDoorTick()` / `_findMessageToShow()`: max 5 shown, one per `type` visible; `_showMessageIcon()` slides icon in + `NewFax.wav`.
3. **[Fact]** Click → `UIMessage:openMessage()`: `strike` opens `UIStaffRise` directly; else creates `UIFax` + `fax_in.wav`.
4. **[Fact]** `UIFax:choice(n)` dispatches string `choice` (`accept_vip`, `declare_epidemic`, ...), then `icon:removeMessage()` + `close()`.
5. **[Fact]** Timeout: `UIMessage:onWorldTick()` → `removeMessage(default_choice)` when `timer` expires.

### C. Adviser path

- **[Fact]** `UIAdviser:say({text, priority}, stay_up, override)` queues unless `adviser_disabled` or duplicate; `talk()` picks highest `priority` in queue; click dismisses one (left) or all (right).

## 3. Key mechanics

- **Priority:** **[Fact]** `Critical=1, High=2, Normal=3, Low=4`; `pop()` scans in order; default `Normal`.
- **Decay:** **[Fact]** `Critical=-1`, `High=31d`, `Normal=7d`, `Low=3d` (in hours); checked as `game_date <= created_date:plusHours(decay)`.
- **Dedup:** **[Fact]** Announcer matches on `entry.name`; Adviser matches on `speech.text`.
- **Desk gate:** **[Fact]** Both enqueue (`playAnnouncement`) and drain (`onTick`) require staffed desk except `Critical`.
- **Pause:** **[Fact]** Paused → only `Critical` drains.
- **Random chatter:** **[Fact]** `rand*.wav` at `Low` every ~4–6 min of ticks (3333 ticks ≈ 1 min).
- **Sounds:** **[Fact]** `NewFax.wav` (icon appears), `fax_in.wav` (fax opened), `Fax_0..8.wav` (keypad), `fax_yes/no.wav` (cheat validate), announcement volume vs `sound_volume`.
- **Fax mutual exclusion:** **[Fact]** `epidemy` ↔ `emergency` cannot co-queue; loser is cancelled (`nextEmergency` / clear epidemic).
- **Cheat backdoor:** **[Fact]** Fax keypad `24328` opens cheats, `112` queues Critical `rand*.wav`.

## 4. Consumers (fax users)

- **VIP (30):** **[Fact]** `PlayerHospital:createVip()` queues `personality` fax with `accept_vip` / `refuse_vip` + `additionalInfo.name`; 20-day timeout, default accept. `UIFax:choice` → `spawnVIP(name)` / `nextVip()`; refuse >2x has 50% force-visit. See [[30-vip-inspection/MAP]].
- **Epidemic (11):** **[Fact]** `Epidemic:sendInitialFax()` queues `epidemy` fax (owner=`self`) with `declare_epidemic` / `cover_up_epidemic`; 480h timeout, default cover-up(2). Choice → `resolveDeclaration()` (fine+rep, no fax) vs `startCoverUp()` (watch timer → inspector → result `report` fax). See [[11-epidemic-system/MAP]].

## 5. Related subsystems

- `Audio:playSound / resolveFilenameWildcard` · `Subtitles:queueSubtitle` · `Hospital:hasReceptionDesk` · `World:spawnVIP/nextVip` · `GameUI:playRandomAnnouncement` · `Date:plusHours`.
