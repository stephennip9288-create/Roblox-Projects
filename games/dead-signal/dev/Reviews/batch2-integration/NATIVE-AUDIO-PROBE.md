# Owner-controlled Batch 2 native audio probe

The owner completed this probe and supplied the full export captured **2026-11-09T02:11:56Z**, then stated **"I confirm all intended clips."** All sixteen exact IDs have successful ContentProvider callbacks, loaded finite expected durations and playback progress. See `NATIVE-AUDIO-OWNER-REPORT.json` (unaltered supplied JSON) and `NATIVE-AUDIO-REVIEW.json` (MAIN's evidence review). No rerun is requested.

The exported `placeVersion=0` is preserved. Roblox documents PlaceVersion as **Not Replicated** server metadata; this client-only probe cannot attest the installed server version or game source. The validator's former positive-version prerequisite was a bug, corrected with zero/invalid-version regression coverage. Studio/client, exact staging universe/place, all sixteen IDs/callbacks, durations, progress and confirmation remain required. Release source/build checks are separate and unchanged.

Roblox's owner-authenticated official asset-status query explicitly returns **ReviewApproved for all sixteen exact Audio IDs**, correct owner 6206795757, not archived. No new key or permission changes were required. Existing source rights/creator review, owner quality listening approval and all 32 experience grants remain accepted.

The temporary probe checks native loading/playback and intended clip identity. It does not publish a place, install scripts into the saved game, change Config, call DataStores, send HTTP, or approve gameplay/production. MAIN accepted the returned per-asset evidence for the prepared staging-only activation; full gameplay/audio/device/multiplayer QA remains pending.

## Original run procedure (retained reference)

1. In Roblox Studio, open **private-staging Dispatch** from Roblox: universe `10771141095`, place `117710269155815`. Use the existing staging experience; an unsaved local file or production place is rejected.
2. Open **View → Output** and the **Command Bar**, press **Play**, and select the **Client** command-bar context. The probe rejects Edit mode, a server command bar, production and every unknown place before making any objects or asset requests.
3. Open `games/dead-signal/dev/Tools/probe-batch2-audio-studio.lua`, copy the entire file and paste it into the Client Command Bar. Execute it. A temporary local panel appears; no asset is requested until you click **CHECK ALL 16**.
4. Use headphones at a comfortable volume. Click **CHECK ALL 16**. It creates one quiet preload Sound at a time, records the actual `AssetFetchStatus`, `IsLoaded`, duration and subsequent playback progress, then plays up to 2.5 seconds per clip at volume 0.35. Each preload has a 20-second bound. Normal completion takes roughly 45 seconds; connection failures are recorded instead of being called passes.
5. Check that you heard the intended clips. **Steam (`101059835221623`) specifically still needs intended-source identity confirmation**: compare it with your original `cinderworks_steam_release_1.wav` from the existing private ZIP. Its current hosted bytes are unchanged and show strong correspondence, but neither fixed quantitative threshold passed. Clothing drag passed the new supplemental comparison. Existing quality listening approval is retained; no new upload or general quality reapproval is requested.
6. After all sixteen load/playback checks pass and you recognize the intended clips, click **CONFIRM INTENDED CLIPS**. This exports the latest report automatically. If a clip is uncertain, use **NEXT CLIP** and **CHECK / REPLAY SELECTED**, or leave it unconfirmed and report the issue.
7. Copy the **latest complete line beginning `DEAD_SIGNAL_B2_AUDIO_PROBE `** from Output, or copy the JSON from the panel, and return it privately to MAIN. If any check failed, return that report with the error and cue name; do not turn failed flags into passes.
8. Click **CLOSE / CLEAN UP** or stop Play. The temporary GUI, Sound and folder are removed. Re-running replaces only the probe's own objects. It also cleans itself up after ten minutes. Do not save or publish the diagnostic into the experience.

The report includes the staging place/version and input capabilities. A Studio device emulator is not a physical-phone or published multiplayer test. Normal gameplay/audio mixing, spatial effects, mute/Low Effects, mobile and multiplayer testing remain separate.

## Review the returned report

From the repository, MAIN can validate the returned JSON without uploading anything:

```bash
python scripts/check_dead_signal_batch2_audio_probe.py --report /path/to/owner-probe-report.json
```

The validator requires sixteen exact event/ID pairs, valid Studio-client/staging context, completed successful ContentProvider callbacks, finite expected durations, successful play calls/progress and the owner's intended-clip confirmation. It rejects timeouts, missing rows, wrong IDs, nonfinite fields and assertions that the probe establishes moderation/gameplay/production approval. Structural validation cannot prove that a submitted file actually ran in Roblox; review the actual owner-provided Output/context before pinning it.

The returned evidence is accepted, including owner-attested steam identity; both numerical steam comparison failures remain frozen. MAIN prepares the actual staging-only audio-active Config/Effects source, retains production authorization false, repins the 61 records and all eight binaries, reruns the five no-publish workflow families and presents a new exact source for separate final merge/deployment authorization. The retained disabled source is not the requested final release.
