Hekili - Warmane Protection Paladin alpha 1
Target: original World of Warcraft 3.3.5a client, build 12340.

INSTALL
1. Close WoW.
2. Extract the Hekili folder into your WoW/Interface/AddOns folder.
3. The resulting file must be Interface/AddOns/Hekili/Hekili.toc.
   Avoid an extra nested Hekili folder. Back up an existing Hekili folder first.
4. Start WoW and enable Hekili on the character-selection AddOns screen.
5. Log into a level-80 Protection Paladin. Select a hostile target.

CONTROLS
/hekili          Main Hekili options.
/hekili unlock   Move the displays.
/hekili lock     Finish moving the displays.
/hek335          Local diagnostic window. Copy the text when reporting issues.

This is an independent experimental backport of Hekili's actual Wrath engine,
not an official Hekili release. It recommends spells; it does not cast them.
Protection Paladin is the supported scope of this first alpha. The Protection 96
priority is selected by default. DPS, cooldown, and optional defensive displays
retain the upstream configuration system. Only actions present in the upstream
priority lists are recommended; this is not a complete encounter-mechanics adviser.

WHAT CHANGED
- Interface version and spell/aura/cast return formats adapted to 3.3.5a.
- Legacy combat-log and spellcast event payloads translated for the existing engine.
- Passive talent ranks and learned spell ranks mapped from the original client.
- Missing timers and item-cache helpers replaced with original-client equivalents.
- Modern UI templates, texture IDs and glow APIs adapted to older frames/textures.
- Native hex GUIDs supported for NPC identification.
- Protection defaults use combat-log target counting; automatic nameplate unit
  detection is unavailable on this client. Enemy counts can lag a pull until damage
  events are seen. Select Single Target / AOE manually if needed.
- Corrected the Divine Plea buff-name typo in the upstream Protection priority.
- Replaced the Wrath Classic Seal of Corruption ID with the original spell ID.
- Corrected the Paladin training-dummy time-to-die expression.
- Status/debug print calls captured in /hek335 instead of the chat window.
- Blessing maintenance disabled by default; no reagent-dependent Greater Blessing
  upkeep is added. Aura and core tank-buff maintenance remain configurable.
- Modern custom quick-menu range sliders are omitted; use the main options window.

VALIDATION AND LIMITS
All bundled Lua files parse in Lua 5.1. Tests exercise legacy spell/aura/cast
conversion, passive talent ranks, combat-log payloads, GUIDs and timer cancellation.
The TOC/XML load order, initialization, specialization setup, display construction,
enable lifecycle, Protection action-list restoration, a three-action precombat
prediction queue and a combat engine update pass under mocked original-client APIs.

These checks do not establish that the addon works in an actual Warmane client.
This alpha has NOT been tested in-game. Actual frame rendering, tooltip item-cache
loading, spell-rank detection, combat-log behaviour and recommendation quality
still need live validation. No maximum-DPS or perfect-rotation claim is made.

FIRST IN-GAME CHECK
Confirm the display appears and changes when you manually cast the suggested spell.
Check Holy Shield, Shield of Righteousness, Hammer of the Righteous, Judgement,
Consecration and Divine Plea during a short combat test. If it fails to load or
stops updating, copy the first Lua error (BugSack/BugGrabber if already installed)
and the /hek335 report. Enable the normal Lua error display through client settings
if needed. Avoid repeatedly clearing errors before copying the first one.

SOURCE
Core/class source: https://github.com/Hekili/hekili, wrath branch
Commit: 2ef2a444da11167f55b9f2011e49e5bb59925aab
Bundled library baseline: Hekili-v3.4.3-1.0.3-wrath release.
Original Hekili contributors retain credit. The GPLv3 license is included;
embedded libraries retain their individual copyright and license notices.
The archive contains complete editable Lua source.
