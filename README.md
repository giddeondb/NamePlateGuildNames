# NameplateGuildNames

Prototype 0.2.0 for WoW Forever interface 16001, developed against reported client 1.60.1 build 70938.

Adds guild labels under accessible player health bars: lavender for friendly players, muted red for non-friendly players. Enable the corresponding friendly/enemy nameplates in the game settings. No target or mouseover is required by the addon. Friendly labels have been verified in game; enemy labels still need live verification.

## Load and edit

This folder is the live addon source. Try `/reload` after installation. If the new addon is not discovered, restart the client once and enable NameplateGuildNames in the AddOns list. Subsequent Lua edits use `/reload`.

- `/ngn status`: concise client, plate, label, and error summary.
- `/ngn refresh`: retry currently accessible plates and show status.
- `/ngn on` or `/ngn off`: enable or hide guild labels.
- `/ngn size 12`: font size from 8 to 24.
- `/ngn offset -4`: vertical offset from -60 to 60; negative moves down.

Settings persist in NameplateGuildNamesDB. The addon does not change game CVars or other addons.

## Limitations and verification

Forbidden nameplates are skipped. Dungeon/raid support and guild queries for untargeted nameplate units need live testing. An absent guild value can mean either no guild or data not available. The addon tries for approximately 3.5 seconds, then waits for a relevant event or manual refresh. Fully inaccessible plates may not appear in the tracked count.

Test with a nearby guilded friendly player without targeting them, then target and untarget them. Check guildless players, enemy players, NPCs, pets, range changes, combat, reload, and dungeon transitions. Friendly-to-hostile changes should recolor the label. Check long names and cast bars for overlap. Other nameplate replacements are outside the initial scope.

Expected: accurate guild labels, no label on NPCs/pets/guildless players, no stale guild after a plate is reused, and no errors. `/ngn status` reports caught API errors rather than repeating them in chat.
