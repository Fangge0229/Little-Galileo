#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_FILE = ROOT / "LittleGalileo" / "chinese_asterisms.json"

HANDCRAFTED_STORY_TYPES = {
    "shenxiu": (
        "folklore",
        "保留 App 既有参宿故事；参考三星高照民俗、二十八宿和 d3-celestial 星官数据。",
    ),
    "jiaoxiu": (
        "folklore",
        "保留 App 既有角宿故事；参考东方苍龙、龙抬头民俗、二十八宿和 d3-celestial 星官数据。",
    ),
    "xinxiu": (
        "folklore",
        "保留 App 既有心宿故事；参考大火星、七月流火传统解释、二十八宿和 d3-celestial 星官数据。",
    ),
    "beidou": (
        "folklore",
        "保留 App 既有北斗故事；参考北斗定向授时传统和 d3-celestial 星官数据。",
    ),
    "polaris": (
        "astronomical",
        "保留 App 既有北极星故事；参考北极星定向知识和 d3-celestial 星官数据。",
    ),
    "altair": (
        "myth",
        "保留 App 既有牛郎星故事；参考牛郎织女民俗和 d3-celestial 星官数据。",
    ),
    "sirius": (
        "folklore",
        "保留 App 既有天狼故事；参考射天狼文学意象和 d3-celestial 星官数据。",
    ),
    "vega": (
        "myth",
        "保留 App 既有织女故事；参考牛郎织女民俗和 d3-celestial 星官数据。",
    ),
}

MANSION_CONTEXT = {
    "角宿": ("东方苍龙七宿之首", "春季"),
    "亢宿": ("东方苍龙的颈部", "春季"),
    "氐宿": ("东方苍龙的根基", "春季"),
    "房宿": ("东方苍龙的胸房", "春季"),
    "心宿": ("东方苍龙的心", "春季"),
    "尾宿": ("东方苍龙的尾", "春季"),
    "箕宿": ("东方苍龙的尾端", "春季"),
    "斗宿": ("北方玄武七宿之一", "冬季"),
    "牛宿": ("北方玄武七宿之一", "冬季"),
    "女宿": ("北方玄武七宿之一", "冬季"),
    "虚宿": ("北方玄武七宿之一", "冬季"),
    "危宿": ("北方玄武七宿之一", "冬季"),
    "室宿": ("北方玄武七宿之一", "冬季"),
    "壁宿": ("北方玄武七宿之一", "冬季"),
    "奎宿": ("西方白虎七宿之一", "秋季"),
    "娄宿": ("西方白虎七宿之一", "秋季"),
    "胃宿": ("西方白虎七宿之一", "秋季"),
    "昴宿": ("西方白虎七宿之一", "秋季"),
    "毕宿": ("西方白虎七宿之一", "秋季"),
    "觜宿": ("西方白虎七宿之一", "秋季"),
    "参宿": ("西方白虎七宿之一", "冬季"),
    "井宿": ("南方朱雀七宿之一", "夏季"),
    "鬼宿": ("南方朱雀七宿之一", "夏季"),
    "柳宿": ("南方朱雀七宿之一", "夏季"),
    "星宿": ("南方朱雀七宿之一", "夏季"),
    "张宿": ("南方朱雀七宿之一", "夏季"),
    "翼宿": ("南方朱雀七宿之一", "夏季"),
    "轸宿": ("南方朱雀七宿之一", "夏季"),
}

SPECIAL_ENTRIES = {
    "傅说": {
        "storyType": "folklore",
        "brief": "以古代贤臣傅说命名的星官",
        "story": "「傅说」取名自商代名臣傅说。传统星官把历史人物放入天空，是把贤臣辅佐君主的理想投射到星空里；这里更适合作为古史人物意象来理解，而不是编成新的神话。",
        "science": "在 App 星图中，这个星官由少量恒星组成，主要用来帮助定位周围星区。它提醒我们，传统星官的名字常来自历史、礼制和人物记忆。",
        "sourceNotes": "参考傅说古史人物意象、传统星官命名和 d3-celestial 星官数据；按民俗/古史意象处理。",
    },
    "王良": {
        "storyType": "folklore",
        "brief": "以传说中善御车马的王良命名",
        "story": "「王良」来自古代善于驾车的御者形象。把他列入星官，说明古人会把车马、出行和驾驭技术投射到天空，像在天上安排一位熟练的车夫。",
        "science": "这个星官在 App 中以多颗星连成图形，适合观察传统星官怎样用星点表现人物和车马主题。它的意义主要来自名称和星区角色，不是现代物理上的同一星团。",
        "sourceNotes": "参考传统星官中以王良为御者的命名、d3-celestial 星官数据；按民俗/古史意象处理。",
    },
    "造父": {
        "storyType": "folklore",
        "brief": "以古代驾车传说人物造父命名",
        "story": "「造父」是古代传说中的善御者。星官用这个名字，延续了天上车马的想象：夜空不仅有宫阙和官署，也有负责驾车远行的人物。",
        "science": "在 App 星图中，造父以少量星点显示，常与车马主题的星官一起帮助辨认附近星区。这样的星官更像文化地图中的标记，而非真实相连的恒星群。",
        "sourceNotes": "参考造父古史/传说人物意象、传统星官命名和 d3-celestial 星官数据。",
    },
    "奚仲": {
        "storyType": "folklore",
        "brief": "以古代车工传说人物奚仲命名",
        "story": "「奚仲」在传统中与造车技术相关。星官保留这个名字，表现了古人把交通、工艺和制度也放进星空叙事里，让夜空成为一幅社会生活图。",
        "science": "这个星官由少量恒星组成，适合作为认识车马相关星官的线索。它的重点是文化命名，不表示这些恒星在宇宙中彼此靠近。",
        "sourceNotes": "参考奚仲古史/工艺人物意象、传统星官命名和 d3-celestial 星官数据。",
    },
    "轩辕": {
        "storyType": "folklore",
        "brief": "以黄帝轩辕意象命名的显著星官",
        "story": "「轩辕」承载黄帝轩辕的古史和王者意象。传统星官把它安置在天空中，是把祖先、帝王和秩序的观念放入星空，而不是单纯描画一个图形。",
        "science": "轩辕在 App 中由多颗星组成，连线较丰富，适合观察长形星官。它说明传统星官常把明亮星和文化名称结合起来，形成便于记忆的天空区域。",
        "sourceNotes": "参考轩辕古史意象、传统星官体系和 d3-celestial 星官数据；按民俗/古史意象处理。",
    },
    "螣蛇": {
        "storyType": "myth",
        "brief": "以会飞的神蛇意象命名",
        "story": "「螣蛇」是古代想象中的神蛇形象。星官用这个名字，把蜿蜒的星点想象成在天空游动的长蛇，保留了中国星空中动物和神异形象的一面。",
        "science": "这个星官由多颗星组成，适合观察星点怎样被连成弯曲的形状。它展示的是从地球视角看到的图案，并不表示这些星真的组成一条蛇。",
        "sourceNotes": "参考螣蛇神异动物意象、传统星官命名和 d3-celestial 星官数据。",
    },
    "天狗": {
        "storyType": "folklore",
        "brief": "带有天狗食日食月民俗联想的星官",
        "story": "「天狗」在民间常和吞食太阳、月亮的想象相连，用来解释日食、月食等少见天象。作为星官时，它保留了古人把异常天象讲成故事的方式。",
        "science": "日食和月食今天可以用太阳、地球、月球的位置关系解释。这个星官适合用来区分民俗解释和现代天文解释：故事帮助记忆，科学说明原因。",
        "sourceNotes": "参考天狗食日食月民俗、传统星官命名和 d3-celestial 星官数据。",
    },
    "老人": {
        "storyType": "folklore",
        "brief": "象征长寿和吉祥的南方亮星",
        "story": "「老人」常被理解为南极老人、寿星一类的吉祥意象。它在南方天空出现时，被古人赋予长寿、安宁的象征意义。",
        "science": "老人星对应的亮星在中国北方不易看到，在南方更容易观察。这个例子能帮助孩子理解：同一颗星在不同纬度看到的高度不同。",
        "sourceNotes": "参考老人星/寿星民俗、传统星官体系和 d3-celestial 星官数据。",
    },
    "太乙": {
        "storyType": "cultural",
        "brief": "带有太一信仰和天上至尊意象的星官",
        "story": "「太乙」的名字带有古代太一、至高天神和天上秩序的意味。把它列为星官，说明古人会用天空表达宇宙中心、帝王权威和祭祀观念。",
        "science": "在 App 星图中，太乙是单星或少星标记，更像重要方位点。传统星官并不都需要复杂连线，有些名字本身就是文化意义的重点。",
        "sourceNotes": "参考太一/太乙文化意象、传统星官命名和 d3-celestial 星官数据；按文化释义处理。",
    },
    "天乙": {
        "storyType": "cultural",
        "brief": "表示天上尊贵神格与秩序的星官",
        "story": "「天乙」与天上尊贵、辅佐和秩序的观念有关。它不是适合硬编情节的星官，更应理解为古人把神圣权威安排进星空的一种命名。",
        "science": "这个星官在 App 中以少量星点呈现。它适合说明：传统星官既有图形，也有礼制、宗教和方位意义。",
        "sourceNotes": "参考天乙文化意象、传统星官命名和 d3-celestial 星官数据；按文化释义处理。",
    },
    "天皇大帝": {
        "storyType": "cultural",
        "brief": "象征天上最高帝座的星官",
        "story": "「天皇大帝」表现的是天上帝王和宇宙中心的观念。它反映古人把人间的尊卑秩序投射到天空，用星官组成一座有君臣、有宫室的天上世界。",
        "science": "这个星官通常以关键星点表示中心性和方位意义。观察它时，可以把重点放在传统星图怎样组织天空，而不是寻找独立神话情节。",
        "sourceNotes": "参考天皇大帝星官名、传统星官体系和 d3-celestial 星官数据；按文化释义处理。",
    },
}

CATEGORY_KEYWORDS = [
    ("southern", ("波斯", "海山", "海石", "火鸟", "飞鱼", "金鱼", "孔雀", "蜜蜂", "南船", "十字架", "异雀")),
    ("astronomical", ("日", "月", "太阳守", "灵台", "渐台", "候", "天纪")),
    ("military", ("军", "旗", "阵", "将军", "弧矢", "钺", "枪", "戈", "棓", "垒", "牢", "车骑", "虎贲", "羽林", "北落师门")),
    ("court", ("帝", "太子", "御女", "女史", "宦者", "尚书", "三公", "七公", "九卿", "五诸侯", "诸王", "郎", "谒者", "进贤", "宗", "相", "大理", "司", "文昌", "柱史", "从官", "少微", "太尊", "五帝")),
    ("market", ("市", "肆", "钱", "屠", "酒旗", "天弁", "列肆", "车肆")),
    ("food", ("谷", "瓜", "臼", "杵", "筐", "刍藁", "积薪", "糠", "仓", "厨", "廪", "囷", "田", "庾", "园", "苑", "樽", "农")),
    ("water", ("河", "江", "水", "渊", "津", "井", "池", "雨", "雷", "电", "霹雳", "云", "四渎", "海", "船")),
    ("animal", ("鳖", "鱼", "狗", "龟", "鹤", "鸟", "鸡", "马", "蜂", "蛇", "狼", "雀")),
    ("road_gate", ("门", "道", "街", "路", "阶", "关", "阙", "垣", "长垣", "阁道")),
    ("building", ("府", "屋", "宫", "台", "楼", "屏", "席", "床", "盖", "华盖", "坟墓", "陵", "厕")),
    ("ritual", ("社", "鼎", "明堂", "宗", "六甲", "天节", "阴德", "天阴", "咸池")),
    ("tool", ("斗", "斛", "衡", "策", "钩", "钤", "钥", "籥", "辐", "柱", "石", "砺", "杠", "辖")),
    ("emotion_omen", ("哭", "泣", "罚", "司非", "司怪", "司禄", "司命", "司危", "天谗", "折威", "顿顽")),
]

CATEGORY_PROFILES = {
    "court": ("天上官署", "朝廷职官、礼制和秩序"),
    "military": ("天上军阵", "守卫、征战和边防"),
    "market": ("天上市井", "交易、店铺和城市生活"),
    "food": ("天上农事与仓储", "粮食、饮食和日常生产"),
    "water": ("天上水域与天气", "河流、水利和天气变化"),
    "animal": ("天上动物形象", "动物观察和形象记忆"),
    "road_gate": ("天上道路关门", "道路、门禁和空间边界"),
    "building": ("天上建筑", "宫室、居所和公共空间"),
    "ritual": ("天上礼制", "祭祀、德行和制度象征"),
    "tool": ("天上器物", "工具、器具和生活技术"),
    "emotion_omen": ("天上占候意象", "吉凶、判断和古代占候观念"),
    "astronomical": ("天文观测星官", "观测、历法和天象记录"),
    "southern": ("近南方天空的补充星官", "后来补入的南方星空和异域想象"),
    "general": ("传统星官", "古人给天空建立的文化坐标"),
}


def clean_base_name(name):
    return name.split("(")[0].split("（")[0]


def enclosure_context(name):
    if "紫微" in name:
        return ("紫微垣", "紫微垣象征天帝居处和中央宫廷")
    if "太微" in name:
        return ("太微垣", "太微垣象征天廷政务和朝会")
    if "天市" in name:
        return ("天市垣", "天市垣象征市场、城邑和交易秩序")
    return None


def select_category(name):
    if name in MANSION_CONTEXT:
        return "mansion"
    if enclosure_context(name):
        return "enclosure"
    for category, keywords in CATEGORY_KEYWORDS:
        if any(keyword in name for keyword in keywords):
            return category
    return "general"


def best_season_for(item, category):
    name = item["name"]
    if name in MANSION_CONTEXT:
        return MANSION_CONTEXT[name][1]
    if category == "southern":
        return "南方低空"
    return "全年可查"


def difficulty_for(item):
    if item.get("difficulty") is not None:
        return item["difficulty"]
    stars = len(item.get("stars", []))
    lines = len(item.get("lines", []))
    if stars >= 8 or lines >= 6:
        return 2
    return 1


def science_text(item):
    stars = len(item.get("stars", []))
    lines = len(item.get("lines", []))
    if lines == 0:
        shape = "它在当前星图数据中没有连线，更像一个位置标记。"
    elif lines == 1:
        shape = "它在当前星图数据中用 1 条线连接星点，形状比较简洁。"
    else:
        shape = f"它在当前星图数据中包含 {lines} 条连线，能形成较清楚的图案。"
    return f"在 App 星图中，「{item['name']}」由 {stars} 颗 HIP 星组成。{shape}这些星是从地球方向看形成的图样，并不一定在宇宙中彼此靠近。"


def generic_entry(item):
    name = item["name"]
    base = clean_base_name(name)
    category = select_category(name)

    if category == "mansion":
        context, _season = MANSION_CONTEXT[name]
        return {
            "brief": f"{context}，是二十八宿的重要星官",
            "story": f"「{name}」是{context}。古人用二十八宿把天空分成有方向和季节感的区域，所以这类星官更像夜空中的坐标和章节；它不一定有单独神话，但承载了四象和星宿分区的传统。",
            "science": science_text(item),
            "storyType": "cultural",
            "sourceNotes": "参考二十八宿、四象分区、传统星官体系和 d3-celestial 星官数据；按文化释义处理。",
        }

    if category == "enclosure":
        enclosure, context = enclosure_context(name)
        side = "边界"
        if "右垣" in name:
            side = "右侧边界"
        elif "左垣" in name:
            side = "左侧边界"
        return {
            "brief": f"{enclosure}的{side}",
            "story": f"「{name}」属于{enclosure}。{context}，左右垣像天上宫城或城墙的两边，帮助古人把一片星空理解成有秩序的空间。",
            "science": science_text(item),
            "storyType": "cultural",
            "sourceNotes": "参考三垣体系、传统星官命名和 d3-celestial 星官数据；按文化释义处理。",
        }

    subject, meaning = CATEGORY_PROFILES[category]
    if category == "general":
        return {
            "brief": "传统星官，用名称帮助标记这片星空",
            "story": f"「{name}」是传统星官体系中的一个名称。它保留了古人给天空分区和命名的方式；即使没有独立神话，也可以作为认识星图、方位和文化记忆的线索。",
            "science": science_text(item),
            "storyType": "cultural",
            "sourceNotes": "参考传统星官体系、三垣二十八宿分类、d3-celestial 星官名与英文释义；本条为保守文化释义。",
        }

    article = "这个"
    if category in {"court", "market", "food", "water", "building", "ritual", "southern"}:
        article = "这组"
    story_type = "astronomical" if category == "astronomical" else "cultural"

    if item.get("en"):
        name_hint = f"它的名称和释义指向「{base}」这一形象"
    else:
        name_hint = f"它的名称指向「{base}」这一形象"

    return {
        "brief": f"{subject}，表现{meaning}",
        "story": f"「{name}」在传统星官体系中属于{subject}。{name_hint}，反映古人会把{meaning}放进夜空，用星星组织成一幅可记忆的天上世界。这里采用文化释义，不把它说成没有依据的神话。",
        "science": science_text(item),
        "storyType": story_type,
        "sourceNotes": "参考传统星官体系、三垣二十八宿分类、d3-celestial 星官名与英文释义；本条为文化释义。",
    }


def enrich_item(item):
    enriched = dict(item)
    base = clean_base_name(item["name"])

    if item["id"] in HANDCRAFTED_STORY_TYPES:
        story_type, notes = HANDCRAFTED_STORY_TYPES[item["id"]]
        enriched["storyType"] = story_type
        enriched["sourceNotes"] = notes
    elif base in SPECIAL_ENTRIES:
        entry = SPECIAL_ENTRIES[base]
        for key in ("brief", "story", "science", "storyType", "sourceNotes"):
            enriched[key] = entry[key]
    else:
        entry = generic_entry(item)
        for key in ("brief", "story", "science", "storyType", "sourceNotes"):
            enriched[key] = entry[key]

    enriched.setdefault("difficulty", difficulty_for(item))
    enriched.setdefault("best_season", best_season_for(item, select_category(item["name"])))
    return enriched


def main():
    data = json.loads(DATA_FILE.read_text(encoding="utf-8"))
    original = data["asterisms"]
    data["asterisms"] = [enrich_item(item) for item in original]
    DATA_FILE.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Enriched {len(data['asterisms'])} Chinese asterism records")


if __name__ == "__main__":
    main()
