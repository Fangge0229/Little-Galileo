# Asterism Story Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fill every Chinese asterism with accurate, conservative display material and remove user-facing "暂无故事" states.

**Architecture:** Add a deterministic enrichment script that preserves existing astronomy data and handwritten stories, fills missing content from curated classifications/templates, and writes stable JSON. Add validation coverage so missing story fields cannot return unnoticed. Update UI copy from "神话故事" to "星官故事".

**Tech Stack:** Python 3 for JSON enrichment/validation; SwiftUI for detail-card copy; Swift Testing/XCTest project build for verification.

---

## File Structure

- Create: `tools/enrich_chinese_asterism_stories.py`
  - Reads `LittleGalileo/chinese_asterisms.json`.
  - Preserves existing handcrafted content.
  - Adds missing `brief`, `story`, `science`, `difficulty`, `best_season`, `storyType`, and `sourceNotes`.
  - Writes stable UTF-8 JSON.
- Create: `tools/validate_chinese_asterism_stories.py`
  - Fails if any asterism lacks required content fields.
  - Fails if any existing handcrafted story is accidentally removed.
- Modify: `LittleGalileo/chinese_asterisms.json`
  - Generated enriched data.
- Modify: `LittleGalileo/Views/CardDetailView.swift`
  - Rename section title from `神话故事` to `星官故事`.
- Modify: `LittleGalileoTests/LittleGalileoTests.swift`
  - Add a test that every loaded Chinese asterism has story material.

### Task 1: Add JSON Story Validator

**Files:**
- Create: `tools/validate_chinese_asterism_stories.py`

- [ ] **Step 1: Create the validator**

```python
#!/usr/bin/env python3
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_FILE = ROOT / "LittleGalileo" / "chinese_asterisms.json"
REQUIRED_FIELDS = ("brief", "story", "science", "storyType", "sourceNotes")
HANDCRAFTED_IDS = {
    "shenxiu",
    "jiaoxiu",
    "xinxiu",
    "beidou",
    "polaris",
    "altair",
    "sirius",
    "vega",
}

def main() -> int:
    data = json.loads(DATA_FILE.read_text(encoding="utf-8"))
    asterisms = data.get("asterisms", [])
    failures = []

    for item in asterisms:
        missing = [field for field in REQUIRED_FIELDS if not str(item.get(field, "")).strip()]
        if missing:
            failures.append(f"{item.get('id')} {item.get('name')}: missing {', '.join(missing)}")

    by_id = {item.get("id"): item for item in asterisms}
    for item_id in sorted(HANDCRAFTED_IDS):
        item = by_id.get(item_id)
        if item is None:
            failures.append(f"{item_id}: missing handcrafted asterism")
        elif item.get("storyType") not in {"myth", "folklore", "astronomical", "cultural"}:
            failures.append(f"{item_id} {item.get('name')}: invalid storyType")

    if failures:
        print("Chinese asterism story validation failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(f"Validated {len(asterisms)} Chinese asterism story records")
    return 0

if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 2: Run validator and confirm current failure**

Run: `python3 tools/validate_chinese_asterism_stories.py`

Expected: FAIL, listing missing `brief`, `story`, `science`, `storyType`, and `sourceNotes` for many current records.

### Task 2: Add Deterministic Enrichment Script

**Files:**
- Create: `tools/enrich_chinese_asterism_stories.py`
- Modify: `LittleGalileo/chinese_asterisms.json`

- [ ] **Step 1: Create enrichment script**

Implement a Python script with these concrete units:

```python
def clean_base_name(name: str) -> str:
    return name.split("(")[0].split("（")[0]

def enclosure_context(name: str) -> str | None:
    if "紫微" in name:
        return "紫微垣象征天帝居处和中央宫廷"
    if "太微" in name:
        return "太微垣象征天廷政务和朝会"
    if "天市" in name:
        return "天市垣象征市场、城邑和交易秩序"
    return None

def mansion_context(name: str) -> str | None:
    mapping = {
        "角宿": "东方苍龙七宿之首",
        "亢宿": "东方苍龙的颈部",
        "氐宿": "东方苍龙的根基",
        "房宿": "东方苍龙的胸房",
        "心宿": "东方苍龙的心",
        "尾宿": "东方苍龙的尾",
        "箕宿": "东方苍龙的尾端",
        "斗宿": "北方玄武七宿之一",
        "牛宿": "北方玄武七宿之一",
        "女宿": "北方玄武七宿之一",
        "虚宿": "北方玄武七宿之一",
        "危宿": "北方玄武七宿之一",
        "室宿": "北方玄武七宿之一",
        "壁宿": "北方玄武七宿之一",
        "奎宿": "西方白虎七宿之一",
        "娄宿": "西方白虎七宿之一",
        "胃宿": "西方白虎七宿之一",
        "昴宿": "西方白虎七宿之一",
        "毕宿": "西方白虎七宿之一",
        "觜宿": "西方白虎七宿之一",
        "参宿": "西方白虎七宿之一",
        "井宿": "南方朱雀七宿之一",
        "鬼宿": "南方朱雀七宿之一",
        "柳宿": "南方朱雀七宿之一",
        "星宿": "南方朱雀七宿之一",
        "张宿": "南方朱雀七宿之一",
        "翼宿": "南方朱雀七宿之一",
        "轸宿": "南方朱雀七宿之一",
    }
    return mapping.get(name)
```

Use curated category rules:

- `myth`: `织女`, `河鼓二`, `王良`, `造父`, `傅说`, `轩辕`, `螣蛇`, `太乙`, `天乙`, `天皇大帝`.
- `folklore`: `北斗`, `北极星`, `天狼`, `老人`, `五车`, `昴宿`, `参宿`, `角宿`, `心宿`.
- `astronomical`: `日`, `月`, `太阳守`, `灵台`, `渐台`, `候`, `天纪`.
- `cultural`: default for institutional, object, animal, military, agricultural, market, palace, water, and road names.

Generate conservative text:

- `brief`: one sentence naming the image represented by the star official.
- `story`: 2-3 short sentences. If `storyType` is `cultural`, say it "象征/代表/反映" rather than "传说".
- `science`: 1-2 short sentences based on star count, lines, rank, and observation, avoiding unsupported physical claims.
- `sourceNotes`: `参考传统星官体系、三垣二十八宿分类、d3-celestial 星官名与英文释义；本条为文化释义。`

- [ ] **Step 2: Run enrichment**

Run: `python3 tools/enrich_chinese_asterism_stories.py`

Expected: `LittleGalileo/chinese_asterisms.json` is updated; existing 8 handcrafted stories remain text-identical.

- [ ] **Step 3: Run validator and confirm pass**

Run: `python3 tools/validate_chinese_asterism_stories.py`

Expected: `Validated 310 Chinese asterism story records`

### Task 3: Update UI Copy

**Files:**
- Modify: `LittleGalileo/Views/CardDetailView.swift`

- [ ] **Step 1: Change detail title**

Replace:

```swift
section(title: "神话故事", text: asterism.story ?? "暂无故事")
```

With:

```swift
section(title: "星官故事", text: asterism.story ?? "暂无故事")
```

- [ ] **Step 2: Search for stale user-facing copy**

Run: `rg -n "神话故事|暂无故事|暂无科学知识" LittleGalileo`

Expected: no `神话故事`; fallback strings may remain but validator proves JSON no longer needs them.

### Task 4: Add Catalog-Level Test

**Files:**
- Modify: `LittleGalileoTests/LittleGalileoTests.swift`

- [ ] **Step 1: Add a test method**

Add a test that loads `StarCatalog` and checks every asterism has non-empty content:

```swift
@Test func catalogHasStoryMaterialForEveryChineseAsterism() async throws {
    let catalog = StarCatalog()
    let asterisms = catalog.chineseAsterisms()

    #expect(asterisms.count == 310)
    #expect(asterisms.allSatisfy { $0.brief?.isEmpty == false })
    #expect(asterisms.allSatisfy { $0.story?.isEmpty == false })
    #expect(asterisms.allSatisfy { $0.science?.isEmpty == false })
}
```

- [ ] **Step 2: Run unit tests**

Run:

```bash
xcodebuild test -quiet \
  -project /Users/qianqian/Desktop/LittleGalileo/LittleGalileo.xcodeproj \
  -scheme LittleGalileo \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1'
```

Expected: all tests pass.

### Task 5: Build and Final Verification

**Files:**
- No new files.

- [ ] **Step 1: Validate JSON**

Run: `python3 tools/validate_chinese_asterism_stories.py`

Expected: `Validated 310 Chinese asterism story records`

- [ ] **Step 2: Build app**

Run:

```bash
xcodebuild build -quiet \
  -project /Users/qianqian/Desktop/LittleGalileo/LittleGalileo.xcodeproj \
  -scheme LittleGalileo \
  -destination 'generic/platform=iOS Simulator'
```

Expected: exit code 0.

- [ ] **Step 3: Summarize changed content**

Report:

- number of enriched asterisms,
- number of story types,
- confirmation that no item has empty `story`,
- whether build/test commands passed.

