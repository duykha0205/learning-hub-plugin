# Learning Hub — Antigravity Agent Rules

## 1. Session Start & Selective Context Loading
- Always start every tutoring or memory session by calling:
  1. `list_users`
  2. `list_domains(userId)`
  3. `get_domain_context(userId, domainId)`
- Read `db://schema-guide` if you need database/table details.
- `get_domain_context` loads only core docs (`00-profile`, `01-roadmap`, `03-weak-spots`, `04-digests`) plus `dueSrsCards`, `activeCorrections`, and `recentSessions`. Fetch `02-knowledge` or `05-feynman-vault` on demand with `read_memory_doc`.
- Strictly isolate domains: never leak English/Science notes into Chinese sessions or vice versa.

## 2. Chinese From Zero (Phase 0 -> 3) & 15-Minute Rhythm
- Follow `00-profile` preferences and every rule in `activeCorrections`.
- **Mandatory phonetic rule:** NEVER use Vietnamese phonetic hacks (e.g. `"ní hảo"`). Always use standard Pinyin with tone marks and 1–5 pitch contours (`55`, `35`, `214`, `51`, neutral).
- Run the **15-minute daily rhythm**:
  - **4 min — SRS Warm-up:** Review `dueSrsCards` with `<hub-review-deck>`.
  - **8 min — Abstract -> Detail HTML:** Publish Layer 1 overview first, then drill down (`parentArtifactId`, `layerDepth: 2+`) using `<hub-audio-phrase>`, `<hub-hanzi-breakdown>`, `<hub-choice-board>`, `<hub-quiz-check>`.
  - **3 min — Multi-Angle Feynman Check:** End with `<hub-feynman-note>` rotating facets (`explain_simple`, `contrast_analogy`, `apply_scenario`, `spot_the_bug`).
- Curriculum sequence: **Phase 0** (3 core pieces: Pinyin · Tones · Hanzi) -> **Phase 1** (Tones 1–4 + tricky initials + 3rd tone sandhi) -> **Phase 2** (30 core radicals) -> **Phase 3** (SVO survival sentences).

## 3. HTML-First Artifact Hub & Side Pane Collaboration
- Call `list_curated_components` and age-gated `search_assets` before building artifacts.
- Include `/sdk/hub-tokens.css` and `/sdk/hub-runtime.js` in `<head>` of every artifact.
- Respect `user.age` HTML sandbox policy:
  - `age < 10` (`strict` mode): `<= 40 KB`, NO inline `<script>` bodies, NO `on*` inline handlers; rely exclusively on `<hub-*>` Web Components.
  - `age >= 10` (`full` mode): `<= 150 KB`, inline `<svg>` and interactive `<script>` allowed; external URLs, `fetch`, `XMLHttpRequest`, `WebSocket`, `EventSource`, `window.top`/`parent` escapes are always forbidden.
- Publish via `publish_artifact` (renders in Antigravity `aux_pane` Side Pane via `ui://hub/app.html` and in the web shell `/s/{sessionId}`).
- Read learner send-back interactions via `get_session_inbox(sessionId)` (triggered automatically when `app.sendMessage` wakes chat from the Side Pane, or via `node scripts/wait-session-event.mjs --session=<id>` when collaborating through the browser shell).

## 4. Non-Negotiable Data & Memory Invariants
- **Never** fabricate `next_review_at`, intervals, or ease factors manually. Always call `submit_feynman_assessment` so TypeScript computes SM-2 transitions transactionally.
- **Never** mutate `learning_events` payloads (Tier 1 append-only ledger).
- **Never** overwrite `00..05` memory documents ad-hoc. Always call `propose_memory_update` so changes create auditable `memory_doc_revisions` synced atomically to SQLite and disk Markdown.
