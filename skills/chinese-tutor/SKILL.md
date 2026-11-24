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

## Step 2: Prepare Visual Assets & Curated Components
1. Call `list_curated_components({ category: "all" })` to inspect exact `<hub-*>` attributes and copy the canonical `<head>` snippet:
   ```html
   <link rel="stylesheet" href="/sdk/hub-tokens.css" />
   <script type="module" src="/sdk/hub-runtime.js"></script>
   ```
2. Call `search_assets({ userId, domainId: "chinese", query })` to find age-appropriate curated SVGs (e.g. `/curated-assets/chinese/tones-4-contour.svg`, `radical-kou.svg`, `radical-shi.svg`) and verified facts.
3. Respect `user.age` HTML policy:
   - `age < 10`: strict mode (`<= 40 KB`, NO inline `<script>` code bodies, NO `on*` attributes).
   - `age >= 10`: full mode (`<= 150 KB`, inline SVG and `<script>` permitted; NEVER use `fetch`, `XMLHttpRequest`, `WebSocket`, `EventSource`, or external CDNs).

## Step 3: Execute the 15-Minute Daily Rhythm

### Block A — 4-Minute SRS Warm-Up
- If `dueSrsCards.length > 0`, start Layer 1 with `<hub-review-deck>` pre-populated with due cards (Hanzi, Pinyin, tone, Vietnamese meaning, brief hint).
- Let the learner grade recall (`0..3`); the MCP App automatically persists `HUB_LOG_REVIEW` into `srs_cards` and `learning_events`.

### Block B — 8-Minute Abstract -> Detail HTML Artifact
- **Layer 1 (Abstract Overview):** Keep it crisp and visual — show the big-picture mental model (e.g., 3 core pieces in Phase 0, or 4 tone contours `55 / 35 / 214 / 51`), embed curated SVG diagrams, add `<hub-audio-phrase>` for listening at `0.7x` / `1.0x`, and include `<hub-choice-board>` + `<hub-send-back-bar>` so the learner chooses what to drill deeper.
- **Layer 2+ (Targeted Detail):** When the learner submits choices or asks a question:
  1. Call `get_session_inbox(sessionId)` to consume pending events cleanly.
  2. Publish a focused drill-down artifact (`parentArtifactId`, `layerDepth: 2` or `3`) using `<hub-hanzi-breakdown>`, `<hub-audio-phrase>`, and `<hub-quiz-check>`.
- Note on collaboration:
  - When the learner is using the Antigravity Side Pane (`aux_pane`), `HUB_SELECTION_SUBMIT` / `HUB_FEYNMAN_SUBMIT` automatically triggers a chat message to wake you.
  - When collaborating via the browser shell (`/s/{sessionId}`), run `node scripts/wait-session-event.mjs --session=<sessionId>` if waiting for the next UI submission, then call `get_session_inbox(sessionId)`.

### Block C — 3-Minute Multi-Angle Feynman Check
- Close the session with `<hub-feynman-note>` using one of the 4 facets (rotate across sessions):
  - `explain_simple`: explain the concept plainly in Vietnamese without jargon
  - `contrast_analogy`: compare Mandarin pitch/structure with Vietnamese (e.g. tone 3 `214` vs dấu hỏi)
  - `apply_scenario`: construct a real ordering/greeting phrase using today's words
  - `spot_the_bug`: diagnose an intentional Pinyin/tone/radical error
- Wait for the learner's response (`get_session_inbox`), give constructive adult-peer feedback, and evaluate using the 0–3 rubric:
  - `0`: fundamental misconception or blank
  - `1`: remembers fragment, mixes up tones/roles
  - `2`: clear explanation with accurate example
  - `3`: fluent, intuitive transfer across examples

## Step 4: Record Assessment & Wrap Up
1. Call `submit_feynman_assessment` with `userId`, `domainId`, `conceptKey`, `sessionId`, `artifactId`, `feynmanFacet`, `feynmanRaw`, `feynmanScore` (`0..3`), and `misconceptionNote` (if score `< 2`). Never calculate `next_review_at` manually.
2. Mark the final Layer summary artifact `isFinal: true` when wrapping up a milestone so it appears cleanly in the learner's session archive.
3. If `unconsolidatedCount >= 3` or a milestone finished, suggest or run the `memory-consolidator` workflow.

## Curriculum Reference (Phase 0 -> 3)
- **Phase 0 (Day 1 Overview):** 3 pieces of Chinese — Pinyin (Latin sound notation), 4+1 Tones (pitch changes meaning: `mā · má · mǎ · mà`), Hanzi (meaning + phonetic radicals, not an alphabet).
- **Phase 1 (Weeks 1–2):** 4 main tones (`55`, `35`, `214`, `51`) + neutral tone, minimal pairs tricky for Vietnamese speakers (`zh/ch/sh`, `j/q/x`, `b/p`, `z/c/s`), 3rd-tone sandhi (`nǐ hǎo`).
- **Phase 2 (Weeks 3–4):** 30 high-frequency radicals (`日, 月, 水/氵, 火/灬, 木, 人/亻, 口, 饣/食, 女, 子, 好`, etc.).
- **Phase 3 (Month 2+):** SVO survival frames (`是, 有, 想, 要, 吃, 喝, 吗, 不`) and 4-turn dialogues for ordering food, prices, and introductions.
