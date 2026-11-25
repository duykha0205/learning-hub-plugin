---
name: memory-consolidator
description: Consolidate unconsolidated Tier 1 learning_events into Tier 2/3 modular Markdown memory documents (00..05) using auditable compress, correct, prune, and promote transformations.
---

# Memory Consolidator Runbook

## Core Invariants (Must Never Be Violated)
1. **Tier 1 (`learning_events`) is strictly append-only.** Never edit or delete `feynman_raw`, `feynman_score`, `misconception_note`, or timestamps. Consolidation ONLY marks `consolidated_at` via `propose_memory_update(..., consumedEventIds)`.
2. **All Tier 2 (`00..05`) changes go through `propose_memory_update`** so Tier 3 `memory_doc_revisions` keeps full `previous_content_md` / `next_content_md` diffs and stays rollback-safe (`apply` / `rollback`).
3. **Never cross-pollinate domains or users.** Process one `(userId, domainId)` pair at a time.

## Step 1: Load Unconsolidated Events & Current Memory Docs
1. Call `list_users` and `list_domains(userId)` if `userId`/`domainId` are not yet confirmed.
2. Call `get_unconsolidated_events({ userId, domainId, limit: 100 })` to inspect chronological Tier 1 `events` (`consolidatedAt === null`) alongside all existing `00..05` `documents`.
3. Call `get_domain_context(userId, domainId)` to also check `dueSrsCards` (`intervalDays`, `repetitions`, `lastFeynmanScore`), `activeCorrections`, and `recentSessions`.
4. If `02-knowledge` or `05-feynman-vault` were not yet inspected with full revision history, call `read_memory_doc`.
5. If `events.length === 0`, report that no unconsolidated events remain and exit cleanly without creating no-op revisions.

## Step 2: Classify & Synthesize 4 Memory Transformations

### 1. `compress` -> `04-digests` (and `01-roadmap`)
- Summarize recent unconsolidated sessions/events into concise dated bullets in `04-recent-digests.md`.
- Keep only the most recent 5–7 detailed session digests at the top; compress older entries into a compact rolling summary so `04-digests` stays crisp for selective context loading.
- Update checkbox states (`[ ]` -> `[~]` -> `[x]`) in `01-curriculum-roadmap.md` when milestones progress.

### 2. `correct` -> `03-weak-spots` (and `00-profile`)
- Inspect events where `feynmanScore <= 1`, `isCorrect === false`, or `misconceptionNote` is non-empty.
- Add or sharpen actionable weak-spot entries in `03-weak-spots.md` with concrete examples and root cause (e.g., mistaking Mandarin tone 3 `214` for Vietnamese dấu hỏi).
- If new learner preferences or corrections emerged, update `00-learner-profile.md` cleanly.

### 3. `prune` -> `03-weak-spots`
- Check which existing items in `03-weak-spots.md` have now been answered accurately (`feynmanScore >= 2` or `isCorrect === true`) across **>= 3 consecutive reviews spanning multiple days**.
- Remove resolved weak spots from `03-weak-spots.md` and note what was cleared in `diffSummary` so weak spots don't clutter future context windows.

### 4. `promote` -> `02-knowledge` and `05-feynman-vault`
- **Promote to `02-knowledge-map.md`:** Concepts whose SRS card meets **both** graduation criteria:
  - `intervalDays >= 21`
  - `lastFeynmanScore >= 2` (or verified multi-angle Feynman score `>= 2`)
  Record concept key, core insight, and graduation date in `02-knowledge-map.md` and mark `[x]` in `01-roadmap`.
- **Promote to `05-feynman-vault.md`:** Any event with `feynmanScore === 3` and rich `feynmanRaw` explanation — preserve the learner's best plain-language explanation/analogy under its concept and `feynmanFacet`.

## Step 3: Propose / Apply Revisions & Mark Consumed Events
1. Decide `autoApply`:
   - If running as an autonomous periodic sweep where low-risk digests/promotions should take effect immediately (or user asked to apply), set `autoApply: true` (revisions remain rollback-safe in `memory_doc_revisions`).
   - If user asked to review proposed memory edits first, set `autoApply: false` so proposals remain pending in `memory_doc_revisions` for review/apply via `POST /api/memory/revisions/[revisionId]` with `{ "action": "apply" }`.
2. Call `propose_memory_update` once per modified `docKey` (`00-profile` .. `05-feynman-vault`) with:
   - `transformType`: `"compress"` | `"correct"` | `"prune"` | `"promote"`
   - `diffSummary`: clear 1-sentence Vietnamese/English summary of what changed and why
   - `newContentMd`: complete updated Markdown document
   - `consumedEventIds`: attach the processed `learning_events` IDs (typically on the primary digest/consolidation revision when `autoApply: true` so they are atomically marked `consolidatedAt`).
3. Present a clear summary of:
   - Number of `learning_events` consolidated
   - Each `docKey` updated, its `transformType`, revision version, and `diffSummary`
   - Any remaining weak spots or next recommended focus area.
