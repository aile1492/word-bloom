# -*- coding: utf-8 -*-
"""
A+B 혼합 컨셉으로 24개 워크플로우 프롬프트 일괄 업데이트.

Stage 1: 파스텔 낮  (밝고 가벼운 진입)
Stage 2: 황금 노을  (따뜻하고 로맨틱)
Stage 3: 보라 황혼  (몽환적이고 주얼톤 — 어둡지 않음)
"""

import json
from pathlib import Path

WORKFLOWS_DIR = Path(__file__).parent

COMP = (
    "vertical portrait composition with low horizon line, "
    "dramatic sky and atmospheric scene dominating the upper two-thirds of the frame, "
    "soft misty blurred ground fading gently toward the bottom, "
    "natural atmospheric depth and gradient"
)

NEW_PROMPTS = {
    # ── ANIMALS ───────────────────────────────────────────────────────────────
    "01_animals.json": {
        "title": "POSITIVE — Animals Stage1 (Pastel Day / Savanna)",
        "text": (
            "serene savanna at bright midday, golden grasslands stretching to the horizon, "
            "soft pastel blue sky with fluffy white clouds, gentle warm sunlight, "
            "peaceful African landscape, airy and cheerful atmosphere, warm delicate tones, "
            "no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },
    "01_animals_stage2.json": {
        "title": "POSITIVE — Animals Stage2 (Golden Sunset / Savanna)",
        "text": (
            "magical savanna at golden hour sunset, warm golden-orange sky with pink and coral clouds, "
            "acacia trees silhouetted against vibrant sunset, romantic warm atmosphere, "
            "long golden shadows across the grasslands, glowing amber light, dreamy and beautiful, "
            "no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },
    "01_animals_stage3.json": {
        "title": "POSITIVE — Animals Stage3 (Purple Twilight / Savanna)",
        "text": (
            "enchanting savanna at magical twilight, lavender and soft purple sky with ethereal glow, "
            "jewel-toned atmosphere with violet and rose hues, gentle luminous light, "
            "mystical and dreamy landscape, rich deep colors glowing softly, luxurious and enchanting, "
            "no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },

    # ── FOOD ──────────────────────────────────────────────────────────────────
    "02_food.json": {
        "title": "POSITIVE — Food Stage1 (Pastel Day / Rustic Kitchen)",
        "text": (
            "charming rustic kitchen table in soft morning light, fresh colorful fruits and pastries, "
            "soft pastel color palette, airy and cheerful atmosphere, gentle natural window light, "
            "delicate and inviting, warm and cozy, no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },
    "02_food_stage2.json": {
        "title": "POSITIVE — Food Stage2 (Golden / Romantic Trattoria)",
        "text": (
            "romantic Italian trattoria at golden hour, warm amber candlelight and sunset glow through windows, "
            "rich warm tones, inviting and cozy atmosphere, golden light on rustic wooden table with food, "
            "dreamy and romantic dining scene, no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },
    "02_food_stage3.json": {
        "title": "POSITIVE — Food Stage3 (Purple Twilight / Luxury Dining)",
        "text": (
            "luxurious fine dining setting at twilight, jewel-toned purple and deep rose ambiance, "
            "elegant table with soft ethereal candlelight glow, lavender and violet atmosphere, "
            "magical and opulent, rich deep colors with soft luminous light, enchanting and sophisticated, "
            "no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },

    # ── MUSIC ─────────────────────────────────────────────────────────────────
    "03_music.json": {
        "title": "POSITIVE — Music Stage1 (Pastel Day / Concert Hall)",
        "text": (
            "beautiful concert hall in soft afternoon light, grand piano on stage, "
            "pastel ivory and cream tones, gentle warm sunlight through high arched windows, "
            "airy and elegant atmosphere, delicate and cheerful, no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },
    "03_music_stage2.json": {
        "title": "POSITIVE — Music Stage2 (Golden / Romantic Jazz Club)",
        "text": (
            "romantic jazz club at golden hour, warm amber and honey-toned lighting, "
            "intimate cozy atmosphere, golden glow on vintage instruments on stage, "
            "dreamy and musical, warm sunset light filtering through windows, "
            "no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },
    "03_music_stage3.json": {
        "title": "POSITIVE — Music Stage3 (Purple Twilight / Magic Opera)",
        "text": (
            "magical opera house at twilight, jewel-toned purple and rose stage lighting, "
            "lavender and violet atmosphere, ethereal glow on grand ornate stage, "
            "enchanting and luxurious, soft luminous light, mystical musical ambiance, "
            "no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },

    # ── MYTHOLOGY ─────────────────────────────────────────────────────────────
    "04_mythology.json": {
        "title": "POSITIVE — Mythology Stage1 (Pastel Day / Greek Temple)",
        "text": (
            "ancient Greek marble temple at bright morning, soft pastel blue sky and warm golden stone, "
            "gentle morning sunlight, serene and peaceful, airy Mediterranean atmosphere, "
            "delicate golden tones, no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },
    "04_mythology_stage2.json": {
        "title": "POSITIVE — Mythology Stage2 (Golden / Norse Fjord)",
        "text": (
            "majestic Norse fjord at golden sunset, warm orange and pink sky reflected in still water, "
            "romantic and epic landscape, golden light on dramatic cliffs, "
            "dreamy aurora gently beginning to glow, warm jewel tones, "
            "no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },
    "04_mythology_stage3.json": {
        "title": "POSITIVE — Mythology Stage3 (Purple Twilight / Enchanted Ruins)",
        "text": (
            "enchanted mythical landscape at magical twilight, lavender and deep rose sky, "
            "ethereal glowing ancient ruins with soft light, jewel-toned purple and violet atmosphere, "
            "soft luminous magical glow, mystical and dreamy, ancient beauty bathed in ethereal light, "
            "no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },

    # ── OCEAN ─────────────────────────────────────────────────────────────────
    "05_ocean.json": {
        "title": "POSITIVE — Ocean Stage1 (Pastel Day / Tropical Beach)",
        "text": (
            "tropical beach at bright midday, crystal clear turquoise water, "
            "soft pastel blue sky with gentle white clouds, white sandy beach with gentle waves, "
            "golden sunshine, airy and cheerful coastal scene, fresh and vibrant, "
            "no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },
    "05_ocean_stage2.json": {
        "title": "POSITIVE — Ocean Stage2 (Golden / Warm Coral Reef)",
        "text": (
            "beautiful coral reef bathed in golden hour light, warm golden light filtering through shallow water, "
            "vibrant orange and pink coral glow, tropical fish in warm tones, "
            "dreamy and magical underwater scene, warm jewel tones, "
            "no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },
    "05_ocean_stage3.json": {
        "title": "POSITIVE — Ocean Stage3 (Purple Twilight / Jewel Sea)",
        "text": (
            "magical ocean at twilight, lavender and deep teal waters, "
            "ethereal bioluminescent glow in jewel tones, violet and purple sky reflected on calm water, "
            "enchanting and dreamy seascape, soft luminous magical light, "
            "luxurious deep jewel-toned ocean colors, no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },

    # ── SCIENCE ───────────────────────────────────────────────────────────────
    "06_science.json": {
        "title": "POSITIVE — Science Stage1 (Pastel Day / Bright Laboratory)",
        "text": (
            "bright modern research laboratory with soft daylight, clean pastel blue and white tones, "
            "scientific equipment in cheerful light, airy and fresh atmosphere, "
            "gentle sunlight through large windows, clean and inviting, "
            "no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },
    "06_science_stage2.json": {
        "title": "POSITIVE — Science Stage2 (Golden / Warm Accelerator)",
        "text": (
            "stunning particle accelerator tunnel bathed in warm golden technical lighting, "
            "amber and honey tones on metallic surfaces, dramatic circular corridor perspective, "
            "glowing warm industrial beauty, dreamy and captivating, "
            "no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },
    "06_science_stage3.json": {
        "title": "POSITIVE — Science Stage3 (Purple Twilight / Observatory)",
        "text": (
            "magical science observatory at twilight, lavender and jewel-toned sky, "
            "large telescope pointing at ethereal purple starlit sky, "
            "glowing rose and violet atmosphere, enchanting stargazing scene, "
            "soft luminous astronomical glow, luxurious and mystical, "
            "no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },

    # ── SPACE ─────────────────────────────────────────────────────────────────
    "07_space.json": {
        "title": "POSITIVE — Space Stage1 (Pastel Blue Hour / Mountain)",
        "text": (
            "mountain peak at soft pastel blue hour, milky way gently visible in light lavender sky, "
            "dreamy and airy atmosphere, soft warm tones on mountain landscape, "
            "peaceful and beautiful stargazing scene, "
            "no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },
    "07_space_stage2.json": {
        "title": "POSITIVE — Space Stage2 (Golden / Warm Nebula)",
        "text": (
            "breathtaking nebula with warm golden and orange cosmic clouds, "
            "vibrant stellar nursery glowing in amber and rose, warm jewel-toned space scene, "
            "dreamy and romantic space photography, rich warm cosmic colors, "
            "photorealistic, 8k ultra detailed, " + COMP
        ),
    },
    "07_space_stage3.json": {
        "title": "POSITIVE — Space Stage3 (Purple Twilight / Jewel Nebula)",
        "text": (
            "magnificent cosmic scene with jewel-toned purple and lavender nebula, "
            "ethereal galactic glow, deep violet and rose cosmic clouds, "
            "soft luminous starlight, enchanting and luxurious space scene, "
            "rich deep purple and teal cosmic colors, magical and dreamy universe, "
            "photorealistic, 8k ultra detailed, " + COMP
        ),
    },

    # ── SPORTS ────────────────────────────────────────────────────────────────
    "08_sports.json": {
        "title": "POSITIVE — Sports Stage1 (Pastel Day / Stadium)",
        "text": (
            "beautiful sports stadium at bright midday, lush green field gleaming in sunshine, "
            "soft pastel blue sky with white clouds, cheerful and energetic atmosphere, "
            "clear golden sunlight, fresh and vibrant, clean and inviting, "
            "no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },
    "08_sports_stage2.json": {
        "title": "POSITIVE — Sports Stage2 (Golden / Olympic Track)",
        "text": (
            "Olympic athletics stadium at golden hour sunset, warm golden light on perfect red running track, "
            "dramatic long golden shadows across the track, vibrant orange and pink sky, "
            "energetic and beautiful, dreamy sports photography, warm jewel tones, "
            "no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },
    "08_sports_stage3.json": {
        "title": "POSITIVE — Sports Stage3 (Purple Twilight / Magic Arena)",
        "text": (
            "magical sports arena at twilight, jewel-toned lavender and rose lighting, "
            "ethereal soft glow illuminating the venue, enchanting and luxurious atmosphere, "
            "soft luminous purple and rose light, dreamy and elegant, rich violet and deep rose tones, "
            "no people, photorealistic, 8k ultra detailed, " + COMP
        ),
    },
}


def main():
    ok = 0
    skip = 0
    for filename, data in NEW_PROMPTS.items():
        filepath = WORKFLOWS_DIR / filename
        if not filepath.exists():
            print(f"  [SKIP] {filename} — 파일 없음")
            skip += 1
            continue

        with open(filepath, "r", encoding="utf-8") as f:
            wf = json.load(f)

        wf["4"]["_meta"]["title"] = data["title"]
        wf["4"]["inputs"]["text"] = data["text"]

        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(wf, f, ensure_ascii=False, indent=2)

        print(f"  [OK]  {filename}")
        ok += 1

    print()
    print(f"완료: {ok}개 업데이트, {skip}개 스킵")
    print()
    print("새 컨셉:")
    print("  Stage1 = 파스텔 낮  (밝고 가벼운 진입)")
    print("  Stage2 = 황금 노을  (따뜻하고 로맨틱)")
    print("  Stage3 = 보라 황혼  (몽환적·주얼톤, 어둡지 않음)")


if __name__ == "__main__":
    main()
