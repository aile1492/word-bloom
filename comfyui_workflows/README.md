# WordPuzzle — ComfyUI 배경 이미지 생성 가이드

> **생성 대상**: 8테마 × 3스테이지 = **24장 배경 이미지** (배경 완료 후 UI 요소 추가 예정)
> **마지막 업데이트**: 2026-03-18

---

## 사용 모델 & 설정

| 항목 | 값 |
|------|-----|
| **Diffusion Model** | `models/unet/flux1-dev-Q8_0.gguf` |
| **Text Encoder 1** | `models/clip/clip_l.safetensors` |
| **Text Encoder 2** | `models/clip/t5xxl_fp8_e4m3fn.safetensors` |
| **VAE** | `models/vae/ae.safetensors` |
| **출력 해상도** | **576 × 1024** (9:16 세로형) |
| **Steps** | 20 |
| **Sampler** | euler |
| **Scheduler** | beta |
| **CFG** | 1.0 (FLUX는 반드시 1.0) |
| **Guidance** | 3.5 (FluxGuidance 노드) |

> ⚠️ **FLUX는 cfg=1.0 필수.** 다른 값으로 바꾸면 화질 저하 발생

---

## 게임 UI 구조와 배경 구도 설계 (A방식)

```
┌─────────────────────┐  ← 상단 15%: 헤더 (테마명/코인/힌트)
│  🌅 드라마틱한 하늘  │       → 배경에서 가장 인상적인 부분이 보여야 함
│  or 메인 피사체      │
├─────────────────────┤
│                     │
│  [격자판 영역]       │  ← 중간 60%: 반투명 흰색 패널 + 글자 타일
│  배경이 살짝 비쳐   │       → 배경이 부드러울수록 가독성 ↑
│  보이는 구간        │
├─────────────────────┤
│  [단어뱅크 + 탭]    │  ← 하단 25%: 배경이 거의 안 보임
└─────────────────────┘
```

**A방식 구도 지시문** (모든 프롬프트에 적용됨):
```
vertical portrait composition with low horizon line,
dramatic sky and atmospheric scene dominating the upper two-thirds of the frame,
soft misty blurred ground fading gently toward the bottom,
natural atmospheric depth and gradient
```

---

## 워크플로우 파일 목록

### 배경 이미지 (24개)

| 테마 | Stage 1 (밝음/입문) | Stage 2 (중간/심화) | Stage 3 (어둠/고난도) |
|------|-------------------|---------------------|----------------------|
| **Animals** | `01_animals.json` | `01_animals_stage2.json` | `01_animals_stage3.json` |
| **Food** | `02_food.json` | `02_food_stage2.json` | `02_food_stage3.json` |
| **Music** | `03_music.json` | `03_music_stage2.json` | `03_music_stage3.json` |
| **Mythology** | `04_mythology.json` | `04_mythology_stage2.json` | `04_mythology_stage3.json` |
| **Ocean** | `05_ocean.json` | `05_ocean_stage2.json` | `05_ocean_stage3.json` |
| **Science** | `06_science.json` | `06_science_stage2.json` | `06_science_stage3.json` |
| **Space** | `07_space.json` | `07_space_stage2.json` | `07_space_stage3.json` |
| **Sports** | `08_sports.json` | `08_sports_stage2.json` | `08_sports_stage3.json` |

### 각 스테이지의 시각적 의도

| Stage | 게임 구간 | 분위기 | 색조 |
|-------|----------|--------|------|
| **Stage 1** | 1~20스테이지 | 밝고 따뜻함. 초보자 환영 | 골든아워, 낮, 따뜻한 색 |
| **Stage 2** | 21~60스테이지 | 드라마틱, 황혼 or 황홀 | 노을, 오로라, 황혼 |
| **Stage 3** | 61~스테이지 | 신비롭고 어두움 | 밤, 심해, 우주, 네온 |

---

## 사용 방법

### Step 1: ComfyUI 실행 후 워크플로우 로드

1. ComfyUI 실행 (`http://127.0.0.1:8188`)
2. 우측 상단 **"Load"** 클릭
3. JSON 파일 선택 (예: `01_animals.json`)
4. 자동으로 노드 그래프 구성됨

### Step 2: 생성

1. **"Queue Prompt"** 버튼 클릭
2. 약 30~60초 대기 (Q8 모델 기준 RTX 3090 기준)
3. 생성 완료 시 `ComfyUI/output/` 폴더에 자동 저장

### Step 3: Godot 프로젝트에 적용

생성된 이미지를 아래 경로에 복사:
```
res://assets/backgrounds/
  ├── bg_animals.png        ← stage1 파일명 변경
  ├── bg_animals_2.png
  ├── bg_animals_3.png
  ├── bg_food.png
  ├── bg_food_2.png
  ... (동일 패턴)
```

> 💡 **포맷**: PNG 또는 JPG 모두 가능. JPG가 용량 절반 (배경은 JPG 권장)

---

## 시드 테이블 (재생산성)

각 파일의 기본 seed를 기록해두면 나중에 동일한 이미지를 재생산할 수 있습니다.

| 파일 | 기본 Seed | 설명 |
|------|-----------|------|
| 01_animals.json | 1001 | 사바나 황금빛 석양 |
| 01_animals_stage2.json | 1002 | 황혼 사바나 + 번개 |
| 01_animals_stage3.json | 1003 | 야간 정글 + 생물발광 |
| 02_food.json | 2002 | 소박한 식탁 + 자연광 |
| 02_food_stage2.json | 2003 | 이탈리아 피자집 화덕 |
| 02_food_stage3.json | 2004 | 럭셔리 파인다이닝 |
| 03_music.json | 3003 | 콘서트홀 그랜드피아노 |
| 03_music_stage2.json | 3004 | 재즈클럽 모노 스포트라이트 |
| 03_music_stage3.json | 3005 | 오페라하우스 퍼플 조명 |
| 04_mythology.json | 4004 | 그리스 신전 새벽 폭풍 |
| 04_mythology_stage2.json | 4005 | 북유럽 피오르 오로라 |
| 04_mythology_stage3.json | 4006 | 화산 폭발 고대 전장 |
| 05_ocean.json | 5005 | 열대섬 공중 촬영 |
| 05_ocean_stage2.json | 5006 | 산호초 수중 촬영 |
| 05_ocean_stage3.json | 5007 | 심해 생물발광 |
| 06_science.json | 6006 | 야간 실험실 네온블루 |
| 06_science_stage2.json | 6007 | 입자가속기 터널 |
| 06_science_stage3.json | 6008 | 사막 전파망원경 + 은하수 |
| 07_space.json | 7007 | 산등성이 은하수 |
| 07_space_stage2.json | 7008 | 성운 클로즈업 |
| 07_space_stage3.json | 7009 | 블랙홀 + 강착원반 |
| 08_sports.json | 8008 | 야간 풋볼 스타디움 항공 |
| 08_sports_stage2.json | 8009 | 황금빛 올림픽 육상트랙 |
| 08_sports_stage3.json | 8010 | 복싱 링 단일 조명 |

> `control_after_generate: "randomize"` 로 설정되어 있어 매번 다른 이미지 생성
> 특정 이미지가 마음에 들면 seed 값을 고정(`fixed`)으로 바꿀 것

---

## 품질 개선 팁

### 마음에 안 드는 경우 시도할 것

| 문제 | 해결 방법 |
|------|----------|
| 흐릿하게 나올 때 | steps를 25~30으로 올림 |
| 너무 어두울 때 | guidance를 3.5→4.5로 올림 |
| 너무 밝을 때 | guidance를 3.5→2.5로 낮춤 |
| 구도가 잘못될 때 | seed를 바꾸고 재생성 |
| 텍스트/글자가 생길 때 | 네거티브 프롬프트 확인 후 재생성 |
| UI 방해할 정도로 복잡할 때 | 프롬프트에 "soft bokeh middle ground" 추가 |

### 더 좋은 품질을 원하면

- **Q8 → Q8**: 이미 최고 퀀타이즈. 대신 steps를 30으로 올릴 것
- **Upscaling**: 576×1024 → 1080×1920 업스케일시 `upscale_models/` 내 4x 모델 추가

---

## 다음 단계: UI 요소 이미지 (예정)

배경 24장 완료 후 제작할 항목:

| 이미지 | 크기 | 용도 |
|--------|------|------|
| 타일 기본 | 128×128 | 글자 타일 기본 상태 |
| 타일 선택중 | 128×128 | 드래그 선택 상태 |
| 타일 정답 | 128×128 | 단어 발견 완료 상태 |
| 코인 아이콘 | 64×64 | 상단 UI 코인 표시 |
| 힌트 아이콘 | 64×64 | 힌트 버튼 |
| 앱 아이콘 | 1024×1024 | 스토어 아이콘 |
| 스플래시 로고 | 576×300 | 타이틀 화면 |

