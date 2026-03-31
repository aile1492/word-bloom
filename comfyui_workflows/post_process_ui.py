# -*- coding: utf-8 -*-
"""
WordPuzzle UI 이미지 후처리 스크립트
ComfyUI 생성 후 배경 제거(rembg) + 리사이즈를 자동으로 수행.

필수 패키지:
  pip install rembg pillow onnxruntime

사용법:
  python post_process_ui.py            # 전체 처리
  python post_process_ui.py --dry-run  # 파일 탐색만 (실제 처리 안 함)
  python post_process_ui.py --only tile
  python post_process_ui.py --only icon
  python post_process_ui.py --only etc

출력 폴더:
  C:/Users/0/ai프로젝트/wordPuzzle_Godot/Puzzle/word-puzzle/assets/ui/
"""

import sys
import argparse
import shutil
from pathlib import Path
from datetime import datetime

# ──────────────────────────────────────────────
# 설정
# ──────────────────────────────────────────────
COMFYUI_OUTPUT = Path("C:/ComfyUI/output")
GODOT_UI_DIR   = Path("C:/Users/0/ai프로젝트/wordPuzzle_Godot/Puzzle/word-puzzle/assets/ui")

# 처리 대상 정의
# prefix        : ComfyUI output 파일명 앞부분
# out_name      : 최종 저장 파일명
# size          : 리사이즈 목표 (None이면 원본 유지)
# rembg         : True면 배경 제거
# group         : --only 옵션 그룹
TARGETS = [
    {
        "prefix":   "tile_normal",
        "out_name": "tile_normal.png",
        "size":     (128, 128),
        "rembg":    True,
        "group":    "tile",
        "desc":     "타일 기본     512→128px, 배경 제거",
    },
    {
        "prefix":   "tile_selected",
        "out_name": "tile_selected.png",
        "size":     (128, 128),
        "rembg":    True,
        "group":    "tile",
        "desc":     "타일 선택중   512→128px, 배경 제거",
    },
    {
        "prefix":   "tile_correct",
        "out_name": "tile_correct.png",
        "size":     (128, 128),
        "rembg":    True,
        "group":    "tile",
        "desc":     "타일 정답     512→128px, 배경 제거",
    },
    {
        "prefix":   "icon_coin",
        "out_name": "icon_coin.png",
        "size":     (64, 64),
        "rembg":    True,
        "group":    "icon",
        "desc":     "코인 아이콘   512→64px, 배경 제거",
    },
    {
        "prefix":   "icon_hint",
        "out_name": "icon_hint.png",
        "size":     (64, 64),
        "rembg":    True,
        "group":    "icon",
        "desc":     "힌트 아이콘   512→64px, 배경 제거",
    },
    {
        "prefix":   "app_icon",
        "out_name": "app_icon.png",
        "size":     (1024, 1024),
        "rembg":    False,
        "group":    "etc",
        "desc":     "앱 아이콘     1024px 유지, 배경 유지",
    },
    {
        "prefix":   "ui_splash",
        "out_name": "ui_splash.png",
        "size":     (576, 300),
        "rembg":    False,
        "group":    "etc",
        "desc":     "스플래시      576×320→576×300 크롭, 배경 유지",
    },
]


# ──────────────────────────────────────────────
# 유틸
# ──────────────────────────────────────────────
def log(msg, level="INFO"):
    ts = datetime.now().strftime("%H:%M:%S")
    icons = {"INFO": "✅", "WARN": "⚠️ ", "ERR": "❌", "RUN": "🔄", "DONE": "🎉", "SKIP": "⏭️ "}
    print(f"[{ts}] {icons.get(level, '  ')} {msg}")


def separator(char="─", width=60):
    print(char * width)


def find_latest_file(prefix: str) -> Path | None:
    """ComfyUI output 폴더에서 prefix로 시작하는 가장 최근 파일 반환."""
    candidates = list(COMFYUI_OUTPUT.glob(f"{prefix}*.png"))
    if not candidates:
        return None
    return max(candidates, key=lambda p: p.stat().st_mtime)


def check_packages() -> bool:
    """필수 패키지 설치 여부 확인."""
    missing = []
    try:
        from PIL import Image  # noqa
    except ImportError:
        missing.append("pillow")
    try:
        import rembg  # noqa
    except ImportError:
        missing.append("rembg")
    try:
        import onnxruntime  # noqa
    except ImportError:
        missing.append("onnxruntime")

    if missing:
        log(f"필수 패키지 없음: {', '.join(missing)}", "ERR")
        log(f"  설치 명령: pip install {' '.join(missing)}", "ERR")
        return False
    return True


# ──────────────────────────────────────────────
# 처리 함수
# ──────────────────────────────────────────────
def process_target(target: dict, dry_run: bool = False) -> bool:
    from PIL import Image
    import rembg

    prefix   = target["prefix"]
    out_name = target["out_name"]
    size     = target["size"]
    do_rembg = target["rembg"]

    # 입력 파일 탐색
    src = find_latest_file(prefix)
    if src is None:
        log(f"{prefix}* 파일을 {COMFYUI_OUTPUT} 에서 찾을 수 없음", "WARN")
        return False

    log(f"  입력: {src.name}", "INFO")

    if dry_run:
        steps = []
        if do_rembg:
            steps.append("배경 제거")
        if size:
            steps.append(f"리사이즈 {size[0]}×{size[1]}")
        steps.append(f"저장 → {out_name}")
        log(f"  [DRY RUN] {' → '.join(steps)}", "SKIP")
        return True

    # ── 이미지 로드
    img = Image.open(src).convert("RGBA")

    # ── 배경 제거 (rembg)
    if do_rembg:
        log("  배경 제거 중... (첫 실행 시 모델 다운로드 ~170MB)", "RUN")
        img_bytes = src.read_bytes()
        result_bytes = rembg.remove(img_bytes)
        import io
        img = Image.open(io.BytesIO(result_bytes)).convert("RGBA")
        log("  배경 제거 완료", "INFO")

    # ── 리사이즈
    if size and img.size != size:
        orig_size = img.size
        # ui_splash: 576×320 → 576×300 (상단 크롭)
        if target["prefix"] == "ui_splash" and img.size[1] > size[1]:
            img = img.crop((0, 0, img.size[0], size[1]))
            log(f"  크롭: {orig_size} → {img.size}", "INFO")
        else:
            img = img.resize(size, Image.LANCZOS)
            log(f"  리사이즈: {orig_size} → {size}", "INFO")

    # ── 저장
    GODOT_UI_DIR.mkdir(parents=True, exist_ok=True)
    dst = GODOT_UI_DIR / out_name
    img.save(dst, "PNG")
    size_kb = dst.stat().st_size / 1024
    log(f"  저장: {dst}  ({size_kb:.0f} KB)", "DONE")
    return True


# ──────────────────────────────────────────────
# 메인
# ──────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="WordPuzzle UI 이미지 후처리")
    parser.add_argument("--dry-run", action="store_true", help="실제 처리 없이 탐색만")
    parser.add_argument("--only",    choices=["tile", "icon", "etc"], help="그룹별 처리")
    args = parser.parse_args()

    separator("═")
    print("  WordPuzzle UI 후처리 — 배경 제거 + 리사이즈")
    separator("═")

    if args.dry_run:
        log("DRY RUN 모드 (실제 저장 안 함)")

    if not args.dry_run and not check_packages():
        sys.exit(1)

    targets = [t for t in TARGETS if not args.only or t["group"] == args.only]

    if not COMFYUI_OUTPUT.exists():
        log(f"ComfyUI output 폴더 없음: {COMFYUI_OUTPUT}", "ERR")
        sys.exit(1)

    separator()
    print(f"  처리 대상: {len(targets)}개  |  출력: {GODOT_UI_DIR}")
    separator()

    ok_count   = 0
    fail_count = 0

    for target in targets:
        print()
        log(f"[{target['group'].upper()}] {target['desc']}", "RUN")
        success = process_target(target, dry_run=args.dry_run)
        if success:
            ok_count += 1
        else:
            fail_count += 1

    # 결과 요약
    print()
    separator("═")
    log(f"완료: 성공 {ok_count}개 / 실패 {fail_count}개", "DONE")
    separator("═")

    if fail_count > 0:
        print()
        log("실패 항목은 ComfyUI에서 해당 이미지를 먼저 생성하세요.", "WARN")
        log("  python auto_generate_ui.py --all", "WARN")

    if ok_count > 0 and not args.dry_run:
        print()
        print(f"  Godot 프로젝트 경로:")
        print(f"    {GODOT_UI_DIR}")
        print()
        print("  배경 제거된 파일 (투명 PNG):")
        for t in targets:
            if t["rembg"]:
                dst = GODOT_UI_DIR / t["out_name"]
                if dst.exists():
                    print(f"    ✅ {t['out_name']}")
        print()
        print("  배경 유지 파일:")
        for t in targets:
            if not t["rembg"]:
                dst = GODOT_UI_DIR / t["out_name"]
                if dst.exists():
                    print(f"    ✅ {t['out_name']}")


if __name__ == "__main__":
    main()
