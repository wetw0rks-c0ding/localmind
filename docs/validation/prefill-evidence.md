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
