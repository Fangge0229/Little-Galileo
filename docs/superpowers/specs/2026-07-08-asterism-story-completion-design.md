# Asterism Story Completion Design

## Goal

Ensure every Chinese asterism in `LittleGalileo/LittleGalileo/chinese_asterisms.json` has useful display material, with no user-facing "暂无故事" or "暂无科学知识" states.

## Current State

- `chinese_asterisms.json` contains 310 Chinese asterisms.
- 8 asterisms currently have `brief`, `story`, and `science`.
- 302 asterisms lack `story`; 35 of those are featured asterisms.
- The UI currently labels the back side section as "神话故事", which is too narrow because many star officials have cultural, institutional, ritual, or astronomical meanings rather than independent myths.

## Accuracy Standard

Do not invent myths. For each asterism:

- If there is a well-attested myth, folklore, or literary tradition, summarize it as a story.
- If there is no reliable independent myth, provide a cultural explanation: what the asterism represents in the traditional sky system, which enclosure or mansion context it belongs to when inferable, and what ancient social, ritual, military, market, agricultural, or courtly idea its name evokes.
- Avoid saying or implying that a cultural explanation is a myth.
- Use short, child-friendly Chinese prose, but keep claims conservative.

## Data Model

Keep existing fields:

- `brief`: one sentence for card front and recommendations.
- `story`: the main "星官故事" text; may be myth, folklore, or cultural explanation.
- `science`: observational or astronomy context in simple language.
- `difficulty`: integer 1-3.
- `best_season`: short Chinese season label when known or "全年可见".

Add optional maintenance fields that Swift `Codable` will ignore unless explicitly modeled later:

- `storyType`: one of `myth`, `folklore`, `cultural`, `astronomical`.
- `sourceNotes`: short source/category note for future review.

## Source Strategy

Use a layered source basis:

- Existing app stories for the 8 already-written featured asterisms.
- `d3-celestial` Chinese asterism names and line data already used by the project.
- Traditional Chinese asterism organization: three enclosures, twenty-eight mansions, four symbols, and near-south-pole additions.
- Public reference material such as the Chinese asterism and Chinese-Western star-name correspondence pages for names, grouping, and broad historical framing.
- Classical framing from `史记·天官书`, `晋书·天文志`, and `步天歌` where relevant, summarized conservatively rather than quoted at length.

## Implementation Shape

Create a repeatable enrichment script rather than hand-editing the JSON:

- Read `chinese_asterisms.json`.
- Preserve all existing star positions, IDs, names, lines, stories, and scientific details.
- For each item missing material, generate deterministic text from curated templates and curated special-case entries.
- Assign `storyType` and `sourceNotes`.
- Write the enriched JSON back with stable formatting.
- Add tests that fail if any asterism lacks non-empty `brief`, `story`, `science`, `storyType`, or `sourceNotes`.

## UI Copy

Change the detail card section title from "神话故事" to "星官故事". This matches the verified content standard and avoids labeling cultural explanations as myths.

## Verification

The work is complete only when:

- Every asterism in `chinese_asterisms.json` has non-empty `brief`, `story`, and `science`.
- Every asterism has `storyType` and `sourceNotes`.
- Existing 8 handcrafted stories are preserved.
- `xcodebuild build` succeeds.
- Tests or a script-level validation prove there are zero missing story fields.
