"""
ui_extractor.py
===============
레퍼런스 스크린샷에서 UI 레이아웃 값을 자동 추출하여
game_screen.gd 변수 형식으로 출력하는 도구.

사용법:
    python ui_extractor.py                  # 파일 선택 다이얼로그
    python ui_extractor.py <경로> [--apply]  # 파일 직접 지정

옵션:
    --apply   game_screen.gd에 직접 적용 (백업 자동 생성)
"""

import sys
import json
import base64
import re
import shutil
from pathlib import Path
from datetime import datetime

try:
    import anthropic
except ImportError:
    print("[오류] anthropic 패키지가 없습니다. pip install anthropic 을 먼저 실행하세요.")
    sys.exit(1)

try:
    from PIL import Image
except ImportError:
    print("[오류] pillow 패키지가 없습니다. pip install pillow 을 먼저 실행하세요.")
    sys.exit(1)


# ── 설정 ────────────────────────────────────────────────────────────────────

GAME_W = 1080
GAME_H = 1920

GD_FILE = Path("C:/Users/0/ai프로젝트/wordPuzzle_Godot/Puzzle/word-puzzle/scripts/ui/screens/game_screen.gd")

# 레이아웃 변수 목록 (game_screen.gd 에서 교체할 변수명)
LAYOUT_VARS = [
    "_lay_topbar_h", "_lay_banner_h", "_lay_wordbank_h",
    "_lay_inner_gap", "_lay_gap", "_lay_adbanner_h",
    "_lay_top_btn_size", "_lay_top_btn_y", "_lay_level_info_y",
    "_lay_stage_y", "_lay_rate_y", "_lay_grid_y_offset",
]
FONT_VARS = [
    "_font_stage", "_font_solve_rate", "_font_coin",
    "_font_theme", "_font_wordbank_max", "_font_btn_action", "_font_ad",
]


# ── 이미지 로드 & 인코딩 ────────────────────────────────────────────────────

def load_image(path: str) -> tuple[str, int, int, str]:
    """이미지를 로드하고 base64와 해상도를 반환한다."""
    img_path = Path(path)
    if not img_path.exists():
        print(f"[오류] 파일을 찾을 수 없습니다: {path}")
        sys.exit(1)

    img = Image.open(img_path)
    w, h = img.size
    suffix = img_path.suffix.lower()
    media_map = {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".webp": "image/webp"}
    media_type = media_map.get(suffix, "image/png")

    with open(img_path, "rb") as f:
        b64 = base64.standard_b64encode(f.read()).decode("utf-8")

    print(f"[이미지] {img_path.name}  해상도: {w}×{h}  타입: {media_type}")
    return b64, w, h, media_type


# ── Claude Vision 분석 ───────────────────────────────────────────────────────

PROMPT = """\
이 이미지는 워드 퍼즐 모바일 게임 스크린샷이다. ({W}×{H} 픽셀)

아래 UI 요소들의 픽셀 좌표와 크기를 최대한 정확하게 측정하라.
모든 측정값은 이 이미지의 픽셀 기준이다.

반드시 JSON 형식으로만 응답하라. 설명 텍스트 없이 JSON만 출력.

{{
  "ref_width": {W},
  "ref_height": {H},
  "topbar": {{
    "height": <TopBar 전체 높이 px>,
    "btn_center_y": <←/★/🛒 버튼들의 중심 Y px>,
    "btn_diameter": <버튼 지름 px>,
    "stage_label_center_y": <"레벨 N" 텍스트 중심 Y px>,
    "stage_font_size_est": <"레벨 N" 텍스트 높이 px (폰트 크기 추정)>,
    "rate_label_center_y": <"XX%의 플레이어..." 텍스트 중심 Y px>,
    "rate_font_size_est": <해당 텍스트 높이 px>,
    "coin_font_size_est": <코인 숫자 텍스트 높이 px>
  }},
  "theme_banner": {{
    "y_top": <ThemeBanner 상단 Y px>,
    "height": <높이 px>,
    "text_height_est": <배너 내 텍스트 높이 px>
  }},
  "word_bank": {{
    "y_top": <WordBank 카드 상단 Y px>,
    "height": <높이 px>,
    "word_font_size_est": <단어 텍스트 높이 px>
  }},
  "grid": {{
    "y_top": <격자 카드 상단 Y px>,
    "y_bottom": <격자 카드 하단 Y px>,
    "cols": <열 수>,
    "rows": <행 수>
  }},
  "action_buttons": {{
    "y_center": <6개 하단 액션버튼 중심 Y px>,
    "diameter": <버튼 지름 px>,
    "font_size_est": <버튼 내 텍스트(200🪙 등) 높이 px>
  }},
  "ad_banner": {{
    "y_top": <광고 배너 상단 Y px>,
    "height": <높이 px>
  }},
  "gaps": {{
    "banner_to_wordbank": <ThemeBanner 하단 ~ WordBank 상단 간격 px>,
    "wordbank_to_grid": <WordBank 하단 ~ Grid 상단 간격 px>
  }}
}}
"""


def _get_api_key() -> str:
    """API 키를 환경변수 → .env 파일 → 대화식 입력 순으로 가져온다."""
    import os
    key = os.environ.get("ANTHROPIC_API_KEY", "").strip()
    if key:
        return key

    env_file = Path(__file__).parent / ".env"
    if env_file.exists():
        for line in env_file.read_text(encoding="utf-8").splitlines():
            if line.startswith("ANTHROPIC_API_KEY="):
                key = line.split("=", 1)[1].strip().strip('"').strip("'")
                if key:
                    return key

    print("\n[API 키 필요] Anthropic API 키를 입력하세요 (sk-ant-api03-...)")
    print("  한 번 입력하면 .env 파일에 저장되어 다음부터 자동 사용됩니다.")
    key = input("  API Key: ").strip()
    if key:
        env_file.write_text(f'ANTHROPIC_API_KEY="{key}"\n', encoding="utf-8")
        print(f"  저장됨: {env_file}")
    return key


def analyze_screenshot(b64: str, w: int, h: int, media_type: str) -> dict:
    """Claude Vision API로 스크린샷을 분석하여 측정값 dict를 반환한다."""
    api_key = _get_api_key()
    if not api_key:
        print("[오류] API 키가 없어 분석을 진행할 수 없습니다.")
        sys.exit(1)
    client = anthropic.Anthropic(api_key=api_key)
    prompt_text = PROMPT.replace("{W}", str(w)).replace("{H}", str(h))

    print("[Claude] 스크린샷 분석 중... (수 초 소요)")
    response = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1500,
        messages=[{
            "role": "user",
            "content": [
                {
                    "type": "image",
                    "source": {"type": "base64", "media_type": media_type, "data": b64},
                },
                {"type": "text", "text": prompt_text},
            ],
        }],
    )

    raw = response.content[0].text.strip()

    # JSON 블록 추출 (```json ... ``` 또는 { ... } 형태 모두 처리)
    json_match = re.search(r"```(?:json)?\s*([\s\S]+?)\s*```", raw)
    if json_match:
        raw = json_match.group(1)
    else:
        # { 로 시작하는 첫 번째 JSON 블록 추출
        brace_start = raw.find("{")
        if brace_start != -1:
            raw = raw[brace_start:]

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        print(f"[오류] JSON 파싱 실패: {e}")
        print("원본 응답:")
        print(raw)
        sys.exit(1)

    return data


# ── 좌표 변환 ────────────────────────────────────────────────────────────────

def scale_h(px: float, ref_h: int) -> float:
    """레퍼런스 높이 px → 게임 높이 px (1920 기준)."""
    return round(px / ref_h * GAME_H, 1)

def scale_w(px: float, ref_w: int) -> float:
    """레퍼런스 너비 px → 게임 너비 px (1080 기준)."""
    return round(px / ref_w * GAME_W, 1)

def estimate_font(text_height_px: float, ref_w: int) -> int:
    """텍스트 높이(px)에서 폰트 크기를 추정한다. 0.75 ratio 적용."""
    scaled = text_height_px / ref_w * GAME_W
    return max(8, int(scaled * 0.75))


def convert_to_godot_vars(data: dict) -> dict:
    """분석 데이터를 Godot 레이아웃 변수값으로 변환한다."""
    ref_w: int = data.get("ref_width", 720)
    ref_h: int = data.get("ref_height", 1560)

    tb  = data.get("topbar", {})
    thm = data.get("theme_banner", {})
    wb  = data.get("word_bank", {})
    grd = data.get("grid", {})
    act = data.get("action_buttons", {})
    ad  = data.get("ad_banner", {})
    gaps = data.get("gaps", {})

    topbar_h      = scale_h(tb.get("height", 207), ref_h)
    btn_diameter  = scale_w(tb.get("btn_diameter", 75), ref_w)
    btn_center_y  = scale_h(tb.get("btn_center_y", 80), ref_h)
    btn_top_y     = round(btn_center_y - btn_diameter / 2, 1)

    stage_cy = scale_h(tb.get("stage_label_center_y", 107), ref_h)
    rate_cy  = scale_h(tb.get("rate_label_center_y", 155), ref_h)

    LEVEL_INFO_Y = 36.0   # 고정값 유지
    STAGE_H      = 60.0
    RATE_H       = 100.0
    stage_y = round(stage_cy - STAGE_H / 2 - LEVEL_INFO_Y, 1)
    rate_y  = round(rate_cy  - RATE_H  / 2 - LEVEL_INFO_Y, 1)

    banner_h  = scale_h(thm.get("height", 55), ref_h)
    wb_h      = scale_h(wb.get("height", 166), ref_h)
    inner_gap = scale_h(gaps.get("banner_to_wordbank", 4), ref_h)
    lay_gap   = scale_h(gaps.get("wordbank_to_grid", 32), ref_h)
    ad_h      = scale_h(ad.get("height", 125), ref_h)

    theme_font_pct = 0.0
    if thm.get("text_height_est") and thm.get("height"):
        theme_font_pct = round(thm["text_height_est"] / thm["height"] * 100, 1)

    vars_out = {
        # layout
        "_lay_topbar_h":     topbar_h,
        "_lay_banner_h":     banner_h,
        "_lay_wordbank_h":   wb_h,
        "_lay_inner_gap":    max(0.0, inner_gap),
        "_lay_gap":          lay_gap,
        "_lay_adbanner_h":   ad_h,
        "_lay_top_btn_size": btn_diameter,
        "_lay_top_btn_y":    max(0.0, btn_top_y),
        "_lay_level_info_y": LEVEL_INFO_Y,
        "_lay_stage_y":      max(0.0, stage_y),
        "_lay_rate_y":       max(0.0, rate_y),
        "_lay_grid_y_offset": -41.0,   # 미세 조정값은 보존
        # fonts
        "_font_stage":        float(estimate_font(tb.get("stage_font_size_est", 38), ref_w)),
        "_font_solve_rate":   float(estimate_font(tb.get("rate_font_size_est", 16), ref_w)),
        "_font_coin":         float(estimate_font(tb.get("coin_font_size_est", 20), ref_w)),
        "_font_theme":        theme_font_pct if theme_font_pct > 0 else 51.0,
        "_font_wordbank_max": float(estimate_font(wb.get("word_font_size_est", 30), ref_w)),
        "_font_btn_action":   float(estimate_font(act.get("font_size_est", 14), ref_w)),
        "_font_ad":           28.0,   # 광고 배너 폰트는 고정
    }
    return vars_out


# ── 출력 ─────────────────────────────────────────────────────────────────────

def print_vars(vars_out: dict) -> None:
    print("\n" + "=" * 60)
    print("  추출된 Godot 레이아웃 변수")
    print("=" * 60)
    print("## 레이아웃")
    layout_keys = [k for k in vars_out if k.startswith("_lay_")]
    for k in layout_keys:
        print(f"  var {k:<25} = {vars_out[k]}")
    print("\n## 폰트")
    font_keys = [k for k in vars_out if k.startswith("_font_")]
    for k in font_keys:
        print(f"  var {k:<25} = {vars_out[k]}")
    print("=" * 60)


# ── game_screen.gd 적용 ──────────────────────────────────────────────────────

def apply_to_gd(vars_out: dict) -> None:
    if not GD_FILE.exists():
        print(f"[오류] 파일을 찾을 수 없습니다: {GD_FILE}")
        return

    # 백업
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup = GD_FILE.with_name(f"game_screen.gd.bak_{ts}")
    shutil.copy2(GD_FILE, backup)
    print(f"\n[백업] {backup.name}")

    content = GD_FILE.read_text(encoding="utf-8")
    changed = 0

    for var_name, value in vars_out.items():
        # float 값 포맷: 소수점 1자리 유지
        if isinstance(value, float) and value == int(value):
            val_str = f"{value:.1f}"
        else:
            val_str = f"{value:.1f}"

        # 패턴: var _lay_xxx: float = 123.0  (주석 포함 가능)
        pattern = rf"(var\s+{re.escape(var_name)}\s*:\s*float\s*=\s*)[^\s#\n]+"
        replacement = rf"\g<1>{val_str}"
        new_content, n = re.subn(pattern, replacement, content)
        if n > 0:
            content = new_content
            changed += 1

    GD_FILE.write_text(content, encoding="utf-8")
    print(f"[적용] {changed}/{len(vars_out)}개 변수 업데이트 완료 → {GD_FILE.name}")


# ── 진입점 ───────────────────────────────────────────────────────────────────

def pick_file() -> str:
    """tkinter 파일 선택 다이얼로그로 이미지 파일 경로를 반환한다."""
    try:
        import tkinter as tk
        from tkinter import filedialog
        root = tk.Tk()
        root.withdraw()
        root.lift()
        root.attributes("-topmost", True)
        path = filedialog.askopenfilename(
            title="레퍼런스 스크린샷 선택",
            filetypes=[("이미지", "*.png *.jpg *.jpeg *.webp"), ("전체", "*.*")],
            initialdir=str(Path.home() / "Downloads"),
        )
        root.destroy()
        return path
    except Exception as e:
        print(f"[파일 선택 오류] {e}")
        return ""


def main() -> None:
    args = sys.argv[1:]
    if args and args[0] in ("-h", "--help"):
        print(__doc__)
        sys.exit(0)

    do_apply  = "--apply"     in args
    from_json = next((a.split("=", 1)[1] for a in args if a.startswith("--from-json=")), None)
    positional = [a for a in args if not a.startswith("--")]

    # ── JSON 직접 입력 모드 ──────────────────────────────────────────────────
    if from_json:
        json_path = Path(from_json)
        if not json_path.exists():
            print(f"[오류] JSON 파일을 찾을 수 없습니다: {from_json}")
            sys.exit(1)
        data = json.loads(json_path.read_text(encoding="utf-8"))
        print(f"[JSON] {json_path.name} 로드 완료")
        vars_out = convert_to_godot_vars(data)
        print_vars(vars_out)
        if do_apply:
            apply_to_gd(vars_out)
        return

    # ── 스크린샷 분석 모드 ───────────────────────────────────────────────────
    if positional:
        screenshot_path = positional[0]
    else:
        print("[안내] 파일 선택 다이얼로그를 엽니다...")
        screenshot_path = pick_file()
        if not screenshot_path:
            print("[취소] 파일을 선택하지 않았습니다.")
            sys.exit(0)

    # 1. 이미지 로드
    b64, ref_w, ref_h, media_type = load_image(screenshot_path)

    # 2. Claude로 분석
    data = analyze_screenshot(b64, ref_w, ref_h, media_type)

    # 2-1. 분석 결과를 JSON으로 저장 (재사용 가능)
    json_out = Path(screenshot_path).with_suffix(".analysis.json")
    json_out.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[저장] 분석 결과: {json_out.name}  (다음엔 --from-json={json_out.name} 으로 재사용 가능)")

    # 3. Godot 변수로 변환
    vars_out = convert_to_godot_vars(data)

    # 4. 출력
    print_vars(vars_out)

    # 5. 적용 (--apply 옵션)
    if do_apply:
        confirm = input("\ngame_screen.gd에 적용하시겠습니까? (y/N): ").strip().lower()
        if confirm == "y":
            apply_to_gd(vars_out)
        else:
            print("[취소] 적용하지 않음.")
    else:
        print("\n--apply 옵션을 추가하면 game_screen.gd에 자동 적용됩니다.")
        print(f"  python ui_extractor.py {screenshot_path} --apply")


if __name__ == "__main__":
    main()
