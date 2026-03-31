# -*- coding: utf-8 -*-
import sys
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import io, json, time, requests
from pathlib import Path
from PIL import Image
import rembg

COMFYUI_URL = "http://127.0.0.1:8000"
OUTPUT_DIR  = Path("C:/ComfyUI/output")
GODOT_OUT   = Path("C:/Users/0/ai프로젝트/wordPuzzle_Godot/Puzzle/word-puzzle/assets/ui/logo_emblem.png")
WF_FILE     = Path(__file__).parent / "ui_logo_emblem.json"

# 1. 큐 제출
print("ComfyUI에 큐 제출 중...")
wf = json.loads(WF_FILE.read_text(encoding="utf-8"))
r  = requests.post(f"{COMFYUI_URL}/prompt", json={"prompt": wf})
pid = r.json().get("prompt_id")
print(f"등록됨 (ID: {pid[:8]}...)")

# 2. 완료 대기
print("생성 대기 중", end="", flush=True)
while True:
    h = requests.get(f"{COMFYUI_URL}/history/{pid}").json()
    if pid in h and h[pid].get("outputs"):
        print(" 완료!")
        break
    print(".", end="", flush=True)
    time.sleep(2)

# 3. 최신 파일 찾기
src = max(OUTPUT_DIR.glob("logo_emblem*.png"), key=lambda p: p.stat().st_mtime)
print(f"파일: {src.name}")

# 4. 배경 제거
print("배경 제거 중...")
result = rembg.remove(src.read_bytes())
img = Image.open(io.BytesIO(result)).convert("RGBA")

# 5. 256x256 리사이즈 (홈 화면 타이틀 위 엠블럼용)
img = img.resize((256, 256), Image.LANCZOS)

# 6. 저장
GODOT_OUT.parent.mkdir(parents=True, exist_ok=True)
img.save(GODOT_OUT, "PNG")
print(f"저장 완료 → {GODOT_OUT}")
print()
print("다음 단계: home_screen.gd 에서 TitleLabel 위에 이 이미지를 추가하세요.")
