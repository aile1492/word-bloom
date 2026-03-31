# -*- coding: utf-8 -*-
"""
ComfyUI 환경 빠른 진단 스크립트.
워크플로우 실행 전 이 스크립트를 먼저 실행해서 환경을 점검하세요.

사용법: python check_comfyui.py
"""

import sys
import os
import requests
from pathlib import Path

# Windows 콘솔 UTF-8 출력 설정
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

COMFYUI_URL = "http://127.0.0.1:8188"
WORKFLOWS_DIR = Path(__file__).parent

REQUIRED_MODELS = {
    "unet":  ["flux1-dev-Q8_0.gguf"],
    "clip":  ["clip_l.safetensors", "t5xxl_fp8_e4m3fn.safetensors"],
    "vae":   ["ae.safetensors"],
}

EXPECTED_CUSTOM_NODES = ["ComfyUI-GGUF", "ComfyUI-GGUF_Forked", "gguf"]

EXPECTED_WORKFLOW_FILES = [
    "01_animals.json",    "01_animals_stage2.json",    "01_animals_stage3.json",
    "02_food.json",       "02_food_stage2.json",       "02_food_stage3.json",
    "03_music.json",      "03_music_stage2.json",      "03_music_stage3.json",
    "04_mythology.json",  "04_mythology_stage2.json",  "04_mythology_stage3.json",
    "05_ocean.json",      "05_ocean_stage2.json",      "05_ocean_stage3.json",
    "06_science.json",    "06_science_stage2.json",    "06_science_stage3.json",
    "07_space.json",      "07_space_stage2.json",      "07_space_stage3.json",
    "08_sports.json",     "08_sports_stage2.json",     "08_sports_stage3.json",
]

ok_count = 0
warn_count = 0
err_count = 0

def ok(msg):
    global ok_count
    ok_count += 1
    print(f"  [OK]   {msg}")

def warn(msg):
    global warn_count
    warn_count += 1
    print(f"  [WARN] {msg}")

def err(msg):
    global err_count
    err_count += 1
    print(f"  [ERR]  {msg}")

# ────────────────────────────────────
print("=" * 60)
print("  WordPuzzle ComfyUI 환경 진단")
print("=" * 60)

# 1. ComfyUI 연결
print("\n[1] ComfyUI 서버 연결")
connected = False
try:
    resp = requests.get(f"{COMFYUI_URL}/system_stats", timeout=5)
    if resp.status_code == 200:
        stats = resp.json()
        sys_info = stats.get("system", {})
        devices  = stats.get("devices", [{}])
        ram_gb   = sys_info.get("ram_total", 0) / (1024 ** 3)
        vram_gb  = devices[0].get("vram_total", 0) / (1024 ** 3) if devices else 0
        ok(f"ComfyUI 응답 정상 ({COMFYUI_URL})")
        ok(f"RAM:  {ram_gb:.1f} GB")
        if vram_gb > 0:
            ok(f"VRAM: {vram_gb:.1f} GB")
            if vram_gb < 8:
                warn(f"VRAM {vram_gb:.1f}GB - Q8 모델에는 12GB+ 권장. Q4 모델 사용 고려")
        else:
            warn("GPU 정보를 가져올 수 없음 (CPU 모드?)")
        connected = True
    else:
        err(f"ComfyUI 응답 에러 (HTTP {resp.status_code})")
except requests.exceptions.ConnectionError:
    warn("ComfyUI가 현재 꺼진 상태 (연결 거부됨)")
    warn(f"  -> 생성 시에는 ComfyUI를 먼저 실행 후 auto_generate.py 를 실행하세요")
    print("  [INFO] ComfyUI 미실행 상태에서는 파일/모델 항목만 확인합니다.\n")
except Exception as e:
    err(f"연결 테스트 예외: {e}")

# 2. 모델 파일 확인 (로컬)
print("\n[2] 모델 파일 확인 (C:/ComfyUI/models)")
comfyui_models_root = Path("C:/ComfyUI/models")
if comfyui_models_root.exists():
    for folder, files in REQUIRED_MODELS.items():
        for fname in files:
            fpath = comfyui_models_root / folder / fname
            if fpath.exists():
                size_mb = fpath.stat().st_size / (1024 ** 2)
                ok(f"models/{folder}/{fname}  ({size_mb:.0f} MB)")
            else:
                err(f"models/{folder}/{fname}  -- 파일 없음! ({fpath})")
else:
    warn("C:/ComfyUI/models 폴더를 찾을 수 없음")

# 3. 커스텀 노드 확인
print("\n[3] 커스텀 노드 확인")
custom_nodes_dir = Path("C:/ComfyUI/custom_nodes")
if custom_nodes_dir.exists():
    found_gguf = False
    for node_dir in custom_nodes_dir.iterdir():
        if node_dir.is_dir():
            name = node_dir.name
            if name in EXPECTED_CUSTOM_NODES:
                ok(f"커스텀 노드: {name}")
                if "GGUF" in name.upper() or name == "gguf":
                    found_gguf = True
    if not found_gguf:
        err("GGUF 커스텀 노드 없음 - UnetLoaderGGUF 사용 불가")
        err("  설치: https://github.com/city96/ComfyUI-GGUF")
else:
    warn("C:/ComfyUI/custom_nodes 폴더를 찾을 수 없음")

# 4. 필수 노드 타입 확인 (ComfyUI 실행 중일 때만)
if connected:
    print("\n[4] 필수 노드 타입 확인 (ComfyUI API)")
    try:
        resp = requests.get(f"{COMFYUI_URL}/object_info", timeout=10)
        if resp.status_code == 200:
            node_types = set(resp.json().keys())
            required_nodes = [
                "UnetLoaderGGUF",
                "DualCLIPLoader",
                "VAELoader",
                "CLIPTextEncode",
                "EmptySD3LatentImage",
                "FluxGuidance",
                "KSampler",
                "VAEDecode",
                "SaveImage",
            ]
            for node in required_nodes:
                if node in node_types:
                    ok(f"노드: {node}")
                else:
                    err(f"노드 없음: {node}")
                    if node == "UnetLoaderGGUF":
                        err("  -> ComfyUI-GGUF 커스텀 노드 설치 필요")
                    elif node in ("FluxGuidance", "EmptySD3LatentImage"):
                        err("  -> ComfyUI를 최신 버전으로 업데이트 필요")
    except Exception as e:
        warn(f"노드 타입 확인 실패: {e}")
else:
    print("\n[4] 필수 노드 타입 확인 -- ComfyUI 꺼짐으로 건너뜀")

# 5. DualCLIPLoader 클립 경로 확인
print("\n[5] DualCLIPLoader 클립 경로 진단")
clip_files     = [Path("C:/ComfyUI/models/clip/clip_l.safetensors"),
                  Path("C:/ComfyUI/models/clip/t5xxl_fp8_e4m3fn.safetensors")]
text_enc_files = [Path("C:/ComfyUI/models/text_encoders/clip_l.safetensors"),
                  Path("C:/ComfyUI/models/text_encoders/t5xxl_fp8_e4m3fn.safetensors")]

clip_ok     = all(f.exists() for f in clip_files)
text_enc_ok = all(f.exists() for f in text_enc_files)

if text_enc_ok:
    ok("text_encoders/ 폴더에 클립 파일 있음 -> DualCLIPLoader 정상 동작 예상")
    for f in text_enc_files:
        size_mb = f.stat().st_size / (1024**2)
        ok(f"  text_encoders/{f.name}  ({size_mb:.0f} MB)")
elif clip_ok:
    warn("클립 파일이 models/clip/ 에만 있음")
    warn("DualCLIPLoader가 models/text_encoders/ 를 찾는 경우 에러 발생 가능")
    print()
    print("  [ 해결 방법 ] 다음 명령을 실행하세요:")
    print("  " + "-" * 55)
    print(r"  mkdir C:\ComfyUI\models\text_encoders")
    print(r"  copy C:\ComfyUI\models\clip\clip_l.safetensors C:\ComfyUI\models\text_encoders\ ")
    print(r"  copy C:\ComfyUI\models\clip\t5xxl_fp8_e4m3fn.safetensors C:\ComfyUI\models\text_encoders\ ")
    print("  " + "-" * 55)
else:
    err("클립 파일을 찾을 수 없음 (clip/ 및 text_encoders/ 모두 없음)")

# 6. 워크플로우 파일 확인
print("\n[6] 워크플로우 파일 확인")
wf_count = 0
for fname in EXPECTED_WORKFLOW_FILES:
    fpath = WORKFLOWS_DIR / fname
    if fpath.exists():
        wf_count += 1
    else:
        err(f"워크플로우 없음: {fname}")

if wf_count == len(EXPECTED_WORKFLOW_FILES):
    ok(f"워크플로우 파일 {wf_count}/{len(EXPECTED_WORKFLOW_FILES)}개 전부 존재")
else:
    warn(f"워크플로우 파일 {wf_count}/{len(EXPECTED_WORKFLOW_FILES)}개만 존재")

# ────────────────────────────────────
print()
print("=" * 60)
print(f"  진단 결과:  OK={ok_count}  WARN={warn_count}  ERR={err_count}")
print("=" * 60)

if err_count == 0 and warn_count <= 1:  # warn 1개는 ComfyUI 꺼짐 경고이므로 허용
    print()
    print("  모든 파일 준비 완료!")
    print("  ComfyUI 실행 후 다음 명령으로 생성 시작:")
    print("  python auto_generate.py --test")
elif err_count == 0:
    print()
    print("  경고 항목이 있지만 생성 시도 가능합니다.")
    print("  python auto_generate.py --test")
else:
    print()
    print(f"  {err_count}개 문제 발견. 위 지시에 따라 해결 후 재진단:")
    print("  python check_comfyui.py")
print()
