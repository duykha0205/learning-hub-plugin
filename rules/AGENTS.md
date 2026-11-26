# Learning Hub — Antigravity Agent Rules

## 1. Session Start & Selective Context Loading
- Always start every tutoring or memory session by calling:
  1. `list_users`
  2. `list_domains(userId)`
  3. `get_domain_context(userId, domainId)`
- Read `db://schema-guide` if you need database/table details.
- `get_domain_context` loads only core docs (`00-profile`, `01-roadmap`, `03-weak-spots`, `04-digests`) plus `dueSrsCards`, `activeCorrections`, and `recentSessions`. Fetch `02-knowledge` or `05-feynman-vault` on demand with `read_memory_doc`.
- Strictly isolate scopes: never leak English/Science notes into Chinese sessions or vice versa.
- **Folder & Path Convention:** Treat `data/<user>/` (e.g. `kha`) as the learner's root folder, and organize subjects/levels as nested folders inside it using `/` paths (e.g. `chinese`, `chinese/hsk1`). To create a folder inside another folder, call `create_domain` with a path `slug` (e.g. `"chinese/hsk1"`) or `parentPath` (e.g. `parentPath: "kha/chinese"`, `slug: "hsk1"`).

## 2. Chinese From Zero (Phase 0 -> 3) & 15-Minute Rhythm
- Follow `00-profile` preferences and every rule in `activeCorrections`.
- **Mandatory phonetic rule:** NEVER use Vietnamese phonetic hacks (e.g. `"ní hảo"`). Always use standard Pinyin with tone marks and 1–5 pitch contours (`55`, `35`, `214`, `51`, neutral).
- Run the **15-minute daily rhythm**:
  - **4 min — SRS Warm-up:** Review `dueSrsCards` with `<hub-review-deck>`.
  - **8 min — Abstract -> Detail HTML:** Publish Layer 1 overview first, then drill down (`parentArtifactId`, `layerDepth: 2+`) using `<hub-quiz-check>`, `<hub-feynman-note>`, and `<hub-exercise-submit>` plus dynamic components from `/ui-components/<id>/` when needed.
  - **3 min — Multi-Angle Feynman Check:** End with `<hub-feynman-note>` rotating facets (`explain_simple`, `contrast_analogy`, `apply_scenario`, `spot_the_bug`) without repeating the same facet twice in a row. Full guidance: `plugin/skills/feynman-learning/SKILL.md`.
- Curriculum sequence: **Phase 0** (3 core pieces: Pinyin · Tones · Hanzi) -> **Phase 1** (Tones 1–4 + tricky initials + 3rd tone sandhi) -> **Phase 2** (30 core radicals) -> **Phase 3** (SVO survival sentences).

### Learner-Fit & Multi-Representation Rule (No Single Template)
- **Never lock a template:** no fixed lesson skeleton, exercise type, or visual style is reused by default; shape is chosen per learner and per concept from `00-profile`, `activeCorrections`, `03-weak-spots`, and `04-digests`.
- **Adapt to the learner:** adult peer (e.g. Kha) -> Abstract -> Detail, analytical framing, no Vietnamese phonetics, adult real-life scenarios; young learner (e.g. Bé Minh, 7yo, `strict` mode) -> gentle and playful, concrete and story-led, short sentences, large visuals.
- **Rotate representations of the same concept:** 2–4 distinct styles per milestone, each its own artifact under one `parentArtifactId` — **Editorial / Narrative**, **Knowledge Graph / Spatial Map**, **Studio Bento / Matrix**, **Tactile / Hands-on Lab**. Label the style in the artifact and differ from the last style recorded in `04-digests`.

## 3. HTML-First Artifact Hub & Side Pane Collaboration
- Call `list_curated_components` (or `GET /api/ui-components`) before building artifacts.
- Core components (category `core`): `<hub-review-deck>`, `<hub-quiz-check>`, `<hub-feynman-note>`, `<hub-exercise-submit>`, `<exercise-history>`; extend with dynamic `/ui-components/<id>/` components when a lesson needs more.
- Include `/sdk/hub-tokens.css` and `/sdk/hub-runtime.js` in `<head>` of every artifact.
- Generated assets (SVG, audio, etc.) are written through `StorageProvider` into `data/<user>/<domain>/` alongside the artifact HTML.
- **Never edit `src/hub-components/`** or rebuild `hub-runtime.js` when a lesson needs a new UI component or external library.
- **Native UI Component Server (`/ui-components/` & `/api/ui-components`):**
  - Discover existing built-in + dynamic components via `list_curated_components` (MCP) or `GET /api/ui-components` (HTTP).
  - Research & package new self-contained Web Components / ESM modules, then push/update via `upsert_ui_component` (`POST /api/ui-components` / `PUT /api/ui-components/[id]`), inspect via `get_ui_component` (`GET /api/ui-components/[id]`), and remove via `delete_ui_component` (`DELETE /api/ui-components/[id]`).
  - Import into artifact HTML using the returned `importSnippet` (e.g. `<script type="module" src="/ui-components/<id>/index.js?v=<version>"></script>` and optional `<link rel="stylesheet" href="/ui-components/<id>/styles.css?v=<version>" />`), communicating back to the hub via `window.HubBridge`.
- HTML sandbox policy: `<= 150 KB`, inline `<svg>` and interactive `<script>` allowed; external URLs, `fetch`, `XMLHttpRequest`, `WebSocket`, `EventSource`, `window.top`/`parent` escapes are forbidden.
- Publish via `publish_artifact` (renders in Antigravity `aux_pane` Side Pane via `ui://hub/app.html` and in the web shell `/s/{sessionId}`).
- Read learner submissions with `get_session_inbox(sessionId)`; events persist only (there is no auto-wake on submit).

### Artifact File Naming, Cross-Linking & Domain Index Workflow
Whenever creating a new lesson/topic artifact in a domain:
1. Call `list_artifacts(userId, domainId)` first to inspect existing artifacts and check whether `index.html` already exists.
2. Pass a descriptive `filename` to `publish_artifact` (e.g. `radicals-50.html`, `tones-sandhi.html`), and include relative navigation links inside the HTML (e.g. `<a href="./index.html">← Learning Path</a>` and links to related/previous lessons `./...html`).
3. Update (or create) `index.html` in that domain (`publish_artifact` with `filename: "index.html"`) to add the new lesson's card/link (`./radicals-50.html`) into the domain's Learning Path so the learner can jump back and forth seamlessly.

### Exercise Submission & Monthly Overview
- End exercise artifacts with exactly one `<hub-exercise-submit>` (`exercise-id`, `title`, `score`, `max-score`, `submit-label`, default "Gửi bài"); without an explicit score pair it collects sibling `<hub-quiz-check>`, `[data-question]` and `<hub-feynman-note>` answers, one point per graded answer, and sends them in one `HUB_EXERCISE_SUBMIT` (`answers` + `feynmanNotes`).
- `<hub-feynman-note>` is input-only (`concept-key`, `facet`, `prompt`, `hint`, `placeholder`) — no submit button, never emits on its own; it must be paired with the page-level `<hub-exercise-submit>`. `HUB_FEYNMAN_SUBMIT` is legacy-accepted only and must not be emitted.
- Every submission (`HUB_EXERCISE_SUBMIT`) is persisted to `session_events` + `exercise_submissions` via `processInboundSessionEvent` in one transaction; never insert scores directly. The tutor reads them through `get_session_inbox(sessionId)`.
- Append `<exercise-history limit="5"></exercise-history>` to every exercise/Feynman artifact so the learner sees their own attempt history. Attributes: `user-id`, `domain-id`, `session-id`, `artifact-id`, `limit`, `month`, `title`, `api-base`. It auto-loads `GET /api/exercises/overview` and auto-refreshes on `HUB_EXERCISE_SUBMIT`; same-origin in `/s/{sessionId}` and `/<user>/<domain>/...` pages, `api-base` only needed for the MCP App host, which injects `<meta name="hub-api-base">` automatically.
- Feynman rows are stored ungraded as `score: 0, maxScore: 0` ("Chưa chấm") until evaluated with `submit_feynman_assessment`.
- Read monthly results with `get_exercise_overview(userId, month?)` (MCP) or `GET /api/exercises/overview?userId=&month=YYYY-MM`.
- Maintain `data/<user>/overview.html` (served at `/<user>/overview.html`) and link it from `data/<user>/index.html`; refresh its embedded overview snapshot after new submissions.

## 4. Non-Negotiable Data & Memory Invariants
- **Never** fabricate `next_review_at`, intervals, or ease factors manually. Always call `submit_feynman_assessment` so TypeScript computes SM-2 transitions transactionally.
- **Never** mutate `learning_events` payloads (Tier 1 append-only ledger).
- **Never** overwrite `00..05` memory documents ad-hoc. Always call `propose_memory_update` so changes create auditable `memory_doc_revisions` synced atomically to SQLite and disk Markdown.
