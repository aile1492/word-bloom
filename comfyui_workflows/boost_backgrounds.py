## boost_backgrounds.py
## bg_*.png 배경 이미지의 채도·밝기·대비를 일괄 향상한다.
## 원본 파일을 덮어씁니다 (원본은 C:/ComfyUI/output/ 에 보존됨).

import sys
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import os
from pathlib import Path
from PIL import Image, ImageEnhance

BG_DIR = Path("C:/Users/0/ai프로젝트/wordPuzzle_Godot/Puzzle/word-puzzle/assets/backgrounds")

SATURATION_FACTOR = 1.4
BRIGHTNESS_FACTOR = 1.1
CONTRAST_FACTOR   = 1.1


def boost_image(path: Path) -> None:
    img = Image.open(path).convert("RGB")

    img = ImageEnhance.Color(img).enhance(SATURATION_FACTOR)
    img = ImageEnhance.Brightness(img).enhance(BRIGHTNESS_FACTOR)
    img = ImageEnhance.Contrast(img).enhance(CONTRAST_FACTOR)

    img.save(path)
    print(f"  [OK] {path.name}")


def main() -> None:
    if not BG_DIR.exists():
        print(f"[ERROR] 디렉터리를 찾을 수 없습니다: {BG_DIR}")
        sys.exit(1)

    png_files = sorted(
        p for p in BG_DIR.glob("bg_*.png")
        if not p.suffix == ".import"
    )

    if not png_files:
        print(f"[INFO] bg_*.png 파일이 없습니다: {BG_DIR}")
        return

    print(f"배경 이미지 향상 시작 — {len(png_files)}개 파일")
    print(f"  채도 ×{SATURATION_FACTOR}  밝기 ×{BRIGHTNESS_FACTOR}  대비 ×{CONTRAST_FACTOR}")
    print()

    for path in png_files:
        boost_image(path)

    print()
    print(f"완료 — {len(png_files)}개 파일 처리됨.")


if __name__ == "__main__":
    main()
