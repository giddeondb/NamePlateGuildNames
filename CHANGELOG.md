# Changelog

## 0.2.1

- Move guild labels below visible cast bars and spell text, returning below the health bar when casting ends.
- Handle cast-frame reuse without leaving stale callbacks attached to another player's label.
- Add screenshots, installation instructions, and installable GitHub release packaging.

## 0.2.0

- Add muted red guild labels for non-friendly players; friendly guilds remain lavender.
- Rename the addon to NamePlateGuildNames.
- Include lifecycle regression tests in the repository.

## 0.1.0

- Add guild labels to accessible friendly player nameplates.
- Add font size, vertical offset, enable/disable, refresh, and diagnostic commands.
- Retry delayed guild information and clear labels when plates are reused.
