# Batch 1 audio asset intake status

Original **84 uploaded IDs** are retained exactly. Config blob `1c7a4dffde21e4cfd3d383d9a0304d06ceb585b2` and the owner-upload record are unchanged. Activation remains restricted to staging universe 10771141095; creator/moderation/experience/listening attestations remain unverified.

These **14 additional candidates** are separate from the original 84. Every Roblox ID is null, every approval/activation field is false, and none was uploaded by MAIN or this integration. Native quality review, owner upload, moderation and experience access are still required.

| Candidate | Proposed use | Upload / acceptance |
| --- | --- | --- |
| wood_break_1 | Board.Break | Not uploaded; unapproved |
| wood_break_2 | Board.Break | Not uploaded; unapproved |
| wood_stress_1 | Board.Stress (future caller needed) | Not uploaded; unapproved |
| wood_stress_2 | Board.Stress (future caller needed) | Not uploaded; unapproved |
| wood_stress_3 | Board.Stress (future caller needed) | Not uploaded; unapproved |
| wood_debris_1 | Board.Debris (future caller needed) | Not uploaded; unapproved |
| wood_debris_2 | Board.Debris (future caller needed) | Not uploaded; unapproved |
| frame_scrape_1 | Enemy.Entry.Contact (replace after review) | Not uploaded; unapproved |
| frame_scrape_2 | Enemy.Entry.Contact (replace after review) | Not uploaded; unapproved |
| frame_scrape_3 | Enemy.Entry.Contact (replace after review) | Not uploaded; unapproved |
| board_fracture_1 | Board.Break | Not uploaded; unapproved |
| window_contact_1 | Enemy.Entry.Contact | Not uploaded; unapproved |
| board_fracture_2 | Board.Break | Not uploaded; unapproved |
| window_contact_2 | Enemy.Entry.Contact | Not uploaded; unapproved |

Scrape source material is cinder block: a disclosed proxy requiring review for the window frame. Stress/debris clips need a genuine event caller; no new event hooks are implemented here. Board.Break can use a reviewed composite at the existing confirmed break event. Dedicated landing recordings remain distinct.

All 14 WAV/OGG hashes match the supplement inventory. Exact PCM reproduction from pinned sources passed, with zero clipped samples and the independent 4x-peak check passing. These are offline file checks.

[Exact hashes/metadata](../audio-corrections-b1/SUPPLEMENTAL-RECORDINGS.json) · [Source provenance](../audio-corrections-b1/SUPPLEMENTAL-SOURCES.json) · [Upload template](../audio-corrections-b1/SUPPLEMENTAL-UPLOAD.template.json) · [Native listening checklist](../audio-corrections-b1/LISTENING-CHECKLIST.md).

## Mechanism asset gaps

The actual 20-weapon timeline has 94 stages. The following **11** lack suitable recordings and intentionally skip with diagnostics; unrelated sword/water/gun mechanisms are not substituted.

| Weapon | Missing real animation phase |
| --- | --- |
| Breaker | action-open |
| Breaker | action-close |
| Arc | cell-out |
| Arc | cell-in |
| Arc | charge |
| Vigil | action-open |
| Vigil | shell-in |
| Vigil | action-close |
| Signal | cell-out |
| Signal | cell-in |
| Signal | charge |

The broader specialist inventory also discloses remaining hound, impact and environmental recording/realism gaps. Do not infer DS-B1-001 completion from routing tests or upload count. Follow the source event/asset audit and native listening checklist.
