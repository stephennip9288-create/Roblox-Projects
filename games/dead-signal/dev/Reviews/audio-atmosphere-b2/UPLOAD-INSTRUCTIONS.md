# Dead Signal Batch 2 — owner audio package

This package contains nine original 32-second music loops and one three-second musical stinger in `Audio/` (OGG), plus mono 48 kHz, 16-bit WAV masters in the owner ZIP. They were composed by deterministic additive synthesis in `prepare_music.py`, using no external recordings or sample libraries. These are music audition candidates, not realistic physical recordings. They have not been uploaded, moderated, granted experience access, activated or accepted through gameplay listening.

1. Extract the ZIP. Open `LISTEN.html`, or play the WAV files directly on your phone/desktop. Review each map's calm and pressure pair at a comfortable fixed level. Reject or request replacement for any candidate you dislike. Physical sound requests are in `RECORDING-REQUESTS.csv`; those files are not included.
2. For accepted files, verify creator/rights ownership and upload using the intended Dead Signal creator account or group. In [Creator Dashboard](https://create.roblox.com/dashboard/creations), open **Development Items → Audio → Upload Asset**; select a WAV or OGG, use its filename as the title and complete the upload. Check current account upload limits in the dashboard. Do not upload WAV and OGG duplicates of the same track.
3. Wait for moderation, then copy each resulting audio asset ID into `UPLOAD-RETURN.csv` beside the matching filename/event. Keep rejected or pending rows false. Retain the original filename, source/provenance, uploader, moderation result and permission evidence together.
4. Open the asset's **Permissions → Experiences → Add experiences** and grant the appropriate **universe ID**, then verify the recorded grant. Private staging is `10771141095`; production is `10770732078`. Granting access to one experience does not establish access to the other. No public distribution is required for this workflow.
5. Return the filled CSV and any physical sound files/rights evidence to MAIN. Mark `creatorReviewed`, `rightsCleared`, `listeningApproved` and `robloxApproved` true only after the corresponding review has passed. Mark `stagingAccess` / `productionAccess` independently. Here `listeningApproved` means the owner accepted the individual candidate for an integration audition; full gameplay acceptance remains a separate pending checklist.

Roblox's current guidance: [Audio assets](https://create.roblox.com/docs/audio/assets) (formats, import and rights), [Asset privacy — grant permissions to games](https://create.roblox.com/docs/projects/assets/privacy#to-games) (experience grants). Instructions checked 2026-11-08. Dashboard wording may vary by account.

## MAIN application after owner return

The upload does not alter game source. MAIN must review and apply the approved event-to-ID mappings to `C.AudioAtmosphere.assets`, integrate PR #70 and build an authorized test candidate. Existing `C.SoundIds` stays intact. The following helper prints proposed JSON assignments only; it never edits source, uploads or publishes:

```sh
python Reviews/audio-atmosphere-b2/emit_asset_intake.py returned-approved.csv --universe 10771141095
```

Run from `games/dead-signal/dev`. Supply only completed, accepted rows; incomplete rows intentionally reject the proposal. JSON `MUSIC-RECORDINGS.json` with reviewed `recordings` entries is also supported. The returned `{event, bank}` pairs correspond to `C.AudioAtmosphere.assets[event] = bank` in Luau; MAIN must translate/review them and preserve any independently verified permissions for other universes. Repeat the proposal check for each intended experience. Do not copy JSON syntax directly into Luau.

Each new bank needs a genuine asset ID plus `rightsCleared=true`, `creatorReviewed=true`, `listeningApproved=true`, `robloxApproved=true` and `permissions["<current universe>"]=true`. `gain=1` leaves the conservative authored mix calibration in place. The supplied templates contain no IDs and all review/access flags are false. Runtime gates cannot be bypassed through a legacy `SoundIds` entry.

MAIN must update the reviewed Batch 2 Config policy/provenance when applying real mappings; the audio source scope guard deliberately pins this PR's empty policy. Do not weaken or rewrite the frozen Batch 1 evidence to accept new assets. Upload permission and approved feature development do not authorize staging or production publication; obtain the owner's separate publication authorization.

## Physical recording brief

Provide a dry, uncompressed mono WAV master, preferably 48 kHz/24-bit, with clean start/end trims, no clipped peaks or baked room reverb. Keep transients below −6 dBFS for mix headroom. Supply the source/performer and ownership or license record, including permission for Roblox game use and editing. MAIN should audition alternatives, select appropriate takes, trim/convert for playback and record hashes before upload. Do not substitute water, blade swings, generic pitched vocals or copyrighted recordings. Three varied takes per category are useful for selection; this first intake selects one accepted clip per new slot.

The six physical categories are additional Batch 2 work. The eleven previously documented specialized reload stages are unchanged Batch 1 limitations and are not included in this request.
