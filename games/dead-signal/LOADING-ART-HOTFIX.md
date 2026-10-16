# Dead Signal v1.8.1 — original loading artwork

The loading image stayed hidden until its own `IsLoaded` flag became true. A
hidden texture can remain unready after preloading, so the original artwork
could remain invisible even when the asset ID was correct and fetch succeeded.

The hotfix makes the transparent image label visible whenever its configured
ID is valid. The static, opaque map scene remains underneath it while it loads
or if the download fails. Preloading cannot change image visibility after a map
switch. Existing full-viewport layout, arrival checks and minimum display time
are retained.

This branch extends the published v1.8 commit
`62a5de44471d3fe41137b5cb9adb07ace4f7d026`. Its only runtime changes are
`LoadingScreen.lua` and the patch version `1.8.1` in Config. Original artwork
IDs, gameplay, profile namespaces, manifests and native/backup binaries remain
unchanged. The same image fix and regression suite are carried forward for v1.9.

| Screen | Original image ID |
| --- | --- |
| Dispatch / Blackwater | 125594819014430 |
| Cinderworks | 133781122932272 |
| Whiteout | 83098782431426 |

## Evidence and verification

The owner's Studio client report from production Dispatch, universe
`10770732078`, showed all three IDs were Image assets and every probe returned
fetch `Success` and `IsLoaded=true`. The configured IDs matched; the game's own
hidden MapArtwork remained `IsLoaded=false`. This establishes Studio access,
not published-server permissions.

The new behavioral suite executes the actual loading module with textures held
unready, checks every map, invalid IDs, fetch errors, repeat travel and stale
preloads. It fails against the old module and passes after the fix. Local
verification passed 8,507 runtime assertions, all 61 runtime compilations and
54 Python repository checks. Offline checks do not establish engine rendering.

## Native acceptance and release

Use a fresh Studio Play session with the candidate. Confirm original artwork
appears on Dispatch and all three map transitions, repeat travel works, text is
readable, the background stays opaque/still, and arrival removes the full layer.
An intentionally invalid artwork ID in a disposable Play session must retain
the fallback without delaying gameplay. Discard temporary Config edits.

Do not publish until the owner has approved the exact hotfix SHA. The existing
manual production workflow on main can select that immutable SHA through its
optional source pin, keeping unaccepted v1.9 gameplay out of production. Retain
the known-good v1.8 release artifacts and review the existing rollback manifest;
checked-in rollback files remain historical and unchanged.
