# Dead Signal — Audio Upload (personal Roblox creator account)

This is a reviewed sound **candidate** package, not a completed audio overhaul. Batch 1.1 DS-B1-001 remains In Progress. Do not publish the game or claim native audio acceptance after uploading sounds.

1. In GitHub Actions run **Dead Signal Audio WAV Upload Package (No Publish)** on main, or wait for its initial automatic no-publish run after the exporter is merged.
2. Open a successful run and download the artifact **dead-signal-84-reviewed-WAV-upload-package** from its Artifacts section. Extract it. The `WAV/` folder contains 84 precisely hash-verified short source-declared CC0 clips.
3. Listen to the bundled `LISTEN.html` with `Auditions/` in a local browser or play the WAV files. Reject unsuitable samples before uploading.
4. In Roblox Studio Asset Manager, or Roblox Creator Dashboard's audio import, select your **personal** creator account. Import a first batch of **3–5 chosen WAV files** (for example `pistol_near_1.wav`, `pistol_far_1.wav`, `rifle_near_1.wav`, `mag_out.wav`) to validate approvals and account limits. Never select a group/unrelated account. Files are WAV, 48 kHz, mono, under 1 MB, up to 10 s. Observe the creator dashboard's actual remaining quota before uploading more.
5. Wait until each uploaded audio asset is approved by moderation. Identify its numeric **audio asset ID**. Name-to-ID correspondence must not be lost; save a mapping `pistol_near_1 -> 123...` etc. Do not confuse asset ID with a Roblox place/universe ID.
6. For each asset, in Creator Dashboard → **Development Items** → **Audio** → select asset → **Permissions** → **Experiences** → **Add Experiences**, enter staging **Universe ID `10771141095`**, Add and Done. Where the renewed Asset Manager offers bulk experience permission assignment, use that for the uploaded batch. No production access is implied.
7. Supply the filename/ID list, moderation status, creator ownership and staging permission evidence for integration. The template `UPLOAD-MAP.template.json` includes exact reviewed WAV SHA256s. Only populate truthful approval flags; never substitute IDs or change hashes. The repo's `emit_bindings.py` produces a source **proposal**, not a Roblox permission verification or publication.
8. Test sound playback after approved ID bindings are reviewed and a **separately authorized** staging build is published. Test mobile and desktop. Until then stock fallbacks remain and DS-B1-001 is incomplete.

**Recording gaps:** dedicated LMG, energy weapon, canine breathing/howl/Alpha/paws, metal boots, ice cracks, steam/emergency equipment and military comms still need original/rights-cleared captures or approved creative treatment.

Reference: `games/dead-signal/dev/Reviews/audio-quality-b11/README.md` and `ASSET-ACTIONS.md` under the combined Batch 1.1 integration branch.

The exporter has **no access to Roblox credentials** and performs no upload or publishing operations. Its purpose is to avoid asking the owner to install Python, ffmpeg, scipy or Linux tools locally.
