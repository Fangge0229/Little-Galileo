#!/usr/bin/env python3
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_FILE = ROOT / "LittleGalileo" / "chinese_asterisms.json"
REQUIRED_FIELDS = ("brief", "story", "science", "storyType", "sourceNotes")
VALID_STORY_TYPES = {"myth", "folklore", "cultural", "astronomical"}
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
        missing = [
            field
            for field in REQUIRED_FIELDS
            if not str(item.get(field, "")).strip()
        ]
        if missing:
            failures.append(
                f"{item.get('id')} {item.get('name')}: missing {', '.join(missing)}"
            )

        story_type = item.get("storyType")
        if story_type and story_type not in VALID_STORY_TYPES:
            failures.append(
                f"{item.get('id')} {item.get('name')}: invalid storyType {story_type}"
            )

    by_id = {item.get("id"): item for item in asterisms}
    for item_id in sorted(HANDCRAFTED_IDS):
        item = by_id.get(item_id)
        if item is None:
            failures.append(f"{item_id}: missing handcrafted asterism")
        elif not str(item.get("story", "")).strip():
            failures.append(f"{item_id} {item.get('name')}: handcrafted story removed")

    if failures:
        print("Chinese asterism story validation failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(f"Validated {len(asterisms)} Chinese asterism story records")
    return 0


if __name__ == "__main__":
    sys.exit(main())
