# Prefill percentage capture attempt (Pixel 6, 2026-11-15)

**Target:** capture the "Processing prompt…" prefill-percentage state of the composer indicator (generating-stats state already proven in `prompt-proc-8.png` / "0 tok · 0.0 tok/s · 28.5s").

**Device:** Pixel 6, serial `1B181FDF60043F` (`model:Pixel_6 device:oriole`).
- `adb -s 1B181FDF60043F shell dumpsys package pro.momin.localmind | grep -E 'lastUpdateTime|versionCode|versionName|firstInstallTime'`:
  - `versionCode=96`, `versionName=1.9.1`, `lastUpdateTime=2026-11-15 01:02:35`, `firstInstallTime=2026-11-15 01:02:35`
- `adb reverse`: `UsbFfs tcp:1234 tcp:1234` (re-asserted; host LM Studio `127.0.0.1:1234` with `crow-9b-heretic-4.6` was reported running).

**Result:** **Prefill percentage state NOT captured (blocked before app interaction).**

**Why:** the device was on the lock screen and presented a PIN prompt ("Enter PIN" / PIN pad visible in UI dumps). Automation cannot bypass a PIN (per on-device skill). Without unlocking, the app could not be opened, the LM Studio server/model could not be configured, and no prompt/prefill run could be started.

**Evidence from this attempt:**
- `docs/validation/prefill-attempt-00-lockscreen.png` + `/tmp/opencode/prefill-00-launch.xml`: lock screen (02:07, fingerprint sensor).
- `docs/validation/prefill-attempt-01-pin.png` + `/tmp/opencode/prefill-01-unlock.xml`: PIN entry screen after wake/unlock swipe; dump shows `text='Enter PIN'` and `desc='PIN area'` with keypad nodes.

**Existing related evidence (not captured this run):** `docs/validation/prompt-proc-8.png` shows the generating-stats state (`0 tok · 0.0 tok/s · 28.5s`) as previously recorded; this attempt did not reach prefill/generation.

**Animations restored:** `window_animation_scale`, `transition_animation_scale`, `animator_duration_scale` set back to `1`; `stay_on_while_plugged_in` set back to `0`.
