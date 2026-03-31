"""
WordPuzzle 배경 이미지 자동 생성 스크립트
ComfyUI API를 통해 24개 워크플로우를 자동으로 큐에 올리고 완료까지 모니터링.

사용법:
  python auto_generate.py --test          # 연결 테스트 + animals 1장만 생성
  python auto_generate.py --all           # 전체 24장 순차 생성
  python auto_generate.py --theme space   # space 테마 3장만 생성
  python auto_generate.py --list          # 워크플로우 목록 출력

의존 패키지 (기본 내장):
  requests, json, os, glob, time, argparse, pathlib, datetime, sys
"""

import json
import os
import glob
import time
import sys
import argparse
import requests
from pathlib import Path
from datetime import datetime, timedelta

# ──────────────────────────────────────────────
# 설정
# ──────────────────────────────────────────────
COMFYUI_URL = "http://127.0.0.1:8000"
WORKFLOWS_DIR = Path(__file__).parent
POLL_INTERVAL = 2       # 완료 확인 주기 (초)
TIMEOUT_PER_IMAGE = 300 # 이미지 1장당 최대 대기 시간 (초)

# 테마별 워크플로우 파일 정의
THEME_FILES = {
    "animals":   ["01_animals.json",   "01_animals_stage2.json",   "01_animals_stage3.json"],
    "food":      ["02_food.json",      "02_food_stage2.json",      "02_food_stage3.json"],
    "music":     ["03_music.json",     "03_music_stage2.json",     "03_music_stage3.json"],
    "mythology": ["04_mythology.json", "04_mythology_stage2.json", "04_mythology_stage3.json"],
    "ocean":     ["05_ocean.json",     "05_ocean_stage2.json",     "05_ocean_stage3.json"],
    "science":   ["06_science.json",   "06_science_stage2.json",   "06_science_stage3.json"],
    "space":     ["07_space.json",     "07_space_stage2.json",     "07_space_stage3.json"],
    "sports":    ["08_sports.json",    "08_sports_stage2.json",    "08_sports_stage3.json"],
}

STAGE_LABELS = ["Stage1 (밝음)", "Stage2 (드라마틱)", "Stage3 (어둠)"]


# ──────────────────────────────────────────────
# 유틸리티
# ──────────────────────────────────────────────
def log(msg: str, level: str = "INFO"):
    ts = datetime.now().strftime("%H:%M:%S")
    prefix = {"INFO": "✅", "WARN": "⚠️ ", "ERR": "❌", "RUN": "🔄", "DONE": "🎉"}.get(level, "  ")
    print(f"[{ts}] {prefix} {msg}")


def separator(char="─", width=60):
    print(char * width)


# ──────────────────────────────────────────────
# ComfyUI API 함수
# ──────────────────────────────────────────────
def test_connection() -> bool:
    """ComfyUI 서버 연결 확인."""
    try:
        resp = requests.get(f"{COMFYUI_URL}/system_stats", timeout=5)
        if resp.status_code == 200:
            stats = resp.json()
            ram = stats.get("system", {}).get("ram_total", 0) / (1024 ** 3)
            vram = stats.get("devices", [{}])[0].get("vram_total", 0) / (1024 ** 3)
            log(f"ComfyUI 연결 성공 | RAM: {ram:.1f}GB | VRAM: {vram:.1f}GB")
            return True
    except requests.exceptions.ConnectionError:
        log("ComfyUI에 연결할 수 없습니다. ComfyUI가 실행 중인지 확인하세요.", "ERR")
        log(f"  접속 주소: {COMFYUI_URL}", "ERR")
    except Exception as e:
        log(f"연결 테스트 실패: {e}", "ERR")
    return False


def load_workflow(filepath: Path) -> dict:
    """워크플로우 JSON 파일 로드."""
    with open(filepath, "r", encoding="utf-8") as f:
        return json.load(f)


def queue_prompt(workflow: dict) -> str | None:
    """워크플로우를 ComfyUI 큐에 제출. prompt_id 반환."""
    payload = {"prompt": workflow}
    try:
        resp = requests.post(f"{COMFYUI_URL}/prompt", json=payload, timeout=30)
        if resp.status_code == 200:
            data = resp.json()
            # 노드 에러 확인
            node_errors = data.get("node_errors", {})
            if node_errors:
                log(f"노드 에러 감지: {node_errors}", "ERR")
                return None
            return data.get("prompt_id")
        else:
            log(f"큐 제출 실패 (HTTP {resp.status_code}): {resp.text[:200]}", "ERR")
    except Exception as e:
        log(f"큐 제출 중 예외 발생: {e}", "ERR")
    return None


def get_queue_size() -> int:
    """현재 큐 대기 중인 항목 수 반환."""
    try:
        resp = requests.get(f"{COMFYUI_URL}/queue", timeout=5)
        if resp.status_code == 200:
            data = resp.json()
            running = len(data.get("queue_running", []))
            pending = len(data.get("queue_pending", []))
            return running + pending
    except Exception:
        pass
    return 0


def wait_for_prompt(prompt_id: str, label: str = "") -> bool:
    """
    특정 prompt_id 완료까지 대기.
    완료되면 True, 타임아웃 또는 에러면 False 반환.
    """
    start = time.time()
    dots = 0
    while True:
        elapsed = time.time() - start

        # 타임아웃 체크
        if elapsed > TIMEOUT_PER_IMAGE:
            log(f"{label} — 타임아웃 ({TIMEOUT_PER_IMAGE}초 초과)", "ERR")
            return False

        # 완료 여부 확인
        try:
            resp = requests.get(f"{COMFYUI_URL}/history/{prompt_id}", timeout=10)
            if resp.status_code == 200:
                history = resp.json()
                if prompt_id in history:
                    result = history[prompt_id]
                    # 에러 확인
                    status = result.get("status", {})
                    if status.get("status_str") == "error":
                        msgs = status.get("messages", [])
                        log(f"{label} — 생성 에러: {msgs}", "ERR")
                        return False
                    # 완료 확인
                    outputs = result.get("outputs", {})
                    if outputs:
                        # 저장된 파일명 추출
                        saved_files = []
                        for node_output in outputs.values():
                            imgs = node_output.get("images", [])
                            for img in imgs:
                                saved_files.append(img.get("filename", ""))
                        elapsed_str = f"{elapsed:.1f}s"
                        filenames = ", ".join(saved_files) if saved_files else "?"
                        print()  # 도트 줄바꿈
                        log(f"{label} — 완료! ({elapsed_str}) → {filenames}", "DONE")
                        return True
        except Exception as e:
            log(f"히스토리 확인 중 에러: {e}", "WARN")

        # 진행 표시
        dots = (dots + 1) % 4
        bar = "█" * int(elapsed / 5) + "░" * max(0, 10 - int(elapsed / 5))
        print(f"\r  [{bar}] {elapsed:.0f}s 경과... {'.' * dots}   ", end="", flush=True)
        time.sleep(POLL_INTERVAL)


def get_output_dir() -> Path:
    """ComfyUI output 폴더 경로 반환."""
    # ComfyUI가 C:\ComfyUI에 설치되어 있다고 가정
    candidates = [
        Path("C:/ComfyUI/output"),
        Path(COMFYUI_URL.replace("http://", "")).replace("127.0.0.1:8188", ""),
    ]
    for p in candidates:
        if p.exists():
            return p
    return Path("C:/ComfyUI/output")


# ──────────────────────────────────────────────
# 메인 생성 로직
# ──────────────────────────────────────────────
def run_workflow(filepath: Path, label: str) -> bool:
    """단일 워크플로우 실행."""
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


def run_test():
    """연결 테스트 + animals stage1 한 장만 생성."""
    separator("═")
    print("  WordPuzzle ComfyUI 연결 테스트")
    separator("═")

    if not test_connection():
        return

    log("테스트 이미지 생성 시작 (animals stage1)")
    separator()
    filepath = WORKFLOWS_DIR / "01_animals.json"
    success = run_workflow(filepath, "animals / Stage1")
    separator()

    if success:
        log("테스트 완료! ComfyUI output 폴더에서 bg_animals_XXXXX.png를 확인하세요.", "DONE")
        log(f"출력 경로: C:/ComfyUI/output/")
    else:
        log("테스트 실패. 에러 메시지를 확인하세요.", "ERR")


def run_theme(theme: str):
    """특정 테마의 3장 생성."""
    if theme not in THEME_FILES:
        log(f"알 수 없는 테마: '{theme}'. 사용 가능: {list(THEME_FILES.keys())}", "ERR")
        return

    separator("═")
    print(f"  테마 생성: {theme.upper()} (3장)")
    separator("═")

    if not test_connection():
        return

    files = THEME_FILES[theme]
    success_count = 0
    start_total = time.time()

    for i, filename in enumerate(files):
        separator()
        label = f"{theme} / {STAGE_LABELS[i]}"
        filepath = WORKFLOWS_DIR / filename
        if run_workflow(filepath, label):
            success_count += 1
        else:
            log(f"{label} 실패. 계속 진행합니다.", "WARN")

    separator("═")
    elapsed = timedelta(seconds=int(time.time() - start_total))
    log(f"테마 '{theme}' 완료: {success_count}/3장 성공 | 소요 시간: {elapsed}", "DONE")


def run_all():
    """전체 24장 순차 생성."""
    separator("═")
    print("  WordPuzzle 전체 배경 이미지 생성 (8테마 × 3장 = 24장)")
    separator("═")

    if not test_connection():
        return

    # 예상 시간 안내
    log("각 이미지당 약 30~90초 예상 → 전체 약 12~36분 소요")
    log("생성 중 ComfyUI를 닫지 마세요.")
    separator()

    total = sum(len(v) for v in THEME_FILES.values())
    done = 0
    failed = []
    start_total = time.time()

    for theme, files in THEME_FILES.items():
        print(f"\n{'─' * 40}")
        print(f"  🎨 {theme.upper()} 테마")
        print(f"{'─' * 40}")

        for i, filename in enumerate(files):
            label = f"{theme} / {STAGE_LABELS[i]}"
            filepath = WORKFLOWS_DIR / filename
            success = run_workflow(filepath, label)
            if success:
                done += 1
            else:
                failed.append(label)
                log(f"{label} 실패. 계속 진행합니다.", "WARN")

            # 전체 진행률 표시
            pct = done / total * 100
            bar = "█" * int(pct / 5) + "░" * (20 - int(pct / 5))
            elapsed = timedelta(seconds=int(time.time() - start_total))
            print(f"  전체 진행: [{bar}] {done}/{total} ({pct:.0f}%) | {elapsed}")

    # 최종 보고
    separator("═")
    elapsed = timedelta(seconds=int(time.time() - start_total))
    log(f"전체 생성 완료: {done}/{total}장 성공 | 소요 시간: {elapsed}", "DONE")

    if failed:
        log(f"실패 항목 ({len(failed)}개):", "WARN")
        for f in failed:
            print(f"    - {f}")
        log("실패 항목은 --theme 옵션으로 개별 재시도 가능합니다.")
    else:
        log("모든 이미지 성공적으로 생성됨!", "DONE")
        log(f"출력 폴더: C:/ComfyUI/output/")
        print()
        print("  다음 단계: Godot 프로젝트의 res://assets/backgrounds/ 에 복사")
        print("  파일명 규칙: bg_animals.png, bg_animals_2.png, bg_animals_3.png ...")


def list_workflows():
    """사용 가능한 워크플로우 목록 출력."""
    separator("═")
    print("  워크플로우 목록")
    separator("═")
    total = 0
    for theme, files in THEME_FILES.items():
        print(f"\n  🎨 {theme.upper()}")
        for i, filename in enumerate(files):
            filepath = WORKFLOWS_DIR / filename
            status = "✅" if filepath.exists() else "❌ 없음"
            print(f"    {status} {filename:40s} ({STAGE_LABELS[i]})")
            if filepath.exists():
                total += 1
    separator()
    log(f"총 {total}개 워크플로우 파일 준비됨")


# ──────────────────────────────────────────────
# CLI
# ──────────────────────────────────────────────
def main():
    global COMFYUI_URL
    parser = argparse.ArgumentParser(
        description="WordPuzzle ComfyUI 배경 이미지 자동 생성",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
예제:
  python auto_generate.py --test
  python auto_generate.py --all
  python auto_generate.py --theme space
  python auto_generate.py --theme animals --theme ocean
  python auto_generate.py --list
        """
    )
    parser.add_argument("--test",   action="store_true", help="연결 테스트 + animals 1장만 생성")
    parser.add_argument("--all",    action="store_true", help="전체 24장 생성")
    parser.add_argument("--theme",  action="append",     help="특정 테마 생성 (반복 사용 가능)", metavar="THEME")
    parser.add_argument("--list",   action="store_true", help="워크플로우 목록 출력")
    parser.add_argument("--url",    default=COMFYUI_URL, help=f"ComfyUI URL (기본: {COMFYUI_URL})")

    args = parser.parse_args()

    # URL 오버라이드
    COMFYUI_URL = args.url

    # 명령 없으면 도움말
    if not any([args.test, args.all, args.theme, args.list]):
        parser.print_help()
        return

    if args.list:
        list_workflows()

    if args.test:
        run_test()

    if args.theme:
        for theme in args.theme:
            run_theme(theme.lower())

    if args.all:
        run_all()


if __name__ == "__main__":
    main()
