# CC_04. 테스트 & QA 전략

---

## 1. 문서 정보

| 항목 | 내용 |
|------|------|
| **문서 ID** | CC_04 |
| **카테고리** | Cross-Cutting |
| **제목** | 테스트 & QA 전략 |
| **관련 문서** | 모든 Phase 문서 (PH_01 ~ PH_08), CC_01 ~ CC_03 |
| **최종 수정일** | 2026-03-11 |
| **상태** | 초안 |

### 1.1 문서 목적

본 문서는 Word Search 퍼즐 게임의 품질 보증을 위한 전체 테스트 전략을 정의한다.
단위 테스트(Unit Test)부터 통합 테스트(Integration Test), 수동 테스트(Manual Test)까지
모든 테스트 계층의 범위, 도구, 실행 방법, 그리고 자동화 파이프라인을 상세히 기술한다.

### 1.2 용어 정의

| 용어 | 설명 |
|------|------|
| **GUT** | Godot Unit Test. Godot 전용 단위 테스트 프레임워크 애드온 |
| **DDA** | Dynamic Difficulty Adjustment. 동적 난이도 조절 시스템 |
| **CI/CD** | Continuous Integration / Continuous Deployment |
| **SUT** | System Under Test. 테스트 대상 시스템 |
| **Coverage** | 코드 커버리지. 테스트가 실행하는 코드의 비율 |
| **Regression** | 회귀 테스트. 기존 기능이 변경 후에도 정상 동작하는지 확인 |

---

## 2. 테스트 전략 개요

### 2.1 테스트 피라미드

```
        ┌─────────┐
        │  수동    │  ← 최소한의 탐색적 테스트
        │ 테스트   │     플랫폼별 UI/UX 검증
       ─┤─────────├─
       │  통합     │  ← 모듈 간 상호작용 검증
       │  테스트   │     게임 루프 전체 흐름
      ─┤──────────├─
      │  단위      │  ← 핵심 로직의 정확성 보장
      │  테스트    │     가장 많은 테스트 케이스
     ─┴───────────┴─
```

| 계층 | 비율 | 자동화 | 실행 빈도 |
|------|------|--------|-----------|
| **단위 테스트** | 70% | 완전 자동화 | 매 커밋 |
| **통합 테스트** | 20% | 부분 자동화 | 매 PR |
| **수동 테스트** | 10% | 수동 | 릴리스 전 |

### 2.2 핵심 도구

| 도구 | 용도 | 버전 |
|------|------|------|
| **GUT (Godot Unit Test)** | 단위/통합 테스트 | 9.x (Godot 4.x 호환) |
| **GitHub Actions** | CI/CD 자동화 | - |
| **godot-ci Docker** | Headless 테스트 실행 | Godot 4.6 기반 |
| **GitHub Issues** | 버그 추적 | - |

### 2.3 품질 목표

| 지표 | 목표 |
|------|------|
| 핵심 로직 코드 커버리지 | **80% 이상** |
| 치명적 버그(Blocker) | **0건** (릴리스 시점) |
| 주요 버그(Major) | **3건 이하** |
| 회귀 테스트 통과율 | **100%** |
| 테스트 실행 시간 | **60초 이내** (전체 단위 테스트) |

---

## 3. GUT 테스트 프레임워크 설정

### 3.1 설치

1. Godot 에디터에서 **AssetLib** 탭 클릭
2. 검색창에 `GUT` 입력
3. **Gut - Godot Unit Testing** 선택 → **Download** → **Install**
4. 프로젝트 설정 → 플러그인 → **GUT** 활성화

### 3.2 디렉토리 구조

```
res://
├── test/                          # 테스트 루트 디렉토리
│   ├── unit/                      # 단위 테스트
│   │   ├── test_grid_generator.gd
│   │   ├── test_score_manager.gd
│   │   ├── test_dda_manager.gd
│   │   ├── test_hangul_utils.gd
│   │   ├── test_coin_manager.gd
│   │   ├── test_save_manager.gd
│   │   ├── test_seeded_random.gd
│   │   └── test_false_lead.gd
│   ├── integration/               # 통합 테스트
│   │   ├── test_game_loop.gd
│   │   ├── test_daily_challenge.gd
│   │   ├── test_save_load_cycle.gd
│   │   └── test_coin_flow.gd
│   └── helpers/                   # 테스트 헬퍼/Mock
│       ├── mock_save_manager.gd
│       ├── mock_ad_manager.gd
│       └── test_data_factory.gd
└── addons/
    └── gut/                       # GUT 애드온 (자동 설치)
```

### 3.3 테스트 파일 네이밍 규칙

| 규칙 | 예시 |
|------|------|
| 테스트 파일 | `test_[모듈명].gd` |
| 테스트 함수 | `test_[테스트_대상_동작]()` |
| 헬퍼 파일 | `mock_[모듈명].gd` 또는 `helper_[기능].gd` |
| 데이터 팩토리 | `test_data_factory.gd` |

### 3.4 GUT 설정 파일 (.gutconfig.json)

```json
{
  "dirs": [
    "res://test/unit/",
    "res://test/integration/"
  ],
  "should_maximize": false,
  "compact_mode": true,
  "log_level": 1,
  "include_subdirs": true,
  "prefix": "test_",
  "suffix": ".gd",
  "color_output": true,
  "font_size": 16
}
```

### 3.5 실행 방법

#### 에디터 내 실행
1. 하단 패널에서 **GUT** 탭 선택
2. **Run All** 버튼 클릭 또는 특정 테스트 파일/함수 선택 후 실행

#### CLI 실행 (Headless)
```bash
# 전체 테스트 실행
godot --headless -s addons/gut/gut_cmdln.gd

# 특정 디렉토리만 실행
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit/

# 특정 테스트 파일만 실행
godot --headless -s addons/gut/gut_cmdln.gd \
  -gtest=res://test/unit/test_grid_generator.gd

# 특정 테스트 함수만 실행
godot --headless -s addons/gut/gut_cmdln.gd \
  -gtest=res://test/unit/test_score_manager.gd \
  -gunit_test_name=test_basic_word_score
```

### 3.6 테스트 기본 템플릿

```gdscript
# res://test/unit/test_example.gd
extends GutTest

# ── 테스트 대상 인스턴스 ──
var _sut: ExampleClass  # System Under Test

func before_each() -> void:
    _sut = ExampleClass.new()

func after_each() -> void:
    if is_instance_valid(_sut):
        _sut.free()

func test_example_behavior() -> void:
    # Arrange (준비)
    var input := "test_input"

    # Act (실행)
    var result := _sut.do_something(input)

    # Assert (검증)
    assert_eq(result, "expected_output", "결과가 기대값과 일치해야 한다")
```

---

## 4. 단위 테스트 목록

### 4.1 격자 시스템 (test_grid_generator.gd)

**테스트 대상:** `GridGenerator` 클래스 — 단어 배치, 격자 생성, 방향 스냅 로직

```gdscript
# res://test/unit/test_grid_generator.gd
extends GutTest

var _generator: GridGenerator


func before_each() -> void:
    _generator = GridGenerator.new()


func after_each() -> void:
    if is_instance_valid(_generator):
        _generator.free()


# ── 4.1.1 격자 크기 일치 ──
func test_grid_size_correct() -> void:
    """요청한 크기(rows x cols)와 실제 생성된 격자 크기가 일치해야 한다."""
    var rows := 10
    var cols := 10
    var words: Array[String] = ["사과", "바나나", "포도"]

    var grid: Array = _generator.generate(rows, cols, words)

    assert_eq(grid.size(), rows, "행(rows) 수가 요청값과 일치해야 한다")
    for row_idx in range(rows):
        assert_eq(
            grid[row_idx].size(), cols,
            "행 %d의 열(cols) 수가 요청값과 일치해야 한다" % row_idx
        )


# ── 4.1.2 모든 단어 배치 확인 ──
func test_all_words_placed() -> void:
    """모든 입력 단어가 격자 내에 배치되어 있어야 한다."""
    var words: Array[String] = ["호랑이", "사자", "독수리"]

    var result: Dictionary = _generator.generate_with_info(8, 8, words)
    var placed_words: Array = result["placed_words"]

    for word in words:
        assert_has(placed_words, word, "'%s'가 격자에 배치되어야 한다" % word)


# ── 4.1.3 겹침 셀 글자 일치 ──
func test_word_overlap_valid() -> void:
    """두 단어가 겹치는 셀에서 양쪽 단어의 글자가 동일해야 한다."""
    # 고의적으로 겹침이 발생하도록 작은 격자 + 많은 단어 사용
    var words: Array[String] = ["가나다", "나라마", "다마바"]

    var result: Dictionary = _generator.generate_with_info(6, 6, words)
    var placements: Array = result["placements"]  # [{word, row, col, dir}, ...]

    # 격자를 순회하며 같은 셀에 여러 단어가 지나는 경우 글자 일치 확인
    var cell_map: Dictionary = {}  # "row,col" -> char
    for placement in placements:
        var syllables: Array = _decompose_word(placement["word"])
        var r: int = placement["row"]
        var c: int = placement["col"]
        var dr: int = placement["dir"].y
        var dc: int = placement["dir"].x
        for i in range(syllables.size()):
            var key := "%d,%d" % [r + dr * i, c + dc * i]
            if cell_map.has(key):
                assert_eq(
                    cell_map[key], syllables[i],
                    "셀 [%s]에서 겹침 글자가 일치해야 한다" % key
                )
            else:
                cell_map[key] = syllables[i]


# ── 4.1.4 격자 밖 배치 방지 ──
func test_no_out_of_bounds() -> void:
    """배치된 단어가 격자 경계를 벗어나지 않아야 한다."""
    var rows := 8
    var cols := 8
    var words: Array[String] = ["코끼리", "하마", "기린", "원숭이"]

    var result: Dictionary = _generator.generate_with_info(rows, cols, words)
    var placements: Array = result["placements"]

    for placement in placements:
        var word_len: int = placement["word"].length()
        var r: int = placement["row"]
        var c: int = placement["col"]
        var dr: int = placement["dir"].y
        var dc: int = placement["dir"].x

        var end_r: int = r + dr * (word_len - 1)
        var end_c: int = c + dc * (word_len - 1)

        assert_true(
            r >= 0 and r < rows,
            "'%s' 시작 행(%d)이 범위 내여야 한다" % [placement["word"], r]
        )
        assert_true(
            c >= 0 and c < cols,
            "'%s' 시작 열(%d)이 범위 내여야 한다" % [placement["word"], c]
        )
        assert_true(
            end_r >= 0 and end_r < rows,
            "'%s' 끝 행(%d)이 범위 내여야 한다" % [placement["word"], end_r]
        )
        assert_true(
            end_c >= 0 and end_c < cols,
            "'%s' 끝 열(%d)이 범위 내여야 한다" % [placement["word"], end_c]
        )


# ── 4.1.5 빈 셀 없음 ──
func test_empty_cells_filled() -> void:
    """격자 생성 후 모든 셀에 음절이 채워져 있어야 한다."""
    var grid: Array = _generator.generate(10, 10, ["테스트", "단어"])

    for r in range(grid.size()):
        for c in range(grid[r].size()):
            assert_ne(
                grid[r][c], "",
                "셀 [%d][%d]가 빈 문자열이면 안 된다" % [r, c]
            )
            assert_true(
                grid[r][c].length() > 0,
                "셀 [%d][%d]에 음절이 채워져 있어야 한다" % [r, c]
            )


# ── 4.1.6 방향 스냅 정확성 ──
func test_direction_snapper() -> void:
    """드래그 각도가 정확히 8방향 중 하나로 스냅되어야 한다."""
    # 8방향: →, ↘, ↓, ↙, ←, ↖, ↑, ↗
    var expected_snaps: Array[Dictionary] = [
        {"angle_deg": 0.0,   "expected": Vector2i(1, 0)},    # →
        {"angle_deg": 45.0,  "expected": Vector2i(1, 1)},    # ↘
        {"angle_deg": 90.0,  "expected": Vector2i(0, 1)},    # ↓
        {"angle_deg": 135.0, "expected": Vector2i(-1, 1)},   # ↙
        {"angle_deg": 180.0, "expected": Vector2i(-1, 0)},   # ←
        {"angle_deg": 225.0, "expected": Vector2i(-1, -1)},  # ↖
        {"angle_deg": 270.0, "expected": Vector2i(0, -1)},   # ↑
        {"angle_deg": 315.0, "expected": Vector2i(1, -1)},   # ↗
    ]

    for snap in expected_snaps:
        var result: Vector2i = _generator.snap_to_direction(snap["angle_deg"])
        assert_eq(
            result, snap["expected"],
            "각도 %.1f°가 %s로 스냅되어야 한다" % [snap["angle_deg"], snap["expected"]]
        )

    # 경계값: 22.5° (→과 ↘ 사이) → 가장 가까운 방향으로 스냅
    var boundary_result: Vector2i = _generator.snap_to_direction(22.0)
    assert_eq(
        boundary_result, Vector2i(1, 0),
        "22°는 →(동쪽)으로 스냅되어야 한다"
    )

    var boundary_result2: Vector2i = _generator.snap_to_direction(23.0)
    assert_eq(
        boundary_result2, Vector2i(1, 1),
        "23°는 ↘(남동)으로 스냅되어야 한다"
    )


# ── 헬퍼 함수 ──
func _decompose_word(word: String) -> Array:
    """단어를 음절 단위 배열로 분해한다."""
    var result: Array = []
    for i in range(word.length()):
        result.append(word[i])
    return result
```

---

### 4.2 점수 시스템 (test_score_manager.gd)

**테스트 대상:** `ScoreManager` — 단어 점수 계산, 콤보 배율, 시간 보너스, 등급 판정

```gdscript
# res://test/unit/test_score_manager.gd
extends GutTest

var _score_mgr: ScoreManager


func before_each() -> void:
    _score_mgr = ScoreManager.new()
    _score_mgr.reset()


func after_each() -> void:
    if is_instance_valid(_score_mgr):
        _score_mgr.free()


# ── 4.2.1 기본 단어 점수 ──
func test_basic_word_score() -> void:
    """기본 점수 공식: 50 + (글자수 × 10)"""
    # 2글자 단어: 50 + (2 × 10) = 70
    assert_eq(
        _score_mgr.calculate_word_score("사과"),
        70,
        "2글자 단어 점수는 70이어야 한다"
    )

    # 3글자 단어: 50 + (3 × 10) = 80
    assert_eq(
        _score_mgr.calculate_word_score("바나나"),
        80,
        "3글자 단어 점수는 80이어야 한다"
    )

    # 4글자 단어: 50 + (4 × 10) = 90
    assert_eq(
        _score_mgr.calculate_word_score("아이스크"),
        90,
        "4글자 단어 점수는 90이어야 한다"
    )

    # 5글자 단어: 50 + (5 × 10) = 100
    assert_eq(
        _score_mgr.calculate_word_score("아이스크림"),
        100,
        "5글자 단어 점수는 100이어야 한다"
    )


# ── 4.2.2 콤보 배율 ──
func test_combo_multiplier() -> void:
    """10초 이내 연속 발견 시 콤보 배율 1.5x 적용."""
    # 첫 번째 단어 발견 (콤보 없음)
    _score_mgr.on_word_found("사과", 0.0)
    var first_score: int = _score_mgr.get_last_score()
    assert_eq(first_score, 70, "첫 단어는 콤보 미적용 70점")

    # 두 번째 단어 발견 (5초 후 → 10초 이내 → 콤보 적용)
    _score_mgr.on_word_found("바나나", 5.0)
    var combo_score: int = _score_mgr.get_last_score()
    # 80 × 1.5 = 120
    assert_eq(combo_score, 120, "10초 이내 연속 발견 시 1.5x 적용 = 120점")

    # 세 번째 단어 발견 (20초 후 → 10초 초과 → 콤보 리셋)
    _score_mgr.on_word_found("포도", 25.0)
    var reset_score: int = _score_mgr.get_last_score()
    assert_eq(reset_score, 70, "10초 초과 시 콤보 리셋, 기본 점수 70점")


# ── 4.2.3 Time Attack 시간 보너스 ──
func test_time_bonus() -> void:
    """Time Attack 모드에서 남은 시간 × 2 보너스 적용."""
    # 남은 시간 30초
    var bonus: int = _score_mgr.calculate_time_bonus(30.0)
    assert_eq(bonus, 60, "남은시간 30초 × 2 = 60점 보너스")

    # 남은 시간 0초
    var no_bonus: int = _score_mgr.calculate_time_bonus(0.0)
    assert_eq(no_bonus, 0, "남은시간 0초 → 보너스 없음")

    # 남은 시간 90초 (최대)
    var max_bonus: int = _score_mgr.calculate_time_bonus(90.0)
    assert_eq(max_bonus, 180, "남은시간 90초 × 2 = 180점 보너스")


# ── 4.2.4 등급 판정: S등급 ──
func test_grade_s() -> void:
    """힌트 미사용 + 90초 이내 클리어 = S등급."""
    var grade: String = _score_mgr.calculate_grade(
        hints_used = 0,
        clear_time = 85.0,
        time_limit = 180.0
    )
    assert_eq(grade, "S", "힌트 0회 + 85초 클리어 → S등급")

    # 경계값: 정확히 90초
    var grade_boundary: String = _score_mgr.calculate_grade(
        hints_used = 0,
        clear_time = 90.0,
        time_limit = 180.0
    )
    assert_eq(grade_boundary, "S", "힌트 0회 + 90초 정확 → S등급")


# ── 4.2.5 등급 판정: A등급 ──
func test_grade_a() -> void:
    """힌트 미사용 + 90초 초과 = A등급."""
    var grade: String = _score_mgr.calculate_grade(
        hints_used = 0,
        clear_time = 120.0,
        time_limit = 180.0
    )
    assert_eq(grade, "A", "힌트 0회 + 120초 클리어 → A등급")


# ── 4.2.6 등급 판정: B등급 ──
func test_grade_b() -> void:
    """힌트 1회 사용 = B등급."""
    var grade: String = _score_mgr.calculate_grade(
        hints_used = 1,
        clear_time = 60.0,
        time_limit = 180.0
    )
    assert_eq(grade, "B", "힌트 1회 → B등급 (시간 무관)")

    # 시간이 빨라도 힌트 1회 사용 시 B등급
    var grade_fast: String = _score_mgr.calculate_grade(
        hints_used = 1,
        clear_time = 30.0,
        time_limit = 180.0
    )
    assert_eq(grade_fast, "B", "힌트 1회 + 30초 클리어 → 여전히 B등급")


# ── 4.2.7 등급 판정: C등급 ──
func test_grade_c() -> void:
    """힌트 2회 이상 사용 = C등급."""
    var grade_2: String = _score_mgr.calculate_grade(
        hints_used = 2,
        clear_time = 60.0,
        time_limit = 180.0
    )
    assert_eq(grade_2, "C", "힌트 2회 → C등급")

    var grade_5: String = _score_mgr.calculate_grade(
        hints_used = 5,
        clear_time = 60.0,
        time_limit = 180.0
    )
    assert_eq(grade_5, "C", "힌트 5회 → C등급")
```

---

### 4.3 DDA 시스템 (test_dda_manager.gd)

**테스트 대상:** `DDAManager` — 동적 난이도 오프셋 계산, 범위 제한, 휴식 스테이지, 톱니파 패턴

```gdscript
# res://test/unit/test_dda_manager.gd
extends GutTest

var _dda: DDAManager


func before_each() -> void:
    _dda = DDAManager.new()


func after_each() -> void:
    if is_instance_valid(_dda):
        _dda.free()


# ── 4.3.1 오프셋 계산 (3스테이지 히스토리 기반) ──
func test_dda_offset_calculation() -> void:
    """최근 3개 스테이지 성과에 따른 난이도 오프셋 계산."""
    # 모두 S등급 → 난이도 상승 (+)
    _dda.record_result({"grade": "S", "hints_used": 0, "time_ratio": 0.4})
    _dda.record_result({"grade": "S", "hints_used": 0, "time_ratio": 0.3})
    _dda.record_result({"grade": "S", "hints_used": 0, "time_ratio": 0.5})

    var offset_up: int = _dda.get_difficulty_offset()
    assert_gt(offset_up, 0, "연속 S등급 시 양수 오프셋 (난이도 상승)")

    # 리셋 후 모두 C등급 → 난이도 하락 (-)
    _dda.reset()
    _dda.record_result({"grade": "C", "hints_used": 3, "time_ratio": 0.95})
    _dda.record_result({"grade": "C", "hints_used": 4, "time_ratio": 0.90})
    _dda.record_result({"grade": "C", "hints_used": 2, "time_ratio": 0.85})

    var offset_down: int = _dda.get_difficulty_offset()
    assert_lt(offset_down, 0, "연속 C등급 시 음수 오프셋 (난이도 하락)")


# ── 4.3.2 오프셋 클램프 (±2 범위) ──
func test_dda_clamp() -> void:
    """DDA 오프셋은 항상 -2 ~ +2 범위 내여야 한다."""
    # 극단적으로 좋은 성과 기록
    for i in range(10):
        _dda.record_result({"grade": "S", "hints_used": 0, "time_ratio": 0.2})

    var offset: int = _dda.get_difficulty_offset()
    assert_true(
        offset >= -2 and offset <= 2,
        "오프셋(%d)이 ±2 범위를 벗어나면 안 된다" % offset
    )

    # 극단적으로 나쁜 성과 기록
    _dda.reset()
    for i in range(10):
        _dda.record_result({"grade": "C", "hints_used": 5, "time_ratio": 1.0})

    var offset_low: int = _dda.get_difficulty_offset()
    assert_true(
        offset_low >= -2 and offset_low <= 2,
        "오프셋(%d)이 ±2 범위를 벗어나면 안 된다" % offset_low
    )


# ── 4.3.3 휴식 스테이지 ──
func test_rest_stage() -> void:
    """10의 배수 스테이지에서 wordCount가 -2 감소한다."""
    var base_word_count := 6

    # 일반 스테이지 (5번)
    var normal: int = _dda.adjust_word_count(base_word_count, 5)
    assert_eq(normal, base_word_count, "일반 스테이지는 wordCount 변동 없음")

    # 휴식 스테이지 (10번)
    var rest_10: int = _dda.adjust_word_count(base_word_count, 10)
    assert_eq(rest_10, base_word_count - 2, "10번 스테이지: wordCount -2")

    # 휴식 스테이지 (20번)
    var rest_20: int = _dda.adjust_word_count(base_word_count, 20)
    assert_eq(rest_20, base_word_count - 2, "20번 스테이지: wordCount -2")

    # 최소값 보장 (wordCount가 2 이하로 내려가지 않음)
    var min_check: int = _dda.adjust_word_count(3, 10)
    assert_gte(min_check, 1, "wordCount 최소값은 1 이상이어야 한다")


# ── 4.3.4 톱니파(Sawtooth) 패턴 검증 ──
func test_sawtooth_pattern() -> void:
    """스테이지 진행 시 난이도가 점진 상승 → 리셋(휴식) 패턴을 따른다."""
    var difficulties: Array[int] = []
    var base := 4

    for stage in range(1, 21):
        var word_count: int = _dda.calculate_stage_word_count(base, stage, 0)
        difficulties.append(word_count)

    # 9번(index 8)까지 증가 추세
    for i in range(1, 9):
        assert_gte(
            difficulties[i], difficulties[i - 1],
            "스테이지 %d → %d에서 난이도 비감소" % [i, i + 1]
        )

    # 10번(index 9)에서 감소 (휴식)
    assert_lt(
        difficulties[9], difficulties[8],
        "스테이지 10은 휴식 스테이지로 난이도 감소"
    )
```

---

### 4.4 한글 유틸 (test_hangul_utils.gd)

**테스트 대상:** `HangulUtils` — 한글 분해/조합, 판별, 음절 풀 관리

```gdscript
# res://test/unit/test_hangul_utils.gd
extends GutTest

var _hangul: HangulUtils


func before_each() -> void:
    _hangul = HangulUtils.new()


func after_each() -> void:
    if is_instance_valid(_hangul):
        _hangul.free()


# ── 4.4.1 한글 분해 ──
func test_decompose() -> void:
    """한글 음절을 초성/중성/종성으로 분해한다."""
    # "호" → 초성 "ㅎ", 중성 "ㅗ", 종성 "" (없음)
    var result: Dictionary = _hangul.decompose("호")
    assert_eq(result["initial"], "ㅎ", "'호'의 초성은 'ㅎ'")
    assert_eq(result["medial"], "ㅗ", "'호'의 중성은 'ㅗ'")
    assert_eq(result["final"], "", "'호'의 종성은 빈 문자열")

    # "한" → 초성 "ㅎ", 중성 "ㅏ", 종성 "ㄴ"
    var result2: Dictionary = _hangul.decompose("한")
    assert_eq(result2["initial"], "ㅎ", "'한'의 초성은 'ㅎ'")
    assert_eq(result2["medial"], "ㅏ", "'한'의 중성은 'ㅏ'")
    assert_eq(result2["final"], "ㄴ", "'한'의 종성은 'ㄴ'")

    # "글" → 초성 "ㄱ", 중성 "ㅡ", 종성 "ㄹ"
    var result3: Dictionary = _hangul.decompose("글")
    assert_eq(result3["initial"], "ㄱ", "'글'의 초성은 'ㄱ'")
    assert_eq(result3["medial"], "ㅡ", "'글'의 중성은 'ㅡ'")
    assert_eq(result3["final"], "ㄹ", "'글'의 종성은 'ㄹ'")


# ── 4.4.2 한글 조합 ──
func test_compose() -> void:
    """초성/중성/종성으로부터 한글 음절을 조합한다."""
    # "ㅎ" + "ㅗ" + "" → "호"
    var char1: String = _hangul.compose("ㅎ", "ㅗ", "")
    assert_eq(char1, "호", "ㅎ + ㅗ → '호'")

    # "ㅎ" + "ㅏ" + "ㄴ" → "한"
    var char2: String = _hangul.compose("ㅎ", "ㅏ", "ㄴ")
    assert_eq(char2, "한", "ㅎ + ㅏ + ㄴ → '한'")

    # "ㄱ" + "ㅡ" + "ㄹ" → "글"
    var char3: String = _hangul.compose("ㄱ", "ㅡ", "ㄹ")
    assert_eq(char3, "글", "ㄱ + ㅡ + ㄹ → '글'")

    # 분해 후 재조합이 원본과 동일한지 검증 (Roundtrip)
    var original := "닭"
    var decomposed: Dictionary = _hangul.decompose(original)
    var recomposed: String = _hangul.compose(
        decomposed["initial"], decomposed["medial"], decomposed["final"]
    )
    assert_eq(recomposed, original, "분해→재조합 roundtrip이 원본과 같아야 한다")


# ── 4.4.3 한글 판별 ──
func test_is_hangul() -> void:
    """주어진 문자가 한글 음절인지 판별한다."""
    # 한글 음절 범위: U+AC00 ~ U+D7A3
    assert_true(_hangul.is_hangul("가"), "'가'는 한글이다")
    assert_true(_hangul.is_hangul("힣"), "'힣'(마지막 한글)은 한글이다")
    assert_true(_hangul.is_hangul("퍼"), "'퍼'는 한글이다")

    # 비한글 문자
    assert_false(_hangul.is_hangul("A"), "'A'는 한글이 아니다")
    assert_false(_hangul.is_hangul("1"), "'1'은 한글이 아니다")
    assert_false(_hangul.is_hangul("あ"), "일본어 히라가나는 한글이 아니다")
    assert_false(_hangul.is_hangul(" "), "공백은 한글이 아니다")
    assert_false(_hangul.is_hangul(""), "빈 문자열은 한글이 아니다")

    # 한글 자모 (음절이 아닌 단독 자모)
    assert_false(_hangul.is_hangul("ㄱ"), "단독 자모 'ㄱ'은 완성형 한글이 아니다")
    assert_false(_hangul.is_hangul("ㅏ"), "단독 모음 'ㅏ'는 완성형 한글이 아니다")


# ── 4.4.4 음절 풀 추출 ──
func test_syllable_pool() -> void:
    """WordPack에서 고유 음절을 정확히 추출한다."""
    var word_pack: Array[String] = ["사과", "바나나", "포도"]
    # 고유 음절: 사, 과, 바, 나, 포, 도
    var pool: Array[String] = _hangul.extract_syllable_pool(word_pack)

    assert_has(pool, "사", "'사'가 음절 풀에 있어야 한다")
    assert_has(pool, "과", "'과'가 음절 풀에 있어야 한다")
    assert_has(pool, "바", "'바'가 음절 풀에 있어야 한다")
    assert_has(pool, "나", "'나'가 음절 풀에 있어야 한다")
    assert_has(pool, "포", "'포'가 음절 풀에 있어야 한다")
    assert_has(pool, "도", "'도'가 음절 풀에 있어야 한다")

    # "바나나"에서 "나"는 중복이므로 고유 개수는 6
    assert_eq(pool.size(), 6, "고유 음절은 6개여야 한다")


# ── 4.4.5 빈칸 채우기에 희귀 음절 미포함 ──
func test_empty_fill_no_rare() -> void:
    """빈 셀 채우기에 사용되는 음절에 희귀 음절이 포함되지 않아야 한다."""
    var word_pack: Array[String] = ["사과", "바나나", "포도", "딸기"]
    var fill_pool: Array[String] = _hangul.get_fill_syllables(word_pack)

    # 희귀 음절 목록 (한글에서 거의 사용되지 않는 음절)
    var rare_syllables: Array[String] = ["뷁", "틩", "흿", "읩"]

    for rare in rare_syllables:
        assert_does_not_have(
            fill_pool, rare,
            "희귀 음절 '%s'가 채우기 풀에 없어야 한다" % rare
        )

    # 채우기 풀의 모든 음절이 한글인지 확인
    for syllable in fill_pool:
        assert_true(
            _hangul.is_hangul(syllable),
            "채우기 음절 '%s'는 한글이어야 한다" % syllable
        )
```

---

### 4.5 코인 시스템 (test_coin_manager.gd)

**테스트 대상:** `CoinManager` — 코인 초기화, 획득, 소모, 잔액 검증

```gdscript
# res://test/unit/test_coin_manager.gd
extends GutTest

var _coin_mgr: CoinManager


func before_each() -> void:
    _coin_mgr = CoinManager.new()
    _coin_mgr.initialize_new_user()


func after_each() -> void:
    if is_instance_valid(_coin_mgr):
        _coin_mgr.free()


# ── 4.5.1 신규 유저 초기 코인 ──
func test_initial_coins() -> void:
    """신규 유저의 초기 코인은 300이어야 한다."""
    assert_eq(
        _coin_mgr.get_balance(), 300,
        "신규 유저 초기 코인은 300"
    )


# ── 4.5.2 코인 획득 ──
func test_earn_coins() -> void:
    """코인 획득 후 잔액이 정확히 증가해야 한다."""
    var initial: int = _coin_mgr.get_balance()

    _coin_mgr.earn(50)
    assert_eq(
        _coin_mgr.get_balance(), initial + 50,
        "50코인 획득 후 잔액은 %d" % (initial + 50)
    )

    _coin_mgr.earn(100)
    assert_eq(
        _coin_mgr.get_balance(), initial + 150,
        "추가 100코인 획득 후 잔액은 %d" % (initial + 150)
    )

    # 0코인 획득 (엣지 케이스)
    _coin_mgr.earn(0)
    assert_eq(
        _coin_mgr.get_balance(), initial + 150,
        "0코인 획득 시 잔액 변동 없음"
    )


# ── 4.5.3 코인 소모 ──
func test_spend_coins() -> void:
    """코인 소모 후 잔액이 정확히 감소해야 한다."""
    var result: bool = _coin_mgr.spend(100)

    assert_true(result, "충분한 잔액에서 소모는 true 반환")
    assert_eq(
        _coin_mgr.get_balance(), 200,
        "300 - 100 = 200코인 잔액"
    )


# ── 4.5.4 잔액 부족 시 실패 ──
func test_insufficient_coins() -> void:
    """잔액이 부족하면 소모 실패(false)하고 잔액은 변하지 않아야 한다."""
    var result: bool = _coin_mgr.spend(500)

    assert_false(result, "잔액 부족 시 false 반환")
    assert_eq(
        _coin_mgr.get_balance(), 300,
        "소모 실패 시 잔액은 그대로 300"
    )


# ── 4.5.5 잔액 음수 방지 ──
func test_coin_never_negative() -> void:
    """어떤 상황에서도 코인 잔액이 음수가 되면 안 된다."""
    # 연속 소모 시도
    _coin_mgr.spend(100)
    _coin_mgr.spend(100)
    _coin_mgr.spend(100)  # 잔액 0
    _coin_mgr.spend(100)  # 잔액 부족 → 실패해야 함

    assert_gte(
        _coin_mgr.get_balance(), 0,
        "잔액은 항상 0 이상이어야 한다 (현재: %d)" % _coin_mgr.get_balance()
    )

    # 정확히 잔액만큼 소모
    _coin_mgr.initialize_new_user()
    _coin_mgr.spend(300)
    assert_eq(
        _coin_mgr.get_balance(), 0,
        "전액 소모 후 잔액은 정확히 0"
    )
```

---

### 4.6 세이브 시스템 (test_save_manager.gd)

**테스트 대상:** `SaveManager` — 저장/로드, 기본값, 손상 복구, 버전 마이그레이션

```gdscript
# res://test/unit/test_save_manager.gd
extends GutTest

const SAVE_PATH := "user://test_save.json"
const BACKUP_PATH := "user://test_save.json.bak"

var _save_mgr: SaveManager


func before_each() -> void:
    _save_mgr = SaveManager.new()
    _save_mgr.set_save_path(SAVE_PATH)
    _save_mgr.set_backup_path(BACKUP_PATH)
    _cleanup_files()


func after_each() -> void:
    _cleanup_files()
    if is_instance_valid(_save_mgr):
        _save_mgr.free()


func _cleanup_files() -> void:
    """테스트용 세이브 파일 정리."""
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)
    if FileAccess.file_exists(BACKUP_PATH):
        DirAccess.remove_absolute(BACKUP_PATH)


# ── 4.6.1 저장 후 로드 데이터 일치 ──
func test_save_and_load() -> void:
    """저장한 데이터를 로드하면 원본과 동일해야 한다."""
    var data := {
        "coins": 500,
        "current_stage": 15,
        "daily_streak": 3,
        "settings": {"sfx_volume": 0.8, "bgm_volume": 0.5},
        "unlocked_themes": ["default", "ocean"],
    }

    _save_mgr.save(data)
    var loaded: Dictionary = _save_mgr.load_data()

    assert_eq(loaded["coins"], 500, "코인 값 일치")
    assert_eq(loaded["current_stage"], 15, "현재 스테이지 값 일치")
    assert_eq(loaded["daily_streak"], 3, "일일 연속 기록 일치")
    assert_eq(loaded["settings"]["sfx_volume"], 0.8, "SFX 볼륨 일치")
    assert_eq(loaded["settings"]["bgm_volume"], 0.5, "BGM 볼륨 일치")
    assert_eq(
        loaded["unlocked_themes"].size(), 2,
        "해금 테마 수 일치"
    )


# ── 4.6.2 초기 세이브 기본값 ──
func test_default_values() -> void:
    """세이브 파일이 없을 때 기본값이 올바르게 설정되어야 한다."""
    var loaded: Dictionary = _save_mgr.load_data()

    assert_eq(loaded["coins"], 300, "기본 코인은 300")
    assert_eq(loaded["current_stage"], 1, "기본 스테이지는 1")
    assert_eq(loaded["daily_streak"], 0, "기본 연속 기록은 0")
    assert_eq(loaded["hints_remaining"], 3, "기본 힌트 수는 3")
    assert_eq(loaded["save_version"], SaveManager.CURRENT_VERSION, "세이브 버전")
    assert_true(loaded.has("settings"), "settings 키가 존재해야 한다")


# ── 4.6.3 손상된 파일 → 백업 복구 ──
func test_corrupted_save() -> void:
    """세이브 파일이 손상되면 백업에서 복구해야 한다."""
    # 정상 데이터를 먼저 저장 (이 과정에서 백업도 생성됨)
    var valid_data := {"coins": 999, "current_stage": 50, "save_version": 1}
    _save_mgr.save(valid_data)

    # 세이브 파일을 손상시킴
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string("{{{CORRUPTED DATA---NOT JSON!!!")
    file.close()

    # 로드 시도 → 백업에서 복구
    var loaded: Dictionary = _save_mgr.load_data()

    assert_eq(
        loaded["coins"], 999,
        "백업에서 복구된 코인 값이 일치해야 한다"
    )
    assert_eq(
        loaded["current_stage"], 50,
        "백업에서 복구된 스테이지 값이 일치해야 한다"
    )


# ── 4.6.4 구버전 데이터 마이그레이션 ──
func test_version_migration() -> void:
    """구버전 세이브 데이터를 현재 버전으로 마이그레이션해야 한다."""
    # v1 형식의 구버전 데이터
    var v1_data := {
        "save_version": 1,
        "coins": 200,
        "stage": 10,  # v1에서는 "stage"로 사용
        # v2에서 추가된 "daily_streak" 없음
        # v2에서 추가된 "settings" 없음
    }

    # v1 데이터를 파일에 직접 저장
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(v1_data))
    file.close()

    # 로드 (마이그레이션 자동 적용)
    var loaded: Dictionary = _save_mgr.load_data()

    assert_eq(
        loaded["save_version"], SaveManager.CURRENT_VERSION,
        "마이그레이션 후 버전이 최신이어야 한다"
    )
    assert_eq(loaded["coins"], 200, "기존 코인 값 보존")
    assert_eq(
        loaded["current_stage"], 10,
        "'stage' → 'current_stage' 키 마이그레이션"
    )
    assert_true(
        loaded.has("daily_streak"),
        "v2에서 추가된 'daily_streak' 필드가 있어야 한다"
    )
    assert_true(
        loaded.has("settings"),
        "v2에서 추가된 'settings' 필드가 있어야 한다"
    )
```

---

### 4.7 SeededRandom (test_seeded_random.gd)

**테스트 대상:** `SeededRandom` — 시드 기반 결정론적 난수, Daily Challenge 시드 포맷

```gdscript
# res://test/unit/test_seeded_random.gd
extends GutTest

var _rng: SeededRandom


func before_each() -> void:
    _rng = SeededRandom.new()


func after_each() -> void:
    if is_instance_valid(_rng):
        _rng.free()


# ── 4.7.1 동일 시드 → 동일 결과 ──
func test_same_seed_same_result() -> void:
    """동일한 시드로 초기화하면 동일한 난수 시퀀스가 생성되어야 한다."""
    var seed_value: int = 12345

    # 첫 번째 시퀀스
    _rng.set_seed(seed_value)
    var sequence_1: Array[int] = []
    for i in range(100):
        sequence_1.append(_rng.next_int(0, 1000))

    # 두 번째 시퀀스 (같은 시드)
    _rng.set_seed(seed_value)
    var sequence_2: Array[int] = []
    for i in range(100):
        sequence_2.append(_rng.next_int(0, 1000))

    assert_eq(
        sequence_1, sequence_2,
        "동일 시드에서 100개 난수 시퀀스가 완전히 일치해야 한다"
    )


# ── 4.7.2 다른 시드 → 다른 결과 ──
func test_different_seed_different() -> void:
    """다른 시드로 초기화하면 다른 난수 시퀀스가 생성되어야 한다."""
    _rng.set_seed(11111)
    var seq_a: Array[int] = []
    for i in range(20):
        seq_a.append(_rng.next_int(0, 10000))

    _rng.set_seed(22222)
    var seq_b: Array[int] = []
    for i in range(20):
        seq_b.append(_rng.next_int(0, 10000))

    assert_ne(
        seq_a, seq_b,
        "다른 시드에서 생성된 시퀀스는 달라야 한다"
    )


# ── 4.7.3 Daily Challenge 시드 포맷 ──
func test_daily_seed_format() -> void:
    """Daily Challenge 시드는 YYYYMMDD 정수 포맷이어야 한다."""
    # 2026년 3월 11일
    var seed: int = _rng.generate_daily_seed(2026, 3, 11)
    assert_eq(seed, 20260311, "2026/03/11 → 시드 20260311")

    # 2026년 1월 1일 (한 자리 월/일의 제로 패딩)
    var seed_jan: int = _rng.generate_daily_seed(2026, 1, 1)
    assert_eq(seed_jan, 20260101, "2026/01/01 → 시드 20260101")

    # 2026년 12월 31일
    var seed_dec: int = _rng.generate_daily_seed(2026, 12, 31)
    assert_eq(seed_dec, 20261231, "2026/12/31 → 시드 20261231")

    # 같은 날짜의 시드로 생성된 퍼즐은 항상 동일해야 한다
    _rng.set_seed(seed)
    var grid_seq_1: Array[int] = []
    for i in range(50):
        grid_seq_1.append(_rng.next_int(0, 100))

    _rng.set_seed(seed)
    var grid_seq_2: Array[int] = []
    for i in range(50):
        grid_seq_2.append(_rng.next_int(0, 100))

    assert_eq(
        grid_seq_1, grid_seq_2,
        "같은 날짜 시드로 생성된 퍼즐 시퀀스는 일치해야 한다"
    )
```

---

### 4.8 거짓 단서 (test_false_lead.gd)

**테스트 대상:** `FalseLeadGenerator` — 활성 조건, 접두사 매칭, 정답 비중복

```gdscript
# res://test/unit/test_false_lead.gd
extends GutTest

var _false_lead: FalseLeadGenerator


func before_each() -> void:
    _false_lead = FalseLeadGenerator.new()


func after_each() -> void:
    if is_instance_valid(_false_lead):
        _false_lead.free()


# ── 4.8.1 11스테이지 이상에서만 활성 ──
func test_false_lead_after_stage_11() -> void:
    """거짓 단서는 11스테이지 이상에서만 생성되어야 한다."""
    var words: Array[String] = ["사과", "바나나", "포도"]

    # 10스테이지 이하: 거짓 단서 비활성
    for stage in range(1, 11):
        var leads: Array = _false_lead.generate(words, stage)
        assert_eq(
            leads.size(), 0,
            "스테이지 %d에서는 거짓 단서가 없어야 한다" % stage
        )

    # 11스테이지 이상: 거짓 단서 활성
    var leads_11: Array = _false_lead.generate(words, 11)
    assert_gt(
        leads_11.size(), 0,
        "스테이지 11에서는 거짓 단서가 1개 이상이어야 한다"
    )

    var leads_20: Array = _false_lead.generate(words, 20)
    assert_gt(
        leads_20.size(), 0,
        "스테이지 20에서도 거짓 단서가 생성되어야 한다"
    )


# ── 4.8.2 접두사 패턴 매칭 ──
func test_false_lead_prefix() -> void:
    """거짓 단서는 정답 단어의 접두사로 시작해야 한다."""
    var words: Array[String] = ["사과", "바나나", "포도나무"]
    var leads: Array = _false_lead.generate(words, 15)

    for lead in leads:
        var has_prefix_match := false
        for word in words:
            # 거짓 단서의 첫 음절이 정답 단어 중 하나의 첫 음절과 일치
            if lead.length() > 0 and word.length() > 0:
                if lead[0] == word[0]:
                    has_prefix_match = true
                    break

        assert_true(
            has_prefix_match,
            "거짓 단서 '%s'는 정답 단어 중 하나의 접두사와 일치해야 한다" % lead
        )


# ── 4.8.3 거짓 단서가 정답과 겹치지 않음 ──
func test_false_lead_not_answer() -> void:
    """거짓 단서는 정답 단어 목록에 포함되면 안 된다."""
    var words: Array[String] = ["사과", "바나나", "포도", "딸기", "수박"]

    # 여러 번 생성해서 한 번도 정답과 겹치지 않는지 확인
    for attempt in range(50):
        var leads: Array = _false_lead.generate(words, 15)
        for lead in leads:
            assert_does_not_have(
                words, lead,
                "거짓 단서 '%s'가 정답 목록에 포함되면 안 된다 (시도 %d)" \
                    % [lead, attempt]
            )
```

---

## 5. 통합 테스트

### 5.1 전체 게임 루프 (test_game_loop.gd)

**시나리오:** 시작 → 격자 생성 → 단어 선택 → 스테이지 클리어 → 결과 화면 → 다음 스테이지

```gdscript
# res://test/integration/test_game_loop.gd
extends GutTest

var _game: GameManager


func before_each() -> void:
    _game = GameManager.new()
    add_child_autofree(_game)
    _game.initialize_for_test()


# ── 5.1.1 전체 게임 루프 ──
func test_full_game_loop() -> void:
    """시작부터 스테이지 클리어까지의 전체 흐름을 검증한다."""
    # 1) 스테이지 시작
    _game.start_stage(1)
    assert_eq(_game.get_state(), GameManager.State.PLAYING, "상태: PLAYING")
    assert_ne(_game.get_grid(), null, "격자가 생성되어야 한다")

    # 2) 모든 단어 찾기
    var target_words: Array = _game.get_target_words()
    assert_gt(target_words.size(), 0, "찾을 단어가 1개 이상 있어야 한다")

    for word in target_words:
        _game.on_word_selected(word)

    # 3) 스테이지 클리어 확인
    assert_eq(
        _game.get_state(), GameManager.State.STAGE_CLEAR,
        "모든 단어 발견 후 STAGE_CLEAR 상태"
    )

    # 4) 결과 데이터 확인
    var result: Dictionary = _game.get_stage_result()
    assert_true(result.has("score"), "결과에 점수가 포함되어야 한다")
    assert_true(result.has("grade"), "결과에 등급이 포함되어야 한다")
    assert_true(result.has("time"), "결과에 시간이 포함되어야 한다")

    # 5) 다음 스테이지 진행
    _game.proceed_to_next_stage()
    assert_eq(_game.get_current_stage(), 2, "다음 스테이지는 2")
    assert_eq(_game.get_state(), GameManager.State.PLAYING, "상태: PLAYING")
```

### 5.2 Daily Challenge (test_daily_challenge.gd)

```gdscript
# res://test/integration/test_daily_challenge.gd
extends GutTest

var _daily: DailyChallengeManager


func before_each() -> void:
    _daily = DailyChallengeManager.new()
    add_child_autofree(_daily)


# ── 5.2.1 같은 날짜 = 같은 퍼즐 ──
func test_same_date_same_puzzle() -> void:
    """같은 날짜에 생성된 Daily Challenge는 동일한 퍼즐이어야 한다."""
    var date := {"year": 2026, "month": 3, "day": 11}

    var puzzle_1: Dictionary = _daily.generate_puzzle(date)
    var puzzle_2: Dictionary = _daily.generate_puzzle(date)

    assert_eq(
        puzzle_1["grid"], puzzle_2["grid"],
        "같은 날짜의 격자가 동일해야 한다"
    )
    assert_eq(
        puzzle_1["words"], puzzle_2["words"],
        "같은 날짜의 단어 목록이 동일해야 한다"
    )


# ── 5.2.2 다른 날짜 = 다른 퍼즐 ──
func test_different_date_different_puzzle() -> void:
    """다른 날짜의 Daily Challenge는 다른 퍼즐이어야 한다."""
    var date_1 := {"year": 2026, "month": 3, "day": 11}
    var date_2 := {"year": 2026, "month": 3, "day": 12}

    var puzzle_1: Dictionary = _daily.generate_puzzle(date_1)
    var puzzle_2: Dictionary = _daily.generate_puzzle(date_2)

    assert_ne(
        puzzle_1["words"], puzzle_2["words"],
        "다른 날짜의 단어 목록이 달라야 한다"
    )
```

### 5.3 세이브/로드 사이클 (test_save_load_cycle.gd)

```gdscript
# res://test/integration/test_save_load_cycle.gd
extends GutTest

var _game: GameManager
var _save_mgr: SaveManager

const TEST_SAVE_PATH := "user://test_integration_save.json"


func before_each() -> void:
    _save_mgr = SaveManager.new()
    _save_mgr.set_save_path(TEST_SAVE_PATH)
    _game = GameManager.new()
    _game.set_save_manager(_save_mgr)
    add_child_autofree(_game)
    add_child_autofree(_save_mgr)


func after_each() -> void:
    if FileAccess.file_exists(TEST_SAVE_PATH):
        DirAccess.remove_absolute(TEST_SAVE_PATH)


# ── 5.3.1 진행 중 저장 → 재시작 → 복원 ──
func test_save_and_restore_progress() -> void:
    """게임 중 저장 후 재시작하면 진행 상황이 정확히 복원되어야 한다."""
    # 1) 게임 진행
    _game.start_stage(5)
    _game.on_word_selected("사과")
    _game.on_word_selected("바나나")

    # 2) 중간 저장
    _game.save_progress()

    # 3) 저장된 상태 확인
    var found_words_before: Array = _game.get_found_words().duplicate()
    var stage_before: int = _game.get_current_stage()
    var score_before: int = _game.get_current_score()

    # 4) 게임 재시작 (새 인스턴스 시뮬레이션)
    _game.reset()
    _game.load_progress()

    # 5) 복원 검증
    assert_eq(
        _game.get_current_stage(), stage_before,
        "스테이지가 복원되어야 한다"
    )
    assert_eq(
        _game.get_found_words(), found_words_before,
        "발견한 단어 목록이 복원되어야 한다"
    )
    assert_eq(
        _game.get_current_score(), score_before,
        "점수가 복원되어야 한다"
    )
```

### 5.4 코인 플로우 (test_coin_flow.gd)

```gdscript
# res://test/integration/test_coin_flow.gd
extends GutTest

var _game: GameManager
var _coin_mgr: CoinManager


func before_each() -> void:
    _coin_mgr = CoinManager.new()
    _coin_mgr.initialize_new_user()
    _game = GameManager.new()
    _game.set_coin_manager(_coin_mgr)
    add_child_autofree(_game)
    add_child_autofree(_coin_mgr)


# ── 5.4.1 클리어→코인획득→힌트사용→코인감소 ──
func test_coin_flow_earn_and_spend() -> void:
    """스테이지 클리어 → 코인 획득 → 힌트 사용 → 코인 감소 흐름."""
    var initial_coins: int = _coin_mgr.get_balance()  # 300

    # 1) 스테이지 클리어 → 코인 획득
    _game.start_stage(1)
    var target_words: Array = _game.get_target_words()
    for word in target_words:
        _game.on_word_selected(word)

    var after_clear: int = _coin_mgr.get_balance()
    assert_gt(
        after_clear, initial_coins,
        "스테이지 클리어 후 코인이 증가해야 한다"
    )

    # 2) 힌트 사용 → 코인 감소
    var hint_cost: int = _game.get_hint_cost()
    var before_hint: int = _coin_mgr.get_balance()

    _game.start_stage(2)
    var hint_result: bool = _game.use_hint()

    assert_true(hint_result, "코인이 충분하면 힌트 사용 성공")
    assert_eq(
        _coin_mgr.get_balance(), before_hint - hint_cost,
        "힌트 사용 후 코인이 비용만큼 감소"
    )


# ── 5.4.2 코인 부족 시 힌트 사용 불가 ──
func test_coin_flow_insufficient_for_hint() -> void:
    """코인이 부족하면 힌트를 사용할 수 없어야 한다."""
    # 코인을 모두 소모
    _coin_mgr.spend(300)
    assert_eq(_coin_mgr.get_balance(), 0, "잔액 0코인")

    _game.start_stage(1)
    var hint_result: bool = _game.use_hint()

    assert_false(hint_result, "코인 부족 시 힌트 사용 실패")
    assert_eq(_coin_mgr.get_balance(), 0, "실패 후에도 잔액은 0 유지")
```

---

## 6. 수동 테스트 매트릭스

### 6.1 플랫폼별 테스트 항목

| 테스트 항목 | Android (Mobile) | iOS | Android TV | Fire TV |
|-------------|:----------------:|:---:|:----------:|:-------:|
| **터치 드래그** (단어 선택) | O | O | - | - |
| **D-pad 네비게이션** | - | - | O | O |
| **화면 회전** (Portrait/Landscape) | O | O | - | - |
| **백그라운드/포그라운드** 전환 | O | O | O | O |
| **광고 재생** | O (AdMob) | O (AdMob) | O (IMA SDK) | O (Amazon Ads) |
| **IAP 구매** | O (Google Play Billing) | O (StoreKit 2) | - | O (Amazon IAP) |
| **알림 수신** | O (FCM) | O (APNs) | - | - |
| **다국어 전환** (한/영/일) | O | O | O | O |
| **다크/라이트 테마** | O | O | O | O |
| **오프라인 플레이** | O | O | O | O |

> **범례:** O = 테스트 필수, - = 해당 없음

### 6.2 입력 방식별 상세 테스트

#### 6.2.1 터치 드래그 (Mobile)
| 테스트 케이스 | 기대 동작 |
|---------------|-----------|
| 시작 셀에서 터치 후 드래그 | 드래그 방향이 8방향으로 스냅, 선택 라인 표시 |
| 대각선 드래그 | 45도 단위로 정확히 스냅 |
| 드래그 중 손가락 떼기 | 선택 확정 → 단어 판정 |
| 빠른 스와이프 | 정상 인식 (최소 드래그 거리 충족 시) |
| 멀티터치 | 첫 번째 터치만 인식, 두 번째 무시 |
| 셀 밖에서 터치 시작 | 무시 (선택 시작 안 됨) |
| 격자 가장자리에서 바깥으로 드래그 | 마지막 유효 셀까지만 선택 |

#### 6.2.2 D-pad 네비게이션 (TV)
| 테스트 케이스 | 기대 동작 |
|---------------|-----------|
| 방향키로 셀 이동 | 한 칸씩 정확히 이동, 포커스 하이라이트 표시 |
| 확인 버튼으로 선택 시작 | 현재 셀에서 선택 모드 진입 |
| 선택 모드 + 방향키 | 8방향 중 하나로 선택 확장 |
| 확인 버튼으로 선택 확정 | 드래그 종료 → 단어 판정 |
| 뒤로 버튼으로 선택 취소 | 현재 선택 취소, 일반 모드 복귀 |
| 메뉴 버튼 | 일시정지 메뉴 표시 |
| 빠른 방향키 반복 입력 | 적절한 입력 딜레이로 오동작 방지 |

### 6.3 화면 및 해상도 테스트

| 대상 | 최소 해상도 | 기준 해상도 | 확인 사항 |
|------|------------|------------|-----------|
| Mobile (Small) | 720 x 1280 | 1080 x 1920 | 터치 영역 최소 48dp, 텍스트 가독성 |
| Mobile (Large) | - | 1440 x 3200 | 격자 셀 과도하게 커지지 않음 |
| Tablet | - | 2048 x 1536 | 가로/세로 모드 모두 정상 |
| Android TV | 1280 x 720 | 1920 x 1080 | 10-foot UI, 포커스 하이라이트 |
| Fire TV | 1280 x 720 | 1920 x 1080 | Amazon 가이드라인 준수 |

### 6.4 수동 테스트 체크리스트 템플릿

```
[ ] 테스트 항목: __________________________
[ ] 플랫폼: _____________ 기기: _____________
[ ] 빌드 번호: ___________
[ ] 테스터: ______________ 날짜: _____________

[ ] 테스트 단계:
    [ ] 1. _____________________________________
    [ ] 2. _____________________________________
    [ ] 3. _____________________________________

[ ] 결과:  [ ] PASS  [ ] FAIL  [ ] BLOCKED
[ ] 비고: _____________________________________
[ ] 스크린샷/녹화 첨부: [ ] 예  [ ] 아니오
```

---

## 7. 성능 목표

### 7.1 성능 지표 및 측정 방법

| 지표 | 목표 | 측정 방법 | 비고 |
|------|------|-----------|------|
| **격자 생성 시간** | < 100ms (10x10) | `Time.get_ticks_msec()` 전후 차이 | 최악의 경우도 200ms 미만 |
| **FPS** | 60fps 안정 유지 | `Performance.get_monitor(Performance.TIME_FPS)` | 30fps 이하 프레임 0 |
| **메모리 사용량** | < 200MB | `OS.get_static_memory_usage()` | 메모리 Leak 없음 |
| **APK 크기** | < 30MB | 빌드 후 파일 크기 확인 | AAB 기준 |
| **시작 시간** | < 3초 | 스플래시 화면 → 메인 메뉴 노출 | Cold Start 기준 |
| **세이브/로드** | < 50ms | `Time.get_ticks_msec()` 전후 차이 | 파일 I/O 포함 |
| **씬 전환** | < 500ms | 전환 시작 → 완료 | 페이드 애니메이션 제외 |
| **입력 지연** | < 16ms (1프레임) | 터치/키 입력 → 시각적 반응 | 체감 즉응성 |

### 7.2 성능 벤치마크 테스트 코드

```gdscript
# res://test/unit/test_performance.gd
extends GutTest

var _generator: GridGenerator


func before_each() -> void:
    _generator = GridGenerator.new()


func after_each() -> void:
    if is_instance_valid(_generator):
        _generator.free()


func test_grid_generation_speed_10x10() -> void:
    """10x10 격자 생성이 100ms 이내에 완료되어야 한다."""
    var words: Array[String] = [
        "사과", "바나나", "포도", "딸기", "수박", "참외"
    ]

    var start_ms: int = Time.get_ticks_msec()
    _generator.generate(10, 10, words)
    var elapsed_ms: int = Time.get_ticks_msec() - start_ms

    assert_lt(
        elapsed_ms, 100,
        "10x10 격자 생성 시간: %dms (목표: < 100ms)" % elapsed_ms
    )


func test_grid_generation_speed_12x12() -> void:
    """12x12 격자 생성이 200ms 이내에 완료되어야 한다."""
    var words: Array[String] = [
        "사과", "바나나", "포도", "딸기", "수박", "참외", "복숭아", "오렌지"
    ]

    var start_ms: int = Time.get_ticks_msec()
    _generator.generate(12, 12, words)
    var elapsed_ms: int = Time.get_ticks_msec() - start_ms

    assert_lt(
        elapsed_ms, 200,
        "12x12 격자 생성 시간: %dms (목표: < 200ms)" % elapsed_ms
    )


func test_grid_generation_average() -> void:
    """격자 생성 100회 평균이 50ms 이내여야 한다."""
    var words: Array[String] = ["호랑이", "사자", "독수리", "고래", "토끼"]
    var total_ms: int = 0

    for i in range(100):
        var start_ms: int = Time.get_ticks_msec()
        _generator.generate(10, 10, words)
        total_ms += Time.get_ticks_msec() - start_ms

    var avg_ms: float = total_ms / 100.0
    assert_lt(
        avg_ms, 50.0,
        "100회 평균 생성 시간: %.1fms (목표: < 50ms)" % avg_ms
    )
```

### 7.3 메모리 Leak 검출

```gdscript
# res://test/unit/test_memory.gd
extends GutTest


func test_no_memory_leak_on_stage_cycle() -> void:
    """스테이지 반복 생성/해제 시 메모리 누수가 없어야 한다."""
    # 초기 메모리 기록 (GC 실행 후)
    # 참고: Godot 4.x에서는 OS.get_static_memory_usage() 활용
    var initial_memory: int = OS.get_static_memory_usage()

    # 50회 스테이지 생성/해제 반복
    for i in range(50):
        var generator := GridGenerator.new()
        var grid: Array = generator.generate(10, 10, ["테스트", "단어"])
        generator.free()

    # 최종 메모리 기록
    var final_memory: int = OS.get_static_memory_usage()
    var diff_kb: float = (final_memory - initial_memory) / 1024.0

    # 허용 범위: 1MB 미만의 증가
    assert_lt(
        diff_kb, 1024.0,
        "메모리 증가량: %.1fKB (허용: < 1024KB)" % diff_kb
    )
```

---

## 8. 버그 추적

### 8.1 도구

**GitHub Issues** 사용. 별도 버그 트래킹 도구를 도입하지 않고 GitHub 내장 기능을 최대한 활용한다.

### 8.2 라벨 체계

| 라벨 | 색상 | 용도 |
|------|------|------|
| `bug` | 빨강 (#d73a4a) | 버그 리포트 |
| `enhancement` | 파랑 (#a2eeef) | 기능 개선 요청 |
| `platform:android` | 초록 (#0e8a16) | Android 관련 |
| `platform:ios` | 회색 (#bfd4f2) | iOS 관련 |
| `platform:tv` | 보라 (#d4c5f9) | TV 플랫폼 관련 |
| `priority:blocker` | 빨강 (#b60205) | 릴리스 차단 |
| `priority:major` | 주황 (#ff9f1c) | 주요 문제 |
| `priority:minor` | 노랑 (#fbca04) | 경미한 문제 |
| `test` | 파랑 (#1d76db) | 테스트 관련 |
| `wontfix` | 흰색 (#ffffff) | 수정 안 함 |

### 8.3 버그 리포트 템플릿

```markdown
---
name: Bug Report
about: 버그 신고를 위한 템플릿
labels: bug
---

## 요약
[버그에 대한 간단한 설명]

## 재현 단계
1. '...'으로 이동
2. '...'를 클릭
3. '...'까지 스크롤
4. 오류 확인

## 예상 동작
[정상적으로 어떻게 동작해야 하는지 설명]

## 실제 동작
[실제로 어떻게 동작했는지 설명]

## 플랫폼 정보
- **기기:** [예: Samsung Galaxy S24]
- **OS:** [예: Android 15]
- **앱 버전:** [예: 1.0.3]
- **빌드 번호:** [예: 2026031101]

## 스크린샷/영상
[가능하면 첨부]

## 추가 정보
[재현율, 발생 조건 등]
- 재현율: [ ] 항상 / [ ] 간헐적 (약 __%)
- 네트워크: [ ] 온라인 / [ ] 오프라인
```

### 8.4 버그 심각도 분류

| 심각도 | 설명 | 예시 | 대응 기한 |
|--------|------|------|-----------|
| **Blocker** | 게임 불가 / 데이터 손실 | 세이브 파일 손상, 크래시 | 즉시 (24시간 이내) |
| **Major** | 핵심 기능 오작동 | 점수 계산 오류, 단어 미인식 | 3일 이내 |
| **Minor** | 비핵심 기능 문제 | UI 겹침, 애니메이션 깨짐 | 다음 릴리스 |
| **Trivial** | 외관/문구 | 오타, 미세 정렬 | 백로그 |

---

## 9. 테스트 자동화 (CI/CD)

### 9.1 아키텍처 개요

```
[개발자 Push/PR]
       │
       ▼
[GitHub Actions 트리거]
       │
       ▼
[godot-ci Docker 컨테이너]
       │
       ├─ GUT 단위 테스트 실행
       ├─ GUT 통합 테스트 실행
       └─ 결과 리포트 생성
              │
              ▼
       [테스트 결과]
       ├─ 전체 통과 → PR 머지 허용
       └─ 실패 있음 → PR 머지 차단
```

### 9.2 GitHub Actions 워크플로우

```yaml
# .github/workflows/test.yml
name: GUT Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

env:
  GODOT_VERSION: "4.6"

jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: barichello/godot-ci:4.6

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Import 프로젝트 (리소스 캐시 생성)
        run: |
          mkdir -p ~/.local/share/godot/
          godot --headless --import 2>&1 || true
        timeout-minutes: 5

      - name: GUT 단위 테스트 실행
        run: |
          godot --headless -s addons/gut/gut_cmdln.gd \
            -gdir=res://test/unit/ \
            -glog=2 \
            -gexit
        timeout-minutes: 5

      - name: GUT 통합 테스트 실행
        run: |
          godot --headless -s addons/gut/gut_cmdln.gd \
            -gdir=res://test/integration/ \
            -glog=2 \
            -gexit
        timeout-minutes: 10

      - name: 테스트 결과 확인
        if: failure()
        run: |
          echo "::error::테스트 실패! PR 머지가 차단됩니다."
          exit 1
```

### 9.3 Branch Protection 설정

GitHub 저장소의 Branch Protection Rules에서 다음을 설정한다.

| 설정 항목 | 값 |
|-----------|---|
| Require status checks to pass | **활성화** |
| Required checks | `test` (위 워크플로우의 job 이름) |
| Require branches to be up to date | **활성화** |
| Require pull request reviews | 1명 이상 |

**효과:** GUT 테스트가 실패하면 PR을 `main`/`develop` 브랜치에 머지할 수 없다.

### 9.4 로컬 Pre-commit Hook (선택)

개발자가 커밋 전에 빠른 단위 테스트를 실행하도록 Git Hook을 설정할 수 있다.

```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "=== GUT 단위 테스트 실행 중... ==="

godot --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://test/unit/ \
  -glog=1 \
  -gexit 2>/dev/null

if [ $? -ne 0 ]; then
    echo "❌ 단위 테스트 실패! 커밋이 중단됩니다."
    echo "   'godot --headless -s addons/gut/gut_cmdln.gd' 로 상세 로그를 확인하세요."
    exit 1
fi

echo "✅ 모든 단위 테스트 통과!"
```

---

## 10. 테스트 실행 계획 (릴리스 주기별)

### 10.1 일상 개발 (매일)

| 활동 | 자동화 | 담당 |
|------|--------|------|
| 변경 코드 관련 단위 테스트 작성/수정 | - | 개발자 |
| Push 시 CI 자동 테스트 | 자동 | GitHub Actions |
| 실패 테스트 즉시 수정 | - | 개발자 |

### 10.2 기능 완성 시 (PR 단위)

| 활동 | 자동화 | 담당 |
|------|--------|------|
| 전체 단위 테스트 실행 | 자동 | GitHub Actions |
| 통합 테스트 실행 | 자동 | GitHub Actions |
| 코드 리뷰 | - | 팀원 |
| 테스트 커버리지 확인 | 수동 | 개발자 |

### 10.3 릴리스 전 (QA 주기)

| 활동 | 자동화 | 담당 |
|------|--------|------|
| 전체 자동화 테스트 스위트 | 자동 | CI |
| 수동 테스트 매트릭스 (6.1) 전체 수행 | 수동 | QA/개발자 |
| 성능 벤치마크 (7.1) 측정 | 수동 | 개발자 |
| 실기기 테스트 (Android/iOS/TV) | 수동 | QA |
| Blocker/Major 버그 0건 확인 | - | 전체 |
| 회귀 테스트 전체 통과 확인 | 자동+수동 | 전체 |

---

## 11. 테스트 커버리지 추적

### 11.1 모듈별 커버리지 목표

| 모듈 | 대상 클래스 | 테스트 파일 | 목표 커버리지 |
|------|------------|------------|--------------|
| 격자 시스템 | `GridGenerator` | `test_grid_generator.gd` | 90% |
| 점수 시스템 | `ScoreManager` | `test_score_manager.gd` | 95% |
| DDA | `DDAManager` | `test_dda_manager.gd` | 85% |
| 한글 유틸 | `HangulUtils` | `test_hangul_utils.gd` | 90% |
| 코인 시스템 | `CoinManager` | `test_coin_manager.gd` | 95% |
| 세이브 시스템 | `SaveManager` | `test_save_manager.gd` | 85% |
| 난수 | `SeededRandom` | `test_seeded_random.gd` | 90% |
| 거짓 단서 | `FalseLeadGenerator` | `test_false_lead.gd` | 85% |
| **전체 평균** | | | **80% 이상** |

### 11.2 커버리지 미달 시 대응

1. PR 리뷰 시 신규 로직에 대한 테스트 존재 여부 확인
2. 커버리지가 목표치 이하로 떨어지면 해당 모듈의 테스트 보강을 기술 부채로 등록
3. 스프린트마다 기술 부채 항목 중 테스트 보강을 1건 이상 해소

---

## 12. 알려진 테스트 한계 및 대안

| 한계 | 설명 | 대안 |
|------|------|------|
| **UI 자동화 테스트 부재** | GUT은 로직 테스트에 특화, UI 상호작용 자동 테스트는 미지원 | 수동 테스트 매트릭스(6장)로 보완 |
| **실기기 자동화 미지원** | CI에서 실기기 테스트 불가 | 릴리스 전 수동 QA로 보완 |
| **광고/IAP 테스트** | 실제 결제/광고는 자동화 불가 | Sandbox/Test 모드 활용 + 수동 검증 |
| **네트워크 의존 테스트** | Daily Challenge 서버 없이 동작 (시드 기반) | Mock 불필요, 시드 결정론성만 검증 |
| **코드 커버리지 수치 측정** | GUT에 내장 커버리지 측정 도구 없음 | 수동으로 테스트 대상 함수 목록 관리 |

---

## 부록 A. GUT Assert 함수 레퍼런스 (자주 사용)

| 함수 | 설명 | 예시 |
|------|------|------|
| `assert_eq(a, b, msg)` | a == b | `assert_eq(score, 100)` |
| `assert_ne(a, b, msg)` | a != b | `assert_ne(grid, null)` |
| `assert_true(val, msg)` | val == true | `assert_true(is_valid)` |
| `assert_false(val, msg)` | val == false | `assert_false(is_empty)` |
| `assert_gt(a, b, msg)` | a > b | `assert_gt(coins, 0)` |
| `assert_lt(a, b, msg)` | a < b | `assert_lt(time_ms, 100)` |
| `assert_gte(a, b, msg)` | a >= b | `assert_gte(balance, 0)` |
| `assert_has(arr, val, msg)` | val in arr | `assert_has(words, "사과")` |
| `assert_does_not_have(arr, val, msg)` | val not in arr | `assert_does_not_have(leads, "정답")` |
| `assert_between(val, lo, hi, msg)` | lo <= val <= hi | `assert_between(offset, -2, 2)` |
| `assert_null(val, msg)` | val == null | `assert_null(error)` |
| `assert_not_null(val, msg)` | val != null | `assert_not_null(result)` |

---

## 부록 B. 테스트 데이터 팩토리

```gdscript
# res://test/helpers/test_data_factory.gd
class_name TestDataFactory
extends RefCounted

## 테스트용 WordPack 생성
static func create_word_pack(count: int = 5) -> Array[String]:
    var all_words: Array[String] = [
        "사과", "바나나", "포도", "딸기", "수박",
        "참외", "복숭아", "오렌지", "키위", "망고",
        "호랑이", "사자", "독수리", "고래", "토끼",
        "학교", "병원", "도서관", "공원", "시장",
    ]
    var result: Array[String] = []
    for i in range(mini(count, all_words.size())):
        result.append(all_words[i])
    return result


## 테스트용 스테이지 결과 생성
static func create_stage_result(
    grade: String = "A",
    hints: int = 0,
    time: float = 60.0
) -> Dictionary:
    return {
        "grade": grade,
        "hints_used": hints,
        "clear_time": time,
        "score": 500,
        "words_found": 5,
    }


## 테스트용 세이브 데이터 생성
static func create_save_data(overrides: Dictionary = {}) -> Dictionary:
    var base := {
        "save_version": 2,
        "coins": 300,
        "current_stage": 1,
        "daily_streak": 0,
        "hints_remaining": 3,
        "settings": {
            "sfx_volume": 1.0,
            "bgm_volume": 1.0,
            "language": "ko",
            "theme": "default",
        },
        "unlocked_themes": ["default"],
        "stage_history": [],
    }
    base.merge(overrides, true)
    return base


## 테스트용 DDA 히스토리 생성
static func create_dda_history(
    grades: Array[String] = ["A", "B", "A"]
) -> Array[Dictionary]:
    var history: Array[Dictionary] = []
    for grade in grades:
        var hints := 0
        var time_ratio := 0.5
        match grade:
            "S": hints = 0; time_ratio = 0.4
            "A": hints = 0; time_ratio = 0.6
            "B": hints = 1; time_ratio = 0.7
            "C": hints = 3; time_ratio = 0.9
        history.append({
            "grade": grade,
            "hints_used": hints,
            "time_ratio": time_ratio,
        })
    return history
```

---

## 부록 C. 테스트 실행 결과 예시

GUT 실행 시 콘솔에 출력되는 결과 형식은 다음과 같다.

```
* test_grid_generator.gd
    [PASS] test_grid_size_correct
    [PASS] test_all_words_placed
    [PASS] test_word_overlap_valid
    [PASS] test_no_out_of_bounds
    [PASS] test_empty_cells_filled
    [PASS] test_direction_snapper

* test_score_manager.gd
    [PASS] test_basic_word_score
    [PASS] test_combo_multiplier
    [PASS] test_time_bonus
    [PASS] test_grade_s
    [PASS] test_grade_a
    [PASS] test_grade_b
    [PASS] test_grade_c

...

-----------------------------
Totals
-----------------------------
Tests:     47
Passing:   47
Failing:    0
Pending:    0
Time:    1.234s
-----------------------------
All tests passed!
```
