"""
UI Layout Extractor GUI
레퍼런스 스크린샷을 선택하면 자동으로 UI 레이아웃 값을 추출하여
game_screen.gd에 적용하는 GUI 도구.
"""

import sys
import json
import base64
import re
import shutil
import threading
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from pathlib import Path
from datetime import datetime


# ── 설정 ──────────────────────────────────────────────────────────────────────

GAME_W = 1080
GAME_H = 1920

GD_FILE = Path("C:/Users/0/ai프로젝트/wordPuzzle_Godot/Puzzle/word-puzzle/scripts/ui/screens/game_screen.gd")
ENV_FILE = Path(__file__).parent / ".env"

COLORS = {
    "bg":       "#1E1E2E",
    "surface":  "#2A2A3E",
    "border":   "#3D3D5C",
    "accent":   "#E91E8C",
    "accent2":  "#7C3AED",
    "text":     "#E8E8F0",
    "text_dim": "#888899",
    "success":  "#22C55E",
    "warning":  "#F59E0B",
    "error":    "#EF4444",
}


# ── 레이아웃 변환 로직 (ui_extractor.py 와 동일) ──────────────────────────────

def scale_h(px, ref_h):
    return round(px / ref_h * GAME_H, 1)

def scale_w(px, ref_w):
    return round(px / ref_w * GAME_W, 1)

def estimate_font(text_height_px, ref_w):
    scaled = text_height_px / ref_w * GAME_W
    return max(8, int(scaled * 0.75))

def convert_to_godot_vars(data: dict) -> dict:
    ref_w = data.get("ref_width", 720)
    ref_h = data.get("ref_height", 1560)

    tb   = data.get("topbar", {})
    thm  = data.get("theme_banner", {})
    wb   = data.get("word_bank", {})
    act  = data.get("action_buttons", {})
    ad   = data.get("ad_banner", {})
    gaps = data.get("gaps", {})

    topbar_h     = scale_h(tb.get("height", 207), ref_h)
    btn_diameter = scale_w(tb.get("btn_diameter", 75), ref_w)
    btn_center_y = scale_h(tb.get("btn_center_y", 80), ref_h)
    btn_top_y    = round(btn_center_y - btn_diameter / 2, 1)

    stage_cy = scale_h(tb.get("stage_label_center_y", 108), ref_h)
    rate_cy  = scale_h(tb.get("rate_label_center_y", 155), ref_h)

    LEVEL_INFO_Y = 36.0
    STAGE_H = 60.0
    RATE_H  = 100.0
    stage_y = round(stage_cy - STAGE_H / 2 - LEVEL_INFO_Y, 1)
    rate_y  = round(rate_cy  - RATE_H  / 2 - LEVEL_INFO_Y, 1)

    banner_h  = scale_h(thm.get("height", 55), ref_h)
    wb_h      = scale_h(wb.get("height", 166), ref_h)
    inner_gap = scale_h(gaps.get("banner_to_wordbank", 0), ref_h)
    lay_gap   = scale_h(gaps.get("wordbank_to_grid", 30), ref_h)
    ad_h      = scale_h(ad.get("height", 125), ref_h)

    theme_font_pct = 0.0
    if thm.get("text_height_est") and thm.get("height"):
        theme_font_pct = round(thm["text_height_est"] / thm["height"] * 100, 1)

    return {
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
        "_lay_grid_y_offset": -41.0,
        "_font_stage":       float(estimate_font(tb.get("stage_font_size_est", 38), ref_w)),
        "_font_solve_rate":  float(estimate_font(tb.get("rate_font_size_est", 15), ref_w)),
        "_font_coin":        float(estimate_font(tb.get("coin_font_size_est", 20), ref_w)),
        "_font_theme":       theme_font_pct if theme_font_pct > 0 else 51.0,
        "_font_wordbank_max": float(estimate_font(wb.get("word_font_size_est", 34), ref_w)),
        "_font_btn_action":  float(estimate_font(act.get("font_size_est", 14), ref_w)),
        "_font_ad":          28.0,
    }

def apply_to_gd(vars_out: dict) -> tuple[bool, str]:
    if not GD_FILE.exists():
        return False, f"파일 없음: {GD_FILE}"
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup = GD_FILE.with_name(f"game_screen.gd.bak_{ts}")
    shutil.copy2(GD_FILE, backup)
    content = GD_FILE.read_text(encoding="utf-8")
    changed = 0
    for var_name, value in vars_out.items():
        val_str = f"{value:.1f}"
        pattern = rf"(var\s+{re.escape(var_name)}\s*:\s*float\s*=\s*)[^\s#\n]+"
        new_content, n = re.subn(pattern, rf"\g<1>{val_str}", content)
        if n > 0:
            content = new_content
            changed += 1
    GD_FILE.write_text(content, encoding="utf-8")
    return True, f"{changed}/{len(vars_out)}개 변수 적용 완료\n백업: {backup.name}"


# ── API 호출 ──────────────────────────────────────────────────────────────────

PROMPT = """\
이 이미지는 워드 퍼즐 모바일 게임 스크린샷이다. ({W}×{H} 픽셀)
아래 UI 요소들의 픽셀 좌표와 크기를 최대한 정확하게 측정하라.
반드시 JSON 형식으로만 응답하라. 설명 텍스트 없이 JSON만 출력.

{{
  "ref_width": {W},
  "ref_height": {H},
  "topbar": {{
    "height": <TopBar 전체 높이 px>,
    "btn_center_y": <←/★/🛒 버튼들의 중심 Y px>,
    "btn_diameter": <버튼 지름 px>,
    "stage_label_center_y": <"레벨 N" 텍스트 중심 Y px>,
    "stage_font_size_est": <"레벨 N" 텍스트 높이 px>,
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
    "font_size_est": <버튼 내 텍스트 높이 px>
  }},
  "ad_banner": {{
    "y_top": <광고 배너 상단 Y px>,
    "height": <높이 px>
  }},
  "gaps": {{
    "banner_to_wordbank": <ThemeBanner 하단 ~ WordBank 상단 간격 px>,
    "wordbank_to_grid": <WordBank 하단 ~ Grid 상단 간격 px>
  }}
}}"""

def analyze_with_claude(image_path: str, api_key: str) -> dict:
    import anthropic
    from PIL import Image as PILImage

    img_path = Path(image_path)
    img = PILImage.open(img_path)
    w, h = img.size
    suffix = img_path.suffix.lower()
    media_map = {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".webp": "image/webp"}
    media_type = media_map.get(suffix, "image/png")

    with open(img_path, "rb") as f:
        b64 = base64.standard_b64encode(f.read()).decode("utf-8")

    client = anthropic.Anthropic(api_key=api_key)
    prompt_text = PROMPT.replace("{W}", str(w)).replace("{H}", str(h))

    response = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1500,
        messages=[{
            "role": "user",
            "content": [
                {"type": "image", "source": {"type": "base64", "media_type": media_type, "data": b64}},
                {"type": "text", "text": prompt_text},
            ],
        }],
    )

    raw = response.content[0].text.strip()
    json_match = re.search(r"```(?:json)?\s*([\s\S]+?)\s*```", raw)
    if json_match:
        raw = json_match.group(1)
    else:
        brace = raw.find("{")
        if brace != -1:
            raw = raw[brace:]

    return json.loads(raw)


# ── GUI ───────────────────────────────────────────────────────────────────────

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("UI Layout Extractor — WordPuzzle Godot")
        self.geometry("640x780")
        self.resizable(False, False)
        self.configure(bg=COLORS["bg"])

        self._vars_out: dict = {}
        self._api_key = tk.StringVar(value=self._load_api_key())
        self._img_path = tk.StringVar()

        self._build_ui()
        self._check_gd_file()

    # ── 내부 헬퍼 ─────────────────────────────────────────────────────────────

    def _load_api_key(self) -> str:
        if ENV_FILE.exists():
            for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
                if line.startswith("ANTHROPIC_API_KEY="):
                    return line.split("=", 1)[1].strip().strip('"').strip("'")
        return ""

    def _save_api_key(self, key: str):
        ENV_FILE.write_text(f'ANTHROPIC_API_KEY="{key}"\n', encoding="utf-8")

    def _check_gd_file(self):
        if not GD_FILE.exists():
            self._log(f"⚠️  game_screen.gd 를 찾을 수 없습니다.\n   {GD_FILE}", "warning")

    # ── UI 빌드 ───────────────────────────────────────────────────────────────

    def _build_ui(self):
        pad = {"padx": 16, "pady": 8}

        # ── 타이틀 ────────────────────────────────────────────────
        title_frame = tk.Frame(self, bg=COLORS["accent"], height=4)
        title_frame.pack(fill="x")

        header = tk.Frame(self, bg=COLORS["bg"])
        header.pack(fill="x", **pad)
        tk.Label(header, text="UI Layout Extractor", font=("Segoe UI", 16, "bold"),
                 fg=COLORS["text"], bg=COLORS["bg"]).pack(anchor="w")
        tk.Label(header, text="레퍼런스 스크린샷 → game_screen.gd 자동 적용",
                 font=("Segoe UI", 9), fg=COLORS["text_dim"], bg=COLORS["bg"]).pack(anchor="w")

        sep = tk.Frame(self, bg=COLORS["border"], height=1)
        sep.pack(fill="x", padx=16)

        # ── API Key ───────────────────────────────────────────────
        key_frame = tk.LabelFrame(self, text=" API Key ", font=("Segoe UI", 9),
                                  fg=COLORS["text_dim"], bg=COLORS["surface"],
                                  bd=1, relief="flat", highlightbackground=COLORS["border"])
        key_frame.pack(fill="x", padx=16, pady=(12, 4))

        key_inner = tk.Frame(key_frame, bg=COLORS["surface"])
        key_inner.pack(fill="x", padx=8, pady=6)

        self._key_entry = tk.Entry(key_inner, textvariable=self._api_key,
                                   show="•", font=("Consolas", 10),
                                   bg=COLORS["bg"], fg=COLORS["text"],
                                   insertbackground=COLORS["text"],
                                   relief="flat", bd=4)
        self._key_entry.pack(side="left", fill="x", expand=True)

        tk.Button(key_inner, text="저장", font=("Segoe UI", 9),
                  bg=COLORS["border"], fg=COLORS["text"], relief="flat",
                  activebackground=COLORS["accent"], activeforeground="white",
                  cursor="hand2", command=self._on_save_key).pack(side="left", padx=(6, 0))

        self._key_status = tk.Label(key_frame, text="", font=("Segoe UI", 8),
                                    fg=COLORS["text_dim"], bg=COLORS["surface"])
        self._key_status.pack(anchor="w", padx=8, pady=(0, 4))
        self._update_key_status()

        # ── 이미지 선택 ────────────────────────────────────────────
        img_frame = tk.LabelFrame(self, text=" 레퍼런스 이미지 ",
                                  font=("Segoe UI", 9), fg=COLORS["text_dim"],
                                  bg=COLORS["surface"], bd=1, relief="flat",
                                  highlightbackground=COLORS["border"])
        img_frame.pack(fill="x", padx=16, pady=4)

        img_inner = tk.Frame(img_frame, bg=COLORS["surface"])
        img_inner.pack(fill="x", padx=8, pady=6)

        self._img_entry = tk.Entry(img_inner, textvariable=self._img_path,
                                   font=("Segoe UI", 9), bg=COLORS["bg"],
                                   fg=COLORS["text"], insertbackground=COLORS["text"],
                                   relief="flat", bd=4, state="readonly")
        self._img_entry.pack(side="left", fill="x", expand=True)

        tk.Button(img_inner, text="파일 선택", font=("Segoe UI", 9),
                  bg=COLORS["border"], fg=COLORS["text"], relief="flat",
                  activebackground=COLORS["accent2"], activeforeground="white",
                  cursor="hand2", command=self._on_pick_image).pack(side="left", padx=(6, 0))

        self._img_info = tk.Label(img_frame, text="PNG / JPG / WEBP 지원",
                                  font=("Segoe UI", 8), fg=COLORS["text_dim"],
                                  bg=COLORS["surface"])
        self._img_info.pack(anchor="w", padx=8, pady=(0, 4))

        # ── 분석 버튼 ──────────────────────────────────────────────
        btn_row = tk.Frame(self, bg=COLORS["bg"])
        btn_row.pack(fill="x", padx=16, pady=8)

        self._analyze_btn = tk.Button(
            btn_row, text="🔍  분석 시작",
            font=("Segoe UI", 11, "bold"),
            bg=COLORS["accent"], fg="white",
            activebackground="#C2185B", activeforeground="white",
            relief="flat", bd=0, pady=10, cursor="hand2",
            command=self._on_analyze,
        )
        self._analyze_btn.pack(fill="x")

        # ── 진행 표시줄 ────────────────────────────────────────────
        self._progress = ttk.Progressbar(self, mode="indeterminate", length=600)
        self._progress.pack(fill="x", padx=16, pady=(0, 4))

        style = ttk.Style()
        style.theme_use("default")
        style.configure("TProgressbar", troughcolor=COLORS["surface"],
                        background=COLORS["accent"], thickness=3)

        # ── 결과 영역 ──────────────────────────────────────────────
        result_frame = tk.LabelFrame(self, text=" 추출 결과 ",
                                     font=("Segoe UI", 9), fg=COLORS["text_dim"],
                                     bg=COLORS["surface"], bd=1, relief="flat")
        result_frame.pack(fill="both", expand=True, padx=16, pady=4)

        self._result_text = tk.Text(
            result_frame, font=("Consolas", 9), bg=COLORS["bg"],
            fg=COLORS["text"], insertbackground=COLORS["text"],
            relief="flat", bd=4, state="disabled",
            selectbackground=COLORS["accent2"],
        )
        scroll = tk.Scrollbar(result_frame, command=self._result_text.yview,
                              bg=COLORS["surface"])
        self._result_text.configure(yscrollcommand=scroll.set)
        scroll.pack(side="right", fill="y")
        self._result_text.pack(fill="both", expand=True, padx=4, pady=4)

        self._result_text.tag_config("header",  foreground=COLORS["accent"],  font=("Consolas", 9, "bold"))
        self._result_text.tag_config("value",   foreground="#79C0FF")
        self._result_text.tag_config("success", foreground=COLORS["success"])
        self._result_text.tag_config("warning", foreground=COLORS["warning"])
        self._result_text.tag_config("error",   foreground=COLORS["error"])
        self._result_text.tag_config("dim",     foreground=COLORS["text_dim"])

        # ── 하단 버튼 ──────────────────────────────────────────────
        bottom = tk.Frame(self, bg=COLORS["bg"])
        bottom.pack(fill="x", padx=16, pady=(4, 12))

        self._copy_btn = tk.Button(
            bottom, text="📋  복사", font=("Segoe UI", 10),
            bg=COLORS["surface"], fg=COLORS["text"], relief="flat", bd=0,
            pady=8, cursor="hand2", state="disabled",
            activebackground=COLORS["border"],
            command=self._on_copy,
        )
        self._copy_btn.pack(side="left", fill="x", expand=True, padx=(0, 4))

        self._apply_btn = tk.Button(
            bottom, text="✅  game_screen.gd 적용", font=("Segoe UI", 10, "bold"),
            bg=COLORS["accent2"], fg="white", relief="flat", bd=0,
            pady=8, cursor="hand2", state="disabled",
            activebackground="#6D28D9",
            command=self._on_apply,
        )
        self._apply_btn.pack(side="left", fill="x", expand=True)

    # ── 이벤트 핸들러 ─────────────────────────────────────────────────────────

    def _update_key_status(self):
        key = self._api_key.get().strip()
        if key and key.startswith("sk-ant-"):
            self._key_status.config(text="✓ API 키 설정됨", fg=COLORS["success"])
        elif key:
            self._key_status.config(text="⚠ 형식 확인 필요 (sk-ant-api03-...)", fg=COLORS["warning"])
        else:
            self._key_status.config(text="API 키를 입력하세요", fg=COLORS["error"])

    def _on_save_key(self):
        key = self._api_key.get().strip()
        if key:
            self._save_api_key(key)
            self._update_key_status()
            self._log("API 키가 저장되었습니다.", "success")

    def _on_pick_image(self):
        path = filedialog.askopenfilename(
            title="레퍼런스 스크린샷 선택",
            filetypes=[("이미지", "*.png *.jpg *.jpeg *.webp"), ("전체", "*.*")],
            initialdir=str(Path.home() / "Downloads"),
        )
        if path:
            self._img_path.set(path)
            try:
                from PIL import Image as PILImage
                img = PILImage.open(path)
                w, h = img.size
                self._img_info.config(
                    text=f"{Path(path).name}  ({w}×{h}px)",
                    fg=COLORS["text"],
                )
            except Exception:
                pass

    def _on_analyze(self):
        key = self._api_key.get().strip()
        path = self._img_path.get().strip()

        if not key:
            messagebox.showerror("API 키 필요", "Anthropic API 키를 입력하고 저장하세요.")
            return
        if not path or not Path(path).exists():
            messagebox.showerror("이미지 필요", "레퍼런스 이미지를 선택하세요.")
            return

        self._analyze_btn.config(state="disabled")
        self._apply_btn.config(state="disabled")
        self._copy_btn.config(state="disabled")
        self._progress.start(10)
        self._clear_log()
        self._log("Claude Vision API로 분석 중...\n", "dim")

        threading.Thread(target=self._run_analysis, args=(path, key), daemon=True).start()

    def _run_analysis(self, path: str, key: str):
        try:
            data = analyze_with_claude(path, key)
            json_out = Path(path).with_suffix(".analysis.json")
            json_out.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
            vars_out = convert_to_godot_vars(data)
            self.after(0, self._on_analysis_done, vars_out, str(json_out))
        except Exception as e:
            self.after(0, self._on_analysis_error, str(e))

    def _on_analysis_done(self, vars_out: dict, json_path: str):
        self._progress.stop()
        self._progress["value"] = 0
        self._analyze_btn.config(state="normal")
        self._vars_out = vars_out

        self._clear_log()
        self._log("✓ 분석 완료\n\n", "success")
        self._log("## Layout\n", "header")
        for k, v in vars_out.items():
            if k.startswith("_lay_"):
                self._log(f"  var {k:<25} = ", "dim")
                self._log(f"{v}\n", "value")
        self._log("\n## Fonts\n", "header")
        for k, v in vars_out.items():
            if k.startswith("_font_"):
                self._log(f"  var {k:<25} = ", "dim")
                self._log(f"{v}\n", "value")
        self._log(f"\n분석 JSON 저장됨: {Path(json_path).name}\n", "dim")

        self._apply_btn.config(state="normal")
        self._copy_btn.config(state="normal")

    def _on_analysis_error(self, err: str):
        self._progress.stop()
        self._analyze_btn.config(state="normal")
        self._log(f"\n오류 발생:\n{err}\n", "error")

    def _on_copy(self):
        lines = []
        for k, v in self._vars_out.items():
            lines.append(f"var {k}: float = {v:.1f}")
        self.clipboard_clear()
        self.clipboard_append("\n".join(lines))
        self._log("\n클립보드에 복사됨.\n", "success")

    def _on_apply(self):
        if not self._vars_out:
            return
        ok = messagebox.askyesno(
            "적용 확인",
            "game_screen.gd에 추출된 값을 적용합니다.\n백업이 자동 생성됩니다. 계속하시겠습니까?"
        )
        if not ok:
            return
        success, msg = apply_to_gd(self._vars_out)
        if success:
            self._log(f"\n✓ {msg}\n", "success")
            messagebox.showinfo("적용 완료", msg)
        else:
            self._log(f"\n오류: {msg}\n", "error")
            messagebox.showerror("오류", msg)

    # ── 로그 헬퍼 ─────────────────────────────────────────────────────────────

    def _log(self, text: str, tag: str = ""):
        self._result_text.config(state="normal")
        if tag:
            self._result_text.insert("end", text, tag)
        else:
            self._result_text.insert("end", text)
        self._result_text.see("end")
        self._result_text.config(state="disabled")

    def _clear_log(self):
        self._result_text.config(state="normal")
        self._result_text.delete("1.0", "end")
        self._result_text.config(state="disabled")


# ── 진입점 ────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    app = App()
    app.mainloop()
