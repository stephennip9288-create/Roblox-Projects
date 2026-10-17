# Inspect the original loading artwork in Studio

The owner reports that the normal Dispatch loading screen now shows the original
artwork after the visibility fix in PRs #15/#16. Retain that runtime fix and its
existing arrival timing. The owner subsequently confirmed all four originals in
Studio and reported "Artwork working in production" after the v1.9 release from
`1a5b9f3`. This is owner-reported evidence for that released build. Recheck travel,
loading exit and image access on each newly integrated staging candidate.

Dispatch's Studio bay preview starts a local operation through
`LobbyService:preview`; it does not call `Travel:begin` or emit a `Travel` event.
That is why starting a local round does not test the teleport loading screen.
Roblox TeleportService itself cannot be playtested in Studio.

## Preview the same screen used by the game

1. With the existing visibility fix installed, press **Play** in Dispatch and
   stay in the lobby. Switch the **Command Bar to Client**.
2. Paste the entire `preview-loading-art-studio.lua` file into the Command Bar
   and run it.
3. Select **BLACKWATER**, **CINDERWORKS**, and **WHITEOUT**. Each screen stays open
   for inspection; the artwork, shade, text, sizing and fallback come from the
   actual `ReplicatedStorage.DeadSignal.LoadingScreen` module.
4. Confirm each original picture appears, fills the screen, stays still and
   leaves the text readable. Output reports the actual image ID, image load and
   visibility flags, and viewport after one and five seconds. If a picture does
   not appear, retain those lines and nearby Roblox asset errors.
5. Select **CLOSE**, stop Play, or let the two-minute cleanup timer expire.

The tool creates only its temporary local GUI. It does not modify source,
configuration, saves, assets or publication. It does not pause a running round;
inspect from Dispatch before deploying. Re-running it replaces only its previous
preview. The game retains its normal loading flow and current one-second minimum.

| Screen | Original image ID |
| --- | --- |
| Dispatch / Blackwater | 125594819014430 |
| Cinderworks | 133781122932272 |
| Whiteout | 83098782431426 |

## Evidence and release boundary

The executable `Tests/loadingpreview.luau` suite runs the actual preview script,
LoadingScreen constructor, and map-selection method with UI/service doubles.
It covers all four configured originals, context guards, diagnostics, map changes,
unready images, repeated invocation, close and timeout. These checks establish
control flow and authored UI properties, not engine rendering or visual quality.

No runtime source, public/staging places, native binaries, profile namespace,
mobile controls, workflows or live configuration change in this PR. This preview
works with both the v1.8.1 maintenance candidate and the v1.9 candidate; it is not
a new game release. The feature branch starts from integration/main revision
`1a5b9f3b811137b6881090ad634a13624d33dd71` and targets the integration branch.

After Studio inspection, use the real Roblox client to verify cross-place
loading, repeated travel, full-layer removal on arrival, and live asset access.
The original-art hotfix was retained in the separately authorized v1.9 production
release (run `38985770842`, attempt 4). This preview and later integration work do
not authorize another release. Gameplay acceptance and future staging/production
publication remain separate gates.
