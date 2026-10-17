# Dead Signal — Work Thread: Audio & Immersion (Approved Batch 1)

**Repository:** `stephennip9288-create/Roblox-Projects`
**Assigned branch:** `feature/dead-signal-audio-immersion`
**PR target:** `integration/dead-signal-next-release`
**Status:** Approved to develop; not published or implemented by this handoff.

Read `games/dead-signal/PARALLEL-DEVELOPMENT.md`, `handoffs/BATCH-1-APPROVED.md`, `dev/README.md`, and `V1.9-STAGING-PLAYTEST.md` from current `main`. Before changing anything audit current integration/main and #18–#21. Coordinate the audio interface and shared file access through MAIN DEV; avoid changes to game rules or combat authority.

## Mission — AUD-01
Deliver an integrated, performant sound pass that makes every map and encounter audibly distinct. Emphasize survival-game information, natural spatial behavior and a cohesive artistic mix rather than loudness.

### Work packages
- **World soundscapes (MAP DEV contract):** Blackwater radio static, emergency systems, faint patrol/searchlight mechanics, military compound wind and distant contact; Cinderworks furnaces, machinery, venting pipes, distant metal impacts and industrial reverb; Whiteout storm/wind, structural creaks, ice, relay interference and muted outdoor atmosphere. Distinguish indoor/outdoor and named rooms when possible. Distant world cues should line up with visible landmarks and events.
- **Weapons and player (COMBAT-UI contract):** distinct mechanical dry-fire, equip, pump/bolt, shell, magazine, reload, upgraded/fire class cues and consistent hit/kill confirmation; sound only on correct acknowledged events, never imply the server registered a miss/hit incorrectly. Support near/far weapon reports and material-aware impacts where feasible without extra network abuse.
- **Infected & special-wave information (ENEMY DEV contract):** spatial zombie footfalls/groans, militarized gear rattles, K9 breathing/howls/snarl/charge, window-entry scraping/impact, hound pack/Alpha direction and charged attack, Stalker warning, armor crack, Volatile fuse, wave transitions, Warden escalation and extraction cues. Threat timing must remain fair under heavy overlap and Low Effects.
- **Mixing and listener design:** rolloff with distance, appropriate max/min ranges, crossfades between zones/events, capped concurrent voices, priority/ducking for critical alerts, per-category gain, random variety without chaotic pitch, hearing-friendly peaks and event cleanup. Account for mobile mono/small speakers/headsets as well as desktop; support existing user volume settings, mute and saved control settings. No sensory overload when 40 NPCs are active.
- **Authenticity:** believable location acoustics and occlusion/equalization where Roblox engine permits; never assume walls physically occlude audio automatically. Test on the actual engine; avoid overpromising full reverb simulation.

### Existing architecture and hard constraints
- Central client audio currently lives in `dev/Source/Runtime/client/Effects.lua` via `FX:sound(key,position)`; `shared/Config.lua` has `SoundIds` plus `Evolution.audio` customization, with stock fallback. `Controller.lua` invokes effects and is owned by COMBAT-UI. Map generation, enemy triggers, Game, Config, shared Presentation and network remotes are gated integration-lead territory.
- **Do not add a new required ModuleScript to the place** solely for audio. The current lossless RBXL patching uses a **fixed 61-script target inventory**; adding a script may invalidate the deployment path. Implement within a contracted existing target, or propose an audited upgrade to the builder *via main integrator* before introducing scripts.
- Request exclusive time-limited ownership of the **audio-facing** portion of `client/Effects.lua` from the integration lead. No uncontrolled editing of particle rendering, cross-lane VFX or public method signatures; preserve `FX:sound(key,position)` for callers unless integration approves an extended compatible contract.
- Draft interface proposals first: semantic event keys, world position/zone, priority, intensity, channel/gain, lifecycle token; preferred remote event source and responsibility for transmitting authoritative cues. Map/Enemy/Combat workers author required event trigger locations in their own lanes, after integration approves contracts; do not directly edit their files without agreement.
- Rights/permissions: never insert arbitrary marketplace/copyrighted audio IDs or user secrets. Document usable creator-owned sound IDs if validated, otherwise preserve working stock/fallback and list precisely which bespoke sounds require approved creator upload/rights. Do not claim license, ownership or audible playback from offline checks.
- No publication to staging/production, no gameplay mechanic changes, no profile schema updates, no modifying RBXL/rollback binaries.

### Deliverables
1. Audio event inventory (map, gameplay, zombie, hound, weapons, UI, objectives, boss/extraction) with semantic event names and trigger contracts agreed by integrator.
2. Reviewed source improvements for timing, prioritization, polyphony budget, spatial rolloff, ambience variation and stop/cleanup lifecycle. Optimize against device limitations. Maintain fallback for empty IDs.
3. Isolated Luau/Lune/Python tests and evidence of stable behavior: repeated wave transitions, map travel, respawn/death, 40-NPC wave, location changes, cancellation, multiple sounds, mute, low effects and missing permissions.
4. Pull request to integration containing source, tests, an **asset availability/licensing matrix** (creator-owned / stock / unavailable) and a Studio + real-device listening checklist. Separate offline results from in-engine listening evidence.

### Pass/fail listening checks
A player should be able to infer approximate threat direction and urgency without looking at the screen; distinctive Blackwater/Cinderworks/Whiteout environments should never sound interchangeable; urgent charge/explosive/ambush/Warden/extraction warnings must cut through the mix at full wave density; reload and gun cues must remain faithful to events; mute and reduced settings must work and ambient loops must cleanly end on map changes and leaving sessions.

Report anything needing gameplay trigger code, custom asset upload or engine sound permissions to MAIN DEV as a nonblocking dependency. Do not claim complete bespoke audio if those approvals/assets are unavailable.
