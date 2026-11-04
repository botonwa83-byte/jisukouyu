#!/usr/bin/env python3
"""把 content/phrases_*.tsv 并入 phrases.json，并按语料重建 curriculum.json。

TSV 列（用 " | " 分隔，共 11 列）：
day | en | zh | scene | focus | ipa | notes | variants | avoid | transfer | context

文件名约定：
    phrases_07_18.tsv      → 默认 01 方案 a 阶段（历史文件）
    phrases_02a_01_30.tsv  → 02 方案 a 阶段

天标题文件名：
    day_titles_1_30.tsv        → 默认 01 方案 a 阶段
    day_titles_02a_1_30.tsv    → 02 方案 a 阶段
格式：day | title

ID 规则：{plan}-{stage}-{day:03d}-{index}
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"
CORE = ROOT / "Core" / "Sources" / "SpeedTalkCore" / "Resources"
PHRASES = CORE / "phrases.json"
CURRICULUM = CORE / "curriculum.json"

DEFAULT_PLAN = "01"
DEFAULT_STAGE = "a"

STAGE_TITLES = {
    ("01", "a"): "吃住行基础",
    ("01", "b"): "办事与医疗",
    ("01", "c"): "邻里与消费",
    ("02", "a"): "求职与面试",
    ("02", "b"): "职场协作",
    ("02", "c"): "校园学术",
    ("03", "a"): "高频俚语",
    ("03", "b"): "社交场合",
    ("03", "c"): "文化与幽默",
}

UNIT_TITLES = {
    ("01", "a", 1): "第一单元：开口与点单",
    ("01", "a", 2): "第二单元：住所与出行",
    ("01", "a", 3): "第三单元：办事与医疗",
    ("01", "a", 4): "第四单元：邻里与消费",
    ("01", "b", 1): "第一单元：银行与证件",
    ("01", "b", 2): "第二单元：医疗与药房",
    ("01", "b", 3): "第三单元：报修、投诉与售后",
    ("01", "b", 4): "第四单元：应急与出行事务",
    ("01", "c", 1): "第一单元：邻里与社区",
    ("01", "c", 2): "第二单元：社交与邀约",
    ("01", "c", 3): "第三单元：消费与娱乐",
    ("01", "c", 4): "第四单元：家庭与节日",
    ("02", "a", 1): "第一单元：面试与自我介绍",
    ("02", "a", 2): "第二单元：行为面试与故事",
    ("02", "a", 3): "第三单元：晋升薪酬与内部沟通",
    ("02", "a", 4): "第四单元：远程出差与合规",
    ("02", "b", 1): "第一单元：日常协作与排期",
    ("02", "b", 2): "第二单元：复盘与冲突管理",
    ("02", "b", 3): "第三单元：招聘入职与跨文化",
    ("02", "b", 4): "第四单元：预算汇报与向上管理",
    ("02", "c", 1): "第一单元：入学与选课",
    ("02", "c", 2): "第二单元：课堂与讨论",
    ("02", "c", 3): "第三单元：作业、论文与反馈",
    ("02", "c", 4): "第四单元：考试、成绩与研究",
    ("03", "c", 1): "第一单元：影视与流行文化",
    ("03", "c", 2): "第二单元：笑话与双关",
    ("03", "c", 3): "第三单元：典故与习语",
    ("03", "c", 4): "第四单元：幽默的分寸",
    ("03", "b", 1): "第一单元：破冰与寒暄",
    ("03", "b", 2): "第二单元：饭局与酒桌",
    ("03", "b", 3): "第三单元：派对与活动",
    ("03", "b", 4): "第四单元：关系维护与冲突",
    ("03", "a", 1): "第一单元：日常俚语与情绪",
    ("03", "a", 2): "第二单元：比喻夸张与反讽吐槽",
    ("03", "a", 3): "第三单元：影视梗、职场黑话与典故",
    ("03", "a", 4): "第四单元：发音语调与听说训练",
}

FILE_PATTERN = re.compile(r"^(phrases|day_titles)_(\d\d)([abc])_")


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def plan_stage_of(path):
    match = FILE_PATTERN.match(path.name)
    if match:
        return match.group(2), match.group(3)
    return DEFAULT_PLAN, DEFAULT_STAGE


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

    for title_path in sorted(CONTENT.glob("day_titles*.tsv")):
        plan, stage = plan_stage_of(title_path)
        for line in title_path.read_text(encoding="utf-8").splitlines():
            if not line.strip() or line.startswith("#"):
                continue
            day, title = line.split(" | ")
            titles[(plan, stage, int(day))] = title.strip()

    for p in phrases.values():
        if not p.get("tags") and p.get("context"):
            p["tags"] = [p["context"]]

    per_day = {}
    for p in phrases.values():
        per_day.setdefault((p["plan"], p["stage"], p["day"]), []).append(p)

    for tsv in sorted(CONTENT.glob("phrases_*.tsv")):
        plan, stage = plan_stage_of(tsv)
        for day_s, en, zh, scene, focus, ipa, notes, variants, avoid, transfer, context in parse_tsv(tsv):
            day = int(day_s)
            key = (plan, stage, day)
            bucket = per_day.setdefault(key, [])
            if en in {p["en"] for p in bucket}:
                continue
            index = len(bucket) + 1
            phrase = {
                "id": f"{plan}-{stage}-{day:03d}-{index}",
                "plan": plan,
                "stage": stage,
                "unit": (day - 1) // 30 + 1,
                "day": day,
                "index": index,
                "en": en,
                "zh": zh,
                "scene": scene,
                "level": 1 if day <= 30 else (2 if day <= 90 else 3),
                "focus": focus,
                "register": "casual",
                "tags": [context] if context else [],
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

    ids_by_plan_stage_day = {}
    for p in ordered:
        ids_by_plan_stage_day.setdefault((p["plan"], p["stage"], p["day"]), []).append(p["id"])

    curriculum = load_json(CURRICULUM)
    total_days = 0
    for plan in curriculum["plans"]:
        plan_id = plan["id"]
        stages = []
        for stage_id in ["a", "b", "c"]:
            days = {
                day: ids
                for (p, s, day), ids in ids_by_plan_stage_day.items()
                if p == plan_id and s == stage_id
            }
            if not days:
                continue
            units = []
            for unit_index in range(1, 5):
                unit_days = []
                for day in range((unit_index - 1) * 30 + 1, unit_index * 30 + 1):
                    ids = sorted(days.get(day, []), key=lambda x: int(x.rsplit("-", 1)[1]))
                    if not ids:
                        continue
                    unit_days.append({
                        "day": day,
                        "title": titles.get((plan_id, stage_id, day), f"第 {day} 天"),
                        "phraseIDs": ids,
                    })
                if unit_days:
                    units.append({
                        "index": unit_index,
                        "title": UNIT_TITLES.get((plan_id, stage_id, unit_index), f"第 {unit_index} 单元"),
                        "days": unit_days,
                    })
            total_days += len(days)
            stages.append({
                "id": stage_id,
                "title": STAGE_TITLES.get((plan_id, stage_id), stage_id.upper()),
                "units": units,
            })
        plan["stages"] = stages

    CURRICULUM.write_text(
        json.dumps(curriculum, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"phrases: {len(ordered)}, days: {total_days}")


if __name__ == "__main__":
    main()
