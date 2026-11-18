# Prefill percentage capture attempt (Pixel 6, 2026-11-15)

**Target:** capture the "Processing prompt…" prefill-percentage state of the composer indicator (generating-stats state already proven in `prompt-proc-8.png` / `0 tok · 0.0 tok/s · 28.5s`).

**Device:** Pixel 6, serial `1B181FDF60043F` (`model:Pixel_6 device:oriole`), `pro.momin.localmind` `versionCode=96`, `versionName=1.9.1`, `lastUpdateTime=2026-11-15 01:02:35`.

## Attempt 1 (02:07, blocked — PIN lock)
- Unlock check: `adb -s 1B181FDF60043F shell dumpsys window | grep mDreamingLockscreen` showed locked/PIN state; automation cannot bypass PIN (per on-device skill).
- **Result:** prefill percentage not captured (no app interaction possible).
- Evidence kept: `docs/validation/prefill-attempt-00-lockscreen.png`, `docs/validation/prefill-attempt-01-pin.png` (+ corresponding `/tmp/opencode` dumps noted at capture time).

## Attempt 2 (02:2x, device unlocked)
- Unlock verified before interaction: `mShowingDream=false mDreamingLockscreen=false`.
- Prep: `stay_on_while_plugged_in=3`, animations set to `0`; `adb -s 1B181FDF60043F reverse tcp:1234 tcp:1234` (`UsbFfs tcp:1234 tcp:1234`); host LM Studio `http://127.0.0.1:1234/v1/models` confirmed serving `crow-9b-heretic-4.6`.
- App flow: launched `pro.momin.localmind/.MainActivity`, opened drawer → Servers; attempted to add an LM Studio/OpenAI-compatible server for `http://localhost:1234` but form field contents were not reliably exposed/editable via uiautomator on this build (text input appeared mis-targeted in dumps). Switched to on-device path: New Chat → model picker → loaded **Qwen 3 0.6B** (accepted RAM warning "Proceed Anyway"; 1.4 GB available / 3 GB recommended).
- Prompt/send: focused composer and sent a long prompt (~20 chunked `adb shell input text` calls, several thousand chars total) to extend prefill. Started `adb shell screenrecord --time-limit 30 /sdcard/prefill.mp4` ~1s before tapping send (`Send message` center ~983,1414 at 02:24:51 local), then sampled screencap+uiautomator dump loop (12 iterations, `prefill-00`..`prefill-11`).
- **Result:** **No "Processing prompt…" prefill-percentage text captured in sampled UI dumps.**
  - `docs/validation/prefill-00.xml`–`prefill-07.xml`: no `Processing`/`%`/`tok/s` status nodes found (grep hits were only the user prompt text containing "prompt").
  - `docs/validation/prefill-08.png`/`prefill-08.xml` (sample timestamp 02:25:26 local): composer/status shows **`0 tok · 0.0 tok/s · 34.6s`** at `bounds="[97,1309][412,1351]"` (generating/processing-stats state, not a prefill percentage). Same status text present in `prefill-09`..`prefill-11`.
  - Sampling cadence was coarse relative to prefill (~3–10 s between saved samples due to `uiautomator dump`/`screencap` latency), so a brief percentage-prefill frame may have occurred between samples.

**Evidence (this attempt):**
- `docs/validation/prefill-00.png`–`docs/validation/prefill-11.png` with matching `prefill-00.xml`–`prefill-11.xml` (rapid post-send samples; copied from `/tmp/opencode/prefill-sample-*`).
- `docs/validation/prefill-recording.mp4` (screenrecord covering send/transition window, pulled from `/sdcard/prefill.mp4`).

**Existing related evidence (not re-captured):** `docs/validation/prompt-proc-8.png` shows generating-stats state `0 tok · 0.0 tok/s · 28.5s`.

**Animations restored:** `window_animation_scale`, `transition_animation_scale`, `animator_duration_scale` set to `1`; `stay_on_while_plugged_in` set to `0`.

## Video frame analysis (`prefill-recording.mp4`)
- **Probe (`ffprobe`):** `docs/validation/prefill-recording.mp4` — duration `29.997389s`, stream `1080x2400` (`r_frame_rate` reported as `90000/1` by ffprobe; frame extraction performed at `fps=10`).
- **Extraction:** `ffmpeg -i docs/validation/prefill-recording.mp4 -t 20 -vf fps=10 /tmp/opencode/frames/f_%04d.png` (200 frames, first 20 s; 1080x2400). Send tap was ~1 s into recording, so prefill window is expected early in extracted sequence.
- **Scene-change signal (cheap check, `select='gt(scene,0.01)',showinfo`, first 20 s):**
  - Status band crop `1080x420+0+1150`: detected changes reported at `pts_time=0.624022`, `0.714233`, `0.846056` and a later `29.206222` (outside 0–20 s analysis window tail context from full decode).
  - Composer band crop `1080x420+0+2050`: no frames reported above threshold in the captured `showinfo` grep output for 0–20 s.
- **Contact sheets (cropped for legibility, `crop=1080:420:*`, scaled, `tile=3x6` over selected 10 fps frames):**
  - `docs/validation/prefill-contact-1.png` — status band `1080x420+0+1150`, **t=0–6 s** (`n=0..59`).
  - `docs/validation/prefill-contact-2.png` — status band `1080x420+0+1150`, **t=6–12 s** (`n=60..119`).
  - `docs/validation/prefill-contact-3.png` — status band `1080x420+0+1150`, **t=12–18 s** (`n=120..179`).
  - Additional crops/sheets: `prefill-contact-status-crop-0-6s/6-12s/12-18s.png`, `prefill-contact-composer-0-6s/6-12s/12-18s.png` (`1080x420+0+2050`), and `prefill-contact-status-0-6s/6-12s/12-18s.png` (uncropped status sheets).
- **Candidate exported frame:** `docs/validation/prefill-frame.png` = extracted `f_0020.png` (~2.0 s into recording, ~1 s after send tap) as a promising early frame for visual review. **Text not machine-read in this pass** (no OCR/vision confirmation here); whether it shows a prefill-percentage status line distinct from `0 tok · 0.0 tok/s` is unconfirmed — contact sheets and frame retained for vision review.
- **Outcome:** a definitive prefill-percentage frame/text was **not confirmed** from this offline extraction pass alone; likely candidates (if any) are in early 0–6 s status/contact-sheet region around scene changes ~0.62–0.85 s and nearby extracted frames.

## Prefill percentage captured (post-fix)

After the 400 ms reveal gate was removed (`53882b2`), the percentage state is
visible on the Pixel 6 with the on-device Qwen 3 0.6B model.

- `prefill-percentage.png` — frame at t≈2.0 s from `screenrecord` during a long
  prompt send. Status line reads **`Processing prompt… 56%`** with the arc.
- `prefill-thinking.png` — same chat several seconds later (keyboard up), status
  unchanged at `Processing prompt… 56%` while the reply had not started.

Known follow-up: the percentage holds at its first computed value (56% here)
instead of advancing, because nothing rebuilds the widget while prefill runs —
the value is computed once from `live.startedAt` and only changes when chat
state changes. A periodic tick during `processingPrompt` is needed for it to
animate like LM Studio's.

## Percentage advances and caps at 99% (follow-up fix)

- `prefill-percentage.png` — `Processing prompt… 26%` shortly after send.
- `prefill-percentage-advancing.png` — same run at ≈2 s: `67%`, proving the 200 ms
  repaint ticker now advances the value instead of freezing it.
- `prefill-percentage-capped.png` — later in the same run: `99%`, never `100%`
  while prefill is still running (the estimate clamps before `easeOut`).

Caption note: the "Another chat is still replying" banner in these frames is an
unrelated concurrent generation, not the indicator.

## PR-branch build proof (237c723, upstream-based)

Built from `/home/missioncontrol/localmind-pr` at `237c723`, installed
04:38:16 (`lastUpdateTime` verified against the 04:12:56 APK), Qwen 3 0.6B
on-device, Pixel 6 `1B181FDF60043F`, 523-char prompt.

- `prefill-pr-advancing.png` — `Processing prompt… 29%`, arc partially filled.
- `prefill-pr-capped.png` — `Processing prompt… 99%`, arc nearly full, never
  `100%` while prefill runs.

Same run showed `29% → 74% → 99%` across consecutive frames: the ticker
advances the estimate and both label and arc clamp at 99% until first token.

## Placement states on final PR build (714af42)

Built from `/home/missioncontrol/localmind-pr` at `714af42` (`flutter build apk --debug`,
APK `app-debug.apk` built 2026-11-15 21:23:44), installed with `adb install -r` at
21:24:19 (`dumpsys package pro.momin.localmind` → `lastUpdateTime=2026-11-15 21:24:19`,
`versionName=1.9.1`, `firstInstallTime=2026-11-15 01:02:35`). Pixel 6 `1B181FDF60043F`,
1080x2400, Qwen 3 0.6B (on-device, loaded via picker; a `Load` tap was required after the
reinstall — send without loading opens the picker with toast `You need to select a model
first`), debug build, animations 0 for the run.

- `prefill-pr-centered.png` — STATE A (centered in-field, empty field). Frame (~3.0 s into
  send) from `screenrecord` of a 645-char prompt send. Input field is empty; the status
  line reads **`Processing prompt… 85%`** (arc + text), horizontally centered inside the
  input field. Cropped read: `…` is a single ellipsis glyph; arc ~85% filled.
- `prefill-pr-typing.png` — STATE B (corner row, typing). Same session, second long-prompt
  send; while prefill was still running, a short prompt (`short follow-up question`) was
  typed into the field and NOT sent. Screenshot shows the typed text in the field with the
  status line in a small top-left corner row above it reading **`Processing prompt… 99%`**
  (arc icon to the left of the label).

Video frames extracted at `fps=10` to `/tmp/opencode/prefill-pr/frames-b/`
(`f_0028.png` = `… 71%`, `f_0030.png` = `… 85%`, both centered in-field, empty field);
`/tmp/opencode/prefill-pr/06-stateB.png` is the STATE B screenshot. `prefill-pr-a.mp4`
captured the pre-model-load failure (send with no model loaded → model picker sheet +
`You need to select a model first` toast), kept for reference.

**Animations restored:** `window_animation_scale`, `transition_animation_scale`,
`animator_duration_scale` set back to `1`; `stay_on_while_plugged_in` set to `0`.

## Prompt counter/cancellation fixes attempt (098a9b1, 2026-11-16)

**Worktree/build:** `/home/missioncontrol/localmind-pr` at `098a9b1` (fix commits `e51d682`, `098a9b1` on top of `714af42`, pushed as `origin/feat/prompt-processing-indicator`, PR abdulmominsakib/localmind#141). Built with `flutter build apk --debug` (APK `build/app/outputs/flutter-apk/app-debug.apk`, mtime `2026-11-16 02:32:07 -0500`), installed to Pixel 6 `1B181FDF60043F` via `adb install -r` at `lastUpdateTime=2026-11-16 02:32:37` (`dumpsys package pro.momin.localmind | grep lastUpdateTime`), animations set to 0 / stay-on 3 for the run and restored to 1 / 0 afterward.

**Fixes implemented and verified by tests:** backup/cloud import validates `promptsProcessed` (missing→0, negatives clamped to 0, wrong types skipped/rejected without aborting whole import; cloud replacement rejects invalid `promptsProcessed` before writes), `incrementPromptsProcessed` reads+updates the stored row in one write transaction and preserves message-derived summaries when publishing, tool follow-up carries original prompt counting state so a successful tool turn counts exactly once, and Stop/cancel paths clear live generation status.

**On-device proof status:** Attempted on Pixel 6 with on-device Qwen 3 0.6B (already downloaded). Device was unlocked (`mDreamingLockscreen=false`). During send attempts the app repeatedly opened the model picker with "You need to select a model first" and did not enter a stable processing/generating state that allowed capturing the requested states (A) centered in-field status while processing empty box, (B) corner row while typing, and (C) Stop clears live status. A microphone-permission system dialog also interrupted one attempt. Because valid re-proof frames/text were not obtained, `docs/validation/prefill-pr-centered.png`, `docs/validation/prefill-pr-typing.png`, and `docs/validation/stop-clears.png` were **not** overwritten/added in this pass. Code-level fixes and regression tests for counting and Stop/live-status clearing passed locally (`flutter test` all green; `flutter analyze` only 3 pre-existing vendored `packages/llamadart` warnings).

## Held fix tip re-proof (098a9b1, 2026-11-18) — GATE 5 PASS

The prior attempt above was blocked at the model picker. This pass beat that
blocker and captured all three requested states from the exact held tip.

**Artifact provenance.** Built in `/home/missioncontrol/localmind-pr` from a
detached checkout of `098a9b1aa221b6d7d47df4dba4673a192e9f7103` (`e51d682` +
`098a9b1` on `714af42`), with system Flutter `3.47.6` and
`flutter build apk --debug`. APK
`build/app/outputs/flutter-apk/app-debug.apk`, mtime
`2026-11-18 00:15:02.672615762 -0500`, 523,549,278 bytes. Installed with
`adb -s 1B181FDF60043F install -r` → `Success`;
`dumpsys package pro.momin.localmind | grep lastUpdateTime` →
`lastUpdateTime=2026-11-18 00:15:37` (`versionName=1.9.1`, `versionCode=96`),
35 s after the APK mtime — install timestamp matches. The source worktree was
restored to `feat/prompt-processing-indicator` at `714af42` afterward; nothing
was committed or pushed there.

**Device / prep.** Pixel 6 (`oriole`, `1B181FDF60043F`, 1080x2400), unlocked
(`mShowingDream=false mDreamingLockscreen=false`), animations 0 and stay-on 3
for the run, restored to 1 / 0 afterward. On-device Qwen 3 0.6B (already
downloaded, preserved by `install -r`).

**Picker handling (the prior blocker).** `RECORD_AUDIO` was granted with
`pm grant` before launch, so the microphone-permission dialog that interrupted
the earlier attempt never appeared; a post-launch dump confirmed no dialog
node. After launch the header still read `Qwen 3 0.6B`, but the composer send
control's content-desc was `'You need to select a model first'` — the engine was
not loaded. Explicit recovery, each tap by freshly dumped bounds:
1. Tapped the header model chip `bounds=137,137,817,266` → model picker sheet.
2. Picker showed `Qwen 3 0.6B` with a `Load` control
   `bounds=783,1567,857,1640`; tapped its center `(820,1603)`.
3. RAM warning appeared (`AVAILABLE RAM 1.7 GB`, `RECOMMENDED 3 GB`) with
   `Proceed Anyway` `bounds=556,1557,912,1677`; tapped `(734,1617)`.
4. Re-dumped after 12 s: picker closed, composer send content-desc changed to
   `'Voice mode'` and the chat input was active. `activeChatTarget.isReady`
   was now true; no further picker reset occurred in subsequent sends.

**Prompt.** 570-char base prompt typed in three `adb shell input text` chunks
(`%s` for spaces); an early stdin-consumption issue duplicated the first chunk,
so ~760 chars were actually sent — comfortably over 500.

**(A) Centered in-field status, empty box.** `adb shell screenrecord` was
started *before* the send tap (`g5-a.mp4`, 60.18 s, 1080x2400). Eight rapid
screencap + `uiautomator dump` samples: samples 0–6 all read
`'Processing prompt… 99%' center=(508,1397) bounds=257,1367,760,1428'` with
`'Stop generation' center=(977,1409)` and an empty input; sample 7 had moved on
to `'0 tok · 0.0 tok/s · 35.4s'`. Video frames were extracted at 4 fps and read
directly: `f_036` shows `Processing prompt… 35%`, `f_040` `96%`, `f_044` and
`f_048` `99%` — arc on the left, label centered inside the empty field, red
Stop on the right. The percentage advances before clamping at 99%, so this is
not a frozen first-frame value.
- `prefill-pr-centered.png` — crop `1080x170+0+1330` of sample s3 (99%):
  arc + `Processing prompt… 99%` centered in an empty composer, mic and red
  Stop. Composer only; no header, no keyboard.

**(B) Corner row while typing.** First attempt typed after generation had
already ended (dump contained only the typed text) and was discarded. Second
send: field cleared, long prompt retyped, screenrecord started, Send tapped and
`short follow-up question` typed 0.4 s later during prefill. Dump:
`'Processing prompt… 99%' center=(272,1320) bounds=97,1299,447,1341'` — a
small top-left corner row above `'short follow-up question'
center=(474,1414) bounds=144,1367,804,1462'`, with `'Stop generation'`
still present.
- `prefill-pr-typing.png` — crop `1080x180+0+1290`: corner row with arc +
  `Processing prompt… 99%` above the typed text, mic and red Stop.

**(C) Stop clears live status.** With processing still active, tapped the red
Stop control at its dumped bounds center `(977,1409)`. Post-Stop dump:
`'Send message' center=(977,1409)` restored, typed text retained, and raw
greps returned 0 hits each for `Processing prompt`, `tok/s`, `Generating`,
`Thinking` and `Stop generation`. The message below shows `No response`.
- `stop-clears.png` — crop `1080x190+0+1280`: the area where the corner status
  sat in (B) is empty, and the composer shows only the typed text with an
  active white Send arrow — no processing or throughput text.

All three crops were re-read visually after cropping. Only the two previously
existing proof PNGs were overwritten (`prefill-pr-centered.png`,
`prefill-pr-typing.png`); `stop-clears.png` was added.
