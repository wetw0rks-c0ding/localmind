# Live Prompt-Processing Indicator + Prompts-Processed Counter

## Goal
Add an LM Studio–style composer status for local/server chat:
- While waiting for the first token: **"Processing prompt… N%"** progress.
- After the first token: **"Generating… 18.4 tok/s · 2.1s"** live stats.
- On success: brief summary (~2.5s) then fade.
- A per-conversation, persisted **"prompts processed"** chip.
- A settings toggle to hide the whole thing (default on).

## Locked decisions (grilled with user)
1. Percentage = **estimated prefill progress**; LM Studio real `prompt_processing.progress` used when available (hybrid).
2. Count is **per-conversation, persisted** in ObjectBox; skipped for incognito.
3. Placement: **composer** (status row above the input row).
4. **All backends**, unified; estimate where no real data.
5. Increment **on successful completion only**, for **user prompts only**:
   - Counts: `sendMessage` (send + edit-and-resend), regenerate/retry.
   - Does **not** count: AI-drafted user messages, smart replies, voice turns, tool-call continuations.
6. Indicator delayed **~400 ms** so instant prefill never flashes.
7. After first token → **live generation stats**.
8. On done → **brief summary then fade**.
9. Stats visible **only during the active reply**.
10. Estimation is **prompt-size aware**.
11. **Settings toggle**, default on; hides indicator + chip.
12. Counter **persisted for normal chats**, excluded from incognito; included in backup/export + cloud sync.

## Implementation map
- `conversation.dart` / `ConversationEntity`: new `promptsProcessed` int (codegen required).
- `conversation_providers.dart`: `incrementPromptsProcessed(id)`.
- `app_settings.dart` + `app_providers.dart`: `showPromptProcessingIndicator` (default true) + setter.
- `data_backup_service.dart`, `cloud_sync_models.dart`: include counters/settings key.
- `chat_service.dart`: `ChatResponseType.prefillProgress` + `progress`; parse LM Studio `prompt_processing.progress`.
- `live_generation.dart` (new): `LiveGeneration` state + `PrefillEstimator`.
- `generation_session.dart`: `countsAsPrompt`, `promptCounted`, `noteFirstToken()` returns bool.
- `chat_notifier.dart`: `ChatState.liveGeneration`; phase transitions; `_maybeCountPrompt` on success.
- `prompt_processing_indicator.dart` (new): status row (progress + stats) and count chip.
- `chat_input_bar.dart`: render status row above input.
- `voice_mode_provider.dart`, AI-user call: `countsAsPrompt: false`.
- `app_en.arb` + others: strings; `flutter gen-l10n`.

## Verification
- `flutter pub get`, `dart run build_runner build`, `flutter gen-l10n`.
- `dart format`, `flutter analyze`, `flutter test`.

## Orchestration ledger (closed-loop)
- Done inline before switch to orchestrator: Conversation model + entity field; ObjectBox codegen (field present); conversation `incrementPromptsProcessed`; AppSettings field/setter/json; backup export/restore + backup allowlist.
- Wave 1: A chat_service prefill event · B live_generation + estimator test · C generation_session flags.
- Wave 2: D chat_notifier integration · F settings UI + voice flag + cloud allowlist · G l10n + gen-l10n.
- Wave 3: E indicator widget + composer integration.
- Wave 4: format/analyze/test verification + fix.

