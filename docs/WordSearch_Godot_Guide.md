# Word Search Game - Godot 4.6 개발 가이드

> **대상:** 바이브 코딩(Claude + GPT5.4) 기반 개발  
> **엔진:** Godot 4.6 Stable + GDScript  
> **플랫폼:** Android / iOS / Android TV / Fire TV  
> **장르:** Word Search (단어 찾기) 퍼즐  
> **작성일:** 2026.03.11

---

## 목차

1. [환경 설정](#1-환경-설정)
2. [프로젝트 구조](#2-프로젝트-구조)
3. [AI 바이브 코딩 규칙](#3-ai-바이브-코딩-규칙)
4. [UI 시스템 핵심 개념](#4-ui-시스템-핵심-개념)
5. [입력 시스템 (터치 + D-Pad)](#5-입력-시스템-터치--d-pad)
6. [단어 배치 알고리즘](#6-단어-배치-알고리즘)
7. [다국어 데이터 구조](#7-다국어-데이터-구조)
8. [Theme 시스템 & 디자이너 핸드오프](#8-theme-시스템--디자이너-핸드오프)
9. [광고 & 수익화](#9-광고--수익화)
10. [Android / TV 내보내기](#10-android--tv-내보내기)
11. [iOS 내보내기](#11-ios-내보내기)
12. [스토어 등록 요구사항](#12-스토어-등록-요구사항)
13. [세이브 & 클라우드 동기화](#13-세이브--클라우드-동기화)
14. [리텐션 기능 설계](#14-리텐션-기능-설계)
15. [TV Lean-back UI 전략](#15-tv-lean-back-ui-전략)
16. [무료 에셋 목록](#16-무료-에셋-목록)
17. [Git 버전 관리](#17-git-버전-관리)
18. [주의사항 & 지뢰밭](#18-주의사항--지뢰밭)
19. [바이브 코딩 프롬프트 템플릿](#19-바이브-코딩-프롬프트-템플릿)
20. [개발 로드맵](#20-개발-로드맵)

---

## 1. 환경 설정

### 1.1 Godot 설치

- **버전:** Godot 4.6 Stable (Standard 빌드, .NET 빌드 아님)
- **다운로드:** https://godotengine.org/download
- **용량:** 약 40MB (설치 불필요, 압축 해제 후 즉시 실행)
- **4.7 dev snapshot은 절대 사용하지 않는다** (불안정, 프로덕션 부적합)

### 1.2 Android 내보내기 사전 설정

Godot에서 Android APK를 빌드하려면 아래 도구가 필요하다:

| 도구 | 버전 | 용도 |
|------|------|------|
| OpenJDK | 17 | Java 컴파일러 |
| Android SDK | API 34+ | Android 빌드 도구 |
| Android Build Tools | 34.0.0 | Gradle 빌드 |
| Android SDK Command-line Tools | latest | SDK 관리 |
| 키스토어 파일 | .keystore | APK 서명 |

**설정 경로:** Godot 메뉴 > Editor > Editor Settings > Export > Android

```
JDK 경로:        C:\Program Files\Java\jdk-17 (예시)
SDK 경로:        C:\Users\{username}\AppData\Local\Android\Sdk (예시)
Debug Keystore:  자동생성 또는 수동 생성
Release Keystore: keytool로 직접 생성 필요
```

**키스토어 생성 명령어:**
```bash
keytool -genkey -v -keystore wordsearch-release.keystore -alias wordsearch -keyalg RSA -keysize 2048 -validity 10000
```

### 1.3 iOS 내보내기 사전 설정

- Mac + Xcode 필수 (Windows/Linux에서는 iOS 빌드 불가)
- Apple Developer 계정 ($99/년)
- Godot가 Xcode 프로젝트를 생성하면 Mac에서 최종 빌드

### 1.4 권장 외부 도구

| 도구 | 용도 |
|------|------|
| Git | 버전 관리 (필수) |
| VS Code | 외부 스크립트 편집 (선택) |
| Android Studio | SDK 관리 및 에뮬레이터 (선택) |
| adb (Android Debug Bridge) | 실기기 디버깅 |

---

## 2. 프로젝트 구조

```
res://
├── project.godot                    # 프로젝트 설정 파일
│
├── assets/                          # [디자이너 영역] 에셋 파일
│   ├── ui/                          # UI 스프라이트, 버튼, 패널 (.png/.svg)
│   │   ├── btn_play.png
│   │   ├── btn_hint.png
│   │   ├── panel_bg.png
│   │   ├── cell_normal.png
│   │   ├── cell_selected.png
│   │   └── cell_found.png
│   ├── fonts/                       # 폰트 파일 (.ttf/.otf)
│   │   ├── NotoSansKR-Regular.ttf
│   │   ├── NotoSansKR-Bold.ttf
│   │   └── NotoSans-Regular.ttf
│   ├── audio/                       # 오디오 파일
│   │   ├── sfx/                     # 효과음 (.ogg/.wav)
│   │   │   ├── cell_tap.ogg
│   │   │   ├── word_found.ogg
│   │   │   ├── level_complete.ogg
│   │   │   └── hint_use.ogg
│   │   └── music/                   # 배경음악 (.ogg)
│   │       ├── menu_bgm.ogg
│   │       └── game_bgm.ogg
│   └── themes/                      # Godot Theme 리소스 (.tres)
│       ├── default_theme.tres       # 마스터 테마
│       ├── mobile_theme.tres        # 모바일 오버라이드
│       └── tv_theme.tres            # TV 오버라이드
│
├── data/                            # [기획자 영역] 게임 데이터
│   ├── words/                       # 단어 목록 (언어별/카테고리별)
│   │   ├── ko/
│   │   │   ├── animals.json
│   │   │   ├── food.json
│   │   │   └── countries.json
│   │   ├── en/
│   │   │   ├── animals.json
│   │   │   └── food.json
│   │   └── ja/
│   │       └── animals.json
│   ├── levels/                      # 레벨 설정
│   │   └── level_config.json
│   └── localization/                # UI 번역
│       └── translations.csv
│
├── scenes/                          # [씬 파일] .tscn
│   ├── ui/
│   │   ├── main_menu.tscn
│   │   ├── settings.tscn
│   │   ├── level_select.tscn
│   │   ├── game_over.tscn
│   │   └── components/
│   │       ├── word_bank.tscn       # 찾을 단어 목록 UI
│   │       ├── timer_display.tscn   # 타이머 표시
│   │       └── score_display.tscn   # 점수 표시
│   └── game/
│       ├── game_board.tscn          # 메인 게임 화면
│       ├── letter_cell.tscn         # 개별 글자 셀 (프리팹)
│       └── letter_grid.tscn         # 글자 그리드 컨테이너
│
├── scripts/                         # [코드 파일] .gd
│   ├── autoload/                    # 전역 싱글톤 (자동 로드)
│   │   ├── game_manager.gd          # 게임 상태 관리
│   │   ├── audio_manager.gd         # 오디오 재생 관리
│   │   ├── save_manager.gd          # 세이브/로드 관리
│   │   ├── ad_manager.gd            # 광고 SDK 관리
│   │   └── layout_manager.gd        # 플랫폼 감지 & 레이아웃 전환
│   ├── ui/
│   │   ├── main_menu.gd
│   │   ├── settings.gd
│   │   └── level_select.gd
│   └── game/
│       ├── game_board.gd            # 게임 보드 컨트롤러
│       ├── letter_cell.gd           # 개별 셀 동작
│       ├── letter_grid.gd           # 그리드 생성 & 관리
│       ├── word_placer.gd           # 단어 배치 알고리즘
│       ├── word_checker.gd          # 단어 검증 로직
│       └── input_handler.gd         # 터치/D-pad 입력 처리
│
├── addons/                          # 서드파티 플러그인
│   └── (AdMob 등 - 후반부에 추가)
│
└── android/                         # Android Custom Build (자동 생성)
    └── build/
```

### 핵심 원칙

- **assets/**: 디자이너가 파일을 교체하는 영역. 코드 없음
- **data/**: 기획자가 데이터를 수정하는 영역. 코드 없음
- **scenes/**: 씬 구조 (.tscn). 에디터에서 시각적으로 편집
- **scripts/**: 로직 코드 (.gd). AI가 생성, 에디터에서 검증
- **파일명 규칙:** 영문 소문자 + 언더스코어 (한글/특수문자 금지)

---

## 3. AI 바이브 코딩 규칙

### 3.1 AI에게 반드시 전달할 컨텍스트

AI에게 코드를 요청할 때 아래 내용을 항상 포함시킨다:

```
- 엔진: Godot 4.6 Stable
- 언어: GDScript (C# 아님)
- UI 구성: .tscn 씬 파일로 구성, 스크립트에서는 @onready로 노드 참조
- 코드에서 add_child()로 UI를 동적 생성하지 말 것
- @export 변수를 사용해서 Inspector에서 조정 가능하게 할 것
- 노드 이름과 타입을 명확하게 명시할 것
- 인덴트: 탭 사용 (스페이스 혼용 금지)
```

### 3.2 .tscn 방식 vs 코드 동적 생성 방식

**올바른 방식 (씬 기반):**
```gdscript
# letter_grid.gd
extends GridContainer

@export var grid_size: int = 8          # Inspector에서 조정 가능
@export var cell_scene: PackedScene     # Inspector에서 letter_cell.tscn 할당
@onready var word_bank: VBoxContainer = $"../WordBank"  # 씬에서 배치된 노드 참조

func generate_grid():
    for i in range(grid_size * grid_size):
        var cell = cell_scene.instantiate()  # 셀만 동적 생성 (데이터 의존적이므로 OK)
        add_child(cell)
```

**잘못된 방식 (전부 코드에서 생성):**
```gdscript
# 이렇게 하면 에디터에서 아무것도 보이지 않는다
func _ready():
    var grid = GridContainer.new()      # 에디터에서 안 보임
    grid.columns = 8
    add_child(grid)
    var label = Label.new()             # 에디터에서 안 보임
    label.text = "Score: 0"
    add_child(label)
```

### 3.3 AI가 자주 틀리는 패턴

| AI 생성 코드 (3.x 문법) | 올바른 4.6 문법 |
|---|---|
| `onready var x = $Node` | `@onready var x = $Node` |
| `export var x = 10` | `@export var x: int = 10` |
| `yield(get_tree(), "idle_frame")` | `await get_tree().process_frame` |
| `connect("signal", self, "method")` | `signal_name.connect(method)` |
| `instance()` | `instantiate()` |
| `rand_range(0, 10)` | `randf_range(0.0, 10.0)` |
| `PoolStringArray` | `PackedStringArray` |
| `KinematicBody2D` | `CharacterBody2D` |
| `var dict = {}; dict.has("key")` | `var dict = {}; "key" in dict` (둘 다 가능) |

### 3.4 Autoload (전역 싱글톤) 등록

Project > Project Settings > Autoload 탭에서 등록:

| 이름 | 경로 | 용도 |
|------|------|------|
| GameManager | res://scripts/autoload/game_manager.gd | 게임 상태 |
| AudioManager | res://scripts/autoload/audio_manager.gd | 사운드 재생 |
| SaveManager | res://scripts/autoload/save_manager.gd | 세이브/로드 |
| AdManager | res://scripts/autoload/ad_manager.gd | 광고 처리 |
| LayoutManager | res://scripts/autoload/layout_manager.gd | 플랫폼 감지 |

어디서든 `GameManager.current_score` 같은 방식으로 접근 가능하다.

---

## 4. UI 시스템 핵심 개념

### 4.1 Control 노드 계층 구조

Word Search에서 사용할 주요 UI 노드:

```
Control (기본 UI 노드)
├── Label              - 텍스트 표시
├── Button             - 클릭/탭 가능 버튼
├── TextureRect        - 이미지 표시
├── Panel              - 배경 패널
├── HBoxContainer      - 수평 배치 컨테이너
├── VBoxContainer      - 수직 배치 컨테이너
├── GridContainer      - 그리드 배치 컨테이너 (핵심: 글자 그리드)
├── MarginContainer    - 여백 컨테이너
├── ScrollContainer    - 스크롤 가능 컨테이너
└── CenterContainer    - 중앙 정렬 컨테이너
```

### 4.2 Container 규칙 (가장 혼란스러운 부분)

**핵심:** Container 안의 자식 노드는 Container가 위치를 관리한다. 수동 이동 불가.

```
MarginContainer          ← 전체 화면 여백
└── VBoxContainer        ← 수직으로 배치
    ├── Label            ← 제목 (Container가 위치 결정)
    ├── GridContainer    ← 글자 그리드 (Container가 위치 결정)
    │   ├── LetterCell   ← 셀 1 (Grid가 위치 결정)
    │   ├── LetterCell   ← 셀 2
    │   └── ...
    └── HBoxContainer    ← 하단 버튼 영역
        ├── Button       ← 힌트 버튼
        └── Button       ← 일시정지 버튼
```

**자유 배치가 필요하면:** Container를 사용하지 않고 일반 Control 노드의 자식으로 넣는다.

### 4.3 앵커 & 마진 (반응형 레이아웃)

- **앵커(Anchor):** 0.0 ~ 1.0, 부모 노드 대비 상대 위치
- **전체 화면 채우기:** Layout > Full Rect (앵커 0,0 ~ 1,1)
- **하단 고정:** Layout > Bottom Wide
- **중앙 정렬:** Layout > Center

에디터에서 Control 노드 선택 > 상단 메뉴의 Layout 드롭다운에서 프리셋 선택.

### 4.4 @export로 에디터 튜닝

```gdscript
extends GridContainer

@export var grid_size: int = 8
@export var cell_size: Vector2 = Vector2(64, 64)
@export var cell_spacing: int = 4
@export var normal_color: Color = Color.WHITE
@export var selected_color: Color = Color.YELLOW
@export var found_color: Color = Color.GREEN
@export_file("*.tscn") var cell_scene_path: String
```

이렇게 선언하면 Inspector 패널에서 슬라이더, 컬러 피커, 파일 선택기로 조정 가능하다.

---

## 5. 입력 시스템 (터치 + D-Pad)

### 5.1 InputMap 설정

Project > Project Settings > Input Map에서 커스텀 액션 추가:

| 액션 이름 | 모바일 | TV D-pad | 키보드 (테스트용) |
|-----------|--------|----------|-------------------|
| `ui_up` | - | D-pad Up | Arrow Up (기본 매핑) |
| `ui_down` | - | D-pad Down | Arrow Down |
| `ui_left` | - | D-pad Left | Arrow Left |
| `ui_right` | - | D-pad Right | Arrow Right |
| `ui_accept` | - | DPAD_CENTER / OK | Enter |
| `ui_cancel` | - | Back | Escape |
| `select_cell` | 터치 | DPAD_CENTER | Enter |
| `use_hint` | 터치 (버튼) | H 키 | H |

### 5.2 플랫폼 감지

```gdscript
# layout_manager.gd (Autoload)
extends Node

enum Platform { MOBILE, TV }
var current_platform: Platform = Platform.MOBILE

func _ready():
    detect_platform()

func detect_platform():
    var screen_size = DisplayServer.screen_get_size()
    # TV는 보통 1920x1080 이상이고 터치가 없음
    if OS.has_feature("android"):
        if not DisplayServer.is_touchscreen_available():
            current_platform = Platform.TV
        else:
            # 화면 크기가 매우 크면 TV 가능성
            if screen_size.x >= 1920:
                current_platform = Platform.TV
            else:
                current_platform = Platform.MOBILE

func is_tv() -> bool:
    return current_platform == Platform.TV
```

### 5.3 터치 입력 처리

```gdscript
# input_handler.gd
extends Node

signal cell_tapped(cell_position: Vector2i)
signal drag_started(cell_position: Vector2i)
signal drag_moved(cell_position: Vector2i)
signal drag_ended()

var is_dragging: bool = false

func _input(event):
    if LayoutManager.is_tv():
        return  # TV에서는 터치 무시

    if event is InputEventScreenTouch:
        if event.pressed:
            var cell_pos = screen_to_grid(event.position)
            if cell_pos != Vector2i(-1, -1):
                is_dragging = true
                drag_started.emit(cell_pos)
        else:
            if is_dragging:
                is_dragging = false
                drag_ended.emit()

    elif event is InputEventScreenDrag and is_dragging:
        var cell_pos = screen_to_grid(event.position)
        if cell_pos != Vector2i(-1, -1):
            drag_moved.emit(cell_pos)

func screen_to_grid(screen_pos: Vector2) -> Vector2i:
    # 화면 좌표를 그리드 셀 좌표로 변환
    # 실제 구현은 그리드 노드의 위치와 셀 크기에 따라 계산
    pass
```

### 5.4 D-pad 포커스 내비게이션

```gdscript
# letter_cell.gd
extends Button  # Button은 기본적으로 포커스 가능

@export var grid_x: int = 0
@export var grid_y: int = 0

func _ready():
    # TV에서 포커스 시각 효과
    focus_entered.connect(_on_focus_entered)
    focus_exited.connect(_on_focus_exited)

func _on_focus_entered():
    # 포커스 하이라이트 표시
    modulate = Color(1.2, 1.2, 0.8)  # 약간 밝게

func _on_focus_exited():
    modulate = Color.WHITE

func _input(event):
    if not has_focus():
        return
    if event.is_action_pressed("ui_accept"):
        # 셀 선택/선택해제 처리
        _on_cell_selected()
```

---

## 6. 단어 배치 알고리즘

### 6.1 핵심 알고리즘

```gdscript
# word_placer.gd
extends RefCounted

# 8방향 벡터
const DIRECTIONS = [
    Vector2i(1, 0),   # 오른쪽
    Vector2i(-1, 0),  # 왼쪽
    Vector2i(0, 1),   # 아래
    Vector2i(0, -1),  # 위
    Vector2i(1, 1),   # 오른쪽 아래 대각
    Vector2i(-1, -1), # 왼쪽 위 대각
    Vector2i(1, -1),  # 오른쪽 위 대각
    Vector2i(-1, 1),  # 왼쪽 아래 대각
]

var grid_size: int
var grid: Array[Array]  # 2D 배열: grid[y][x]

func generate(size: int, words: Array[String]) -> Dictionary:
    grid_size = size
    _init_empty_grid()

    # 긴 단어부터 배치 (성공률 향상)
    var sorted_words = words.duplicate()
    sorted_words.sort_custom(func(a, b): return a.length() > b.length())

    var placed_words: Array[Dictionary] = []

    for word in sorted_words:
        var result = _try_place_word(word)
        if result != null:
            placed_words.append(result)

    _fill_remaining_cells()

    return {
        "grid": grid,
        "placed_words": placed_words
    }

func _try_place_word(word: String, max_attempts: int = 100) -> Variant:
    for attempt in range(max_attempts):
        var dir = DIRECTIONS[randi() % DIRECTIONS.size()]
        var start = Vector2i(randi() % grid_size, randi() % grid_size)

        if _can_place(word, start, dir):
            _place_word(word, start, dir)
            return {"word": word, "start": start, "direction": dir}

    return null  # 배치 실패

func _can_place(word: String, start: Vector2i, dir: Vector2i) -> bool:
    for i in range(word.length()):
        var pos = start + dir * i
        if pos.x < 0 or pos.x >= grid_size or pos.y < 0 or pos.y >= grid_size:
            return false
        var current = grid[pos.y][pos.x]
        if current != "" and current != word[i]:
            return false  # 충돌 (다른 글자가 이미 있음)
    return true

func _place_word(word: String, start: Vector2i, dir: Vector2i):
    for i in range(word.length()):
        var pos = start + dir * i
        grid[pos.y][pos.x] = word[i]

func _fill_remaining_cells():
    # 빈 셀을 랜덤 문자로 채움
    for y in range(grid_size):
        for x in range(grid_size):
            if grid[y][x] == "":
                grid[y][x] = _get_random_letter()

func _get_random_letter() -> String:
    # 언어별로 다르게 구현
    var letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    return letters[randi() % letters.length()]

func _init_empty_grid():
    grid = []
    for y in range(grid_size):
        var row: Array[String] = []
        for x in range(grid_size):
            row.append("")
        grid.append(row)
```

### 6.2 난이도별 설정

```json
{
  "easy": {
    "grid_size": 8,
    "word_count": 5,
    "directions": ["right", "down"],
    "time_limit": 300
  },
  "medium": {
    "grid_size": 12,
    "word_count": 8,
    "directions": ["all_8"],
    "time_limit": 240
  },
  "hard": {
    "grid_size": 15,
    "word_count": 12,
    "directions": ["all_8"],
    "time_limit": 180
  }
}
```

---

## 7. 다국어 데이터 구조

### 7.1 단어 데이터 JSON 형식

```json
{
  "language": "ko",
  "category_id": "animals",
  "display_name": "동물",
  "icon": "res://assets/ui/category_animals.png",
  "words": [
    {
      "word": "코끼리",
      "display": "코끼리",
      "hint": "가장 큰 육상 포유류",
      "difficulty": 1
    },
    {
      "word": "기린",
      "display": "기린",
      "hint": "목이 긴 동물",
      "difficulty": 1
    }
  ]
}
```

### 7.2 언어별 랜덤 채움 문자

| 언어 | 채움 문자 셋 | 비고 |
|------|-------------|------|
| 영어 | A-Z (26자) | 균등 분포 또는 영어 빈도 가중치 |
| 한국어 | 빈도 높은 음절 (가,나,다,라,마,...) | 실제 한국어 음절 빈도표 기반 |
| 일본어 | 카타카나 (ア-ン) | 게임용은 카타카나 권장 |

### 7.3 UI 번역 CSV

```csv
key,ko,en,ja
menu_play,게임 시작,Play,プレイ
menu_settings,설정,Settings,設定
menu_daily,오늘의 도전,Daily Challenge,今日のチャレンジ
game_hint,힌트,Hint,ヒント
game_score,점수,Score,スコア
game_time,시간,Time,タイム
game_found,찾은 단어,Words Found,見つけた単語
```

Godot에서: Project > Project Settings > Localization > Add 로 CSV 등록

---

## 8. Theme 시스템 & 디자이너 핸드오프

### 8.1 Theme 리소스 생성

1. FileSystem 패널에서 우클릭 > New Resource > Theme
2. `default_theme.tres`로 저장
3. Theme Editor에서 각 컨트롤 타입별 스타일 설정

### 8.2 Theme에서 설정할 항목

| 컨트롤 | 속성 | 용도 |
|--------|------|------|
| Label | font, font_size, font_color | 모든 텍스트 기본 스타일 |
| Button | font, normal/hover/pressed StyleBox | 버튼 스타일 |
| Panel | panel StyleBox | 패널 배경 |
| GridContainer | 개별 설정 불가 → 자식 셀에서 처리 | - |

### 8.3 디자이너 작업 순서

1. Godot 4.6 설치 (40MB)
2. 프로젝트 폴더 열기
3. `res://assets/themes/default_theme.tres` 더블클릭
4. Theme Editor에서 폰트/색상/스타일 변경
5. `res://assets/ui/` 폴더의 이미지 파일을 같은 이름으로 교체
6. `res://assets/fonts/` 폴더의 폰트 파일 교체
7. `res://assets/audio/` 폴더의 사운드 파일을 같은 이름으로 교체
8. 저장 후 실행하여 확인

**디자이너가 스크립트 파일을 열 필요가 전혀 없다.**

---

## 9. 광고 & 수익화

### 9.1 플랫폼별 광고 전략

| 플랫폼 | 광고 SDK | 광고 형식 | 주의사항 |
|--------|---------|----------|----------|
| Android (모바일) | AdMob | 배너 + 보상형 동영상 | Godot AdMob 플러그인 사용 |
| iOS | AdMob | 배너 + 보상형 동영상 | Godot iOS AdMob 플러그인 |
| Android TV | Google IMA SDK | 동영상 인터스티셜만 | AdMob 사용 금지 (계정 정지 위험) |
| Fire TV | Amazon Mobile Ads | 배너 + 인터스티셜 | Google Play Services 미지원 |

### 9.2 AdMob은 Android TV를 공식 지원하지 않는다

- Google Mobile Ads SDK 팀이 2025년 3월 공식 확인
- TV에서 AdMob 사용 시 계정 정지 위험
- 인터스티셜 닫기 버튼이 D-pad로 작동하지 않음
- **TV 광고는 반드시 Google IMA SDK를 사용할 것**

### 9.3 AdMob 플러그인 통합 시점

**개발 초기에 AdMob을 넣지 않는다.**

1. 게임 로직 + UI 완성 (광고 없이)
2. Git 브랜치 생성 (`feature/admob`)
3. AdMob 플러그인 설치 및 테스트
4. 문제 없으면 main에 병합

이유: AdMob 플러그인이 Godot 버전 업데이트 시 호환성 문제를 자주 일으킨다. 게임 개발과 광고 통합을 분리하면 양쪽 문제를 독립적으로 해결할 수 있다.

### 9.4 IAP (인앱 구매)

| 플랫폼 | IAP SDK | 상품 예시 |
|--------|---------|----------|
| Google Play | Google Play Billing | 힌트팩 10개, 프리미엄 테마, 광고 제거 |
| App Store | StoreKit | 동일 |
| Amazon | Amazon IAP | 동일 (Google Play Billing 사용 불가) |

---

## 10. Android / TV 내보내기

### 10.1 기본 Android 내보내기

1. Project > Export > Add > Android
2. Export Preset 설정:
   - Package Unique Name: `com.yourcompany.wordsearch`
   - Version Code: 1 (업데이트마다 증가)
   - Version Name: "1.0.0"
   - Min SDK: 24 (Android 7.0)
   - Target SDK: 34+
   - Keystore: Release 키스토어 경로 및 비밀번호

### 10.2 Android TV 추가 설정

Custom Build를 활성화하고 `android/build/AndroidManifest.xml`을 수동 편집:

```xml
<!-- Leanback 지원 선언 -->
<uses-feature android:name="android.software.leanback" android:required="false" />

<!-- 터치스크린 불필수 -->
<uses-feature android:name="android.hardware.touchscreen" android:required="false" />

<!-- TV 런처 인텐트 추가 (기존 activity 태그 안에) -->
<intent-filter>
    <action android:name="android.intent.action.MAIN" />
    <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
</intent-filter>
```

**TV 배너 이미지:** 320x180px PNG를 `android/build/res/drawable/` 에 `banner.png`로 배치

### 10.3 Fire TV 추가 고려사항

- Fire OS는 Android 기반이므로 APK를 그대로 제출 가능
- Google Play Services가 없으므로 AdMob 직접 사용 불가
- Amazon IAP SDK를 별도로 통합해야 함
- 최소 Fire OS 7 (Android 9) 타겟

---

## 11. iOS 내보내기

### 11.1 필수 요건

- Mac 컴퓨터 (Xcode 실행 필수)
- Apple Developer 계정 ($99/년)
- Xcode 최신 버전

### 11.2 절차

1. Godot에서 Export > Add > iOS
2. Bundle Identifier 설정: `com.yourcompany.wordsearch`
3. Export Path 지정 후 Export
4. 생성된 Xcode 프로젝트를 Mac에서 열기
5. Signing & Capabilities에서 Team 선택
6. Archive > Distribute App > App Store Connect

### 11.3 주의사항

- ATT (App Tracking Transparency) 프롬프트 구현 필수
- Privacy Nutrition Labels 작성 필수
- 광고 SDK 포함 시 SKAdNetwork 설정 필요

---

## 12. 스토어 등록 요구사항

### 12.1 Google Play Store

| 항목 | 요구사항 |
|------|---------|
| App Bundle | AAB 형식 필수 |
| Target API | 34+ |
| 콘텐츠 등급 | IARC 설문 완료 (전체이용가 예상) |
| 개인정보처리방침 | URL 필수 (광고 포함 앱) |
| 데이터 안전 양식 | 광고 SDK 데이터 수집 신고 |
| 스크린샷 | 폰 최소 2장 + 태블릿 권장 |
| 앱 아이콘 | 512x512 PNG |
| Feature Graphic | 1024x500 PNG |

### 12.2 Google Play for Android TV (추가)

| 항목 | 요구사항 |
|------|---------|
| TV 배너 | 320x180 PNG |
| TV 스크린샷 | 1920x1080 최소 3장 |
| Leanback 선언 | AndroidManifest |
| D-pad 네비게이션 | 모든 UI 요소 접근 가능 |
| 터치 불필수 선언 | AndroidManifest |

### 12.3 Apple App Store

| 항목 | 요구사항 |
|------|---------|
| 앱 아이콘 | 1024x1024 PNG (투명 배경 불가) |
| 스크린샷 | 6.7" + 5.5" 최소 |
| 개인정보처리방침 | URL 필수 |
| ATT 프롬프트 | 광고 추적 시 필수 |
| 심사 기간 | 보통 24-48시간 |

### 12.4 Amazon Appstore (Fire TV)

| 항목 | 요구사항 |
|------|---------|
| APK 형식 | APK 허용 (AAB도 가능) |
| TV 배너 | 320x180 PNG |
| 스크린샷 | 1920x1080 최소 3장 |
| Fire OS 호환 | Fire OS 7+ (Android 9) |
| Google 서비스 | 사용 불가 (Amazon 서비스 대체) |

---

## 13. 세이브 & 클라우드 동기화

### 13.1 로컬 세이브 구조

```gdscript
# save_manager.gd
extends Node

const SAVE_PATH = "user://save_data.json"

var save_data: Dictionary = {
    "version": 1,
    "language": "ko",
    "completed_levels": [],        # 완료한 레벨 ID 배열
    "best_times": {},              # {level_id: best_time_seconds}
    "stars": {},                   # {level_id: star_count}
    "unlocked_categories": ["animals"],  # 해금된 카테고리
    "hints_remaining": 5,
    "total_words_found": 0,
    "daily_streak": 0,
    "last_daily_date": "",
    "settings": {
        "music_volume": 0.8,
        "sfx_volume": 1.0,
        "language": "ko",
        "theme": "default"
    }
}

func save():
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(save_data, "\t"))
    file.close()

func load_save():
    if FileAccess.file_exists(SAVE_PATH):
        var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
        var json = JSON.new()
        json.parse(file.get_as_text())
        save_data = json.data
        file.close()
```

### 13.2 클라우드 동기화 (Firebase - 선택사항)

- Godot Firebase 플러그인 사용
- 로컬 세이브를 먼저 수행하고, 온라인 시 Firestore에 동기화
- 충돌 시: 타임스탬프 비교 후 최신 데이터 유지, completed_levels는 합집합

---

## 14. 리텐션 기능 설계

### 14.1 데일리 챌린지

```gdscript
# 날짜 기반 시드로 모든 플레이어에게 동일한 퍼즐 생성
func get_daily_seed() -> int:
    var date = Time.get_date_dict_from_system()
    return date.year * 10000 + date.month * 100 + date.day

func generate_daily_puzzle():
    seed(get_daily_seed())
    # 이후 랜덤 함수가 모든 기기에서 동일한 결과 생성
```

### 14.2 진행 시스템

- 카테고리 잠금해제: 이전 카테고리 완료 시 다음 카테고리 개방
- 별 등급: 시간/힌트 사용 기준으로 1-3성 부여
- 힌트 경제: 일일 로그인 보상 + 보상형 광고 시청 + 연속 기록 보상

### 14.3 랭킹 (선택)

- Firebase Firestore로 데일리 챌린지 리더보드
- TV에서는 로컬 기록만 표시

---

## 15. TV Lean-back UI 전략

### 15.1 크기 스케일링

| UI 요소 | 모바일 | TV | 비율 |
|---------|--------|-----|------|
| 본문 텍스트 | 14sp | 24sp | 1.7x |
| 버튼 텍스트 | 16sp | 28sp | 1.75x |
| 그리드 셀 글자 | 20sp | 36sp | 1.8x |
| 포커스 타겟 크기 | 48dp | 56dp | 1.17x |
| 그리드 셀 크기 | 40dp | 64dp | 1.6x |
| 그리드 최대 크기 | 15x15 | 12x12 | 축소 |

### 15.2 Godot 설정

```
Project Settings:
- Display > Window > Size > Viewport Width: 1920
- Display > Window > Size > Viewport Height: 1080
- Display > Window > Stretch > Mode: canvas_items
- Display > Window > Stretch > Aspect: keep
```

### 15.3 TV UI 원칙

- 배경색: 어두운 톤 (#1A1A2E)
- 글자색: 밝은 톤 (#EAEAEA)
- 포커스 링: 뚜렷한 애니메이션 (단순 색상 변경 부족)
- 호버 상태 없음 (TV에 마우스 없음)
- 여백: 모바일 대비 40-60% 증가
- 안전 영역: 화면 가장자리에서 5% (96px @1920) 여백
- 단어 은행: 사이드바 배치 (TV 화면 가로가 넓으므로)
- 폰트 굵기: SemiBold 이상 (거리에서 Regular는 가늘어 보임)

---

## 16. 무료 에셋 목록

### 16.1 UI 에셋 (CC0 - 저작자 표시 불필요)

| 리소스 | URL | 설명 |
|--------|-----|------|
| Kenney UI Pack | kenney.nl/assets/ui-pack | 버튼, 패널, 아이콘 |
| Kenney Game Icons | kenney.nl/assets/game-icons | 게임용 아이콘 세트 |
| Kenney UI Audio | kenney.nl/assets/ui-audio | UI 클릭 사운드 |

### 16.2 폰트 (OFL - 상업 이용 가능)

| 폰트 | URL | 용도 |
|------|-----|------|
| Noto Sans KR | fonts.google.com | 한국어 본문/제목 |
| Noto Sans JP | fonts.google.com | 일본어 |
| Noto Sans | fonts.google.com | 영문/기본 |

### 16.3 사운드 (CC0)

| 리소스 | URL | 설명 |
|--------|-----|------|
| Kenney Audio | kenney.nl/assets | 게임 효과음 |
| Freesound.org | freesound.org | CC0 필터 검색 가능 |
| OpenGameArt.org | opengameart.org | 게임 전문 |

### 16.4 라이선스 매니페스트

프로젝트 루트에 `LICENSES.md` 파일을 유지한다:

```markdown
# Third-Party Asset Licenses

## Kenney UI Pack
- Source: kenney.nl
- License: CC0 1.0 Universal (Public Domain)

## Noto Sans KR
- Source: Google Fonts
- License: SIL Open Font License 1.1

## (추가 에셋마다 기록)
```

---

## 17. Git 버전 관리

### 17.1 .gitignore

```
# Godot
.godot/

# Android build
android/build/.gradle/
android/build/build/
android/build/gradlew
android/build/gradlew.bat
android/build/gradle/

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
*.swp

# Export
*.apk
*.aab
*.ipa
```

### 17.2 커밋 전략

```
feat: 새 기능 추가
fix: 버그 수정
ui: UI 변경
data: 단어 데이터/레벨 데이터 변경
audio: 오디오 에셋 변경
theme: 테마/스타일 변경
ad: 광고 관련 변경
build: 빌드 설정 변경
```

### 17.3 브랜치 전략

```
main                 ← 안정 버전
├── develop          ← 개발 통합
├── feature/grid     ← 그리드 기능
├── feature/admob    ← 광고 통합 (분리!)
├── feature/tv-ui    ← TV UI 적응
└── release/1.0      ← 출시 준비
```

---

## 18. 주의사항 & 지뢰밭

### 18.1 AI 바이브 코딩 지뢰

| 문제 | 증상 | 해결 |
|------|------|------|
| 3.x / 4.x 문법 혼용 | 컴파일 에러 | AI에게 "Godot 4.6 GDScript" 명시 |
| 전부 코드에서 동적 생성 | 에디터에서 안 보임 | ".tscn으로 구성, @onready 참조" 지시 |
| 탭/스페이스 혼용 | IndentationError | 에디터 설정에서 탭 통일 |
| 존재하지 않는 함수/노드 | 런타임 에러 | 공식 문서에서 확인 |
| 한 파일에 모든 코드 | 유지보수 불가 | 기능별 스크립트 분리 지시 |

### 18.2 AdMob 지뢰

| 문제 | 증상 | 해결 |
|------|------|------|
| 플러그인 버전 불일치 | Export 실패 | Godot 버전에 맞는 플러그인 사용 |
| Custom Build 미활성화 | 플러그인 미인식 | Export에서 Use Custom Build 체크 |
| APP ID 미설정 | 앱 시작 시 크래시 | AdMob 노드에 APP ID 입력 |
| TV에서 AdMob 사용 | 계정 정지 위험 | TV는 IMA SDK만 사용 |
| Gradle 빌드 실패 | 빌드 에러 | adb logcat으로 원인 확인 |

### 18.3 Android TV 지뢰

| 문제 | 증상 | 해결 |
|------|------|------|
| Leanback 미선언 | Play Store TV 등록 거부 | AndroidManifest 수동 편집 |
| 터치 필수로 선언됨 | TV에서 설치 불가 | touchscreen required="false" |
| D-pad Center 미매핑 | OK 버튼 무반응 | InputMap에서 매핑 확인 |
| 배너 이미지 누락 | 스토어 등록 거부 | 320x180 배너 추가 |
| Focus 미설정 | D-pad로 이동 불가 | Control 노드의 focus_mode 확인 |

### 18.4 일반 Godot 지뢰

| 문제 | 증상 | 해결 |
|------|------|------|
| 파일명에 한글/특수문자 | Import 실패 | 영문 소문자 + 언더스코어만 사용 |
| .ogg 대신 .mp3 루프 | 루프 시 미세한 갭 | 배경음악은 .ogg 사용 |
| Container 안에서 수동 이동 | 위치가 리셋됨 | Container가 위치를 관리하는 것이 정상 |
| Theme 미적용 | 스타일 안 바뀜 | 루트 Control에 Theme 리소스 할당 확인 |
| iOS 빌드 | Mac 없이 불가 | Mac 필수 (클라우드 Mac 대안) |

---

## 19. 바이브 코딩 프롬프트 템플릿

### 19.1 새 씬 요청 템플릿

```
Godot 4.6 GDScript 기준으로 작업해줘.

[요청 내용 설명]

규칙:
- .tscn 씬 파일의 노드 구조를 먼저 알려줘 (노드 이름, 타입, 부모-자식 관계)
- 스크립트에서 UI 노드를 add_child()로 동적 생성하지 마
- @onready로 씬의 노드를 참조해
- 에디터에서 조정할 값은 @export 변수로 선언해
- 인덴트는 탭을 사용해
- signal을 활용해서 노드 간 통신해
```

### 19.2 기존 코드 수정 템플릿

```
Godot 4.6 GDScript 기준이야.

현재 코드:
[기존 코드 붙여넣기]

수정 요청:
[원하는 변경 사항]

규칙:
- 기존 노드 구조는 변경하지 마
- @export 변수를 유지해
- 새로 추가되는 노드가 있으면 씬에 추가할 노드 정보를 별도로 알려줘
```

### 19.3 에러 해결 템플릿

```
Godot 4.6에서 에러가 발생했어.

에러 메시지:
[에러 메시지 복사]

관련 코드:
[해당 스크립트 전체 또는 관련 부분]

씬 구조:
[해당 씬의 노드 트리 - Godot 에디터 Scene 패널에서 확인 가능]

원인과 수정 방법을 알려줘.
```

---

## 20. 개발 로드맵

### Phase 1: 핵심 기능 (1-2주)

- [ ] Godot 4.6 설치 및 프로젝트 생성
- [ ] Git 초기화 및 .gitignore 설정
- [ ] 프로젝트 디렉토리 구조 생성
- [ ] Autoload 스크립트 등록
- [ ] 글자 그리드 씬 구현 (GridContainer + LetterCell)
- [ ] 단어 배치 알고리즘 구현
- [ ] 모바일 터치 입력 (탭 + 드래그)
- [ ] 단어 검증 로직
- [ ] 기본 게임 루프 (시작 > 풀기 > 완료)

### Phase 2: UI & 게임 플로우 (1-2주)

- [ ] 메인 메뉴 씬
- [ ] 레벨 선택 씬
- [ ] 게임 보드 씬 (그리드 + 단어 은행 + 타이머 + 점수)
- [ ] 게임 오버 / 완료 씬
- [ ] 설정 화면
- [ ] Theme 리소스 구성
- [ ] 기본 사운드 연동 (Kenney 에셋)

### Phase 3: 콘텐츠 & 데이터 (1주)

- [ ] 한국어 단어 데이터 작성 (최소 5개 카테고리, 카테고리당 20-30단어)
- [ ] 영어 단어 데이터 작성
- [ ] 난이도 시스템 구현
- [ ] 세이브/로드 시스템
- [ ] 힌트 시스템

### Phase 4: TV 적응 (1주)

- [ ] D-pad 포커스 내비게이션 구현
- [ ] TV용 Theme 오버라이드 (tv_theme.tres)
- [ ] 플랫폼 감지 및 동적 레이아웃 전환
- [ ] Android TV 매니페스트 설정
- [ ] TV 에뮬레이터에서 테스트

### Phase 5: 수익화 & 폴리싱 (1주)

- [ ] AdMob 플러그인 통합 (별도 브랜치)
- [ ] 보상형 광고 (힌트 보상)
- [ ] TV용 IMA SDK 통합
- [ ] 데일리 챌린지 시스템
- [ ] 진행 시스템 (별, 잠금해제)
- [ ] UI 폴리싱 및 애니메이션

### Phase 6: 출시 준비 (1주)

- [ ] 스토어 에셋 준비 (스크린샷, 아이콘, 배너, 설명문)
- [ ] 개인정보처리방침 페이지 작성
- [ ] Google Play 내부 테스트 트랙 등록
- [ ] Apple TestFlight 배포
- [ ] Amazon Appstore 제출
- [ ] 버그 수정 및 최종 QA

### Phase 7: 디자이너 핸드오프 (이후)

- [ ] 디자이너에게 Godot 설치 및 Theme Editor 사용법 안내
- [ ] UI 에셋 교체 가이드 문서 작성
- [ ] 사운드 에셋 교체 가이드 문서 작성

---

## 부록: 자주 쓰는 GDScript 패턴

### 씬 전환

```gdscript
# 씬 전환
get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
```

### 타이머

```gdscript
# 1회 실행 타이머
await get_tree().create_timer(1.0).timeout
print("1초 후 실행")

# 반복 타이머 (씬에 Timer 노드 추가 후)
@onready var game_timer: Timer = $GameTimer

func _ready():
    game_timer.timeout.connect(_on_timer_tick)
    game_timer.start(1.0)  # 1초마다

func _on_timer_tick():
    time_remaining -= 1
```

### JSON 파일 읽기

```gdscript
func load_word_data(path: String) -> Dictionary:
    var file = FileAccess.open(path, FileAccess.READ)
    var json = JSON.new()
    json.parse(file.get_as_text())
    file.close()
    return json.data
```

### Signal 연결

```gdscript
# 방법 1: 코드에서 연결
button.pressed.connect(_on_button_pressed)

# 방법 2: 에디터에서 연결 (권장)
# 노드 선택 > Node 탭 > 시그널 더블클릭 > 연결할 함수 선택

# 커스텀 시그널
signal word_found(word: String, score: int)

# 시그널 발행
word_found.emit("코끼리", 100)
```

### 플랫폼 조건부 실행

```gdscript
if OS.has_feature("android"):
    # Android (모바일 + TV)
    pass
elif OS.has_feature("ios"):
    # iOS
    pass
elif OS.has_feature("web"):
    # 웹
    pass
else:
    # 데스크톱 (개발용)
    pass
```
