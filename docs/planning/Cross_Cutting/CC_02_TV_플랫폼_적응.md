# CC_02: TV 플랫폼 적응 (TV Platform Adaptation)

| 항목 | 내용 |
|------|------|
| **문서 ID** | CC_02 |
| **버전** | v1.0 |
| **작성일** | 2026-03-11 |
| **엔진** | Godot 4.6 Stable (GDScript) |
| **프로젝트** | 낱말 찾기(Word Search) 퍼즐 게임 |
| **분류** | Cross-Cutting |
| **출처** | Godot Guide §5.2-5.4, §9, §10.2, §15 |

---

## 관련 문서

| 문서 ID | 제목 | 관계 |
|---------|------|------|
| P01_03 | 입력 시스템 기술명세 | D-pad 입력 처리 원본 정의 |
| P08_01 | UI 디자인 시스템 | 모바일 기준 UI 시스템, TV 스케일링 기준 |
| P06_01 | 수익화 및 경제 시스템 | TV 광고 제한 및 IAP 연동 |
| P10_01 | 빌드 및 출시 | Android TV / Fire TV 빌드 설정 |
| CC_01 | 다국어 지원 | TV 폰트 크기 오버라이드 |

---

## 목차

1. [TV 플랫폼 개요](#1-tv-플랫폼-개요)
2. [플랫폼 감지 시스템](#2-플랫폼-감지-시스템)
3. [크기 스케일링 체계](#3-크기-스케일링-체계)
4. [D-pad 입력 시스템](#4-d-pad-입력-시스템)
5. [TV UI 디자인 원칙](#5-tv-ui-디자인-원칙)
6. [TV 전용 화면 레이아웃](#6-tv-전용-화면-레이아웃)
7. [TV 테마 (dark_tv_theme.tres)](#7-tv-테마-dark_tv_themetres)
8. [TV 광고 제한](#8-tv-광고-제한)
9. [TV IAP 고려사항](#9-tv-iap-고려사항)
10. [성능 최적화](#10-성능-최적화)
11. [Android TV vs Fire TV 차이표](#11-android-tv-vs-fire-tv-차이표)
12. [AndroidManifest TV 설정](#12-androidmanifest-tv-설정)
13. [테스트 체크리스트](#13-테스트-체크리스트)
14. [참조 문서](#14-참조-문서)
15. [변경 이력](#15-변경-이력)

---

## 1. TV 플랫폼 개요

### 1.1 대상 플랫폼

| 플랫폼 | OS | 비고 |
|--------|-----|------|
| **Android TV** | Android TV OS | Google Play 배포, Leanback 필수 |
| **Amazon Fire TV** | Fire OS (Android Fork) | Amazon Appstore 배포 |

### 1.2 TV 환경의 핵심 차이

TV 환경은 모바일과 근본적으로 다른 사용 맥락을 가진다. 이 문서에 정의된 모든 TV 적응 사항은 아래 차이에서 비롯된다.

| 항목 | 모바일 | TV |
|------|--------|-----|
| **입력 장치** | 터치스크린 | D-pad 리모컨 전용 |
| **화면 크기** | 5~7인치 | 43~65인치 이상 |
| **시청 거리** | 30cm | 3m 이상 (Lean-back) |
| **마우스/호버** | 없음 (터치) | 없음 (D-pad) |
| **화면 비율** | 다양 (16:9, 20:9 등) | 16:9 고정 |
| **해상도** | 다양 | 1920x1080 (FHD) 기본 |
| **테마 기본값** | 밝은/어두운 선택 | 어두운 톤 권장 |
| **포커스 표시** | 터치 피드백 | 포커스 링 필수 |

### 1.3 설계 원칙

1. **D-pad First**: 모든 UI 요소는 D-pad만으로 접근 가능해야 한다.
2. **Lean-back Readability**: 3m 거리에서 모든 텍스트가 판독 가능해야 한다.
3. **Dark Theme Default**: TV 환경에서는 어두운 배경이 눈의 피로를 줄인다.
4. **Focus Visibility**: 현재 포커스 위치가 항상 명확히 보여야 한다.
5. **Safe Area Compliance**: 모든 콘텐츠는 TV Safe Area 내에 배치한다.

---

## 2. 플랫폼 감지 시스템

### 2.1 LayoutManager 플랫폼 감지

`LayoutManager`는 Autoload(싱글톤)로 등록하며, 앱 시작 시 현재 플랫폼을 감지한다. P01_03에서 정의한 `layout_manager.gd`를 기반으로 TV 감지 로직을 통합한다.

```gdscript
## layout_manager.gd (Autoload)
## 플랫폼 감지 및 TV/모바일 레이아웃 분기 관리
extends Node

enum Platform { MOBILE, TV }

var current_platform: Platform = Platform.MOBILE

## TV 감지 완료 시 발생
signal platform_detected(platform: Platform)


func _ready() -> void:
	detect_platform()
	platform_detected.emit(current_platform)


func detect_platform() -> void:
	if OS.has_feature("android"):
		# 1차 판별: 터치스크린 유무
		if not DisplayServer.is_touchscreen_available():
			current_platform = Platform.TV
		else:
			# 2차 판별: 대형 화면 + Android TV 특성
			var screen_size := DisplayServer.screen_get_size()
			if screen_size.x >= 1920:
				current_platform = Platform.TV
			else:
				current_platform = Platform.MOBILE
	else:
		# PC 테스트 시: 커맨드 라인 인자로 TV 모드 강제 가능
		if OS.has_feature("tv_debug") or "--tv-mode" in OS.get_cmdline_args():
			current_platform = Platform.TV
		else:
			current_platform = Platform.MOBILE

	print("[LayoutManager] Platform detected: ", Platform.keys()[current_platform])


func is_tv() -> bool:
	return current_platform == Platform.TV


func is_mobile() -> bool:
	return current_platform == Platform.MOBILE
```

### 2.2 TV 모드 디버그

PC에서 TV 레이아웃을 테스트하려면 다음 방법을 사용한다.

- **방법 1**: Godot Editor > Project > Export > Feature Tags에 `tv_debug` 추가
- **방법 2**: 커맨드 라인에서 `--tv-mode` 인자 전달
- **방법 3**: Project Settings > Display > Window에서 해상도를 1920x1080으로 설정

---

## 3. 크기 스케일링 체계

### 3.1 스케일링 테이블

TV 환경에서는 시청 거리(3m+)를 감안하여 모든 UI 요소를 확대한다. 아래 테이블은 모바일 기준 대비 TV 적용 크기를 정의한다.

| UI 요소 | 모바일 | TV | 배율 | 비고 |
|---------|--------|-----|------|------|
| 본문 텍스트 | 14sp | 24sp | 1.7x | 설명, 안내 텍스트 |
| 버튼 텍스트 | 16sp | 28sp | 1.75x | 버튼 내부 레이블 |
| 제목 텍스트 | 22sp | 38sp | 1.73x | 화면 제목, 헤더 |
| 격자 셀 글자 | 20sp | 36sp | 1.8x | 퍼즐 격자 내 글자 |
| 포커스 타겟 최소 크기 | 48dp | 56dp | 1.17x | 최소 터치/포커스 영역 |
| 격자 셀 크기 | 40dp | 64dp | 1.6x | 개별 셀 너비/높이 |
| 격자 최대 크기 | 15x15 | 12x12 | 축소 | TV 렌더링 부하 감소 |
| 버튼 Padding | 12dp | 20dp | 1.67x | 버튼 내부 여백 |
| 화면 Margin | 16dp | 26dp | 1.63x | 화면 가장자리 여백 |

### 3.2 tv_scale_factor.gd (Resource)

스케일링 값을 Resource로 관리하여, 에디터에서 직접 수정 가능하게 한다.

```gdscript
## tv_scale_factor.gd
## TV 환경 UI 스케일링 팩터 정의 Resource
class_name TvScaleFactor
extends Resource

## --- 텍스트 크기 (px) ---
@export_group("Text Sizes")
@export var body_text_mobile: int = 14
@export var body_text_tv: int = 24
@export var button_text_mobile: int = 16
@export var button_text_tv: int = 28
@export var title_text_mobile: int = 22
@export var title_text_tv: int = 38
@export var grid_cell_text_mobile: int = 20
@export var grid_cell_text_tv: int = 36

## --- 크기 (px) ---
@export_group("Element Sizes")
@export var focus_target_min_mobile: int = 48
@export var focus_target_min_tv: int = 56
@export var grid_cell_size_mobile: int = 40
@export var grid_cell_size_tv: int = 64
@export var grid_max_mobile: int = 15
@export var grid_max_tv: int = 12

## --- 여백 (px) ---
@export_group("Spacing")
@export var button_padding_mobile: int = 12
@export var button_padding_tv: int = 20
@export var screen_margin_mobile: int = 16
@export var screen_margin_tv: int = 26

## --- Safe Area ---
@export_group("Safe Area")
@export var safe_area_percent: float = 0.05  ## 화면 가장자리 5%


## 현재 플랫폼에 맞는 텍스트 크기 반환
func get_body_text_size() -> int:
	return body_text_tv if LayoutManager.is_tv() else body_text_mobile

func get_button_text_size() -> int:
	return button_text_tv if LayoutManager.is_tv() else button_text_mobile

func get_title_text_size() -> int:
	return title_text_tv if LayoutManager.is_tv() else title_text_mobile

func get_grid_cell_text_size() -> int:
	return grid_cell_text_tv if LayoutManager.is_tv() else grid_cell_text_mobile

func get_grid_cell_size() -> int:
	return grid_cell_size_tv if LayoutManager.is_tv() else grid_cell_size_mobile

func get_grid_max_dimension() -> int:
	return grid_max_tv if LayoutManager.is_tv() else grid_max_mobile

func get_focus_target_min() -> int:
	return focus_target_min_tv if LayoutManager.is_tv() else focus_target_min_mobile

func get_button_padding() -> int:
	return button_padding_tv if LayoutManager.is_tv() else button_padding_mobile

func get_screen_margin() -> int:
	return screen_margin_tv if LayoutManager.is_tv() else screen_margin_mobile

func get_safe_area_pixels() -> int:
	## @1920 해상도에서 5% = 96px
	var viewport_width := DisplayServer.window_get_size().x
	return int(viewport_width * safe_area_percent)
```

### 3.3 Resource 인스턴스 생성

`res://resources/tv_scale_factor.tres` 파일을 생성하여 기본값을 저장한다. `LayoutManager`에서 로드하여 전역 접근 가능하게 한다.

```gdscript
## layout_manager.gd에 추가
var scale_factor: TvScaleFactor

func _ready() -> void:
	scale_factor = load("res://resources/tv_scale_factor.tres") as TvScaleFactor
	if scale_factor == null:
		scale_factor = TvScaleFactor.new()
		push_warning("[LayoutManager] tv_scale_factor.tres not found, using defaults.")
	detect_platform()
	platform_detected.emit(current_platform)
```

---

## 4. D-pad 입력 시스템

### 4.1 포커스 네비게이션 기본 원칙

Godot의 `Control` 노드는 기본적으로 포커스 시스템을 지원한다. TV 모드에서는 다음 속성을 활용한다.

| Control 속성 | 설명 | TV 설정 |
|-------------|------|---------|
| `focus_mode` | 포커스 수신 가능 여부 | `FOCUS_ALL` (모든 상호작용 요소) |
| `focus_neighbor_top` | 위쪽 D-pad 시 이동 대상 | 인접 셀/버튼 NodePath |
| `focus_neighbor_bottom` | 아래쪽 D-pad 시 이동 대상 | 인접 셀/버튼 NodePath |
| `focus_neighbor_left` | 왼쪽 D-pad 시 이동 대상 | 인접 셀/버튼 NodePath |
| `focus_neighbor_right` | 오른쪽 D-pad 시 이동 대상 | 인접 셀/버튼 NodePath |
| `focus_next` | Tab 키 이동 대상 | 다음 논리적 요소 |
| `focus_previous` | Shift+Tab 이동 대상 | 이전 논리적 요소 |

### 4.2 격자 내 D-pad 이동

격자 셀(LetterCell)은 `Button`을 상속하므로 기본 포커스를 지원한다. 격자 생성 시 인접 셀 간 `focus_neighbor`를 자동으로 설정한다.

```gdscript
## grid_manager.gd (격자 생성 시 포커스 이웃 설정)
## TV 모드에서 격자 셀 간 D-pad 네비게이션을 자동 구성한다.

func setup_grid_focus_neighbors(grid: Array[Array]) -> void:
	## grid: 2D Array of LetterCell (Button 상속)
	if not LayoutManager.is_tv():
		return

	var rows: int = grid.size()
	var cols: int = grid[0].size()

	for row in range(rows):
		for col in range(cols):
			var cell: Button = grid[row][col]
			cell.focus_mode = Control.FOCUS_ALL

			# 상(Top)
			if row > 0:
				cell.focus_neighbor_top = cell.get_path_to(grid[row - 1][col])

			# 하(Bottom)
			if row < rows - 1:
				cell.focus_neighbor_bottom = cell.get_path_to(grid[row + 1][col])

			# 좌(Left)
			if col > 0:
				cell.focus_neighbor_left = cell.get_path_to(grid[row][col - 1])

			# 우(Right)
			if col < cols - 1:
				cell.focus_neighbor_right = cell.get_path_to(grid[row][col + 1])

	## 초기 포커스: 격자 중앙 셀
	var center_row: int = rows / 2
	var center_col: int = cols / 2
	grid[center_row][center_col].grab_focus()
```

### 4.3 TV 단어 선택 모드 (tv_input_handler.gd)

TV에서는 터치 드래그가 불가능하므로, D-pad를 이용한 2단계 선택 방식을 사용한다.

**선택 플로우:**

```
[격자 탐색] ──D-pad Center(OK)──> [시작 셀 선택됨]
                                       │
                              D-pad 방향 입력
                                       │
                                       v
                              [방향 결정 + 끝 셀 이동]
                                       │
                              D-pad Center(OK)
                                       │
                                       v
                              [끝 셀 확정 → 단어 검증]
```

**상세 단계:**

1. **격자 탐색 모드**: D-pad 상/하/좌/우로 셀 간 이동. 포커스 링 표시.
2. **시작 셀 선택**: D-pad Center(OK) 버튼을 눌러 시작 셀을 선택한다. 시작 셀에 시각적 마커 표시.
3. **방향 선택 및 끝 셀 이동**: D-pad 방향 입력으로 선택 방향을 결정한다. 8방향 중 가장 가까운 유효 방향으로 스냅(snap)된다. D-pad를 반복 입력하면 해당 방향으로 끝 셀이 한 칸씩 확장된다.
4. **끝 셀 확정**: D-pad Center(OK)를 다시 눌러 끝 셀을 확정한다. 시작 셀~끝 셀 사이의 글자 조합으로 단어를 자동 검증한다.
5. **취소**: Back 버튼을 누르면 현재 선택을 취소하고 격자 탐색 모드로 복귀한다.

```gdscript
## tv_input_handler.gd
## TV 환경 전용 D-pad 기반 단어 선택 처리
extends Node

enum SelectionState {
	BROWSING,       ## 격자 셀 탐색 중
	START_SELECTED, ## 시작 셀 선택됨, 방향 대기
	EXTENDING,      ## 끝 셀 방향 확장 중
}

var state: SelectionState = SelectionState.BROWSING
var start_cell: Vector2i = Vector2i(-1, -1)
var end_cell: Vector2i = Vector2i(-1, -1)
var selection_direction: Vector2i = Vector2i.ZERO

## 외부 연결용 Signal
signal word_submitted(start: Vector2i, end_pos: Vector2i)
signal selection_cancelled()
signal cell_highlight_requested(cells: Array[Vector2i])

## 8방향 벡터 (정방향 + 대각선)
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(0, -1),   # 상
	Vector2i(0, 1),    # 하
	Vector2i(-1, 0),   # 좌
	Vector2i(1, 0),    # 우
	Vector2i(-1, -1),  # 좌상
	Vector2i(1, -1),   # 우상
	Vector2i(-1, 1),   # 좌하
	Vector2i(1, 1),    # 우하
]

## 격자 크기 (외부에서 설정)
var grid_rows: int = 0
var grid_cols: int = 0


func _input(event: InputEvent) -> void:
	if not LayoutManager.is_tv():
		return

	match state:
		SelectionState.BROWSING:
			_handle_browsing(event)
		SelectionState.START_SELECTED:
			_handle_start_selected(event)
		SelectionState.EXTENDING:
			_handle_extending(event)


func _handle_browsing(event: InputEvent) -> void:
	## 격자 탐색 모드: D-pad Center(OK)로 시작 셀 선택
	if event.is_action_pressed("ui_accept"):
		var focused := get_viewport().gui_get_focus_owner()
		if focused and focused.has_method("get_grid_position"):
			start_cell = focused.get_grid_position()
			end_cell = start_cell
			selection_direction = Vector2i.ZERO
			state = SelectionState.START_SELECTED
			_highlight_cells([start_cell])
			get_viewport().set_input_as_handled()


func _handle_start_selected(event: InputEvent) -> void:
	## 시작 셀 선택됨: 방향 입력 대기
	var dir := _get_dpad_direction(event)
	if dir != Vector2i.ZERO:
		## D-pad 입력을 8방향 중 가장 가까운 유효 방향으로 스냅
		selection_direction = _snap_to_nearest_direction(dir)
		end_cell = start_cell + selection_direction
		if _is_valid_cell(end_cell):
			state = SelectionState.EXTENDING
			_highlight_cells(_get_cells_between(start_cell, end_cell))
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_cancel"):
		## Back: 선택 취소
		_cancel_selection()
		get_viewport().set_input_as_handled()


func _handle_extending(event: InputEvent) -> void:
	## 끝 셀 확장 중
	var dir := _get_dpad_direction(event)
	if dir != Vector2i.ZERO:
		## 같은 방향으로 한 칸 확장
		var next_end := end_cell + selection_direction
		if _is_valid_cell(next_end):
			end_cell = next_end
			_highlight_cells(_get_cells_between(start_cell, end_cell))
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_accept"):
		## D-pad Center(OK): 끝 셀 확정 -> 단어 제출
		word_submitted.emit(start_cell, end_cell)
		_reset_selection()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("ui_cancel"):
		## Back: 선택 취소
		_cancel_selection()
		get_viewport().set_input_as_handled()


func _get_dpad_direction(event: InputEvent) -> Vector2i:
	if event.is_action_pressed("ui_up"):
		return Vector2i(0, -1)
	elif event.is_action_pressed("ui_down"):
		return Vector2i(0, 1)
	elif event.is_action_pressed("ui_left"):
		return Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right"):
		return Vector2i(1, 0)
	return Vector2i.ZERO


func _snap_to_nearest_direction(input_dir: Vector2i) -> Vector2i:
	## D-pad 입력(4방향)을 가장 가까운 8방향으로 변환
	## 기본적으로 D-pad 입력 그대로 사용 (4방향)
	## 대각선은 연속 입력 조합으로 처리 가능
	var best_dir := DIRECTIONS[0]
	var best_dot := -2.0
	var input_f := Vector2(input_dir)
	for dir in DIRECTIONS:
		var dot := input_f.dot(Vector2(dir))
		if dot > best_dot:
			best_dot = dot
			best_dir = dir
	return best_dir


func _is_valid_cell(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_cols and pos.y >= 0 and pos.y < grid_rows


func _get_cells_between(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	## 시작과 끝 사이의 모든 셀 좌표 반환 (직선/대각선)
	var cells: Array[Vector2i] = []
	var diff := to - from
	var steps := maxi(absi(diff.x), absi(diff.y))
	if steps == 0:
		cells.append(from)
		return cells

	var step_dir := Vector2i(signi(diff.x), signi(diff.y))
	for i in range(steps + 1):
		cells.append(from + step_dir * i)
	return cells


func _highlight_cells(cells: Array[Vector2i]) -> void:
	cell_highlight_requested.emit(cells)


func _cancel_selection() -> void:
	selection_cancelled.emit()
	_reset_selection()


func _reset_selection() -> void:
	state = SelectionState.BROWSING
	start_cell = Vector2i(-1, -1)
	end_cell = Vector2i(-1, -1)
	selection_direction = Vector2i.ZERO
```

### 4.4 Back 버튼 처리

TV 리모컨의 Back 버튼은 Godot에서 `ui_cancel` 액션에 매핑된다. 모든 화면에서 Back 버튼이 일관되게 동작해야 한다.

| 현재 화면 | Back 버튼 동작 |
|-----------|---------------|
| HomeScreen | 앱 종료 확인 팝업 |
| GameScreen (탐색 중) | 일시정지 메뉴 |
| GameScreen (선택 중) | 선택 취소, 탐색 모드로 복귀 |
| ResultScreen | HomeScreen으로 이동 |
| SettingsScreen | 이전 화면으로 복귀 |
| 팝업/다이얼로그 | 팝업 닫기 |

```gdscript
## back_button_handler.gd
## 모든 화면의 Back 버튼(ui_cancel) 처리를 통합 관리한다.
## 각 화면 Scene의 루트 노드에 연결하여 사용한다.
extends Node

@export var is_root_screen: bool = false  ## HomeScreen처럼 최상위 화면인 경우


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_root_screen:
			_show_exit_confirmation()
		else:
			_navigate_back()
		get_viewport().set_input_as_handled()


func _navigate_back() -> void:
	## SceneManager 등의 화면 전환 시스템을 통해 이전 화면으로 이동
	## 구체적 구현은 P02_01 게임 상태머신 참조
	pass


func _show_exit_confirmation() -> void:
	## 종료 확인 다이얼로그 표시
	## TV에서는 포커스가 큰 버튼에 잡혀야 함
	pass
```

---

## 5. TV UI 디자인 원칙

### 5.1 색상 체계

| 역할 | 색상 코드 | 설명 |
|------|----------|------|
| 배경색 (Primary Background) | `#1A1A2E` | 어두운 남색 계열, TV 기본 배경 |
| 보조 배경색 (Secondary Background) | `#16213E` | 패널, 카드 배경 |
| 본문 텍스트 | `#EAEAEA` | 밝은 회색, 가독성 확보 |
| 제목 텍스트 | `#FFFFFF` | 순백, 제목/강조 |
| 포커스 링 색상 | `#FFD700` | 골드, 높은 시인성 |
| 포커스 Glow 색상 | `#FFD70066` | 포커스 링 외곽 Glow (40% 투명도) |
| 격자 셀 기본 | `#2A2A4A` | 어두운 보라 계열 |
| 격자 셀 포커스 | `#3D3D6B` | 포커스 시 밝아진 셀 |
| 선택된 셀 | `#4CAF50` | 녹색 하이라이트 |
| 찾은 단어 셀 | `#FF9800` | 주황색 |
| 비활성 텍스트 | `#888888` | 회색, 비활성 항목 |

### 5.2 포커스 링 애니메이션

TV에서 포커스 링은 단순 색상 변경만으로는 부족하다. 3가지 시각적 차별화를 결합한다.

1. **색상 변경**: 테두리 색상을 `#FFD700` (골드)로 변경
2. **크기 변화**: 포커스된 요소를 `scale 1.05`로 살짝 확대
3. **Glow 효과**: 외곽에 `#FFD70066` Glow 표시

```gdscript
## tv_focus_effect.gd
## TV 포커스 시각 효과를 Control 노드에 적용한다.
## 대상 노드에 이 스크립트를 Autoload 또는 Mixin으로 연결한다.
extends Node

const FOCUS_SCALE := Vector2(1.05, 1.05)
const NORMAL_SCALE := Vector2(1.0, 1.0)
const FOCUS_COLOR := Color("#FFD700")
const FOCUS_DURATION := 0.15  ## 초


## 대상 Control에 포커스 시각 효과를 연결한다.
func attach_focus_effect(control: Control) -> void:
	if not LayoutManager.is_tv():
		return
	control.focus_entered.connect(_on_focus_entered.bind(control))
	control.focus_exited.connect(_on_focus_exited.bind(control))


func _on_focus_entered(control: Control) -> void:
	var tween := control.create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "scale", FOCUS_SCALE, FOCUS_DURATION)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(control, "modulate", Color(1.2, 1.2, 1.0), FOCUS_DURATION)

	## pivot을 중앙으로 설정 (확대 시 중앙 기준)
	control.pivot_offset = control.size / 2.0


func _on_focus_exited(control: Control) -> void:
	var tween := control.create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "scale", NORMAL_SCALE, FOCUS_DURATION)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate", Color.WHITE, FOCUS_DURATION)
```

### 5.3 호버 상태 비활성화

TV에는 마우스가 없으므로 호버(hover) 상태가 존재하지 않는다. Theme에서 `hover` StyleBox를 `normal`과 동일하게 설정하여 불필요한 시각 전환을 방지한다.

### 5.4 여백 및 Safe Area

| 항목 | 모바일 | TV | 배율 |
|------|--------|-----|------|
| 화면 Margin | 16dp | 26dp | 1.63x |
| 컴포넌트 간격 | 8dp | 13dp | 1.63x |
| 섹션 간격 | 24dp | 38dp | 1.58x |
| **Safe Area** | 없음 | 가장자리 5% | - |

**Safe Area 계산:**
- 1920x1080 해상도 기준: 좌우 96px, 상하 54px
- 모든 인터랙티브 요소와 중요 텍스트는 Safe Area 안에 배치한다.
- 배경 이미지/장식 요소만 Safe Area 밖으로 확장 가능하다.

### 5.5 폰트 요구사항

| 항목 | 사양 |
|------|------|
| 폰트 굵기 | **SemiBold (600)** 이상 |
| 본문 최소 크기 | 24sp (TV) |
| 줄 간격(Line Height) | 1.4~1.6배 |
| 자간(Letter Spacing) | 기본값 또는 +0.5px |

Regular 굵기 폰트는 3m 거리에서 가늘어 보여 판독이 어렵다. TV에서는 SemiBold 이상을 기본으로 사용한다.

### 5.6 단어 목록 배치

TV 화면은 가로가 넓으므로(16:9), 단어 목록을 격자 옆 사이드바에 배치한다. 모바일에서는 격자 아래에 배치하는 것과 다른 레이아웃이다.

---

## 6. TV 전용 화면 레이아웃

### 6.1 GameScreen TV 변형

```
+------------------------------------------------------------------+
|  Safe Area (5% inset)                                            |
|  +------------------------------------------------------------+  |
|  |  [Level 16]                              [Coin: 180]       |  |
|  |                                                            |  |
|  |  +---------------------------+  +------------------------+ |  |
|  |  |                           |  |   단어 목록             | |  |
|  |  |                           |  |                        | |  |
|  |  |       격자 (12x12)        |  |   [v] T I G E R       | |  |
|  |  |       (중앙 배치)         |  |   [v] E A G L E       | |  |
|  |  |                           |  |   [ ] D O L P H I N   | |  |
|  |  |       글자 크기: 36sp     |  |   [ ] W H A L E       | |  |
|  |  |       셀 크기: 64dp       |  |   [ ] S H A R K       | |  |
|  |  |                           |  |                        | |  |
|  |  +---------------------------+  +------------------------+ |  |
|  |                                                            |  |
|  |  [Hint: 100 coins]           [Shuffle]                    |  |
|  +------------------------------------------------------------+  |
+------------------------------------------------------------------+
```

**레이아웃 구성 (Godot 노드 구조):**

```
GameScreen_TV (MarginContainer)         ## Safe Area 여백 적용
  +-- VBoxContainer
       +-- TopBar (HBoxContainer)
       |    +-- LevelLabel
       |    +-- Spacer (Control, h_size_flags=EXPAND)
       |    +-- CoinDisplay (HBoxContainer)
       +-- ContentArea (HBoxContainer)   ## 격자 + 사이드바
       |    +-- GridContainer (CenterContainer)
       |    |    +-- PuzzleGrid
       |    +-- WordListPanel (PanelContainer)
       |         +-- ScrollContainer
       |              +-- VBoxContainer (단어 항목들)
       +-- BottomBar (HBoxContainer)
            +-- HintButton
            +-- ShuffleButton
```

### 6.2 HomeScreen TV 변형

```
+------------------------------------------------------------------+
|  Safe Area                                                       |
|  +------------------------------------------------------------+  |
|  |                                                            |  |
|  |             Word Search Puzzle                             |  |
|  |             (타이틀 로고, 38sp)                             |  |
|  |                                                            |  |
|  |         +----------------------------+                     |  |
|  |         |    [>] Play                 |  <-- 포커스 링      |  |
|  |         +----------------------------+                     |  |
|  |         |    [ ] Daily Challenge      |                     |  |
|  |         +----------------------------+                     |  |
|  |         |    [ ] Settings             |                     |  |
|  |         +----------------------------+                     |  |
|  |                                                            |  |
|  |             v1.0.0                                         |  |
|  +------------------------------------------------------------+  |
+------------------------------------------------------------------+
```

**특징:**
- 메뉴 버튼을 세로 중앙에 대형으로 배치
- 첫 번째 버튼(Play)에 자동 포커스
- 버튼 높이 최소 56dp, 텍스트 28sp
- 버튼 간 간격 16dp

### 6.3 ResultScreen TV 변형

```
+------------------------------------------------------------------+
|  Safe Area                                                       |
|  +------------------------------------------------------------+  |
|  |                                                            |  |
|  |             Level Complete!  (38sp)                        |  |
|  |                                                            |  |
|  |    +---------------------------------------------------+   |  |
|  |    |  시간: 02:34     점수: 1,250     단어: 8/8        |   |  |
|  |    +---------------------------------------------------+   |  |
|  |                                                            |  |
|  |    +-----------------------+ +-----------------------+     |  |
|  |    |   [>] Next Level      | |   [ ] Home            |     |  |
|  |    +-----------------------+ +-----------------------+     |  |
|  |                                                            |  |
|  +------------------------------------------------------------+  |
+------------------------------------------------------------------+
```

**특징:**
- 결과 요약을 대형 텍스트로 표시
- Next Level 버튼에 자동 포커스
- 좌우 버튼 배치 (D-pad 좌/우로 전환)

---

## 7. TV 테마 (dark_tv_theme.tres)

### 7.1 테마 구조

TV 전용 Theme Resource를 별도 파일(`res://themes/dark_tv_theme.tres`)로 정의한다. 모바일 기본 테마를 상속하되, TV에서 필요한 값을 오버라이드한다.

### 7.2 Theme 오버라이드 항목

```
dark_tv_theme.tres
├── Default Font: NotoSansKR-SemiBold.ttf (SemiBold 이상)
├── Default Font Size: 24
├── Button/
│   ├── font_size: 28
│   ├── styles/normal: StyleBoxFlat (bg: #2A2A4A, corner_radius: 8)
│   ├── styles/hover: StyleBoxFlat (normal과 동일 -- 호버 없음)
│   ├── styles/pressed: StyleBoxFlat (bg: #4CAF50)
│   ├── styles/focus: StyleBoxFlat (border: #FFD700, width: 3, bg: #3D3D6B)
│   └── colors/font_color: #EAEAEA
├── Label/
│   ├── font_size: 24
│   └── colors/font_color: #EAEAEA
├── PanelContainer/
│   └── styles/panel: StyleBoxFlat (bg: #16213E, corner_radius: 12)
└── LineEdit/ (사용 빈도 낮음)
    └── styles/focus: StyleBoxFlat (border: #FFD700, width: 3)
```

### 7.3 테마 생성 Pseudocode

```gdscript
## tv_theme_builder.gd
## TV 전용 Theme을 GDScript로 생성하는 유틸리티.
## 에디터에서 .tres로 저장하는 것을 권장하지만,
## 런타임 생성이 필요한 경우 사용한다.
extends Node

const BG_PRIMARY := Color("#1A1A2E")
const BG_SECONDARY := Color("#16213E")
const TEXT_PRIMARY := Color("#EAEAEA")
const TEXT_TITLE := Color("#FFFFFF")
const FOCUS_COLOR := Color("#FFD700")
const CELL_DEFAULT := Color("#2A2A4A")
const CELL_FOCUS := Color("#3D3D6B")
const CELL_SELECTED := Color("#4CAF50")
const CELL_FOUND := Color("#FF9800")


func create_tv_theme() -> Theme:
	var theme := Theme.new()

	## --- 기본 폰트 ---
	var font := load("res://fonts/NotoSansKR-SemiBold.ttf") as Font
	if font:
		theme.default_font = font
	theme.default_font_size = 24

	## --- Button ---
	theme.set_font_size("font_size", "Button", 28)
	theme.set_color("font_color", "Button", TEXT_PRIMARY)
	theme.set_color("font_hover_color", "Button", TEXT_PRIMARY)
	theme.set_color("font_focus_color", "Button", TEXT_TITLE)
	theme.set_color("font_pressed_color", "Button", TEXT_TITLE)

	# Normal
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = CELL_DEFAULT
	btn_normal.corner_radius_top_left = 8
	btn_normal.corner_radius_top_right = 8
	btn_normal.corner_radius_bottom_left = 8
	btn_normal.corner_radius_bottom_right = 8
	btn_normal.content_margin_left = 20
	btn_normal.content_margin_right = 20
	btn_normal.content_margin_top = 12
	btn_normal.content_margin_bottom = 12
	theme.set_stylebox("normal", "Button", btn_normal)

	# Hover = Normal (TV에 호버 없음)
	theme.set_stylebox("hover", "Button", btn_normal)

	# Focus
	var btn_focus := btn_normal.duplicate() as StyleBoxFlat
	btn_focus.bg_color = CELL_FOCUS
	btn_focus.border_color = FOCUS_COLOR
	btn_focus.border_width_left = 3
	btn_focus.border_width_right = 3
	btn_focus.border_width_top = 3
	btn_focus.border_width_bottom = 3
	theme.set_stylebox("focus", "Button", btn_focus)

	# Pressed
	var btn_pressed := btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = CELL_SELECTED
	theme.set_stylebox("pressed", "Button", btn_pressed)

	## --- Label ---
	theme.set_font_size("font_size", "Label", 24)
	theme.set_color("font_color", "Label", TEXT_PRIMARY)

	## --- PanelContainer ---
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = BG_SECONDARY
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	theme.set_stylebox("panel", "PanelContainer", panel_style)

	return theme
```

### 7.4 런타임 테마 교체

`LayoutManager`가 TV를 감지하면 루트 UI에 TV 테마를 적용한다.

```gdscript
## layout_manager.gd에 추가
var tv_theme: Theme

func _apply_platform_theme() -> void:
	if is_tv():
		tv_theme = load("res://themes/dark_tv_theme.tres") as Theme
		if tv_theme == null:
			push_warning("[LayoutManager] dark_tv_theme.tres not found.")
			return
		## 씬 트리의 루트 Control에 테마 적용
		var root := get_tree().root
		## 첫 번째 Control 자식을 찾아서 테마 적용
		for child in root.get_children():
			if child is Control:
				child.theme = tv_theme
				break
	## 모바일은 기본 테마 유지
```

---

## 8. TV 광고 제한

### 8.1 핵심 규칙

> **AdMob은 Android TV에서 사용 금지이다.**

Google Mobile Ads SDK 팀이 공식 확인한 바에 따르면, Android TV에서 AdMob을 사용하면 **계정 정지(Account Suspension)** 위험이 있다. 이는 정책 위반으로 분류된다.

### 8.2 플랫폼별 TV 광고 전략

| 항목 | Android TV | Fire TV |
|------|-----------|---------|
| **허용 SDK** | Google IMA SDK | Amazon Mobile Ads SDK |
| **허용 형식** | 동영상 Interstitial만 | Banner + Interstitial |
| **보상형 광고** | 사용 불가 | 사용 불가 |
| **Banner 광고** | 사용 불가 | 사용 가능 (하단) |
| **닫기 방식** | D-pad으로 닫기 필수 | D-pad으로 닫기 필수 |

### 8.3 보상형 광고 미지원 사유

TV 환경에서 보상형 광고(Rewarded Ad)를 지원하지 않는 이유:

1. **UX 부적합**: 리모컨으로 30초 광고 시청 후 닫기 버튼을 찾는 것이 불편하다.
2. **SDK 미지원**: IMA SDK는 보상형 광고 형식을 제공하지 않는다.
3. **사용자 기대**: TV Lean-back 환경에서 강제 시청은 부정적 경험을 준다.

### 8.4 TV 광고 표시 규칙

- **빈도**: 레벨 완료 후 3판마다 최대 1회 전면 광고
- **길이**: 최대 15초 (Skippable 5초 후)
- **닫기**: D-pad Center(OK) 또는 Back 버튼으로 닫기 가능해야 함
- **시점**: 자연스러운 전환점(레벨 완료 후, 화면 전환 시)에만 노출

### 8.5 광고 분기 Pseudocode

```gdscript
## ad_manager.gd (TV 광고 분기 처리)
## 플랫폼에 따라 적절한 광고 SDK를 호출한다.

func show_interstitial() -> void:
	if not LayoutManager.is_tv():
		## 모바일: AdMob Interstitial
		_show_admob_interstitial()
		return

	## TV 플랫폼 분기
	if _is_fire_tv():
		_show_amazon_interstitial()
	else:
		## Android TV: IMA SDK
		_show_ima_interstitial()


func _is_fire_tv() -> bool:
	## Fire TV 감지: Amazon 제조사 또는 Fire OS 확인
	var manufacturer := OS.get_model_name().to_lower()
	return "amazon" in manufacturer or "fire" in manufacturer


func _show_ima_interstitial() -> void:
	## Google IMA SDK를 통한 동영상 Interstitial 표시
	## 실제 구현은 GDExtension 또는 Android 플러그인 사용
	print("[AdManager] Showing IMA interstitial (Android TV)")
	pass


func _show_amazon_interstitial() -> void:
	## Amazon Mobile Ads SDK를 통한 Interstitial 표시
	## 실제 구현은 Android 플러그인 사용
	print("[AdManager] Showing Amazon interstitial (Fire TV)")
	pass


func _show_admob_interstitial() -> void:
	## AdMob Interstitial (모바일 전용)
	print("[AdManager] Showing AdMob interstitial (Mobile)")
	pass
```

---

## 9. TV IAP 고려사항

### 9.1 리모컨 구매 플로우

TV에서 인앱 구매(IAP) 시 리모컨만으로 전체 플로우를 진행할 수 있어야 한다.

**구매 플로우 단계:**

```
[상점 화면] --> D-pad로 상품 선택 --> [OK] 눌러 구매 시작
    --> [구매 확인 팝업] --> [확인] 버튼에 포커스
    --> [OK] 눌러 확정 --> OS 결제 화면 (PIN 입력 등)
    --> 결제 완료 --> [구매 완료 팝업]
```

### 9.2 구매 확인 팝업 요구사항

| 항목 | 사양 |
|------|------|
| 버튼 크기 | 최소 56dp 높이, 200dp 너비 |
| 텍스트 크기 | 28sp (버튼), 24sp (설명) |
| 기본 포커스 | [취소] 버튼 (실수 방지) |
| 상품 정보 | 상품명, 가격, 설명을 명확히 표시 |
| PIN 입력 | OS가 처리 (앱에서 구현 불필요) |

### 9.3 플랫폼별 IAP SDK

| 플랫폼 | IAP SDK | 비고 |
|--------|---------|------|
| Android TV | Google Play Billing Library | Google Play 배포 필수 |
| Fire TV | Amazon IAP SDK | Google Play Services 미지원 |

> **주의**: Google Play Billing과 Amazon IAP는 API가 다르므로, 추상화 레이어를 통해 분기 처리해야 한다. P06_01 수익화 문서의 IAP 구조를 참조한다.

---

## 10. 성능 최적화

### 10.1 TV 환경 성능 제약

TV 셋톱박스는 스마트폰 대비 GPU/CPU 성능이 낮은 경우가 많다. 특히 저가형 Fire TV Stick은 제한된 리소스를 가진다.

| 항목 | 목표 |
|------|------|
| 메모리 사용량 | < 200MB |
| 프레임 속도 | 안정적 30fps 이상 |
| 격자 최대 크기 | 12x12 (TV 전용 제한) |
| 초기 로딩 시간 | < 3초 |

### 10.2 최적화 전략

| 전략 | 상세 |
|------|------|
| **격자 크기 제한** | TV에서 격자 최대 12x12로 제한. 15x15는 셀 크기 64dp 기준 960dp 폭으로 사이드바 공간 부족. 12x12는 768dp로 사이드바 배치 가능. |
| **배경 애니메이션 간소화** | 파티클 최대 개수 50% 축소. 복잡한 셰이더 비활성화. |
| **텍스처 최적화** | TV는 FHD(1920x1080) 고정이므로 4K 텍스처 불필요. 최대 1024x1024 텍스처 사용. |
| **노드 수 절감** | 격자 셀 외 불필요한 장식 노드 최소화. |
| **Font Cache** | TV 테마 폰트를 미리 로드하여 런타임 지연 방지. |

### 10.3 성능 분기 Pseudocode

```gdscript
## performance_manager.gd
## TV 환경에서 성능 관련 설정을 조정한다.

func apply_tv_performance_settings() -> void:
	if not LayoutManager.is_tv():
		return

	## 파티클 감소
	_reduce_particles(0.5)  ## 50% 축소

	## 배경 애니메이션 간소화
	_simplify_background_animations()

	## V-Sync 활성화 (TV는 항상 60Hz 고정)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)


func _reduce_particles(factor: float) -> void:
	## 씬 내 모든 GPUParticles2D의 amount를 factor만큼 축소
	for node in get_tree().get_nodes_in_group("particles"):
		if node is GPUParticles2D:
			node.amount = int(node.amount * factor)


func _simplify_background_animations() -> void:
	## 배경 애니메이션 노드의 속도를 낮추거나 비활성화
	for node in get_tree().get_nodes_in_group("bg_animation"):
		if node is AnimationPlayer:
			node.speed_scale = 0.5
```

---

## 11. Android TV vs Fire TV 차이표

| 항목 | Android TV | Fire TV |
|------|-----------|---------|
| **OS** | Android TV OS | Fire OS (Android Fork) |
| **스토어** | Google Play Store | Amazon Appstore |
| **결제** | Google Play Billing | Amazon IAP SDK |
| **광고** | Google IMA SDK만 | Amazon Mobile Ads SDK |
| **어시스턴트** | Google Assistant | Alexa |
| **배포 포맷** | AAB (App Bundle) | APK |
| **Google Play Services** | 지원 | 미지원 |
| **최소 OS 버전** | Android 10+ | Fire OS 7+ (Android 9 기반) |
| **배너 이미지** | 320x180px 필수 | 1920x1080px 권장 |
| **리모컨 레이아웃** | 제조사별 다양 | 통일된 Fire TV 리모컨 |
| **D-pad 매핑** | 표준 Android KeyEvent | 표준 Android KeyEvent (호환) |
| **디버그** | adb connect / Android Studio | adb connect / Fire TV 설정에서 ADB 활성화 |

### 11.1 공통 사항

두 플랫폼 모두 다음 사항을 공유한다:

- Android 기반이므로 Godot의 Android Export 활용
- D-pad KeyEvent 코드 호환 (DPAD_UP/DOWN/LEFT/RIGHT/CENTER)
- `uses-feature android.hardware.touchscreen required="false"` 선언 필수
- Leanback Launcher Intent 필요
- Back 버튼 = Android `KEYCODE_BACK`

### 11.2 Fire TV 전용 고려사항

- Google Play Services에 의존하는 기능(Google Sign-In, Firebase Auth 등) 사용 불가
- Amazon의 자체 인증/분석 서비스 사용 또는 독립 솔루션 필요
- APK 형식으로 빌드 (AAB 미지원)
- Amazon Appstore 심사 기준은 Google Play와 상이

---

## 12. AndroidManifest TV 설정

### 12.1 필수 AndroidManifest 수정

Godot의 Custom Build를 활성화하고 `android/build/AndroidManifest.xml`을 수동 편집한다.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.yourcompany.wordsearch">

    <!-- Leanback 지원 선언 (required=false: 모바일/TV 동시 지원) -->
    <uses-feature
        android:name="android.software.leanback"
        android:required="false" />

    <!-- 터치스크린 불필수 선언 (TV 필수) -->
    <uses-feature
        android:name="android.hardware.touchscreen"
        android:required="false" />

    <application
        android:banner="@drawable/banner"
        android:icon="@mipmap/icon"
        android:label="@string/app_name">

        <activity android:name="com.godot.game.GodotApp"
            android:configChanges="..."
            android:screenOrientation="landscape">

            <!-- 기존 모바일 런처 인텐트 -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>

            <!-- TV Leanback 런처 인텐트 (추가) -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LEANBACK_LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

### 12.2 TV 배너 이미지

| 항목 | 사양 |
|------|------|
| 파일명 | `banner.png` |
| 크기 | 320 x 180 px |
| 형식 | PNG |
| 경로 | `android/build/res/drawable/banner.png` |
| 용도 | TV 런처 홈 화면에 표시 |

### 12.3 Godot Project Settings (TV)

```
Project Settings:
  Display > Window > Size > Viewport Width: 1920
  Display > Window > Size > Viewport Height: 1080
  Display > Window > Stretch > Mode: canvas_items
  Display > Window > Stretch > Aspect: keep
```

> **참고**: 이 설정은 TV 전용 빌드에서 적용한다. 모바일과 TV를 하나의 APK/AAB로 배포하는 경우, 런타임에서 `LayoutManager`가 뷰포트 크기를 동적으로 조정한다.

---

## 13. 테스트 체크리스트

### 13.1 D-pad 네비게이션 테스트

| # | 항목 | 합격 기준 | 결과 |
|---|------|----------|------|
| 1 | 모든 화면 D-pad 접근 | D-pad만으로 모든 화면의 모든 인터랙티브 요소에 접근 가능 | [ ] |
| 2 | 격자 셀 이동 | D-pad 상/하/좌/우로 인접 셀 이동, 경계에서 멈춤 | [ ] |
| 3 | 단어 선택 플로우 | OK -> 방향 -> OK 순서로 단어 선택 완료 | [ ] |
| 4 | 선택 취소 | Back 버튼으로 선택 중 취소 가능 | [ ] |
| 5 | Back 버튼 | 모든 화면에서 Back 버튼 동작 (이전 화면/취소) | [ ] |
| 6 | 초기 포커스 | 화면 진입 시 적절한 요소에 자동 포커스 | [ ] |
| 7 | 포커스 순환 방지 | 격자 경계에서 포커스가 반대편으로 순환하지 않음 | [ ] |

### 13.2 시각 디자인 테스트

| # | 항목 | 합격 기준 | 결과 |
|---|------|----------|------|
| 8 | 포커스 링 가시성 | 포커스 링이 3m 거리에서 명확히 보임 | [ ] |
| 9 | 포커스 애니메이션 | 포커스 전환 시 색상+크기+glow 변화 확인 | [ ] |
| 10 | 텍스트 판독성 | 3m 거리에서 모든 텍스트(본문, 버튼, 격자) 판독 가능 | [ ] |
| 11 | Safe Area | 모든 인터랙티브 요소와 중요 텍스트가 Safe Area(5%) 내에 위치 | [ ] |
| 12 | Dark 테마 적용 | 배경 어두운 톤, 텍스트 밝은 톤 | [ ] |
| 13 | 호버 상태 없음 | 마우스 없이도 시각적 이상 없음 (호버=normal 확인) | [ ] |

### 13.3 레이아웃 테스트

| # | 항목 | 합격 기준 | 결과 |
|---|------|----------|------|
| 14 | 격자 + 사이드바 배치 | 격자가 좌측, 단어 목록이 우측 사이드바에 정상 배치 | [ ] |
| 15 | 격자 최대 12x12 | TV에서 격자 크기가 12x12를 초과하지 않음 | [ ] |
| 16 | 버튼 크기 | 모든 버튼의 포커스 타겟이 56dp 이상 | [ ] |
| 17 | 여백 증가 | 모바일 대비 여백 40-60% 증가 확인 | [ ] |

### 13.4 광고/IAP 테스트

| # | 항목 | 합격 기준 | 결과 |
|---|------|----------|------|
| 18 | Android TV 광고 | IMA SDK Interstitial만 노출, AdMob 미사용 | [ ] |
| 19 | Fire TV 광고 | Amazon Ads SDK로 배너/Interstitial 노출 | [ ] |
| 20 | 광고 D-pad 닫기 | 전면 광고를 D-pad(OK 또는 Back)으로 닫을 수 있음 | [ ] |
| 21 | IAP 리모컨 구매 | D-pad만으로 구매 확인 팝업 조작 및 구매 완료 가능 | [ ] |

### 13.5 성능 테스트

| # | 항목 | 합격 기준 | 결과 |
|---|------|----------|------|
| 22 | 메모리 | < 200MB 사용 | [ ] |
| 23 | 프레임 속도 | 안정적 30fps 이상 (Fire TV Stick 포함) | [ ] |
| 24 | 로딩 시간 | 초기 로딩 < 3초 | [ ] |
| 25 | 격자 생성 시간 | 12x12 격자 생성 < 0.5초 | [ ] |

### 13.6 테스트 장비

| 장비 | 용도 | 비고 |
|------|------|------|
| Android TV Emulator (Android Studio) | 기본 기능 테스트 | `adb shell input keyevent` 로 D-pad 시뮬레이션 |
| Fire TV Stick (실기기) | Fire TV 성능/광고 테스트 | 가장 낮은 성능 기준 |
| Nvidia Shield TV | Android TV 실기기 | 고성능 기준 |
| PC + `--tv-mode` | 빠른 레이아웃 확인 | 키보드 화살표로 D-pad 대용 |

---

## 14. 참조 문서

| 출처 | 내용 |
|------|------|
| Godot Guide §5.2-5.4 | 플랫폼 감지, 터치 입력, D-pad 포커스 네비게이션 |
| Godot Guide §9 | TV 광고 제한 (IMA only, AdMob 사용 금지) |
| Godot Guide §10.2 | Android TV AndroidManifest 설정 |
| Godot Guide §15 | TV Lean-back UI 전략 (스케일링, Godot 설정, UI 원칙) |
| P01_03 | 입력 시스템 기술명세 (InputMap, D-pad 매핑) |
| P08_01 | UI 디자인 시스템 (모바일 기준 Theme, 색상 체계) |
| P06_01 | 수익화 및 경제 시스템 (IAP 추상화 구조) |
| [Android TV 디자인 가이드](https://developer.android.com/design/ui/tv) | Google 공식 TV UI 가이드라인 |
| [Fire TV 개발 문서](https://developer.amazon.com/docs/fire-tv/getting-started-developing-apps-and-games-for-amazon-fire-tv.html) | Amazon Fire TV 개발 가이드 |

---

## 15. 변경 이력

| 버전 | 날짜 | 변경 내용 | 작성자 |
|------|------|----------|--------|
| v1.0 | 2026-03-11 | 최초 작성. Godot Guide §5, §9, §10, §15 통합. | - |
