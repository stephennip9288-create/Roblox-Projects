# Dead Signal — Approved Batch 1: World, Infected, Weapons & Audio

**Owner approval:** 2026-10-16 in the Dead Signal ideas/planning conversation. This batch is **approved for development, NOT implemented, tested, merged, or authorized for staging/production**. Distinct from the previously closed planning batch and from existing v1.9 enemy evolution candidates.

**Scope:** 31 tracked items (12 maps, 9 enemies, 9 weapons/UI, 1 audio). New work must be implemented in the existing 4-place Dead Signal experience, not by replacing the whole game or creating new maps. Owner approved all associated specialist recommendations and background-world extensions as well as the explicit ID requirements below. **Maintain the 3 existing map identities, Dispatch, navigation, Warden, extraction, revive, persistence, and mobile performance.**

## Snapshot of already-in-flight work; avoid duplicate PRs
At planning review (2026-10-16), these independently authored PRs were OPEN targeting `integration/dead-signal-next-release`:
- **#21 Maps:** "Remaster Dead Signal's three maps and wall interactions" on `feature/dead-signal-map-remaster` (head `6311ea3063bc789eea9cb0bc8876ef1f43f9b800`).
- **#19 Enemies:** "Fix enemy retargeting, hound flanks and stalled-route recovery" on `feature/dead-signal-enemy-systems` (head `7d5f23f48eb61fb57a0f785378b22010594237c9`).
- **#20 Combat/UI:** "Polish weapon ADS, combat input and compact HUD" on `feature/dead-signal-combat-ui` (head `533614972cd0c17212203d3099202f534a75aed8`).
- **#18 Loading artwork preview:** separate testing PR on `test/dead-signal-loading-art-preview`; do not disturb accepted artwork.
Check current PR states and heads before work; these are a *snapshot*, not stable references or evidence of live implementation. **Do not force-push, overwrite, or quietly expand those PRs with the new batch.** New work should use fresh follow-up branches, coordinated by the integration lead. Work staged on top of an unmerged parent PR is dependent upon that parent; prevent duplicate diffs when opening follow-up PRs.

## MAP — owner-approved map and environment requirements (MAP DEV)

| ID | Requirement / verification target |
| --- | --- |
| MAP-01 | Rebuild all three current maps with genuinely independent architectural layout, combat rhythm, atmosphere and visual silhouette; not reskins of one grid. |
| MAP-02 | Every area reflects the map's lore and believable purpose; preserve Blackwater military communications, Cinderworks industrial steelworks and Whiteout polar listening/research themes. |
| MAP-03 | Dense, believable environmental detail and readable prop placement; avoid empty rooms and clutter that obstructs gameplay. |
| MAP-04 | Varied purchasable/unlockable passages: rubble, debris, collapsed material, security bulkheads, ice, machinery or thematic barricades; clear price/interact cue and collision state. |
| MAP-05 | Non-grid layouts with irregular footprints, diagonals, angled/curved connectors, interlocking but non-rectangular traversal loops; fair navigation and orientation. |
| MAP-06 | Purposeful elevation: balconies, galleries, service tunnels, stairs, ramps, catwalks and multi-floor rooms, all traversable by eligible NPCs. |
| MAP-07 | Detail inaccessible exterior/beyond-boundary world to match theme; distant structures, silhouettes, terrain, activity, landmarks and believable sightlines. |
| MAP-08 | Environmental storytelling through believable traces of the outbreak: barricades, damaged equipment, warnings, equipment and personal traces; lore readable without long mandatory text. |
| MAP-09 | Elevation affects player decisions and alternate routes without creating unreachable invulnerable positions. |
| MAP-10 | Bounded, theme-specific ambient environmental events—power fluctuation, lighting changes, distant machinery, weather and safe structural effects—without random soft locks or deaths. |
| MAP-11 | Distinct, realistic thematic barrier vocabulary per map with intuitive player affordances, alternate visuals and legible unlock messaging. |
| MAP-12 | Professional, readable lighting and atmospheric design: real light sources, contrast, shadows and optimized fog/haze; visual threats and objectives remain distinguishable. |

**Map identity prompts (creative direction, not fixed exact blockout):** Blackwater: ruined military communications complex, antenna fields, checkpoints, watchtowers, damaged vehicles, pine/forested perimeter. Cinderworks: enormous steelworks with smelters, rail yards, machinery, pipework, industrial skyline, catwalks and smoke. Whiteout: polar relay/research outpost with ice tunnels, snowbanks, remote structures, frozen vehicles, mountains and storm visibility. Each map's inaccessible world is a layered extension (detailed foreground, simpler far geometry and atmospheric distance), not a playable expansion.

**Included earlier owner-approved placement polish:** Real wall-mounted weapon displays, accessible perks/buys/objectives, eye-level unlock signs, no overlapping prompts/clipping, clear revive/extraction paths, no safe spots or blocked enemy routes, first-person and mobile readability. Every room/landmark should have an authentic function, not random placement. Distant landmarks should work from windows and elevated vantage points.

## EN — owner-approved enemy and AI requirements (ENEMY DEV)

| ID | Requirement / verification target |
| --- | --- |
| EN-01 | Significantly improve zombie anatomy, infected skin/clothing and believable silhouettes without disrupting authoritative damage/hitboxes. |
| EN-02 | Military-themed zombies with believable uniform/tactical variation, damage, equipment and outbreak history. |
| EN-03 | Rework hounds into intimidating, anatomically recognizable infected animals with believable locomotion and convincing damage/animation. |
| EN-04 | Animate legitimate exterior-to-interior window entry (approach, grab/vault/crawl, landing, pursuit) rather than teleport/pop-in, synced with collision and AI. |
| EN-05 | Different infected military archetypes: infantry, security, special operations, officers, hazmat/heavy armor; match their source location and avoid repetitious clone appearance. |
| EN-06 | Infected military working dogs/K9s with canine anatomy, credible run/leap and injuries; elites can be exaggerated while visually distinct. |
| EN-07 | Traverse actual geometry through vaults, low obstacles, doors, ledges and recoveries with bounded, AI-aware movement and no stuck loops. |
| EN-08 | Directional hit/stagger/death reactions and optional equipment degradation, without changing server combat correctness or enabling stun-lock exploitation. |
| EN-09 | Believable enemy entrances (windows, outer approaches, vents, damaged doors, tunnels) with advance cues and no unfair instantaneous spawn near players. |

**Preserve existing candidate evolution systems:** The Hunt/Redline/Iron March/Containment Breach/Critical Mass, breakable armor, elite variants, pack tactics, Stalker, Volatile, rewards, hazards, Warden/extraction precedence. Audit what already exists; evolve it rather than duplicating. Preserve telegraphs in low-effects mode and color-independent differences.

## WPN — owner-approved weapon, handling and UI requirements (COMBAT-UI DEV)

| ID | Requirement / verification target |
| --- | --- |
| WPN-01 | Substantially improve realism, geometry quality, proportions and fit of every weapon/viewmodel; retain original gameplay identity. |
| WPN-02 | Better components: receivers, optics, iron sights, magazine wells, stocks, barrels, grips, detailed surface/attachments. |
| WPN-03 | Smooth, believable weapon-specific firing, reload, recoil, handling and switching, without hiding threats or desynchronizing authoritative state. |
| WPN-04 | Unobstructed and mechanically sensible ADS, precise aim alignment at multiple field-of-view, aspect and mobile configurations. |
| WPN-05 | High-fidelity, physically plausible components by weapon class and clear silhouettes. |
| WPN-06 | Centered true sight picture across reflex, iron and magnified sights; align optic/reticle with actual aiming; no gun obstructing sightline. |
| WPN-07 | Weapon-specific action details: magazine changes, bolt slides, charging, shell loading, handling with correct timing and cancellation state. |
| WPN-08 | High-quality but bounded muzzle flash/smoke, shell ejection, mechanical animation, recoil feedback and hits; low-effects equivalent. |
| WPN-09 | Material/detail variations for steel, polymer, rubber, leather, wood and worn finishes, including distinctive upgrades beyond pure color changes. |

**Included earlier owner-approved UI polish:** Legible, uncluttered HUD, first-person interactions, revive markers and warnings, compact responsive layout, no mobile fire/aim control obstruction; preserve current saved custom controls and previously closed mobile decisions unless an actual defect is demonstrated and approved. Audio synchronization is handled via the Audio lane's API.

## AUD — owner-approved complete audio and immersion pass (AUDIO DEV)

**AUD-01:** Purpose-built coherent soundscape spanning: per-map ambience and distant world activity; realistic weapon reports/reload/metal mechanics; readable, directional approaching zombie and hound cues; radio interference, military/lore transmissions; environmental materials/footsteps, rooms/corridors and indoor-outdoor transitions; distinctive special-wave, elite and objective warnings; layered intensity escalation and priority/volume management. Include distance-based rolloff, meaningful stereo/spatial placement, settings and low-end/mobile optimization, accessibility and nonintrusive mixes. **Never depend on unavailable third-party audio or claim an uploaded audio ID works until Studio confirms ownership/permission**. Use safe placeholders with transparent documentation when needed. Audio must never mask imminent danger cues or spam sounds for each enemy in crowded waves.

## Shared acceptance rules (all lanes)

1. Feature branch -> PR -> integration lead, **not direct main**; no publication from Work feature branches.
2. Explicitly inventory existing implementations and #18–#21 before coding; classify each row as **already present, modified, genuinely new, or blocked** with evidence. No duplicate feature rewrite.
3. Preserve four-place native RBXL assets, the 61-script lossless patcher contract, place ID isolation, production save schema, protected backups, loading art and production workflows. New runtime script records/non-source assets require a separately approved, fidelity-audited build path.
4. Add scripted regression tests for route reachability, deterministic spawn and animations, sight lines, audio cleanup, UI scaling, performance caps and lifecycle resets as applicable. Document test method and known blind spots.
5. Test the *integrated* game in Roblox Studio and in an explicitly authorized private staging experience with solo/2-/4-player sessions across three maps; mobile/desktop, low-effects, high-round load, revive, extraction, Warden and teleport functionality.
6. Any deployment—**including private staging**—requires separate explicit owner authorization; production requires its own subsequent authorization. Approval of this creative batch is **not** deployment approval.
7. Avoid counterfeit/unauthorized imported weapon, music or proprietary audiovisual assets. Favor original authored designs and rights-cleared/creator-owned assets.

**This is the development scope of Batch 1.** Do not mark it complete merely because the handoffs were published.
