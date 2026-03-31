# -*- coding: utf-8 -*-
"""
WordPuzzle UI 아이콘 생성 스크립트 (7개)

사용법:
  python auto_generate_icons.py --all
  python auto_generate_icons.py --list
"""
import json, time, sys, argparse, requests
from pathlib import Path
from datetime import datetime, timedelta

COMFYUI_URL  = "http://127.0.0.1:8000"
WORKFLOWS_DIR = Path(__file__).parent
POLL_INTERVAL = 2
TIMEOUT       = 300

ICON_FILES = [
    ("icon_settings.json",        "설정 버튼 아이콘"),
    ("icon_back.json",            "뒤로가기 버튼 아이콘"),
    ("icon_tab_daily.json",       "탭 — 데일리"),
    ("icon_tab_team.json",        "탭 — 팀"),
    ("icon_tab_collection.json",  "탭 — 컬렉션"),
    ("icon_tab_shop.json",        "탭 — 상점"),
]

def log(msg, level="INFO"):
    ts = datetime.now().strftime("%H:%M:%S")
    icons = {"INFO":"✅","WARN":"⚠️ ","ERR":"❌","RUN":"🔄","DONE":"🎉"}
    print(f"[{ts}] {icons.get(level,'  ')} {msg}")

def test_connection():
    try:
        r = requests.get(f"{COMFYUI_URL}/system_stats", timeout=5)
        if r.status_code == 200:
            log("ComfyUI 연결 성공"); return True
    except: pass
    log("ComfyUI 연결 실패", "ERR"); return False

def queue_prompt(workflow):
    try:
        r = requests.post(f"{COMFYUI_URL}/prompt", json={"prompt": workflow}, timeout=30)
        if r.status_code == 200:
            d = r.json()
            if d.get("node_errors"): log(f"노드 에러: {d['node_errors']}", "ERR"); return None
            return d.get("prompt_id")
    except Exception as e: log(str(e), "ERR")
    return None

def wait_for(prompt_id, label):
    start = time.time()
    dots  = 0
    while True:
        elapsed = time.time() - start
        if elapsed > TIMEOUT: log(f"{label} 타임아웃", "ERR"); return False
        try:
            r = requests.get(f"{COMFYUI_URL}/history/{prompt_id}", timeout=10)
            if r.status_code == 200:
                h = r.json()
                if prompt_id in h:
                    st = h[prompt_id].get("status", {})
                    if st.get("status_str") == "error": log(f"{label} 에러", "ERR"); return False
                    out = h[prompt_id].get("outputs", {})
                    if out:
                        files = [img["filename"] for v in out.values() for img in v.get("images",[])]
                        print(); log(f"{label} 완료 ({elapsed:.1f}s) → {', '.join(files)}", "DONE"); return True
        except: pass
        dots = (dots+1)%4
        bar = "█"*int(elapsed/5) + "░"*max(0,10-int(elapsed/5))
        print(f"\r  [{bar}] {elapsed:.0f}s {'.'*dots}   ", end="", flush=True)
        time.sleep(POLL_INTERVAL)

def run_all():
    print("═"*60); print("  WordPuzzle 아이콘 생성 (6개)"); print("═"*60)
    if not test_connection(): return
    done, failed = 0, []
    start = time.time()
    for filename, label in ICON_FILES:
        print("─"*60)
        fp = WORKFLOWS_DIR / filename
        if not fp.exists(): log(f"파일 없음: {filename}", "ERR"); failed.append(label); continue
        log(f"{label} 큐 제출 중...", "RUN")
        wf = json.loads(fp.read_text(encoding="utf-8"))
        pid = queue_prompt(wf)
        if not pid: failed.append(label); continue
        log(f"등록됨 (ID: {pid[:8]}...)")
        if wait_for(pid, label): done += 1
        else: failed.append(label)
    print("═"*60)
    elapsed = timedelta(seconds=int(time.time()-start))
    log(f"완료: {done}/{len(ICON_FILES)}개 | {elapsed}", "DONE")
    if failed:
        for f in failed: print(f"  ❌ {f}")

def main():
    global COMFYUI_URL
    p = argparse.ArgumentParser()
    p.add_argument("--all",  action="store_true")
    p.add_argument("--list", action="store_true")
    p.add_argument("--url",  default=COMFYUI_URL)
    args = p.parse_args()
    COMFYUI_URL = args.url
    if args.list:
        for f, l in ICON_FILES:
            status = "✅" if (WORKFLOWS_DIR/f).exists() else "❌"
            print(f"  {status} {f:35s} {l}")
    if args.all: run_all()
    if not args.all and not args.list: p.print_help()

if __name__ == "__main__": main()
