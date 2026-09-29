# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Gemma Conversation Reviewer** — a single-file browser application for store staff to review and annotate AI shopping assistant (Gemma/Pandora) conversations. Users upload Excel files containing conversation logs, review each conversation with ratings/tags/notes, and export structured JSON results. Supports multi-reviewer merge and comparison.

Three versions exist:
- `Gemma Conversation Reviewer.html` — V1, legacy (2,949 lines)
- `Gemma Conversation Reviewer V2.html` — intermediate version (if present)
- `Gemma Conversation Reviewer V3.html` — **current active version** (5,086 lines), adds analytics, Chart.js, priority flagging
- `local_conversation_viewer.html` — standalone utility for debugging individual conversation JSON locally

## Running & Development

No build system, package manager, tests, or linting. Open the HTML file directly in a browser. All dependencies load from CDN: `xlsx.js` (Excel parsing), `Chart.js` (analytics charts), Google Fonts (Montserrat).

## Architecture

Everything lives in a single HTML file with inline CSS (~1,900 lines) and JavaScript. No modules or bundling.

### Global State

```javascript
conversations = {}           // { convId: { id, date, turns, messages, ... } }
allConversations = []        // all parsed conversations
filteredConversations = []   // result of current filter/search
currentConversationId = null
reviews = {
    ratings: {},             // convId -> 1–5
    relevance: {},           // convId -> yes/partial/no
    textQuality: {},         // convId -> good/acceptable/poor
    suggestions: {},         // convId -> [productIds]
    notes: {},
    pmNotes: {},             // password-protected (pandora2026)
    flags: {},               // convId -> [messageIndexes]
    tags: {},                // convId -> [tag-ids]
    priorityConvIds: [],
    avgRating: null          // overall reviewer rating, set at export
}
productCache = {}            // cached Pandora API product metadata
CONFIG = { ... }             // API URLs, PM password, client ID
```

### Key Subsystems

**File Handling** — `handleFileSelect` → `processData`. Excel parsed via XLSX.js; finds header row containing "External Record Id". Agent responses are JSON inside markdown code blocks, parsed to extract `conversationAnswer`, `followup`, `productIds`, `productDetail`.

**Tag System** — 12 tags across 3 categories:
- *Recommendations*: wrong-match, partial-match, good-match, excellent-match
- *Response Quality*: poor-response, needs-improvement, good-response, excellent-response
- *Intent Recognition*: wrong-intent, partially-accurate, mostly-accurate, accurate-intent

**Validation Rules** (enforced at export via `validateExport`; real-time via `checkCurrentConversationValidation`):
- Rating ≤3 → notes required
- `wrong-match` or `partial-match` tags → product suggestions + notes required
- `needs-improvement` tag → notes required
- Rating 5 + "Not Relevant" relevance → warning (non-blocking)

**Auto-Save** — `startAutoSave()` sets a 30-second interval writing `reviews` to localStorage (`gemma-reviews-autosave`). On reload, prompts recovery if saved conversation IDs match currently loaded data.

**Export/Import** — `exportAnnotations()` validates, prompts for overall average rating, then downloads JSON. `loadAnnotations()` restores a previous export to continue reviewing.

**Merge/Compare** — `loadMergedReviews()` accepts multiple reviewer JSONs, color-codes by reviewer, flags 2+ star disagreements. `buildAnalytics()` produces distribution charts and agreement metrics (V3).

**Product Integration** — `createProductImages(productIds)` renders cards; `updateProductCard()` fetches metadata from Pandora API and caches in `productCache`. Failures degrade silently (images just don't appear).

**Analytics** (V3) — `showAnalyticsModal()` → `buildAnalytics()`: rating distributions, tag usage, inter-rater agreement, problems table. Uses Chart.js.

### CSS Variables (theming)

```css
--pink: #FF93A0      /* primary actions, progress */
--purple: #BB568C    /* secondary, active states */
--brown: #3C291D     /* header, text */
--red: #E73126       /* errors, warnings, mandatory fields */
```

## Conventions

- All state changes trigger corresponding display update functions (unidirectional flow).
- Modals are created dynamically in JS (password dialog, export confirmation, merge analysis) — no pre-defined HTML.
- Product details fetched async without blocking render; export succeeds regardless of product load state.
- Flags are stored as message array indices — fragile if message order changes, but conversations are static.
- When adding a new tag: update `TAG_DEFINITIONS`, add tag button HTML, update validation rules if the tag has conditional requirements.
- `V2_CHANGES.md` documents historical feature additions; `gemma-reviewer-guide.txt` is the staff user guide.
