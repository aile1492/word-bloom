# -*- coding: utf-8 -*-
import sys
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import io, time, requests
from pathlib import Path
from PIL import Image
import rembg

COMFYUI_URL   = "http://127.0.0.1:8000"
OUTPUT_DIR    = Path("C:/ComfyUI/output")
GODOT_OUT     = Path("C:/Users/0/ai프로젝트/wordPuzzle_Godot/Puzzle/word-puzzle/assets/icons/tabs/home.png")

# 1. 가장 최근 icon_tab_home 파일 찾기 (이미 생성됐으면 바로 처리)
existing = sorted(OUTPUT_DIR.glob("icon_tab_home*.png"), key=lambda p: p.stat().st_mtime)
if existing:
    src = existing[-1]
    print(f"파일 발견: {src.name}")
else:
    print("icon_tab_home*.png 파일이 없습니다. ComfyUI에서 생성 완료를 기다립니다...")
    # 폴링
    while True:
        files = sorted(OUTPUT_DIR.glob("icon_tab_home*.png"), key=lambda p: p.stat().st_mtime)
        if files:
            src = files[-1]
            print(f"\n완료! → {src.name}")
            break
        print(".", end="", flush=True)
        time.sleep(2)

# 2. 배경 제거
print("배경 제거 중...")
result = rembg.remove(src.read_bytes())
img = Image.open(io.BytesIO(result)).convert("RGBA")

# 3. 리사이즈 64x64
img = img.resize((64, 64), Image.LANCZOS)

# 4. 저장
GODOT_OUT.parent.mkdir(parents=True, exist_ok=True)
img.save(GODOT_OUT, "PNG")
print(f"저장 완료 → {GODOT_OUT}")
