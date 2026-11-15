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
