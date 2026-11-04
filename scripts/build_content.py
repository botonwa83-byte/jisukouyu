#!/usr/bin/env python3
"""把 content/*.tsv 的语料并入 phrases.json，并重建 curriculum.json。

TSV 列（\t 分隔）：
day  en  zh  scene  focus  ipa  notes  variants  avoid  transfer  context

notes / variants 用 ; 分隔多条。
ID 规则：{plan}-{stage}-{day:03d}-{index}
"""

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"
CORE = ROOT / "Core" / "Sources" / "SpeedTalkCore" / "Resources"
PHRASES = CORE / "phrases.json"
CURRICULUM = CORE / "curriculum.json"

UNIT_TITLES = {
    1: "第一单元：开口与点单",
    2: "第二单元：住所与出行",
    3: "第三单元：办事与医疗",
    4: "第四单元：邻里与消费",
}


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def parse_tsv(path):
    rows = []
    for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = [part.strip() for part in line.split(" | ")]
        if len(parts) != 11:
            sys.exit(f"{path.name}:{lineno} 列数应为 11，实际 {len(parts)}")
        rows.append(parts)
    return rows


def main():
    phrase_file = load_json(PHRASES)
    phrases = {p["id"]: p for p in phrase_file["phrases"]}
    titles = {}

    title_path = CONTENT / "day_titles.tsv"
    if title_path.exists():
        for line in title_path.read_text(encoding="utf-8").splitlines():
            if not line.strip() or line.startswith("#"):
                continue
            day, title = line.split(" | ")
            titles[int(day)] = title.strip()

    per_day = {}
    for p in phrases.values():
        per_day.setdefault((p["plan"], p["stage"], p["day"]), []).append(p)

    for tsv in sorted(CONTENT.glob("phrases_*.tsv")):
        for day_s, en, zh, scene, focus, ipa, notes, variants, avoid, transfer, context in parse_tsv(tsv):
            day = int(day_s)
            key = ("01", "a", day)
            bucket = per_day.setdefault(key, [])
            existing = {p["en"] for p in bucket}
            if en in existing:
                continue
            index = len(bucket) + 1
            phrase = {
                "id": f"01-a-{day:03d}-{index}",
                "plan": "01",
                "stage": "a",
                "unit": (day - 1) // 30 + 1,
                "day": day,
                "index": index,
                "en": en,
                "zh": zh,
                "scene": scene,
                "level": 1 if day <= 30 else (2 if day <= 90 else 3),
                "focus": focus,
                "register": "casual",
                "tags": [],
                "pronunciation": {
                    "ipa": ipa,
                    "notes": [n.strip() for n in notes.split(";") if n.strip()],
                },
                "variants": [v.strip() for v in variants.split(";") if v.strip()],
                "avoid": avoid,
                "transfer": transfer,
                "context": context,
            }
            bucket.append(phrase)
            phrases[phrase["id"]] = phrase

    ordered = sorted(phrases.values(), key=lambda p: (p["plan"], p["stage"], p["day"], p["index"]))
    PHRASES.write_text(
        json.dumps({"version": 1, "phrases": ordered}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    # 重建 01-a 的 120 天课纲
    days = {}
    for p in ordered:
        if p["plan"] == "01" and p["stage"] == "a":
            days.setdefault(p["day"], []).append(p["id"])

    units = []
    for unit_index in range(1, 5):
        unit_days = []
        for day in range((unit_index - 1) * 30 + 1, unit_index * 30 + 1):
            ids = sorted(days.get(day, []))
            if not ids:
                continue
            unit_days.append({
                "day": day,
                "title": titles.get(day, f"第 {day} 天"),
                "phraseIDs": ids,
            })
        units.append({
            "index": unit_index,
            "title": UNIT_TITLES[unit_index],
            "days": unit_days,
        })

    curriculum = load_json(CURRICULUM)
    for plan in curriculum["plans"]:
        if plan["id"] == "01":
            plan["stages"] = [{"id": "a", "title": "吃住行基础", "units": units}]

    CURRICULUM.write_text(
        json.dumps(curriculum, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"phrases: {len(ordered)}, days: {len(days)}")


if __name__ == "__main__":
    main()
