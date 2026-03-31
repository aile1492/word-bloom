# -*- coding: utf-8 -*-
"""
WordPuzzle UI 요소 이미지 자동 생성 스크립트
ComfyUI API를 통해 7개 UI 에셋을 자동 생성.

사용법:
  python auto_generate_ui.py --all       # 전체 7개 생성
  python auto_generate_ui.py --list      # 목록 확인
  python auto_generate_ui.py --only tile # 타일 3종만 생성
  python auto_generate_ui.py --only icon # 아이콘 2종만 생성
  python auto_generate_ui.py --only etc  # 앱아이콘 + 스플래시 생성
"""

import json
import time
import sys
import argparse
import requests
from pathlib import Path
from datetime import datetime, timedelta

COMFYUI_URL = "http://127.0.0.1:8000"
WORKFLOWS_DIR = Path(__file__).parent
POLL_INTERVAL = 2
TIMEOUT_PER_IMAGE = 300

UI_FILES = {
    "tile":  [
        ("ui_tile_normal.json",   "타일 기본     (128×128)"),
        ("ui_tile_selected.json", "타일 선택중   (128×128)"),
        ("ui_tile_correct.json",  "타일 정답     (128×128)"),
    ],
    "icon": [
        ("ui_coin_icon.json",     "코인 아이콘   (64×64)"),
        ("ui_hint_icon.json",     "힌트 아이콘   (64×64)"),
    ],
    "etc": [
        ("ui_app_icon.json",      "앱 아이콘     (1024×1024)"),
        ("ui_splash.json",        "스플래시 로고 (576×320)"),
    ],
}

ALL_FILES = UI_FILES["tile"] + UI_FILES["icon"] + UI_FILES["etc"]


# ──────────────────────────────────────────────
def log(msg, level="INFO"):
    ts = datetime.now().strftime("%H:%M:%S")
    prefix = {"INFO": "✅", "WARN": "⚠️ ", "ERR": "❌", "RUN": "🔄", "DONE": "🎉"}.get(level, "  ")
    print(f"[{ts}] {prefix} {msg}")


def separator(char="─", width=60):
    print(char * width)


def test_connection():
    try:
        resp = requests.get(f"{COMFYUI_URL}/system_stats", timeout=5)
        if resp.status_code == 200:
            stats = resp.json()
            ram  = stats.get("system", {}).get("ram_total", 0) / (1024 ** 3)
            vram = stats.get("devices", [{}])[0].get("vram_total", 0) / (1024 ** 3)
            log(f"ComfyUI 연결 성공 | RAM: {ram:.1f}GB | VRAM: {vram:.1f}GB")
            return True
    except requests.exceptions.ConnectionError:
        log("ComfyUI에 연결할 수 없습니다.", "ERR")
        log(f"  접속 주소: {COMFYUI_URL}", "ERR")
    except Exception as e:
        log(f"연결 테스트 실패: {e}", "ERR")
    return False


def load_workflow(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        return json.load(f)


def queue_prompt(workflow):
    payload = {"prompt": workflow}
    try:
        resp = requests.post(f"{COMFYUI_URL}/prompt", json=payload, timeout=30)
        if resp.status_code == 200:
            data = resp.json()
            node_errors = data.get("node_errors", {})
            if node_errors:
                log(f"노드 에러: {node_errors}", "ERR")
                return None
            return data.get("prompt_id")
        else:
            log(f"큐 제출 실패 (HTTP {resp.status_code}): {resp.text[:200]}", "ERR")
    except Exception as e:
        log(f"큐 제출 예외: {e}", "ERR")
    return None


def wait_for_prompt(prompt_id, label=""):
    start = time.time()
    dots = 0
    while True:
        elapsed = time.time() - start
        if elapsed > TIMEOUT_PER_IMAGE:
            log(f"{label} — 타임아웃", "ERR")
            return False
        try:
            resp = requests.get(f"{COMFYUI_URL}/history/{prompt_id}", timeout=10)
            if resp.status_code == 200:
                history = resp.json()
                if prompt_id in history:
                    result = history[prompt_id]
                    status = result.get("status", {})
                    if status.get("status_str") == "error":
                        log(f"{label} — 생성 에러: {status.get('messages', [])}", "ERR")
                        return False
                    outputs = result.get("outputs", {})
                    if outputs:
                        saved = []
                        for node_out in outputs.values():
                            for img in node_out.get("images", []):
                                saved.append(img.get("filename", ""))
                        print()
                        log(f"{label} — 완료! ({elapsed:.1f}s) → {', '.join(saved)}", "DONE")
                        return True
        except Exception as e:
            log(f"히스토리 확인 에러: {e}", "WARN")

        dots = (dots + 1) % 4
        bar = "█" * int(elapsed / 5) + "░" * max(0, 10 - int(elapsed / 5))
        print(f"\r  [{bar}] {elapsed:.0f}s 경과... {'.' * dots}   ", end="", flush=True)
        time.sleep(POLL_INTERVAL)


def run_workflow(filepath, label):
    if not filepath.exists():
        log(f"파일 없음: {filepath}", "ERR")
        return False
    log(f"{label} 큐 제출 중...", "RUN")
    workflow = load_workflow(filepath)
    prompt_id = queue_prompt(workflow)
    if not prompt_id:
        log(f"{label} 큐 제출 실패", "ERR")
        return False
    log(f"{label} 큐 등록됨 (ID: {prompt_id[:8]}...)")
    return wait_for_prompt(prompt_id, label)


def run_all(group=None):
    separator("═")
    if group:
        targets = UI_FILES.get(group, [])
        print(f"  WordPuzzle UI 이미지 생성 — {group.upper()} ({len(targets)}개)")
    else:
        targets = ALL_FILES
        print(f"  WordPuzzle UI 이미지 생성 — 전체 ({len(targets)}개)")
    separator("═")

    if not test_connection():
        return

    done = 0
    failed = []
    start_total = time.time()

    for filename, label in targets:
        separator()
        filepath = WORKFLOWS_DIR / filename
        if run_workflow(filepath, label):
            done += 1
        else:
            failed.append(label)
            log(f"{label} 실패. 계속 진행합니다.", "WARN")

    separator("═")
    elapsed = timedelta(seconds=int(time.time() - start_total))
    log(f"완료: {done}/{len(targets)}개 성공 | 소요 시간: {elapsed}", "DONE")

    if failed:
        log(f"실패 항목 ({len(failed)}개):", "WARN")
        for f in failed:
            print(f"    - {f}")
    else:
        log("모든 UI 이미지 성공적으로 생성됨!", "DONE")
        log("출력 폴더: C:/ComfyUI/output/")
        print()
        print("  ⚠️  주의: 타일·아이콘은 흰 배경으로 생성됩니다.")
        print("  Godot에서 사용 시 배경 제거(rembg) 또는 모듈레이트 처리 필요")
        print()
        print("  다음 단계: Godot 프로젝트의 res://assets/ui/ 에 복사")


def list_files():
    separator("═")
    print("  UI 워크플로우 목록")
    separator("═")
    for group, files in UI_FILES.items():
        print(f"\n  [{group.upper()}]")
        for filename, label in files:
            filepath = WORKFLOWS_DIR / filename
            status = "✅" if filepath.exists() else "❌ 없음"
            print(f"    {status}  {filename:30s}  {label}")
    separator()


def main():
    global COMFYUI_URL
    parser = argparse.ArgumentParser(description="WordPuzzle UI 이미지 자동 생성")
    parser.add_argument("--all",   action="store_true", help="전체 7개 생성")
    parser.add_argument("--only",  choices=["tile", "icon", "etc"], help="그룹별 생성")
    parser.add_argument("--list",  action="store_true", help="목록 출력")
    parser.add_argument("--url",   default=COMFYUI_URL, help=f"ComfyUI URL (기본: {COMFYUI_URL})")
    args = parser.parse_args()

    COMFYUI_URL = args.url

    if not any([args.all, args.only, args.list]):
        parser.print_help()
        return

    if args.list:
        list_files()
    if args.all:
        run_all()
    if args.only:
        run_all(group=args.only)


if __name__ == "__main__":
    main()
