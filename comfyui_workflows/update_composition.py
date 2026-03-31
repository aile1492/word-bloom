"""
모든 워크플로우 JSON 프롬프트에 A방식 구도 지시문을 추가하는 스크립트.

게임 UI 구조 (배경 위에 오버레이):
  상단 15%: 헤더 (테마명/코인) — 배경의 드라마틱한 부분이 보여야 함
  중간 60%: 격자판 (반투명 패널 위에 타일)
  하단 25%: 단어뱅크 + 탭바

A방식: 이미지 자체가 위쪽이 드라마틱하고 아래로 갈수록 부드럽게 페이드되도록 구도 지시
"""

import json, os, glob

# 구도 지시문 (모든 프롬프트 맨 뒤에 추가)
COMPOSITION_TAG = (
    ", vertical portrait composition with low horizon line, "
    "dramatic sky and atmospheric scene dominating the upper two-thirds of the frame, "
    "soft misty blurred ground fading gently toward the bottom, "
    "natural atmospheric depth and gradient"
)

workflow_dir = os.path.dirname(os.path.abspath(__file__))
json_files = glob.glob(os.path.join(workflow_dir, "0*.json"))

updated = 0
skipped = 0

for filepath in sorted(json_files):
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)

    # 노드 "4" = POSITIVE 프롬프트
    if "4" in data and "inputs" in data["4"] and "text" in data["4"]["inputs"]:
        old_text: str = data["4"]["inputs"]["text"]

        # 이미 추가된 경우 스킵
        if "vertical portrait composition" in old_text:
            print(f"  SKIP (already updated): {os.path.basename(filepath)}")
            skipped += 1
            continue

        data["4"]["inputs"]["text"] = old_text + COMPOSITION_TAG

        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f"  UPDATED: {os.path.basename(filepath)}")
        updated += 1
    else:
        print(f"  ERROR: node 4 not found in {os.path.basename(filepath)}")

print(f"\nDone. Updated: {updated}, Skipped: {skipped}")
