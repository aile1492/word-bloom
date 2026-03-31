# -*- coding: utf-8 -*-
import sys
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
"""
아이콘 후처리: 배경 제거(rembg) + 리사이즈 + Godot 폴더 저장

필수: pip install rembg pillow onnxruntime

사용법:
  python post_process_icons.py
  python post_process_icons.py --dry-run
"""
import sys, argparse, io
from pathlib import Path
from datetime import datetime

COMFYUI_OUTPUT = Path("C:/ComfyUI/output")
GODOT_ICONS    = Path("C:/Users/0/ai프로젝트/wordPuzzle_Godot/Puzzle/word-puzzle/assets/icons")

# prefix → (출력경로, 크기, rembg여부)
TARGETS = [
    ("icon_settings",       GODOT_ICONS / "ui/icon_settings.png",           (64, 64),  True),
    ("icon_back",           GODOT_ICONS / "ui/icon_back.png",                (64, 64),  True),
    ("icon_tab_daily",      GODOT_ICONS / "tabs/icon_tab_daily.png",         (64, 64),  True),
    ("icon_tab_team",       GODOT_ICONS / "tabs/icon_tab_team.png",          (64, 64),  True),
    ("icon_tab_collection", GODOT_ICONS / "tabs/icon_tab_collection.png",    (64, 64),  True),
    ("icon_tab_shop",       GODOT_ICONS / "tabs/icon_tab_shop.png",          (64, 64),  True),
    # 기존 아이콘도 재처리 (assets/ui/ 에 이미 있지만 icons/ui/ 에도 복사)
    ("icon_coin",           GODOT_ICONS / "ui/icon_coin.png",                (64, 64),  False),
    ("icon_hint",           GODOT_ICONS / "ui/icon_hint.png",                (64, 64),  False),
]

def log(msg, level="INFO"):
    ts = datetime.now().strftime("%H:%M:%S")
    icons = {"INFO":"✅","WARN":"⚠️ ","ERR":"❌","RUN":"🔄","DONE":"🎉","SKIP":"⏭️ "}
    print(f"[{ts}] {icons.get(level,'  ')} {msg}")

def find_latest(prefix):
    files = list(COMFYUI_OUTPUT.glob(f"{prefix}*.png"))
    # Also check assets/ui for coin/hint (already processed)
    if not files:
        alt = Path("C:/Users/0/ai프로젝트/wordPuzzle_Godot/Puzzle/word-puzzle/assets/ui") / f"{prefix}.png"
        if alt.exists():
            return alt
    return max(files, key=lambda p: p.stat().st_mtime) if files else None

def process(prefix, dst, size, do_rembg, dry_run):
    src = find_latest(prefix)
    if src is None:
        log(f"[{prefix}] 파일 없음 — 먼저 생성하세요", "WARN"); return False
    log(f"[{prefix}] 입력: {src.name}", "INFO")
    if dry_run:
        log(f"[{prefix}] [DRY RUN] → {dst.name} ({size})", "SKIP"); return True

    from PIL import Image
    import rembg

    img = Image.open(src).convert("RGBA")
    if do_rembg:
        log(f"[{prefix}] 배경 제거 중...", "RUN")
        result = rembg.remove(src.read_bytes())
        img = Image.open(io.BytesIO(result)).convert("RGBA")
    img = img.resize(size, Image.LANCZOS)
    dst.parent.mkdir(parents=True, exist_ok=True)
    img.save(dst, "PNG")
    log(f"[{prefix}] 저장 완료 → {dst}  ({dst.stat().st_size//1024}KB)", "DONE")
    return True

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--dry-run", action="store_true")
    args = p.parse_args()

    if not args.dry_run:
        missing = []
        try: from PIL import Image
        except: missing.append("pillow")
        try: import rembg
        except: missing.append("rembg")
        try: import onnxruntime
        except: missing.append("onnxruntime")
        if missing:
            log(f"패키지 필요: pip install {' '.join(missing)}", "ERR"); sys.exit(1)

    print("═"*60); print("  아이콘 후처리 — 배경 제거 + 리사이즈"); print("═"*60)
    ok = fail = 0
    for prefix, dst, size, do_rembg in TARGETS:
        print()
        if process(prefix, dst, size, do_rembg, args.dry_run): ok += 1
        else: fail += 1
    print(); print("═"*60)
    log(f"완료: 성공 {ok}개 / 실패 {fail}개", "DONE")
    if ok and not args.dry_run:
        print(); print(f"  저장 위치: {GODOT_ICONS}")

if __name__ == "__main__": main()
