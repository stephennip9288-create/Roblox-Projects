# Proposed audio event inventory and caller contract

**Pending integrator decision in #23.** All names below are implemented by the standalone proposal. Only the legacy names currently have runtime callers; this document is not evidence that new triggers are wired. No remote/schema change is introduced. Existing `FX:sound(key,position)` remains valid and no caller needs a new required argument.

## Interface

| Call | Contract |
| --- | --- |
| `FX:sound(key, position?, options?)` | Position is a finite world Vector3 for a real source, or nil for listener/UI audio. Returns a voice record on admission, otherwise `false, reason`; callers may ignore the result as today. No deferred warning queue. |
| `options.source` | Stable enemy/hazard/weapon source string or number, max 96 characters. Without it, use the 8-stud spatial cell or `local`. Per-event/per-source cooldown prevents spam while keeping distinct directions. |
| `options.token` | Lifecycle string/number, max 96 characters; defaults to current session token. Use an acknowledged reload/equip token for mechanics. Do not put a source Instance into tokens. |
| `options.priority`, `gain` | Optional reduction only. Catalog priority cannot be raised; gain stays 0..1. Categories are fixed by catalog. |
| `options.class`, `weapon`, `upgraded`, `material` | Optional approved asset specialization. `Weapon.Fire` requires a known weapon class. A weapon specialization must exist in C.Weapons. Only configured IDs can play. |
| `options.occluded=true` | Optional explicit routine-spatial approximation: EQ High -7dB, Mid -1dB, gain .8. Critical warnings ignore it. Caller owns any bounded occlusion query; no automatic raycasts/wall blocking or full reverb simulation. |
| `FX:audioState({map,token,active,room,indoors,intensity,anchors})` | Map is Lobby/Station/Foundry/Frost; token is client session/character generation. Supply this at acknowledged state/zone transitions. `active=false` ends map/weapon voices for travel/results/elimination. Downed players keep danger cues. New map/token resets voices and source cooldowns. |
| `state.anchors` | Dictionary keyed by exact `World.*` event name -> real authored Vector3. Distant events require an anchor; no guessed landmark coordinates. Moving anchors update on the next bounded world tick. |
| `state.intensity` | Finite 0..1 presentation value, preferably from existing round/phase state. Changes ambient gain only; no game rules or threat timing change. |
| `FX:audioCancel(token)` | On acknowledged reload cancellation, swap, character replacement or invalidated attack. Removes matching voices/cooldowns synchronously; no scheduled foley survives the token. |
| `FX:audioReset(token)` | Whole local session lifecycle reset. Does not clear the 30s failed-asset backoff. |
| `FX:audioMix({ambience,world,weapons,mechanics,infected,ui})` | Transient 0..1 category gains. Existing saved master volume remains authoritative and applies to playing voices. No new saved field/UI is assumed. |
| `FX:audioDestroy()` | Idempotent owner shutdown; Sound/anchor/Ended connection cleanup. Effects folder destruction invokes it too. |

The current State payload has **no run ID**. Controller should own a local generation token for Deploy/new character/travel/reset; do not assume an unavailable `state.runId`. The existing render/FX animation tick drives cleanup without adding a RunService connection or remote traffic.

## Event ownership and timing

Priority: 0 ambience; 1 incidental; 2 routine feedback; 3 important; 4 imminent danger. Normal/Low Effects budgets are 20/12 total, with 8/6 reserved for priority 4. Within full critical capacity, nearer warnings can replace farther warnings. These are bounded authored policies, not a guarantee every individual NPC gets a separate audible voice.

| Semantic keys | Owner / source | Timing and current status |
| --- | --- | --- |
| `Pistol`, `Rifle`, `SMG`, `Shotgun`, `Heavy`, `Sniper`, `Energy`; optional `Weapon.Fire` + class | Combat/UI, confirmed Shot origin or local listener | Legacy local fire is currently predicted. Remote Shot is server-issued. Proposal preserves this; owner must explicitly decide acknowledged local report wiring to meet the stricter Batch 1 target without duplicating shots. Far asset uses the same event, not another remote. |
| `Reload`, `Weapon.Reload` | Combat/UI, Reload Feed acknowledgment | Existing Reload call is acknowledged. Start token when accepted, not on input press. |
| `Weapon.Magazine`, `Weapon.Bolt`, `Weapon.Pump`, `Weapon.Shell` | Combat/UI, accepted animation phase | New trigger dependency: advance on the accepted weapon action timeline; invalidate with token on swap/cancel/death. Audio layer does not guess gun action timings. |
| `Equip`, `Weapon.Equip`, `Empty`, `Weapon.Empty` | Combat/UI, accepted slot / dry-fire decision | Equip legacy call occurs during viewmodel rebuild; refinement to acknowledged slot/equip is caller-owned. Empty is throttled. |
| `Hit`, `Kill`, `Weapon.Hit`, `Weapon.Kill` | Combat/UI, authoritative Hit Feed | Existing confirmation is server-issued. Never derive a hit/kill from local raycast or sound playback. |
| `Weapon.Impact` | Combat owner, confirmed result/material | New optional trigger; reuse confirmed impact point and bounded event data. Empty slot stays silent. |
| `Player.Footstep` | Combat/UI animation/movement owner | New local grounded material/step hook; do not duplicate Roblox default character footsteps. No new high-frequency remotes. |
| `Zombie.Groan`, `Zombie.Gear`, `Zombie.Footstep` | Enemy owner, nearby living actor/pose | New bounded local animation hooks; stable enemy source ID, range/cadence culling. No per-NPC per-frame sound creation. |
| `Zombie.Entry` | Enemy owner, actual window approach/vault/landing | New entry-phase hook dependency. Source remains at the real entrance and cannot advertise a teleport as an animation. |
| `Zombie.Attack`, legacy `Attack`, `Enemy`, `Redline` | Enemy owner -> existing EnemyAttack Feed | Existing broad attack routing preserved; distinguish incidental attack from imminent telegraph when upgrading callers. |
| `Hound.Breath`, `Hound.Snarl`, `Hound.Alpha` | Enemy owner, K9 pose/pack leader | New source/animation hooks. One Alpha presentation cue, with cooldown; no 40-voice howl loop. |
| `Hound.Charge`, `Stalker.Warning` | Enemy owner, authoritative preparation start | Map existing EnemyTelegraph + position to these semantic keys at start of the full warning window; never delay damage to accommodate loading. Legacy Howl/Stalker still work. |
| `Elite.VolatileFuse` | Enemy owner, HazardWarning start | Use hazard ID as source; actual warning position. Legacy Volatile/Howl still supported. Retain visible warnings at Low Effects and mute. |
| `Elite.ArmorBreak`, legacy `ArmorBreak` | Enemy/combat owner, authoritative plate break | Existing break Feed already provides position. Do not play on predicted plate damage. |
| `Warden.Warning` / legacy `ShockCharge` | Enemy/Game owner, ShockWarning | Existing authoritative shock warning call preserved. New name clarifies semantic priority. |
| `Warden.Phase` | Enemy/Game owner, accepted phase transition | New transition trigger; never repeat on every snapshot. |
| `Howl`, `Redline`, `IronMarch`, `Stalker`, `Volatile` | Game event -> FX:event | Existing named special-wave cues retained. Howl is currently ambiguous between prep, charge, attack and fuse; semantic caller split is required for precise mixes. |
| `Wave.Prepare`, `Wave.Complete`, legacy `Round`, `Victory` | Game/Controller owner, single phase edge | Optional new phase keys; no repeated snapshot fan-out. Warden/exfil scheduling is untouched. |
| `Objective.Signal`, `Objective.Extraction` | Game/Controller owner, accepted objective/Exfil edge | New objective-specific hooks. Extraction warning once per transition, not per participant/tick. |
| `Vent`, `Power`, `Box`, `Perk`, `Revive`, `Down`, `Click`, `Board`, `Grenade` | Existing feeds/FX callers | Preserve current caller responsibility, spatial position where already provided, and damage authority. |
| `Radio.Transmission` | Map/Game owner, authored lore/event | New finite slot, max 10s, no invented voiceover or essential spoken-only instructions. |
| `Ambient`, `Radio`, `Machinery`, `Wind`, `Dispatch` | Existing Controller every 20s | Legacy finite playback retained for configured slots; no silent conversion into persistent loops. Do not route new world state and duplicate old long ambient tracks simultaneously. |

## Map/zone contract

| Map | Persistent bed keys (3 normal / 2 Low Effects) | Bounded activity key and authored anchor |
| --- | --- | --- |
| Dispatch (`Lobby`) | `World.Dispatch.room` | Optional finite Radio.Transmission; no automatic radio dialogue. |
| Blackwater (`Station`) | `World.Station.wind`, `World.Station.radio`, `World.Station.power` | `World.Station.contact`: distant perimeter/antenna activity. |
| Cinderworks (`Foundry`) | `World.Foundry.machinery`, `World.Foundry.furnace`, `World.Foundry.vent` | `World.Foundry.impact`: visible rail/steelworks landmark. |
| Whiteout (`Frost`) | `World.Frost.wind`, `World.Frost.relay`, `World.Frost.structure` | `World.Frost.ice`: frozen ridge/outer structure. |

MAP DEV supplies room identity, indoors/outdoors and optional named anchors from actual authored geometry. Keep zone lookup bounded; do not scan every map descendant on each audio frame. `room` is stored for diagnostics/contracts; this proposal does not invent different impulse responses for each named room. The first exterior bed fades to 28% indoors; interior beds use 65% outdoors, with bounded intensity gain. Activity interval is deterministic 18–28 seconds and requires a configured asset plus an authored landmark within rolloff range. No distant activity is mapped to a random location.

Loop and zone fades do not duck critical warnings. Native mixing, mono direction/readability and authored room transitions still need the listening checklist.
