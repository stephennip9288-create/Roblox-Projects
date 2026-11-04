# DS-B1-006: authored-art dependency

**The full visual overhaul is incomplete.** This PR improves posture, timed attacks, entry poses and worn equipment while retaining the existing character meshes. It does not supply a new undead face, skin texture, body sculpt or damaged uniform atlas. Generated straps and geometric equipment are not accepted substitutes for those deliverables.

## Audited retained assets

The immutable Lobby baseline contains `ReplicatedStorage.DeadSignalArt`, art revision 6. Its six `Infected_1`–`Infected_6` families contain 26/26/28/32/28/32 MeshParts; `Warden` 34, `Crawler` 20 and `Hound` 8. The generated articulated model reports anatomy revision 8. [Rig-Reference.json](Rig-Reference.json) records the exact existing MeshContent/TextureContent URIs, source sizes and ArtBone tags. These identifiers are existing references, not uploaded or permission-verified assets. Reading mesh bounds does not inspect their native surfaces.

`server/RigAnatomy.lua` currently fits the retained six-bone art templates via `ArtBone` and `ArtBind`, then rebinds segmented limb shells to the articulated skeleton. That shared, read-only adapter and protected native asset containers are unchanged by this PR. An arbitrarily imported skinned character is not a proven drop-in replacement.

## Creator / Studio deliverables

| Deliverable | Required review criteria |
|---|---|
| Undead anatomy and heads | Several recognizable body builds; irregular posture; credible skull, jaw, eyelids, teeth and asymmetrical facial damage. Skin must read as infected rather than smooth mannequin plastic at gameplay distance. Keep damage restrained and platform-appropriate. |
| Skin and cloth atlases | Creator-owned or rights-cleared albedo and approved material detail; mottling, limited infection lesions, grime and worn cloth seams. No clean-soldier-only recolors. Include UVs and source working files. |
| Blackwater personnel | Damaged communications headsets, radio harnesses and fatigues; exposed faces and varied reanimated silhouettes. |
| Cinderworks personnel | Industrial/security responder clothing, worn protective equipment and heat/soot damage with readable exposed infection. |
| Whiteout personnel | Cold-weather military/science layers, damaged collars and insulated clothing; faces and infection remain readable beneath winter equipment. |
| Archetypes and elites | Retain small/fast Runner, low Crawler, large Warden, hooded Stalker, canine Hound/Alpha; armor break, exposed weak points, reactor and elite silhouette markers must remain clear. |
| Motion polish | In actual Studio gameplay, review idle/shamble/run, hit direction and flinch, attack windup/contact/recovery, bracing/climbing/reversing/landing and captured death/ragdoll. Author additional curves or AnimationTracks if the procedural candidate fails that review. |

For a rigid-part replacement, author around the existing root-local rest pose and **14 humanoid deform/hit-zone bones**: Torso, Head and left/right Arm, Forearm, Hand, Leg, Shin, Foot. Preserve HumanoidRootPart and connected Motor6D pivots; feet lie at the declared NavigationRootHeight. Cosmetic meshes remain massless, noncolliding and nonquerying; hit zones, live collider, armor and weak-point Parts stay server-owned. Canines additionally retain jaw, ears and tail joints. A skinned mesh or a different bind convention requires a MAIN-reviewed RigAnatomy adapter and the corresponding preservation-aware native asset patch before intake.

Proposed starting budgets, **not approved limits or measured native costs**: 6k–8k triangles per ordinary LOD0 humanoid; 14–24 cosmetic mesh pieces and one or two shared 1024px atlases per family. MAIN/creator must measure the actual retained plus replacement art, batching, memory and frame time with 40 enemies on the target mobile tier before choosing final budgets. Keep separate distant detail reduction; avoid per-enemy expensive lighting or particle stacks.

The asset handoff must include source files, license/ownership provenance, exact approved Roblox IDs, moderation status and use permission in the relevant experience. MAIN must record the approved asset/container patch path, before/after binary preservation audit and rollback. No asset upload, ID invention, native replacement or publication is included here.

## Acceptance remains open

The SVG comparisons in this directory show only part bounds and joints. They cannot validate facial quality, infection materials, native mesh deformation or animation replication. DS-B1-006 remains **In Progress / not Verified** until creator-authored quality changes are integrated and the owner reviews real gameplay captures from all three maps. This source PR alone does not close it.
