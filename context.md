## Continuation Context

This file is meant to make continuing tomorrow easy, even if the previous chat is gone.

## Core Intent Behind The Work

The original product goal was not just “semantic search for registry items”.

The goal was:

1. The user gives a natural language prompt about their registry.
2. The prompt can include things like:
   - budget
   - people
   - vibe
   - event type
   - what they already have
   - what they do not want
3. The system should return **two outputs**:
   - a list of **browsable relevant products**
   - a **full curated kit/plan** that is already decided for them
4. The planning layer should not behave like plain cosine similarity ranking plus greedy budget picking.
5. It should understand essentials and avoid missing critical categories for a use case.

The key reasoning was:

- Pure vector similarity is good for relevance.
- Pure greedy budget selection is good for staying under budget.
- But those two alone are **not enough** to build a smart registry plan.
- Without an additional planning layer, the system may select only items that score well semantically and happen to fit budget, while still missing essential kit pieces.

That is exactly why the later planning improvements were added.

## The Prompt That Led Here

This is the exact idea that drove the work:

> when i give a prompt about my registry with things like budget , people , vibe and stuff it should first provide me a list of all browsable products, and also a full kit decided already with use of vector embeddings but also a planning layer tht doesnt let me miss any essential stuff because with cosine similarity and greedy picking i'll only pick essentials matching the embedding score and in budget not actually having smart planning but laater it was added by you, and other changes to make this happen were done but ui wiring and integraation wasnt done as members are changing ui

That statement is the most important context for continuing work.

## What Was Built To Support That Goal

The implementation evolved in two stages.

### Stage 1: On-device AI planner foundation

This shipped in commit:
- `9c4b20b`
- `feat: Add on-device AI registry planner`

That stage added:

1. On-device vector embeddings using Apple `NaturalLanguage` / `NLEmbedding`
2. Product indexing
3. Prompt embedding and cosine similarity search
4. Budget parsing
5. Basic greedy budget-aware plan building
6. New planner UI
7. Registry entry point to launch planner

This stage made the feature real, but still relatively simple in planning intelligence.

### Stage 2: Smarter planning refinement

This was later committed in:
- `bedfac4`
- `feat: improve registry planner matching and guidance`

That stage added or refined:

1. richer product metadata
2. richer embeddable product descriptions
3. event detection
4. style detection
5. ownership detection
6. exclusion detection
7. event templates with required and optional slots
8. slot-aware candidate selection
9. affordability and relevance re-ranking
10. conversation state structures
11. a `RegistryPlannerService` abstraction
12. detailed handoff documentation in `summary.md`

This second stage is the part that moved the feature from:

- “AI product matcher”

to:

- “AI registry planner with a planning layer”

## Important Product Design Distinction

The desired output is conceptually **two-tiered**:

### 1. Browsable products

This is the semantic search output.

Purpose:
- show the user relevant items matching the prompt
- allow exploration
- let the user browse what the system found

This should come from vector similarity results, filtered and possibly lightly ranked.

### 2. Planned kit / curated registry bundle

This is the planning output.

Purpose:
- make decisions for the user
- ensure essential categories are covered
- produce a coherent set under the budget
- avoid obvious gaps

This should come from a planning layer that uses:

- event type
- slot requirements
- exclusions
- ownership
- style hints
- affordability
- semantic relevance

This distinction matters because tomorrow someone may try to simplify it back into “just ranking products”.

That would lose the main product intent.

## What The Current Architecture Contains

### Data and indexing

Files involved:
- `ws-hackathon-app-release/WSHackathonApp/Features/Home/ProductItemDTO.swift`
- `ws-hackathon-app-release/WSHackathonApp/Features/Home/ProductItem.swift`
- `ws-hackathon-app-release/WSHackathonApp/Core/AI/ProductItem+Embedding.swift`
- `ws-hackathon-app-release/WSHackathonApp/Core/AI/ProductVectorStore.swift`
- `hackathon-mock-api-ios/mock-api/responses/skus.json`

What this layer does:
- expands the catalog schema
- stores richer structured product metadata
- synthesizes human-like text to embed
- builds an in-memory vector index

Why it matters:
- this is the retrieval quality layer
- without rich metadata, the planner quality drops

### Intent extraction

Files involved:
- `ws-hackathon-app-release/WSHackathonApp/Core/AI/PromptParser.swift`
- `ws-hackathon-app-release/WSHackathonApp/Core/AI/ScoredProduct.swift`

What this layer does:
- extracts budget
- extracts event type
- extracts style hints
- extracts owned keywords
- extracts excluded keywords
- stores conversation state structures

Why it matters:
- this is the bridge between free-form text and structured planning inputs

### Planning layer

Files involved:
- `ws-hackathon-app-release/WSHackathonApp/Core/AI/RegistryPlanBuilder.swift`
- `ws-hackathon-app-release/WSHackathonApp/Core/AI/RegistryPlannerService.swift`

What this layer does:
- defines required and optional slots per event template
- filters products user already has or excludes
- tries to fill essential slots first
- then optional slots
- then remaining general items under budget
- tracks missing essentials
- tracks coverage score
- tracks essentials vs optional spend

Why it matters:
- this is the part added specifically to solve the “cosine similarity plus greedy pick is not enough” problem

### UI layer

Files involved:
- `ws-hackathon-app-release/WSHackathonApp/Features/Registry/RegistryView.swift`
- `ws-hackathon-app-release/WSHackathonApp/Features/RegistryPlanner/RegistryPlannerView.swift`
- `ws-hackathon-app-release/WSHackathonApp/Features/RegistryPlanner/RegistryPlannerViewModel.swift`
- `ws-hackathon-app-release/WSHackathonApp/Features/RegistryPlanner/RegistryPlanResultView.swift`

What this layer currently does:
- lets user type a prompt
- builds the vector index
- runs search
- displays curated results
- adds items to registry

## The Most Important Current Limitation

The smarter architecture was added, but **full UI wiring/integration is not complete**.

This is especially important because the UI is being changed by teammates.

Right now:

- the planner UI exists
- the vector search exists
- the smarter planning logic exists
- the service abstraction exists

But:

- the UI is not fully wired to expose the full “browsable products + planned kit” split cleanly
- `RegistryPlannerService` is not yet the central integrated path used by the planner UI
- the UI may still be using the older direct flow through `ProductVectorStore`, `PromptParser`, and `RegistryPlanBuilder`

So if work continues tomorrow, the likely engineering task is not inventing the planning logic from scratch.

The likely task is:

1. preserve the already-built planning logic
2. integrate it cleanly with the UI that teammates are changing
3. expose both browse results and final planned kit in the UX

## What Must Not Be Lost In Future Work

If someone continues this work, they should preserve these principles:

1. The feature is not just a search bar.
2. Retrieval and planning are separate responsibilities.
3. Vector embeddings solve relevance, not completeness.
4. Registry planning needs event-aware essential coverage.
5. Budget handling should not break essential kit reasoning.
6. Ownership and exclusion handling are product requirements, not nice-to-haves.
7. Rich catalog metadata is core infrastructure for planner quality.

## If You Need To Explain The Change In One Paragraph

The app was upgraded from a normal catalog/registry flow into an on-device AI registry planner. The first phase introduced semantic product retrieval using Apple embeddings and a planner UI. The second phase improved the logic so it no longer depends only on cosine similarity and greedy budget selection; it now has a planning layer that uses event templates, required slots, exclusions, ownership, style signals, and richer product metadata to produce a more complete registry kit instead of just a ranked list.

## If You Forget What Was Done, Read These First

1. `summary.md`
2. `context.md`
3. `ws-hackathon-app-release/WSHackathonApp/Core/AI/RegistryPlannerService.swift`
4. `ws-hackathon-app-release/WSHackathonApp/Core/AI/RegistryPlanBuilder.swift`
5. `ws-hackathon-app-release/WSHackathonApp/Core/AI/PromptParser.swift`
6. `ws-hackathon-app-release/WSHackathonApp/Core/AI/ProductItem+Embedding.swift`
7. `ws-hackathon-app-release/WSHackathonApp/Features/RegistryPlanner/RegistryPlannerViewModel.swift`

## Reusable Prompt For Tomorrow

If you need to ask another assistant to continue from here, use something close to this:

> Read `summary.md` and `context.md` first. This project has an on-device AI registry planner built on Apple NaturalLanguage sentence embeddings. The original intent is not only to return semantically similar products, but to produce two outputs from a free-text registry prompt: a browsable list of relevant products and a curated full registry kit that does not miss essentials. A smarter planning layer was added after the initial vector-search implementation because cosine similarity plus greedy budget picking was not enough. That planning layer now includes event-aware templates, required and optional slots, ownership/exclusion handling, style hints, affordability-aware scoring, richer SKU metadata, and a `RegistryPlannerService`, but the UI wiring and integration are not fully complete because teammates are changing the UI. Analyze the current code deeply, preserve the planning architecture, and help integrate the browse-results output and the planned-kit output cleanly into the current UI without regressing the planner quality.

## Demo/Discussion Framing

If someone asks what changed, the best short answer is:

- We first added an on-device embedding-based registry planner.
- Then we improved it with an actual planning layer so it can build a more complete registry kit instead of only ranking products by semantic similarity.
- The remaining work is mainly integration and presentation, not inventing the planner logic.

## Final Note

If tomorrow feels confusing, the safest mental model is:

- `ProductVectorStore` answers: “what products are relevant?”
- `PromptParser` answers: “what did the user mean?”
- `RegistryPlanBuilder` / `RegistryPlannerService` answer: “what should the final registry plan actually contain?”
- UI integration answers: “how do we show both browse results and the decided kit clearly?”

That is the whole story in one line:

**relevance retrieval was added first, smart planning was added after, and clean UI integration is the next likely step.**
