# APP_01: 기술 스택 총괄

| 항목 | 내용 |
|------|------|
| 문서 버전 | 1.0 |
| 작성일 | 2026-03-11 |
| 프로젝트 | Word Search Puzzle (Godot 4.6 + GDScript) |
| 출처 | TSD SS1,3.1,3.2.15 + Godot Guide SS1-4 conversion |

---

## 목차

1. [기술 스택 요약](#1-기술-스택-요약)
2. [project.godot 핵심 설정](#2-projectgodot-핵심-설정)
3. [Autoload 목록 및 역할](#3-autoload-목록-및-역할)
4. [전체 모듈 목록](#4-전체-모듈-목록)
5. [모듈 의존성 다이어그램](#5-모듈-의존성-다이어그램)
6. [게임 상수 리소스 (GameConstants)](#6-게임-상수-리소스-gameconstants)
7. [Enum 정의 목록](#7-enum-정의-목록)
8. [데이터 구조 정의](#8-데이터-구조-정의)
9. [플랫폼별 대응 표](#9-플랫폼별-대응-표)
10. [보안 및 무결성](#10-보안-및-무결성)
11. [참조 문서](#11-참조-문서)

---

## 1. 기술 스택 요약

본 프로젝트의 전체 기술 스택을 항목별로 정리한다. 모든 선택은 **모바일(Android/iOS) 및 TV(Android TV/Fire TV) 크로스 플랫폼** 출시를 전제로 결정되었다.

| 항목 | 선택 | 비고 |
|------|------|------|
| **Engine** | Godot 4.6 Stable (Standard Build) | .NET 빌드 아님. 4.7 dev snapshot 사용 금지 |
| **Language** | GDScript | Python 유사 문법, 엔진 네이티브 통합, 빠른 이터레이션 |
| **UI** | Control Node Hierarchy | Container 기반 반응형 레이아웃, Theme Resource 시스템 |
| **Rendering** | Compatibility Renderer (OpenGL ES 3.0) | 모바일/TV 최대 호환성. Forward+ 및 Mobile Renderer 불필요 |
| **Input** | InputEventScreenTouch/Drag + InputMap | 모바일 터치 + TV D-pad 동시 지원 |
| **Storage** | FileAccess + JSON (`user://`) | 로컬 세이브. 플랫폼별 경로 자동 추상화 |
| **Audio** | AudioStreamPlayer + AudioBus | SFX/BGM 분리 버스, .ogg 포맷 사용 (루프 갭 방지) |
| **Build** | Android (APK/AAB), iOS (Xcode), TV | Android: Gradle 빌드, iOS: Mac + Xcode 필수 |
| **Ads** | AdMob (Mobile), IMA SDK (TV) | TV에서 AdMob 사용 시 계정 정지 위험. 반드시 IMA SDK |
| **Analytics** | Firebase Analytics (Planned) | 출시 후 단계적 도입 예정 |
| **Version Control** | Git | .godot/ 폴더 제외, 브랜치 전략 적용 |

### Renderer 선택 근거

Godot 4.6은 세 가지 렌더러를 제공한다:

| 렌더러 | 그래픽 API | 대상 | 본 프로젝트 적합도 |
|--------|-----------|------|:------------------:|
| Forward+ | Vulkan | 데스크톱/콘솔 3D 고사양 | 부적합 |
| Mobile | Vulkan | 모바일 3D 중사양 | 불필요 |
| **Compatibility** | **OpenGL ES 3.0 / WebGL 2** | **2D/경량 3D, 최대 호환** | **적합** |

본 프로젝트는 2D UI 기반 퍼즐 게임이므로 Compatibility Renderer가 최적이다. OpenGL ES 3.0을 사용하여 Android 7.0(API 24) 이상의 거의 모든 기기에서 구동된다.

---

## 2. project.godot 핵심 설정

`project.godot` 파일은 Godot 프로젝트의 루트 설정 파일이다. 아래는 본 프로젝트에 필수적인 핵심 설정 항목이다.

### 2.1 Display (화면)

| 설정 경로 | 값 | 설명 |
|-----------|-----|------|
| `display/window/size/viewport_width` | `1080` | 기준 해상도 가로 (모바일 세로 모드 기준) |
| `display/window/size/viewport_height` | `1920` | 기준 해상도 세로 |
| `display/window/size/window_width_override` | `540` | 에디터 테스트 시 윈도우 크기 (절반) |
| `display/window/size/window_height_override` | `960` | 에디터 테스트 시 윈도우 크기 (절반) |
| `display/window/stretch/mode` | `canvas_items` | UI 스케일링 모드 (2D UI 최적) |
| `display/window/stretch/aspect` | `expand` | 화면 비율 대응 방식 (레터박스 없이 확장) |
| `display/window/handheld/orientation` | `portrait` | 모바일 세로 고정 (TV에서는 무시됨) |

> **TV 대응 참고**: TV 빌드 시 LayoutManager가 런타임에 viewport를 1920x1080으로 재설정하고, 가로(landscape) 레이아웃으로 전환한다.

### 2.2 Rendering (렌더링)

| 설정 경로 | 값 | 설명 |
|-----------|-----|------|
| `rendering/renderer/rendering_method` | `gl_compatibility` | Compatibility Renderer 사용 |
| `rendering/textures/canvas_textures/default_texture_filter` | `linear` | 텍스처 필터링 (선형 보간) |
| `rendering/environment/defaults/default_clear_color` | `Color(0.1, 0.1, 0.18, 1)` | 기본 배경색 (어두운 남색) |

### 2.3 Input (입력)

| 설정 경로 | 값 | 설명 |
|-----------|-----|------|
| `input_devices/pointing/emulate_touch_from_mouse` | `true` | PC에서 마우스로 터치 시뮬레이션 (개발용) |
| `input_devices/pointing/emulate_mouse_from_touch` | `false` | 터치를 마우스로 변환하지 않음 (순수 터치 사용) |

### 2.4 커스텀 InputMap 액션

| 액션 이름 | 용도 | 모바일 매핑 | TV D-pad 매핑 | 키보드(개발용) |
|-----------|------|:----------:|:------------:|:-------------:|
| `select_cell` | 셀 선택/확인 | 터치 | DPAD_CENTER / OK | Enter |
| `use_hint` | 힌트 사용 | UI 버튼 | H 키 | H |
| `pause_game` | 일시정지 | UI 버튼 | Start / Menu | Escape |
| `ui_up` | 상 이동 | - | D-pad Up | Arrow Up |
| `ui_down` | 하 이동 | - | D-pad Down | Arrow Down |
| `ui_left` | 좌 이동 | - | D-pad Left | Arrow Left |
| `ui_right` | 우 이동 | - | D-pad Right | Arrow Right |
| `ui_accept` | UI 확인 | - | DPAD_CENTER | Enter |
| `ui_cancel` | UI 취소/뒤로 | - | Back | Escape |

### 2.5 Internationalization (국제화)

| 설정 경로 | 값 | 설명 |
|-----------|-----|------|
| `internationalization/locale/translations` | `["res://data/localization/translations.csv"]` | UI 번역 CSV 파일 경로 |
| `internationalization/locale/locale_filter_mode` | `1` (Include) | 지원 로케일만 포함 |
| `internationalization/locale/locale_filter` | `["ko", "en"]` | 지원 언어: 한국어, 영어 |

---

## 3. Autoload 목록 및 역할

Autoload는 게임 시작 시 자동으로 로드되어 씬 전환에도 유지되는 전역 싱글톤 Node이다. `Project > Project Settings > Autoload` 탭에서 등록한다.

| Name | Path | 책임 | Key Signals |
|------|------|------|-------------|
| **GameManager** | `res://scripts/autoload/game_manager.gd` | 게임 상태 관리, 현재 스테이지 번호, 게임 모드 전환, 전체 게임 흐름 오케스트레이션 | `stage_started`, `stage_completed`, `game_mode_changed` |
| **SaveManager** | `res://scripts/autoload/save_manager.gd` | JSON 기반 세이브/로드, `user://save_data.json` 파일 관리, 데이터 무결성 검증 | `data_loaded`, `data_saved` |
| **AudioManager** | `res://scripts/autoload/audio_manager.gd` | SFX/BGM 재생, AudioBus 볼륨 제어, 사운드 풀링 | 없음 (fire-and-forget 방식) |
| **AdManager** | `res://scripts/autoload/ad_manager.gd` | 광고 SDK 래퍼, 플랫폼별 SDK 분기(AdMob/IMA), 보상 콜백 처리 | `ad_rewarded`, `ad_closed` |
| **LayoutManager** | `res://scripts/autoload/layout_manager.gd` | 플랫폼 감지(Mobile/TV), 레이아웃 모드 전환, UI 스케일 팩터 제공 | `layout_changed` |
| **CoinManager** | `res://scripts/autoload/coin_manager.gd` | 코인 잔액 관리, 획득/소비 트랜잭션, 잔액 부족 검증 | `coin_changed`, `insufficient_coins` |

### Autoload 등록 순서

등록 순서가 초기화 순서를 결정하므로 의존성을 고려하여 아래 순서를 따른다:

```
1. LayoutManager   ← 플랫폼 감지가 가장 먼저 (다른 매니저들이 참조)
2. SaveManager     ← 저장 데이터 로드 (다른 매니저 초기화에 필요)
3. AudioManager    ← SaveManager의 볼륨 설정 참조
4. CoinManager     ← SaveManager의 코인 잔액 참조
5. AdManager       ← CoinManager 보상 연동
6. GameManager     ← 모든 매니저 준비 완료 후 게임 흐름 시작
```

### Autoload 접근 예시

```gdscript
# 어느 스크립트에서든 전역으로 접근 가능
func _on_word_found(word: String) -> void:
    var score: int = ScoreManager.calculate_score(word)
    GameManager.add_score(score)
    CoinManager.earn(GameConstants.stage_clear_reward)
    AudioManager.play_sfx(SFXType.WORD_FOUND)
```

---

## 4. 전체 모듈 목록

프로젝트를 구성하는 모든 스크립트 모듈의 종합 목록이다. 각 모듈의 유형, 책임, 그리고 기존 C# 레퍼런스 파일을 명시한다.

| 모듈명 | 스크립트 경로 | 유형 | 책임 | C# 참조 파일 |
|--------|-------------|:----:|------|:------------:|
| **game_manager.gd** | `res://scripts/autoload/game_manager.gd` | Autoload | 게임 FSM 상태 관리, 스테이지 진행, 게임 모드 전환, 전체 오케스트레이션 | `GameController.cs` |
| **grid_generator.gd** | `res://scripts/game/grid_generator.gd` | Utility | Grid 생성, 단어 배치, 빈 셀 채우기, SeededRandom 연동 | `GridGenerator.cs` |
| **grid_data.gd** | `res://scripts/game/grid_data.gd` | Resource | Grid 2D 배열 데이터 구조, 배치된 단어 정보 보유 | `GridData.cs` |
| **grid_input_handler.gd** | `res://scripts/game/grid_input_handler.gd` | UI | 터치 드래그/탭 입력 처리, D-pad 포커스 이동, 셀 좌표 변환 | `GridInputHandler.cs` |
| **direction_snapper.gd** | `res://scripts/game/direction_snapper.gd` | Utility | 드래그 벡터를 8방향 중 가장 가까운 방향으로 스냅 | `DirectionSnapper.cs` |
| **score_manager.gd** | `res://scripts/managers/score_manager.gd` | Manager | 점수 계산, 콤보 배율, 길이 보너스, 노힌트 보너스 | `GameController.cs` (일부) |
| **timer_manager.gd** | `res://scripts/managers/timer_manager.gd` | Manager | 게임 타이머, Time Attack 카운트다운, 시간 보너스 처리 | `GameController.cs` (일부) |
| **hint_manager.gd** | `res://scripts/managers/hint_manager.gd` | Manager | 힌트 종류별 로직(첫 글자, 전체 공개, 돋보기, 타이머 연장), 코인 차감 | `HintManager.cs` |
| **word_loader.gd** | `res://scripts/game/word_loader.gd` | Utility | JSON 단어 데이터 로드, 언어/카테고리별 필터링, WordPack 파싱 | `WordLoader.cs` |
| **save_manager.gd** | `res://scripts/autoload/save_manager.gd` | Autoload | JSON 세이브/로드, 데이터 버전 마이그레이션, 체크섬 검증 | 신규 |
| **screen_manager.gd** | `res://scripts/managers/screen_manager.gd` | Manager | 씬 전환 관리, 전환 애니메이션, 씬 스택 관리 | 신규 |
| **audio_manager.gd** | `res://scripts/autoload/audio_manager.gd` | Autoload | SFX/BGM 재생, AudioBus 제어, 사운드 풀링 | 신규 |
| **hangul_utils.gd** | `res://scripts/utils/hangul_utils.gd` | Utility | 한글 자모 분리/합성, 초성/중성/종성 추출, 채움 문자 생성 | `HangulUtils.cs` |
| **seeded_random.gd** | `res://scripts/utils/seeded_random.gd` | Utility | 시드 기반 의사 난수 생성(LCG), Daily Challenge 결정론적 퍼즐 | `SeededRandom.cs` |
| **theme_randomizer.gd** | `res://scripts/utils/theme_randomizer.gd` | Utility | 스테이지별 테마 랜덤 선택, 중복 방지, SeededRandom 연동 | 신규 (GameController에서 추출) |
| **dda_manager.gd** | `res://scripts/managers/dda_manager.gd` | Manager | 동적 난이도 조절, 플레이어 히스토리 분석, Grid 크기/단어 수 오프셋 | `DDAManager.cs` |
| **false_lead_generator.gd** | `res://scripts/game/false_lead_generator.gd` | Utility | 거짓 단서 생성, 접두사 기반 함정 배치, DDA 연동 밀도 조절 | `FalseLeadGenerator.cs` |
| **coin_manager.gd** | `res://scripts/autoload/coin_manager.gd` | Autoload | 코인 잔액 CRUD, 획득/소비 트랜잭션, 잔액 변동 Signal | 신규 |
| **avatar_manager.gd** | `res://scripts/managers/avatar_manager.gd` | Manager | 아바타/프로필 아이콘 관리, 해금 조건 확인 | 신규 |
| **ad_manager.gd** | `res://scripts/autoload/ad_manager.gd` | Autoload | 광고 SDK 래퍼, AdMob/IMA 분기, 보상형 광고 콜백 | 신규 |
| **layout_manager.gd** | `res://scripts/autoload/layout_manager.gd` | Autoload | 플랫폼 감지, Mobile/TV 모드 전환, UI 스케일 팩터 | 신규 |
| **retention_manager.gd** | `res://scripts/managers/retention_manager.gd` | Manager | 일일 로그인 보상, 연속 출석 스트릭, 보상 지급 | 신규 |
| **achievement_manager.gd** | `res://scripts/managers/achievement_manager.gd` | Manager | 업적 조건 추적, 달성 알림, 플랫폼 업적 연동 | 신규 |
| **leaderboard_manager.gd** | `res://scripts/managers/leaderboard_manager.gd` | Manager | 리더보드 점수 제출, 순위 조회, 플랫폼 서비스 연동 | 신규 |

### 디렉토리 구조

```
res://scripts/
├── autoload/                    # 전역 싱글톤 (6개)
│   ├── game_manager.gd
│   ├── save_manager.gd
│   ├── audio_manager.gd
│   ├── coin_manager.gd
│   ├── ad_manager.gd
│   └── layout_manager.gd
├── managers/                    # 기능별 매니저 (9개)
│   ├── score_manager.gd
│   ├── timer_manager.gd
│   ├── hint_manager.gd
│   ├── screen_manager.gd
│   ├── dda_manager.gd
│   ├── avatar_manager.gd
│   ├── retention_manager.gd
│   ├── achievement_manager.gd
│   └── leaderboard_manager.gd
├── game/                        # 게임 핵심 로직 (5개)
│   ├── grid_generator.gd
│   ├── grid_data.gd
│   ├── grid_input_handler.gd
│   ├── word_loader.gd
│   └── false_lead_generator.gd
├── utils/                       # 유틸리티 (4개)
│   ├── direction_snapper.gd
│   ├── hangul_utils.gd
│   ├── seeded_random.gd
│   └── theme_randomizer.gd
└── ui/                          # UI 스크립트 (씬별)
    ├── main_menu.gd
    ├── settings.gd
    ├── level_select.gd
    ├── game_board.gd
    ├── letter_cell.gd
    ├── letter_grid.gd
    └── ...
```

---

## 5. 모듈 의존성 다이어그램

각 모듈 간의 의존 관계를 시각적으로 표현한다. 화살표(`→`)는 "의존한다" 또는 "호출한다"를 의미한다.

### 5.1 전체 의존성 트리

```
GameManager (오케스트레이터)
│
├── grid_generator ──→ grid_data
│   │                  word_loader
│   │                  false_lead_generator ──→ hangul_utils
│   │                  hangul_utils
│   │                  seeded_random
│   │
├── grid_input_handler ──→ direction_snapper
│
├── hint_manager ──→ coin_manager
│
├── dda_manager
│
├── score_manager
│
├── timer_manager
│
├── screen_manager
│
├── theme_randomizer ──→ seeded_random
│
├── save_manager
│
├── audio_manager
│
├── coin_manager
│
├── retention_manager ──→ save_manager
│                         coin_manager
│
├── achievement_manager ──→ save_manager
│
├── leaderboard_manager
│
└── layout_manager
```

### 5.2 계층별 분류

```
┌─────────────────────────────────────────────────────────────────┐
│ Layer 0: Platform / Infra                                       │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐            │
│  │LayoutManager │ │ SaveManager  │ │ AudioManager │            │
│  └──────────────┘ └──────────────┘ └──────────────┘            │
├─────────────────────────────────────────────────────────────────┤
│ Layer 1: Economy / Ads                                          │
│  ┌──────────────┐ ┌──────────────┐                              │
│  │ CoinManager  │ │  AdManager   │                              │
│  └──────────────┘ └──────────────┘                              │
├─────────────────────────────────────────────────────────────────┤
│ Layer 2: Game Logic                                             │
│  ┌───────────────┐ ┌───────────────┐ ┌──────────────────┐      │
│  │ GridGenerator  │ │  DDAManager   │ │ FalseLeadGen     │      │
│  ├───────────────┤ ├───────────────┤ ├──────────────────┤      │
│  │ GridData       │ │ ScoreManager  │ │ DirectionSnapper │      │
│  ├───────────────┤ ├───────────────┤ ├──────────────────┤      │
│  │ WordLoader     │ │ TimerManager  │ │ HintManager      │      │
│  └───────────────┘ └───────────────┘ └──────────────────┘      │
├─────────────────────────────────────────────────────────────────┤
│ Layer 3: Utilities                                              │
│  ┌──────────────┐ ┌───────────────┐ ┌──────────────────┐      │
│  │ HangulUtils  │ │ SeededRandom  │ │ ThemeRandomizer  │      │
│  └──────────────┘ └───────────────┘ └──────────────────┘      │
├─────────────────────────────────────────────────────────────────┤
│ Layer 4: Meta / Retention                                       │
│  ┌──────────────────┐ ┌──────────────────┐ ┌────────────────┐  │
│  │ RetentionManager │ │AchievementManager│ │LeaderboardMgr  │  │
│  └──────────────────┘ └──────────────────┘ └────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│ Layer 5: Orchestrator                                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                     GameManager                          │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 5.3 의존성 규칙

1. **상위 레이어는 하위 레이어만 참조한다** (Layer 5 → Layer 0~4, Layer 4 → Layer 0~3 등)
2. **동일 레이어 간 참조는 최소화한다** (hint_manager → coin_manager 예외 허용)
3. **Utility(Layer 3)는 다른 모듈을 참조하지 않는다** (순수 함수 모듈)
4. **Signal을 통한 역방향 통신**: 하위 레이어가 상위 레이어에 직접 의존하지 않고, Signal을 emit하면 상위에서 connect한다

---

## 6. 게임 상수 리소스 (GameConstants)

모든 튜닝 가능한 게임 상수를 하나의 Resource 클래스에 정의한다. `@export`로 선언하여 Inspector에서 직접 조정할 수 있다.

### 6.1 리소스 파일

- **스크립트**: `res://scripts/resources/game_constants.gd`
- **인스턴스**: `res://data/game_constants.tres`

### 6.2 전체 코드

```gdscript
# game_constants.gd
class_name GameConstants extends Resource

## ──────────────────────────────────────
## Grid (격자)
## ──────────────────────────────────────

## 시작 Grid 가로 크기
@export var start_grid_width: int = 5
## 시작 Grid 세로 크기
@export var start_grid_height: int = 5
## 최대 Grid 가로 크기
@export var max_grid_width: int = 10
## 최대 Grid 세로 크기
@export var max_grid_height: int = 10
## Grid 크기가 1 증가하는 스테이지 간격
@export var grid_growth_interval: int = 4

## ──────────────────────────────────────
## Words (단어)
## ──────────────────────────────────────

## 시작 스테이지 단어 수
@export var start_word_count: int = 4
## 최대 단어 수
@export var max_word_count: int = 12
## 단어 수가 1 증가하는 스테이지 간격
@export var word_growth_interval: int = 5

## ──────────────────────────────────────
## Scoring (점수)
## ──────────────────────────────────────

## 단어 발견 기본 점수
@export var base_word_score: int = 50
## 글자 수당 추가 보너스
@export var length_bonus_per_char: int = 10
## 콤보 배율 (기본 x1.5)
@export var combo_multiplier: float = 1.5
## 콤보 유지 시간 (초)
@export var combo_time_window: float = 10.0
## 힌트 미사용 보너스 점수
@export var no_hint_bonus: int = 100

## ──────────────────────────────────────
## Time Attack (타임어택)
## ──────────────────────────────────────

## 타임어택 제한 시간 (초)
@export var time_attack_duration: int = 180
## 단어 발견 시 추가 시간 (초)
@export var time_bonus_per_word: int = 10

## ──────────────────────────────────────
## DDA (동적 난이도 조절)
## ──────────────────────────────────────

## DDA 히스토리 분석 크기 (최근 N 스테이지)
@export var dda_history_size: int = 3
## 빠른 클리어 판정 임계값 (제한 시간 대비 %)
@export var dda_fast_clear_threshold: float = 90.0
## DDA 최대 난이도 오프셋
@export var dda_max_offset: int = 2

## ──────────────────────────────────────
## False Lead (거짓 단서)
## ──────────────────────────────────────

## 거짓 단서 등장 시작 스테이지
@export var false_lead_start_stage: int = 11
## 스테이지당 최대 거짓 단서 수
@export var false_lead_max_per_stage: int = 2
## 거짓 단서 접두사 최소 길이
@export var false_lead_prefix_length_min: int = 2
## 거짓 단서 접두사 최대 길이
@export var false_lead_prefix_length_max: int = 3

## ──────────────────────────────────────
## Hints (힌트)
## ──────────────────────────────────────

## 첫 글자 힌트 코인 비용
@export var hint_first_letter_cost: int = 100
## 전체 공개 힌트 코인 비용
@export var hint_full_reveal_cost: int = 200
## 돋보기 힌트 코인 비용
@export var hint_magnifier_cost: int = 150
## 타이머 연장 힌트 코인 비용
@export var hint_timer_extend_cost: int = 80
## 타이머 연장 초
@export var hint_timer_extend_seconds: int = 30
## 방향 표시 부스터 코인 비용
@export var booster_direction_cost: int = 120

## ──────────────────────────────────────
## Coins (코인)
## ──────────────────────────────────────

## 초기 지급 코인
@export var initial_coins: int = 300
## 스테이지 클리어 보상 코인
@export var stage_clear_reward: int = 50
## 힌트 미사용 보너스 코인
@export var no_hint_bonus_coins: int = 30
## S랭크 달성 보너스 코인
@export var s_rank_bonus: int = 50
## 데일리 챌린지 완료 보상 코인
@export var daily_challenge_reward: int = 100
## 연속 출석 1일당 추가 코인
@export var streak_bonus_per_day: int = 20
## 연속 출석 최대 보너스 일수
@export var max_streak_bonus_days: int = 7
## 보상형 광고 시청 보상 코인
@export var rewarded_ad_coins: int = 50

## ──────────────────────────────────────
## Retention (리텐션)
## ──────────────────────────────────────

## 일일 로그인 보상 (7일 주기, Day1~Day7)
@export var daily_login_rewards: Array[int] = [20, 30, 40, 50, 60, 80, 150]
## 휴식 스테이지 출현 간격
@export var rest_stage_interval: int = 10
## 휴식 스테이지 단어 수 감소량
@export var rest_stage_word_reduction: int = 2

## ──────────────────────────────────────
## Daily Challenge (데일리 챌린지)
## ──────────────────────────────────────

## 데일리 챌린지 해금 스테이지
@export var daily_challenge_unlock_stage: int = 24

## ──────────────────────────────────────
## Rank Thresholds (랭크 기준)
## ──────────────────────────────────────

## S랭크 제한 시간 (초 이내 클리어)
@export var s_rank_time_limit: float = 90.0
```

### 6.3 사용 방법

```gdscript
# GameConstants 리소스를 로드하여 사용하는 예시
# game_manager.gd

@export var constants: GameConstants  # Inspector에서 game_constants.tres 할당

func _ready() -> void:
    if constants == null:
        constants = preload("res://data/game_constants.tres")

func calculate_grid_size(stage: int) -> Vector2i:
    var width: int = mini(
        constants.start_grid_width + stage / constants.grid_growth_interval,
        constants.max_grid_width
    )
    var height: int = mini(
        constants.start_grid_height + stage / constants.grid_growth_interval,
        constants.max_grid_height
    )
    return Vector2i(width, height)
```

---

## 7. Enum 정의 목록

모든 게임 Enum을 단일 스크립트 파일에 정의하여 프로젝트 전체에서 일관되게 사용한다.

### 7.1 파일 경로

`res://scripts/game/game_enums.gd`

### 7.2 전체 Enum 코드

```gdscript
# game_enums.gd
# 프로젝트 전역 Enum 정의
# class_name을 사용하지 않고 const로 참조하거나,
# Autoload로 등록하여 전역 접근 가능하게 한다.
class_name GameEnums


## 게임 모드
enum GameMode {
    CLASSIC,           ## 시간 제한 없는 기본 모드
    TIME_ATTACK,       ## 제한 시간 내 최대 단어 찾기
    DAILY_CHALLENGE,   ## 매일 동일 퍼즐, 1일 1회
    MARATHON,          ## 연속 스테이지 도전
}

## 게임 상태 (FSM)
enum GameState {
    IDLE,              ## 대기 상태 (메뉴 등)
    PLAYING,           ## 게임 진행 중
    PAUSED,            ## 일시 정지
    COMPLETED,         ## 스테이지 클리어
    FAILED,            ## 시간 초과 등 실패
}

## 지원 언어
enum Language {
    EN,                ## 영어
    KO,                ## 한국어
}

## 화면 타입
enum ScreenType {
    TITLE,             ## 타이틀 / 메인 메뉴
    GAME,              ## 게임 플레이 화면
    RESULT,            ## 결과 화면
    DAILY_CHALLENGE,   ## 데일리 챌린지 화면
    STATS,             ## 통계 화면
}

## 셀 상태
enum CellState {
    IDLE,              ## 기본 상태
    HOVER,             ## 포커스/호버 상태 (TV D-pad)
    DRAGGING,          ## 드래그 선택 중
    FOUND,             ## 단어 발견 완료
    HINT_FIRST_LETTER, ## 첫 글자 힌트 활성
    HINT_MAGNIFIER,    ## 돋보기 힌트 활성
}

## 힌트 종류
enum HintType {
    FIRST_LETTER,      ## 첫 글자 강조
    FULL_REVEAL,       ## 단어 전체 공개
    MAGNIFIER,         ## 영역 돋보기
    TIMER_EXTEND,      ## 타이머 연장
}

## 부스터 종류
enum BoosterType {
    SHUFFLE,           ## Grid 셔플 (빈 셀 재배치)
    DIRECTION_SHOW,    ## 단어 방향 표시
}

## 8방향
enum Direction {
    RIGHT,             ## → (1, 0)
    LEFT,              ## ← (-1, 0)
    DOWN,              ## ↓ (0, 1)
    UP,                ## ↑ (0, -1)
    DOWN_RIGHT,        ## ↘ (1, 1)
    UP_LEFT,           ## ↖ (-1, -1)
    DOWN_LEFT,         ## ↙ (-1, 1)
    UP_RIGHT,          ## ↗ (1, -1)
}

## 효과음 종류
enum SFXType {
    TICK,              ## 셀 터치/이동 시 틱 사운드
    WORD_FOUND,        ## 단어 발견
    WRONG,             ## 잘못된 선택
    STAGE_CLEAR,       ## 스테이지 클리어
    TIMER_WARNING,     ## 타이머 경고 (잔여 30초 등)
    HINT_USE,          ## 힌트 사용
    COMBO,             ## 콤보 발동
    COIN_EARN,         ## 코인 획득
    BUTTON_CLICK,      ## UI 버튼 클릭
    ACHIEVEMENT,       ## 업적 달성
}

## 배경음악 종류
enum BGMType {
    MENU,              ## 메뉴/타이틀 BGM
    PLAY,              ## 게임 플레이 BGM
    TENSION,           ## 긴장 BGM (타이머 임박)
    RESULT,            ## 결과 화면 BGM
}

## 테마 카테고리
enum ThemeType {
    ANIMALS,           ## 동물
    FOOD,              ## 음식
    SPACE,             ## 우주
    SPORTS,            ## 스포츠
    SCIENCE,           ## 과학
    MUSIC,             ## 음악
    OCEAN,             ## 바다
    MYTHOLOGY,         ## 신화
}
```

### 7.3 Direction → Vector2i 매핑 유틸리티

```gdscript
# direction_snapper.gd 내부에서 사용
const DIRECTION_VECTORS: Dictionary = {
    GameEnums.Direction.RIGHT:      Vector2i(1, 0),
    GameEnums.Direction.LEFT:       Vector2i(-1, 0),
    GameEnums.Direction.DOWN:       Vector2i(0, 1),
    GameEnums.Direction.UP:         Vector2i(0, -1),
    GameEnums.Direction.DOWN_RIGHT: Vector2i(1, 1),
    GameEnums.Direction.UP_LEFT:    Vector2i(-1, -1),
    GameEnums.Direction.DOWN_LEFT:  Vector2i(-1, 1),
    GameEnums.Direction.UP_RIGHT:   Vector2i(1, -1),
}
```

---

## 8. 데이터 구조 정의

게임에서 사용하는 핵심 데이터 구조를 Dictionary 스키마 형태로 정의한다. GDScript에서는 typed Dictionary를 직접 강제할 수 없으므로, 아래 스키마를 문서 계약으로 준수한다.

### 8.1 SaveData (세이브 데이터)

전체 게임 진행 상태를 저장하는 최상위 구조.

```gdscript
# save_manager.gd에서 관리
var save_data: Dictionary = {
    "version": 1,                        # int - 세이브 포맷 버전 (마이그레이션용)
    "checksum": "",                      # String - 무결성 검증용 해시
    "language": "ko",                    # String - 현재 언어 ("ko" | "en")
    "current_stage": 1,                  # int - 현재 진행 스테이지
    "highest_stage": 1,                  # int - 최고 도달 스테이지
    "total_score": 0,                    # int - 누적 총 점수
    "total_words_found": 0,              # int - 총 발견 단어 수
    "total_play_time": 0.0,              # float - 총 플레이 시간 (초)
    "coins": 300,                        # int - 현재 코인 잔액

    "stage_results": {},                 # Dictionary[String, StageResult] - 스테이지별 결과
    "daily_challenge": {
        "last_completed_date": "",       # String - 마지막 완료 날짜 (YYYY-MM-DD)
        "streak": 0,                     # int - 데일리 연속 클리어 일수
        "total_completed": 0,            # int - 총 데일리 완료 횟수
    },
    "retention": {
        "last_login_date": "",           # String - 마지막 로그인 날짜
        "login_streak": 0,              # int - 연속 로그인 일수
        "claimed_day": 0,               # int - 보상 수령 완료 일차 (0~6)
    },
    "achievements": [],                  # Array[String] - 달성한 업적 ID 목록
    "settings": {
        "music_volume": 0.8,             # float - BGM 볼륨 (0.0~1.0)
        "sfx_volume": 1.0,              # float - SFX 볼륨 (0.0~1.0)
        "vibration": true,               # bool - 진동 피드백
        "notifications": true,           # bool - 푸시 알림
    },
    "dda_history": [],                   # Array[StageHistory] - DDA용 최근 스테이지 이력
}
```

### 8.2 GridData (Grid 데이터)

하나의 퍼즐 Grid를 표현하는 구조.

```gdscript
# grid_data.gd (Resource 또는 Dictionary)
var grid_data: Dictionary = {
    "width": 5,                          # int - Grid 가로 크기
    "height": 5,                         # int - Grid 세로 크기
    "cells": [["가","나","다","라","마"], ...],  # Array[Array[String]] - 2D 글자 배열 [y][x]
    "placed_words": [],                  # Array[PlacedWord] - 배치된 단어 목록
    "seed": 0,                           # int - 생성에 사용된 시드값 (Daily Challenge용)
}
```

### 8.3 PlacedWord (배치된 단어)

Grid에 배치된 개별 단어의 위치 정보.

```gdscript
var placed_word: Dictionary = {
    "word": "코끼리",                     # String - 원본 단어
    "display": "코끼리",                  # String - 화면 표시용 텍스트
    "start": Vector2i(2, 3),             # Vector2i - 시작 셀 좌표 (x, y)
    "direction": GameEnums.Direction.RIGHT,  # Direction enum - 배치 방향
    "length": 3,                         # int - 단어 글자 수
    "found": false,                      # bool - 발견 여부
    "found_color_index": -1,             # int - 발견 시 할당된 색상 인덱스
}
```

### 8.4 WordEntry (단어 항목)

단어 데이터베이스의 개별 항목.

```gdscript
var word_entry: Dictionary = {
    "word": "코끼리",                     # String - 실제 단어 (Grid 배치용)
    "display": "코끼리",                  # String - 표시용 텍스트 (Word Bank 표시)
    "hint": "가장 큰 육상 포유류",        # String - 힌트 텍스트
    "difficulty": 1,                     # int - 난이도 등급 (1=쉬움, 2=보통, 3=어려움)
}
```

### 8.5 WordPack (단어 팩)

테마별 단어 묶음 파일의 최상위 구조. JSON 파일 형식.

```gdscript
# res://data/words/ko/animals.json 파일 구조
var word_pack: Dictionary = {
    "language": "ko",                    # String - 언어 코드
    "category_id": "animals",            # String - 카테고리 식별자
    "display_name": "동물",              # String - 화면 표시용 카테고리명
    "icon": "res://assets/ui/category_animals.png",  # String - 카테고리 아이콘 경로
    "words": [],                         # Array[WordEntry] - 단어 목록
}
```

### 8.6 GameResult (게임 결과)

스테이지 완료 시 생성되는 결과 데이터.

```gdscript
var game_result: Dictionary = {
    "stage": 1,                          # int - 스테이지 번호
    "mode": GameEnums.GameMode.CLASSIC,  # GameMode - 게임 모드
    "score": 500,                        # int - 획득 점수
    "time_elapsed": 45.3,               # float - 소요 시간 (초)
    "words_found": 5,                    # int - 발견 단어 수
    "total_words": 5,                    # int - 전체 단어 수
    "hints_used": 0,                     # int - 사용한 힌트 수
    "max_combo": 3,                      # int - 최대 콤보 수
    "coins_earned": 80,                  # int - 획득 코인
    "rank": "S",                         # String - 달성 랭크 ("S", "A", "B", "C")
    "is_new_best": false,                # bool - 최고 기록 갱신 여부
    "no_hint_clear": true,               # bool - 힌트 미사용 클리어 여부
    "date": "2026-03-11",               # String - 클리어 날짜 (YYYY-MM-DD)
}
```

### 8.7 StageHistory (DDA용 스테이지 이력)

DDA 분석에 사용되는 최근 스테이지 플레이 기록.

```gdscript
var stage_history: Dictionary = {
    "stage": 10,                         # int - 스테이지 번호
    "clear_time_ratio": 0.65,           # float - 제한 시간 대비 클리어 시간 비율 (0.0~1.0)
    "hint_count": 1,                     # int - 힌트 사용 횟수
    "wrong_attempts": 2,                 # int - 틀린 시도 횟수
    "grid_size": Vector2i(7, 7),         # Vector2i - Grid 크기
    "word_count": 6,                     # int - 단어 수
}
```

### 8.8 AchievementData (업적 데이터)

업적 정의 구조.

```gdscript
var achievement_data: Dictionary = {
    "id": "words_100",                   # String - 업적 고유 ID
    "title": "단어 수집가",              # String - 업적 제목
    "description": "총 100개 단어 발견",  # String - 달성 조건 설명
    "icon": "res://assets/ui/ach_words_100.png",  # String - 업적 아이콘 경로
    "condition_type": "total_words_found", # String - 조건 체크 대상 필드
    "condition_value": 100,              # int - 달성 기준값
    "reward_coins": 200,                 # int - 달성 보상 코인
    "platform_id": "CgkI...",           # String - 플랫폼 업적 ID (Google Play / Game Center)
}
```

---

## 9. 플랫폼별 대응 표

각 타겟 플랫폼의 특성과 기술적 대응 방안을 정리한다.

### 9.1 종합 대응 표

| 항목 | Android (Mobile) | iOS | Android TV | Fire TV |
|------|:-----------------:|:---:|:----------:|:-------:|
| **입력 방식** | 터치(탭/드래그) | 터치(탭/드래그) | D-pad + OK | D-pad + OK |
| **화면 방향** | Portrait (세로) | Portrait (세로) | Landscape (가로) | Landscape (가로) |
| **기본 해상도** | 1080x1920 | 1080x1920 | 1920x1080 | 1920x1080 |
| **광고 SDK** | AdMob | AdMob | Google IMA SDK | Amazon Mobile Ads |
| **IAP** | Google Play Billing | StoreKit | Google Play Billing | Amazon IAP |
| **리더보드** | Google Play Games Services | Game Center | Google Play Games | 로컬 전용 |
| **업적** | Google Play Games Services | Game Center | Google Play Games | 로컬 전용 |
| **세이브 동기화** | Firebase / GPGS Cloud Save | iCloud / Game Center | GPGS Cloud Save | 로컬 전용 |
| **푸시 알림** | FCM | APNs (via FCM) | 미지원 | 미지원 |
| **안전 영역** | 상단 노치/펀치홀 고려 | Safe Area Insets | 화면 가장자리 5% (96px) | 화면 가장자리 5% |
| **최소 OS** | Android 7.0 (API 24) | iOS 15.0 | Android 8.0 (API 26) | Fire OS 7 (Android 9) |
| **빌드 형식** | APK (테스트) / AAB (스토어) | Xcode Archive | APK (테스트) / AAB (스토어) | APK |
| **스토어** | Google Play Store | Apple App Store | Google Play for TV | Amazon Appstore |
| **진동 피드백** | 지원 (Input.vibrate_handheld) | 지원 (UIImpactFeedbackGenerator) | 미지원 | 미지원 |

### 9.2 플랫폼 분기 코드 패턴

```gdscript
# layout_manager.gd
extends Node

enum PlatformType { MOBILE_ANDROID, MOBILE_IOS, TV_ANDROID, TV_FIRE }

var current_platform: PlatformType = PlatformType.MOBILE_ANDROID
var is_tv: bool = false
var is_mobile: bool = true

signal layout_changed(platform: PlatformType)

func _ready() -> void:
    _detect_platform()

func _detect_platform() -> void:
    if OS.has_feature("ios"):
        current_platform = PlatformType.MOBILE_IOS
        is_tv = false
        is_mobile = true
    elif OS.has_feature("android"):
        if _is_tv_device():
            if _is_fire_tv():
                current_platform = PlatformType.TV_FIRE
            else:
                current_platform = PlatformType.TV_ANDROID
            is_tv = true
            is_mobile = false
        else:
            current_platform = PlatformType.MOBILE_ANDROID
            is_tv = false
            is_mobile = true
    else:
        # 데스크톱 (개발용) - 모바일로 기본 설정
        current_platform = PlatformType.MOBILE_ANDROID
        is_tv = false
        is_mobile = true

    layout_changed.emit(current_platform)

func _is_tv_device() -> bool:
    # 터치스크린 미지원 또는 대형 화면
    if not DisplayServer.is_touchscreen_available():
        return true
    var screen_size: Vector2i = DisplayServer.screen_get_size()
    return screen_size.x >= 1920

func _is_fire_tv() -> bool:
    # Fire TV는 Amazon 전용 기기
    # Manufacturer 문자열로 판별
    var manufacturer: String = OS.get_model_name().to_lower()
    return "amazon" in manufacturer or "fire" in manufacturer

## UI 스케일 팩터 반환
func get_ui_scale() -> float:
    if is_tv:
        return 1.8  # TV는 약 1.8배 확대
    return 1.0

## 폰트 크기 가져오기
func get_font_size(base_size: int) -> int:
    return int(base_size * get_ui_scale())
```

### 9.3 Android TV 매니페스트 필수 설정

```xml
<!-- android/build/AndroidManifest.xml 추가 항목 -->

<!-- Leanback 지원 선언 -->
<uses-feature android:name="android.software.leanback" android:required="false" />

<!-- 터치스크린 불필수 -->
<uses-feature android:name="android.hardware.touchscreen" android:required="false" />

<!-- 기존 activity 태그 내부에 TV 런처 인텐트 추가 -->
<intent-filter>
    <action android:name="android.intent.action.MAIN" />
    <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
</intent-filter>
```

### 9.4 iOS ATT (App Tracking Transparency) 처리

```gdscript
# ad_manager.gd 내부
func _request_tracking_authorization() -> void:
    if OS.has_feature("ios"):
        # iOS 14.5+ ATT 프롬프트
        # Godot iOS 플러그인 또는 네이티브 브릿지를 통해 호출
        # ATT 승인 후에만 개인화 광고 표시
        pass
    else:
        # Android는 ATT 불필요
        _initialize_ads()
```

---

## 10. 보안 및 무결성

### 10.1 세이브 파일 체크섬

로컬 세이브 파일의 변조를 탐지하기 위해 선택적으로 체크섬을 적용한다. 완벽한 보안이 아닌 캐주얼 변조 방지가 목적이다.

```gdscript
# save_manager.gd

const CHECKSUM_SECRET: String = "WordSearchPuzzle2026"  # 앱 내 고정 키

## 세이브 데이터의 체크섬 생성
func _generate_checksum(data: Dictionary) -> String:
    var data_copy: Dictionary = data.duplicate(true)
    data_copy.erase("checksum")  # 체크섬 필드 자체는 제외
    var json_str: String = JSON.stringify(data_copy, "", false)
    return (json_str + CHECKSUM_SECRET).sha256_text()

## 세이브 시 체크섬 포함
func save() -> void:
    save_data["checksum"] = _generate_checksum(save_data)
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(save_data, "\t"))
    file.close()
    data_saved.emit()

## 로드 시 체크섬 검증
func load_save() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false

    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    var json: JSON = JSON.new()
    var error: Error = json.parse(file.get_as_text())
    file.close()

    if error != OK:
        push_warning("Save file parse error: %s" % json.get_error_message())
        return false

    save_data = json.data
    var stored_checksum: String = save_data.get("checksum", "")
    var computed_checksum: String = _generate_checksum(save_data)

    if stored_checksum != computed_checksum:
        push_warning("Save file integrity check failed. Resetting to defaults.")
        _reset_to_defaults()
        return false

    data_loaded.emit()
    return true
```

### 10.2 서버 비의존 아키텍처

| 항목 | 설계 방침 |
|------|-----------|
| **핵심 게임플레이** | 완전 오프라인. 서버 없이 단독 구동 |
| **단어 데이터** | `res://data/words/`에 번들링. 런타임 다운로드 불필요 |
| **세이브** | 로컬 `user://` 경로에 JSON 저장. 클라우드 동기화는 선택적 |
| **데일리 챌린지** | 날짜 기반 시드로 오프라인 생성. 서버 검증 불필요 |
| **리더보드** | 플랫폼 서비스(GPGS/Game Center) 의존. 오프라인 시 로컬 기록만 |

### 10.3 IAP 영수증 검증

```gdscript
# 클라이언트 사이드 검증 (기본)
# 각 플랫폼 API를 통해 영수증의 유효성을 확인한다.
# 서버 사이드 검증이 권장되나, 본 프로젝트에서는 클라이언트 검증만 적용한다.

func _on_purchase_completed(receipt: Dictionary) -> void:
    match LayoutManager.current_platform:
        LayoutManager.PlatformType.MOBILE_ANDROID, \
        LayoutManager.PlatformType.TV_ANDROID:
            # Google Play Billing Library의 acknowledgePurchase 호출
            _verify_google_play_receipt(receipt)
        LayoutManager.PlatformType.MOBILE_IOS:
            # StoreKit의 Transaction.finish 호출
            _verify_apple_receipt(receipt)
        LayoutManager.PlatformType.TV_FIRE:
            # Amazon IAP의 notifyFulfillment 호출
            _verify_amazon_receipt(receipt)
```

### 10.4 SeededRandom 결정론적 보장

Daily Challenge의 공정성을 위해, 동일 날짜에는 모든 기기에서 동일한 퍼즐이 생성되어야 한다.

```gdscript
# seeded_random.gd
class_name SeededRandom extends RefCounted

## LCG (Linear Congruential Generator) 파라미터
const A: int = 1664525
const C: int = 1013904223
const M: int = 2147483647  # 2^31 - 1

var _state: int = 0

func _init(seed_value: int = 0) -> void:
    _state = absi(seed_value) % M

## 0.0 ~ 1.0 범위의 float 반환
func next_float() -> float:
    _state = (A * _state + C) % M
    return float(_state) / float(M)

## min ~ max 범위의 int 반환 (inclusive)
func next_int(min_val: int, max_val: int) -> int:
    return min_val + int(next_float() * (max_val - min_val + 1))

## 배열을 제자리에서 셔플
func shuffle_array(arr: Array) -> void:
    for i in range(arr.size() - 1, 0, -1):
        var j: int = next_int(0, i)
        var temp: Variant = arr[i]
        arr[i] = arr[j]
        arr[j] = temp

## Daily Challenge 시드 생성
static func get_daily_seed() -> int:
    var date: Dictionary = Time.get_date_dict_from_system()
    return date.year * 10000 + date.month * 100 + date.day
```

**결정론적 보장 검증 방법**: 동일 시드로 SeededRandom을 초기화한 후, `next_int()`를 N회 호출했을 때 결과 시퀀스가 항상 동일한지 단위 테스트로 확인한다.

---

## 11. 참조 문서

본 문서에서 참조하거나 연관된 프로젝트 문서 목록이다.

### Phase 문서

| 문서 ID | 제목 | 관련 섹션 |
|---------|------|-----------|
| P00_01 | 프로젝트 구조 및 설정 | SS2 project.godot 설정, SS4 디렉토리 구조 |
| P00_02 | 코딩 컨벤션 및 아키텍처 | SS3 Autoload 패턴, SS5 의존성 규칙 |
| P01_01 | 게임 규칙 및 그리드 설계 | SS6 GameConstants (Grid/Words), SS7 Enum (Direction, CellState) |
| P01_02 | 단어 배치 알고리즘 | SS4 grid_generator.gd, SS8 GridData/PlacedWord |
| P01_03 | 입력 처리 및 단어 판정 | SS4 grid_input_handler.gd, direction_snapper.gd |
| P02_01 | 게임 상태 머신 (FSM) | SS7 GameState enum, SS4 game_manager.gd |
| P02_03 | 저장 및 불러오기 | SS8 SaveData, SS10 체크섬 검증 |
| P03_01 | 난이도 및 DDA 시스템 | SS6 DDA 상수, SS8 StageHistory |
| P04_01 | 힌트 및 부스터 시스템 | SS6 Hints/Boosters 상수, SS7 HintType/BoosterType enum |
| P05_01 | 게임 모드 상세 | SS7 GameMode enum, SS6 Time Attack/Daily Challenge 상수 |
| P06_01 | 수익화 시스템 | SS6 Coins 상수, SS9 광고 SDK 분기, SS10 IAP 영수증 |
| P07_01 | 리텐션 시스템 | SS6 Retention 상수, SS4 retention_manager.gd |
| P10_01 | 빌드 및 출시 가이드 | SS9 플랫폼별 빌드 설정, AndroidManifest 설정 |

### Cross-Cutting 문서

| 문서 ID | 제목 | 관련 섹션 |
|---------|------|-----------|
| CC_01 | 데이터 구조 및 리소스 | SS8 데이터 구조 전체 |
| CC_02 | 로컬라이제이션 | SS2.5 Internationalization 설정 |
| CC_03 | 성능 최적화 | SS1 Compatibility Renderer 선택 |
| CC_04 | 분석 및 텔레메트리 | SS1 Firebase Analytics |

### Appendix 문서

| 문서 ID | 제목 | 관련 섹션 |
|---------|------|-----------|
| APP_02 | 용어집 | 전체 (기술 용어 정의 참조) |

### 외부 참조

| 자료 | 경로 | 내용 |
|------|------|------|
| Godot Guide | `WordSearch_Godot_Guide.md` (프로젝트 루트) | 환경 설정, 프로젝트 구조, AI 바이브 코딩 규칙, 빌드 가이드 |
| C# 레퍼런스 코드 | `코드/` 디렉토리 | GridGenerator.cs, GridData.cs 등 15개 원본 파일 |
| TSD (Technical Stack Document) | 본 문서 | 기술 스택 총괄 |

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|:----:|:----:|-----------|
| 1.0 | 2026-03-11 | 최초 작성 -- 기술 스택 요약, project.godot 설정, Autoload 6종 정의, 전체 모듈 24종 목록, 의존성 다이어그램, GameConstants Resource 정의, Enum 12종 정의, 데이터 구조 8종 스키마, 플랫폼 4종 대응 표, 보안/무결성 정책 수립 |
