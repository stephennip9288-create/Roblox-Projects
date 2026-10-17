# Audio asset availability and rights matrix

No audio was generated, imported, uploaded or purchased. No Roblox audio ownership, license entitlement or native playback permission was independently verified. Current Config has empty custom SoundIds and Evolution.audio slots. Numeric IDs used in offline tests are **arbitrary mocked fixtures**, never recommended asset IDs.

| Asset / family | Availability | Rights / permission status | Proposal behavior and required action |
| --- | --- | --- | --- |
| `rbxasset://sounds/unsheath.wav` | Existing bundled fallback | Retained from audited game source; no new license assertion. Native playback pending. | UI/equip/reload/empty/power/box; treated Iron March/Volatile/shock placeholders. Replace mechanics with approved original recordings for realism. |
| `rbxasset://sounds/impact_water.mp3` | Existing bundled fallback | Same stock status; native playback pending. | Hit/board/grenade/armor/vent placeholders. Not claimed to be realistic metal, explosives or gun impacts. |
| `rbxasset://sounds/uuhhh.mp3` | Existing bundled fallback | Same stock status; native playback pending. | Enemy/down/kill/howl/Stalker treatments; **not a bespoke canine recording**. |
| `rbxasset://sounds/action_get_up.mp3` | Existing bundled fallback | Same stock status; native playback pending. | Round/revive/perk/victory/Redline placeholders. |
| `rbxasset://sounds/swordslash.wav` | Existing bundled fallback | Same stock status; native playback pending. | Pistol/rifle/SMG placeholder reports, fixed class treatment and 0.1s trim. Not firearm-quality audio. |
| `rbxasset://sounds/swordlunge.wav` | Existing bundled fallback | Same stock status; native playback pending. | Shotgun/heavy/sniper/energy placeholder reports; Heavy trimmed to 0.1s. |
| `World.Dispatch.room` | Unavailable | Creator-owned / rights-cleared asset and experience permission required. | Silent until configured. Quiet military operations-room bed. |
| `World.Station.wind`, `.radio`, `.power`, `.contact` | Unavailable | Same approval/upload/permission dependency. | Silent slots: compound weather, radio/electrical bed, emergency systems, distant contact at authored landmark. |
| `World.Foundry.machinery`, `.furnace`, `.vent`, `.impact` | Unavailable | Same dependency. | Silent slots: steelworks machinery, smelter roar, pipe/steam, distant metal. |
| `World.Frost.wind`, `.relay`, `.structure`, `.ice` | Unavailable | Same dependency. | Silent slots: storm, interference, structural creaks, distant ice. |
| `Ambient`, `Radio`, `Machinery`, `Wind`, `Dispatch`, `Radio.Transmission` | Empty existing / new alias slots | No supplied usable recording or voice license. | Finite configured playback only. Radio voiceover/lore remains unrecorded; no generated dialogue/assets are claimed. |
| Weapon class report IDs plus `.Far`, `.Upgraded`, `.<weapon ID>` | Unavailable custom recordings | Original or rights-cleared recordings; creator experience access to every ID. | Bundled class fallback; custom reports play at authored pitch. Far layer selects one asset from the same shot, not a second voice/network event. |
| `Weapon.Equip`, `.Reload`, `.Magazine`, `.Bolt`, `.Pump`, `.Shell`, `.Empty` and optional `.<class>` / `.<weapon ID>` | Unavailable custom recordings | Same dependency. | Existing stock treatment where possible; distinct realistic mechanical foley remains pending. |
| `Weapon.Impact.<material>`, `Player.Footstep.<material>`, `Zombie.Footstep.<material>` | Unavailable | Material recording rights plus permission and owner-authored material/timing hooks. | Silent, so empty slots do not duplicate default character footsteps or invent material cues. |
| `Zombie.Groan`, `.Attack`, `.Entry`, `Elite.ArmorBreak` | Unavailable custom recordings | Same dependency. | Legacy stock fallback; new timing hooks still caller-owned. |
| `Zombie.Gear`, `Hound.Breath` | Unavailable | Original military kit and animal recordings required. | Silent; does not misrepresent a human grunt as breathing/gear. |
| `Hound.Snarl`, `.Charge`, `.Alpha`, `Stalker.Warning`, `Elite.VolatileFuse` | Unavailable bespoke recordings | Rights-cleared animal/design assets; native permission and threat listening checks. | Existing treated stock warning fallback, with reserved priority. No copyrighted Black Ops/Halo recordings. |
| `Warden.Warning`, `.Phase`, `Wave.Prepare`, `.Complete`, `Objective.Signal`, `.Extraction` | Unavailable bespoke design | Original warning motifs and creator permission required. | Retained stock treatments available; final distinctiveness/listening acceptance pending. |
| Any creator-owned validated audio | **None provided/validated** | No ID can currently be classified as creator-owned and audibly verified by this work. | Integrator records exact ID, creator, source license/release, experience sharing, test SHA/device/result before acceptance. |

## Config entry conventions (proposal, pending integration)

Use the existing `C.SoundIds[key]` and `C.Evolution.audio[key]` dictionaries; no required Config edit or profile field is introduced by this branch. A value may be a positive numeric asset ID, numeric string, `rbxassetid://<digits>`, or a small array of those variants. Empty/zero/malformed values use the existing bundled treatment when available. World beds/footsteps/gear with no honest bundled equivalent remain silent.

For a semantic key, resolution prefers an exact Evolution entry, optional upgrade/weapon/material/class specialization, exact SoundIds entry, then its legacy alias's Evolution/SoundIds entry. Specific material/class recordings precede generic ones. Reports may select `<class>.Far` beyond 70 studs. Arrays cycle deterministically without uncontrolled pitch variation. Bundled treatments keep authored class pitches; custom recordings use native playback speed.

An unloaded custom cue with a stock equivalent immediately uses the bundled treatment instead of waiting past its threat/acknowledgment timing. Missing/denied loop assets retire after five seconds without blocking and receive a 30-second retry backoff. This policy tests failure handling; **it does not prove that an ID has permission or will load in Roblox**. Do not infer denial solely from this timeout on a slow connection.

Before submitting assets, provide clean loop boundaries for beds, no dialogue/critical information embedded into optional ambience, restrained peaks, appropriate mono compatibility and documented permitted use. Verify in the four-place experience, including a published private client only after the owner authorizes staging publication. Asset upload itself is a separate approval; none is attempted here.
