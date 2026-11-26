---
name: chinese-tutor
description: Teach Mandarin Chinese from absolute zero (Phase 0 to Phase 3) using the 15-minute daily rhythm, HTML-First Learning Hub artifacts, SM-2 spaced repetition, and multi-angle Feynman assessment.
---

# Chinese Tutor Runbook (Phase 0 -> 3)

## Step 1: Bootstrap Context & Active Rules
1. Call `list_users` to confirm the target learner (`userId`, e.g., `"kha"`, `age`).
2. Call `list_domains(userId)` to verify `"chinese"` (`dom-kha-zh`).
3. Call `get_domain_context(userId, "chinese")` to load:
   - `00-profile` (preferences, addressing style, 15m/day cadence)
   - `01-roadmap` (Phase 0 -> 3 progress)
   - `03-weak-spots` (active misconceptions)
   - `04-digests` (recent session recaps)
   - `dueSrsCards` (concepts ready for review today)
   - `activeCorrections` (mandatory rules — **never** use Vietnamese phonetic hacks like `"ní hảo"`)
   - `recentSessions` (resume active session or start a new one)

## Step 2: Prepare Components
1. Call `list_curated_components({ category: "all" })` (or `GET /api/ui-components`) to inspect exact `<hub-*>` + dynamic component attributes and copy the canonical `<head>` snippet:
   ```html
   <link rel="stylesheet" href="/sdk/hub-tokens.css" />
   <script type="module" src="/sdk/hub-runtime.js"></script>
   ```
2. **Dynamic UI Components (`/ui-components/` & `/api/ui-components`):**
   - **Rule: Never edit `src/hub-components/`** or rebuild `hub-runtime.js` when a lesson needs a new UI component or external library.
   - Research and package new self-contained Web Components / ESM modules, then:
     - Push or update via MCP `upsert_ui_component` (or `POST /api/ui-components` / `PUT /api/ui-components/[id]`).
     - Inspect via `get_ui_component` (`GET /api/ui-components/[id]`) and remove via `delete_ui_component` (`DELETE /api/ui-components/[id]`).
     - Import into artifact HTML using the returned `importSnippet` (e.g. `<script type="module" src="/ui-components/<id>/index.js?v=<version>"></script>` and optional `<link rel="stylesheet" href="/ui-components/<id>/styles.css?v=<version>" />`), communicating back to the hub via `window.HubBridge`.
3. HTML sandbox policy: unified `full` mode (`<= 150 KB`, inline SVG and `<script>` permitted; NEVER use `fetch`, `XMLHttpRequest`, `WebSocket`, `EventSource`, `window.top`/`parent` escapes, or untrusted external scripts).
4. **Artifact checklist:** end every exercise artifact with exactly one `<hub-exercise-submit>` — it collects `<hub-quiz-check>`, `[data-question]` and `<hub-feynman-note>` answers in one `HUB_EXERCISE_SUBMIT` — and append `<exercise-history limit="5">` so the learner sees their own attempt history (it auto-loads `/api/exercises/overview` and refreshes right after the POST commits). Lessons include `<hub-review-deck>` for due SRS cards, `<hub-quiz-check>` for active recall, and `<hub-feynman-note>` for the closing check.

Generated assets (SVG, audio, etc.) are written through `StorageProvider` into `data/<user>/<domain>/` alongside the artifact HTML.

**Live origin (canonical, never `localhost`):** `https://hub.zinvest.trade` — session shell `https://hub.zinvest.trade/s/{sessionId}`, artifact `https://hub.zinvest.trade/<user>/<domain>/<file>` (e.g. `.../kha/chinese/radicals-50.html`), overview `.../<user>/overview.html`, APIs `.../api/...`, remote MCP `https://hub.zinvest.trade/mcp` (Streamable HTTP, bearer token from host env — never paste the token anywhere). Keep links inside artifact HTML relative; use absolute URLs only in chat and external sharing.

## Learner-Fit & Multi-Representation Rule (No Single Template)
Lesson shape is chosen per learner and per concept. Never reuse one fixed layout, exercise format, or tone by default.
1. **Never lock a template.** No default lesson skeleton, exercise type, or visual style carries over unexamined between sessions or concepts.
2. **Fit the learner first.** Design from `00-profile`, `activeCorrections`, `03-weak-spots`, and `04-digests`; content, tone, and examples follow that learner, not a generic audience.
   - Adult peer learner (e.g. Kha): Abstract -> Detail, analytical framing, no Vietnamese phonetic hacks, adult real-life scenarios.
   - Young learner (e.g. Bé Minh, 7yo, `strict` HTML mode): gentle and playful, story/concrete-first, short sentences, large visuals, no IPA or pitch-contour dumps.
3. **Rotate representations of the same concept.** For a key lesson or concept, produce multiple distinct styles over the arc — same facts, different angle. Use 2–4 per milestone, each as its own artifact linked back with `parentArtifactId`:
   - **Editorial / Narrative** — prose, story-led, typographic hierarchy.
   - **Knowledge Graph / Spatial Map** — nodes and edges, radicals and compounds as a map.
   - **Studio Bento / Matrix** — comparable tiles side by side (tones, minimal pairs).
   - **Tactile / Hands-on Lab** — sort, drag, quiz, audio drill; the learner manipulates the material.
4. **Name the style in the artifact** (e.g. subtitle `Spatial Map`) and check `04-digests` so the next session rotates away from the last style used.

## Step 3: Execute the 15-Minute Daily Rhythm

### Block A — 4-Minute SRS Warm-Up
- If `dueSrsCards.length > 0`, start Layer 1 with `<hub-review-deck>` pre-populated with due cards (Hanzi, Pinyin, tone, Vietnamese meaning, brief hint).
- Let the learner grade recall (`0..3`); the MCP App automatically persists `HUB_LOG_REVIEW` into `srs_cards` and `learning_events`.

### Block B — 8-Minute Abstract -> Detail HTML Artifact
- **Layer 1 (Abstract Overview):** Keep it crisp and visual — show the big-picture mental model (e.g., 3 core pieces in Phase 0, or 4 tone contours `55 / 35 / 214 / 51`), embed generated SVG diagrams, add a `howler`-based audio player (`/ui-components/howler/`) for listening at `0.7x` / `1.0x`, then let the learner ask what to drill deeper.
- **Layer 2+ (Targeted Detail):** When the learner submits an exercise or asks a question:
  1. Call `get_session_inbox(sessionId)` to consume pending events cleanly.
  2. Publish a focused drill-down artifact (`parentArtifactId`, `layerDepth: 2` or `3`) using `<hub-quiz-check>` plus dynamic components from `/ui-components/` (e.g. `hanzi-writer` for stroke order, `howler` for audio).
- End every exercise artifact with `<hub-exercise-submit>` plus `<exercise-history limit="5">` so `HUB_EXERCISE_SUBMIT` persists the result and the learner sees their attempt history.
- Note on collaboration:
  - Every submission (`HUB_EXERCISE_SUBMIT`, including the `feynmanNotes` collected by `<hub-exercise-submit>`) is persisted to `session_events` + `exercise_submissions`; it does **not** wake the agent.
  - Read pending events explicitly with `get_session_inbox(sessionId)` in both the Antigravity Side Pane (`aux_pane`) and the browser shell (`/s/{sessionId}`).

### Artifact File Naming, Cross-Linking & Domain Index Workflow
Whenever creating a new lesson/topic artifact in a domain:
1. Call `list_artifacts(userId, domainId)` first to inspect existing artifacts and check whether `index.html` already exists.
2. Pass a descriptive `filename` to `publish_artifact` (e.g. `radicals-50.html`, `tones-sandhi.html`), and include relative navigation links inside the HTML (e.g. `<a href="./index.html">← Learning Path</a>` and links to related/previous lessons `./...html`).
3. Update (or create) `index.html` in that domain (`publish_artifact` with `filename: "index.html"`) to add the new lesson's card/link (`./radicals-50.html`) into the domain's Learning Path so the learner can jump back and forth seamlessly.

### Block C — 3-Minute Multi-Angle Feynman Check
- Close the session with `<hub-feynman-note>` using one of the 4 facets; never repeat the same facet twice in a row (rotate across sessions):
  - `explain_simple`: explain the concept plainly in Vietnamese without jargon
  - `contrast_analogy`: compare Mandarin pitch/structure with Vietnamese (e.g. tone 3 `214` vs dấu hỏi)
  - `apply_scenario`: construct a real ordering/greeting phrase using today's words
  - `spot_the_bug`: diagnose an intentional Pinyin/tone/radical error
- Full Feynman + Spaced Repetition / Active Recall / Interleaving guidance: `plugin/skills/feynman-learning/SKILL.md`.
- `<hub-feynman-note>` only collects input; the page-level `<hub-exercise-submit>` sends it inside `HUB_EXERCISE_SUBMIT` as `feynmanNotes`. Wait for the learner's response (`get_session_inbox`), give constructive adult-peer feedback, and evaluate using the 0–3 rubric:
  - `0`: fundamental misconception or blank
  - `1`: remembers fragment, mixes up tones/roles
  - `2`: clear explanation with accurate example
  - `3`: fluent, intuitive transfer across examples

## Step 4: Record Assessment & Wrap Up
1. Call `submit_feynman_assessment` with `userId`, `domainId`, `conceptKey`, `sessionId`, `artifactId`, `feynmanFacet`, `feynmanRaw`, `feynmanScore` (`0..3`), and `misconceptionNote` (if score `< 2`). Never calculate `next_review_at` manually.
2. Mark the final Layer summary artifact `isFinal: true` when wrapping up a milestone so it appears cleanly in the learner's session archive.
3. If `unconsolidatedCount >= 3` or a milestone finished, suggest or run the `memory-consolidator` workflow.
4. When the learner asks for progress, call `get_exercise_overview(userId, month?)` and regenerate `data/<user>/overview.html` (linked from `data/<user>/index.html`, served at `/<user>/overview.html`) with the refreshed snapshot.

## Curriculum Reference (Phase 0 -> 3)
- **Phase 0 (Day 1 Overview):** 3 pieces of Chinese — Pinyin (Latin sound notation), 4+1 Tones (pitch changes meaning: `mā · má · mǎ · mà`), Hanzi (meaning + phonetic radicals, not an alphabet).
- **Phase 1 (Weeks 1–2):** 4 main tones (`55`, `35`, `214`, `51`) + neutral tone, minimal pairs tricky for Vietnamese speakers (`zh/ch/sh`, `j/q/x`, `b/p`, `z/c/s`), 3rd-tone sandhi (`nǐ hǎo`).
- **Phase 2 (Weeks 3–4):** 30 high-frequency radicals (`日, 月, 水/氵, 火/灬, 木, 人/亻, 口, 饣/食, 女, 子, 好`, etc.).
- **Phase 3 (Month 2+):** SVO survival frames (`是, 有, 想, 要, 吃, 喝, 吗, 不`) and 4-turn dialogues for ordering food, prices, and introductions.
