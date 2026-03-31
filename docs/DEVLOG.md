# WordPuzzle Godot — 개발 로그

기획서에 없는 추가 요청 사항 및 버그 수정 기록.
기획서 경로: `C:/Users/0/ai프로젝트/wordPuzzle_Godot/기획서 최종본/`

---

## AdMob 광고 모듈 통합 (2026-03-19)

### [FEAT] AdMob 광고 시스템 전면 구현
- **플러그인**: Poing Studios godot-admob-plugin (Godot 4.x, Android + iOS)
- **파일 생성**: `scripts/autoload/ad_config.gd`
- **파일 재작성**: `scripts/autoload/ad_manager.gd`
- **파일 수정**: `scripts/ui/screens/game_screen.gd`, `scripts/ui/screens/home_screen.gd`

#### 광고 전략
| 유형 | 조건 | 타이밍 |
|------|------|--------|
| Banner | Lv.5+ | 게임 화면 하단 상시 |
| Interstitial | Lv.5+, 3스테이지마다 | Next Stage 탭 후, 90초 쿨다운 |
| Rewarded | 제한 없음 | 힌트 부족 시 유저 자발적 선택 |

- Lv.1~4 완전 무광고 (유저 안착 보호)
- 광고 제거 IAP: Banner + Interstitial 제거, Rewarded 유지

#### 구현 상세
- `AdConfig`: 정책 상수(AD_FREE_LEVELS, INTERSTITIAL_INTERVAL, INTERSTITIAL_COOLDOWN), 테스트/프로덕션 Unit ID (Android/iOS 분리), `get_unit_id()` 헬퍼
- `AdManager`: 플러그인 감지 → SDK 초기화 → 배너/전면/보상형 preload/show/hide. 에디터 fallback(stub 모드: 시그널만 에밋)
- `game_screen.gd`: `start_stage()`에서 배너 show, `_on_back_pressed()`에서 배너 hide, 스테이지 클리어 후 전면광고 삽입, `_grant_ad_hint()` 보상형 광고 await
- `home_screen.gd`: `ads_removed_changed` 시그널로 ad-remove 버튼 자동 숨김

#### 필수 후속 작업
- [ ] Poing Studios 플러그인 AssetLib에서 설치 및 활성화
- [ ] AdMob 콘솔에서 앱 등록 및 Unit ID 발급
- [ ] `ad_config.gd`의 `PROD_*` 상수에 실제 Unit ID 입력
- [ ] `USE_TEST_ADS = false`로 변경 후 릴리즈
- [ ] iOS Info.plist에 ATT 설명 문구 추가
- [ ] Android/iOS export 설정에 AdMob App ID 추가

---

## 바텀 네비게이션 바 리디자인 (2026-03-18)

### [FEAT] 하단 탭바 프리미엄 스타일로 전면 교체
- **파일**: `scripts/ui/components/bottom_tab_bar.gd`, `assets/ui/nav_bar_bg.png`, `assets/ui/nav_bar_active.png`

#### 변경 사항

**에셋 교체**
- `nav_bar_bg.png`: 기존 오렌지 배경 → 보라색 글래스 둥근 바 배경
- `nav_bar_active.png`: 기존 오렌지 인디케이터 → 골든 필(pill) 인디케이터

**에셋 이미지 처리**
- 원본 1280x853 이미지에서 투명 패딩 제거 후 리사이즈
- `nav_bar_bg.png`: 1080x160 (바 영역에 정확히 맞춤)
- `nav_bar_active.png`: 200x56 (골든 필 인디케이터)
- 탭 아이콘 5개: 64x64 → 256x256 업스케일 (LANCZOS)

**bottom_tab_bar.gd — 처음부터 완전 재작성 (HBoxContainer 제거, 수동 배치)**
- HBoxContainer 제거 → 모든 노드를 루트 Control에 직접 추가, 절대 좌표 배치
- 홈 아이콘 250px, 아이콘 하단이 바 상단+50px (바 위로 200px 돌출)
- 사이드 아이콘 140px(비활성)/150px(활성), 아이콘 하단이 바 상단+50px (바 위로 90px 돌출)
- 골든 필 180x48px, 라벨 뒤 센터 정렬
- 라벨: 24px(사이드)/28px(홈), 바 하단 14px 위에 고정
- 각 탭별 독립 터치 영역(돌출 포함) + 홈 오버레이
- Tween: TRANS_CUBIC + EASE_OUT

**tscn 수정**
- HBoxContainer 제거 (순수 Control 기반)
- 바 높이: 168px → 160px (`bottom_tab_bar.tscn`, `main_scene.tscn` 5개 화면)

#### 미구현 (추후)
- 반짝이(sparkle) CPUParticles2D 파티클 효과

---

## 게임 화면 설정 팝업 구현 (2026-03-18)

### [FEAT] ⚙ 설정 버튼 → 인게임 설정 팝업
- **파일**: `scenes/screens/game_screen.tscn`, `scripts/ui/screens/game_screen.gd`, `scripts/autoload/audio_manager.gd`

#### 변경 사항

**game_screen.tscn**
- `RightBtns` HBoxContainer에 `SettingsButton` 노드 추가 (`unique_name_in_owner=true`, 74×74, 텍스트 "⚙")

**game_screen.gd**
- `@onready var settings_button: Button = %SettingsButton` 추가
- `_ready()`에서 `settings_button.pressed.connect(_on_settings_pressed)` 연결
- `_setup_styles()` 원형 버튼 루프 및 `_apply_dynamic_layout()` 크기 루프에 `settings_button` 포함
- `_on_settings_pressed()` → `_show_settings_popup()` 호출
- `_show_settings_popup()`: CanvasLayer layer=15, CenterContainer 중앙 정렬, 팝 인 0.18s TRANS_BACK, 배경 탭으로도 닫힘
- `_settings_add_audio_section()`: 레이블+토글 행 + HSlider, 토글 OFF 시 슬라이더 비활성(투명도 0.35)
- `_settings_make_link_button()`: 다크 배경 링크 버튼 (문의하기, 이용약관 공통)

#### 팝업 구성
| 항목 | 기능 |
|------|------|
| 🎵 배경음악 | 토글(켜기/끄기) + 볼륨 슬라이더 (0~1) |
| 🔊 효과음 | 토글(켜기/끄기) + 볼륨 슬라이더 (0~1) |
| 📧 개발자에게 문의하기 | 플레이스홀더 (TODO: `OS.shell_open("mailto:")`) |
| 📋 이용약관 | 플레이스홀더 (TODO: `OS.shell_open("https://...")`) |

**audio_manager.gd**
- `_music_enabled`, `_sfx_enabled` 상태 변수 추가
- `set_music_enabled(bool)`, `set_sfx_enabled(bool)`, `get_music_enabled()`, `get_sfx_enabled()` 추가
- `_music_vol_db()`: `_music_enabled=false`면 -80dB 반환 (뮤트)
- `play_sfx()`: `_sfx_enabled=false`면 즉시 return (SFX 억제)
- `_save_audio_settings()`: `music_enabled`, `sfx_enabled` 저장 키 추가
- `_ready()`: 저장된 enabled 값 복원

---

## 7일 연속 출석 스트릭 시스템 (2026-03-18)

### [FEAT] 힌트 밸런스 전면 재설계 + 7일 스트릭 출석 시스템 구현
- **파일**: `scripts/autoload/hint_ticket_manager.gd`, `scripts/ui/screens/home_screen.gd`

#### 힌트 수급 경로 최종 밸런스

| 수급 경로 | 첫글자/일 | 정답보기/일 |
|-----------|-----------|------------|
| 스테이지 클리어 (3회·5회당) | ≈1.67 | ≈1.0 |
| 7일 연속 스트릭 평균 | ≈3.43 | ≈1.57 |
| 광고 시청 (상한 ~2회) | ≈1.0 | ≈1.0 |
| **합계** | **≈6.1** | **≈3.6** |
- 적극적 플레이어(4~5 첫글자/일, 1~2 정답보기/일) 기준 소폭 잉여 → 광고 유도 자연 발생

#### 7일 연속 스트릭 보상표 (미출석 시 Day 1 하드 리셋)

| Day | 첫글자 | 정답보기 | 비고 |
|-----|--------|----------|------|
| 1 | ×2 | ×0 | |
| 2 | ×2 | ×1 | |
| 3 | ×3 | ×1 | |
| 4 | ×3 | ×1 | |
| 5 | ×4 | ×2 | 중반 점프 |
| 6 | ×4 | ×2 | |
| **7** | **×6** | **×4** | ★ 헤드라인 보상 (Day1 대비 ~3배) |

#### 누적 마일스톤 (연속 여부 무관, 리셋 없음)

| 누적일 | 첫글자 | 정답보기 |
|--------|--------|----------|
| 7일 | +5 | +2 |
| 14일 | +5 | +3 |
| 30일 | +8 | +5 |
| 60일 | +10 | +7 |
| 100일 | +15 | +10 |

#### 변경 사항
- `DAILY_FIRST_LETTER`, `DAILY_REVEAL` 상수 제거 → `STREAK_REWARDS` 배열로 교체
- `check_and_claim_daily()` 반환 타입: `bool` → `Dictionary`
  - 키: `fl, rv, streak_day, cumulative, milestone_fl, milestone_rv`
- 신규 변수: `streak_day`, `streak_last_date`, `cumulative_days` (SaveManager 저장)
- 신규 저장 키: `hint_streak_day`, `hint_streak_date`, `hint_cumulative`
- `_get_yesterday()`: unix-86400 기반으로 어제 날짜 문자열 반환
- `get_streak_info()`: 외부 UI에서 현재 스트릭 상태 조회용

#### 팝업 UI 업데이트 (home_screen.gd)
- `_show_daily_reward_popup(data: Dictionary)`: 시그니처 변경
- 7일 캘린더 스트립: 완료(핑크✓) / 오늘(오렌지 강조, 58px) / 미래(다크) / Day7(★)
- 제목: "🎁 출석 보상"(Day1) / "🔥 N일 연속 출석!"(Day2~6) / "★ 7일 연속 달성!"(Day7)
- 내일 보상 예고 텍스트 추가
- 누적 마일스톤 달성 시 골드 배너 추가
- Day 1은 정답보기 0개 → rv 배지 미표시 (0이면 조건부 숨김)

---

## 일일 출석 힌트 보상 (2026-03-18)

### [FEAT] 일일 출석 → 힌트 티켓 지급
- **파일**: `scripts/autoload/hint_ticket_manager.gd`, `scripts/ui/screens/home_screen.gd`
- 홈 화면 진입 시 `HintTicketManager.check_and_claim_daily()` 호출
- 하루 1회만 지급 (날짜 문자열 `YYYY-MM-DD`를 SaveManager `hint_daily_date` 키로 비교)
- 지급량: 첫글자 힌트 ×2 + 정답보기 힌트 ×1 (`DAILY_FIRST_LETTER`, `DAILY_REVEAL` 상수)
- 지급 시 `daily_reward_claimed` 시그널 발행
- 홈 화면에서 신호를 받아 보상 카드 팝업 표시 (팝인 애니메이션 0.22s TRANS_BACK)
- 팝업: 핑크(첫글자) + 보라(정답보기) 배지 + "확인" 버튼 → 페이드아웃 0.15s 후 닫힘
- 이미 오늘 수령했으면 팝업 없이 조용히 통과

---

## 힌트 티켓 시스템 전환 + 코인 UI 제거 (2026-03-18)

### [DESIGN] 코인 경제 → 힌트 티켓 경제 전환
- 기획 변경: 코인(Coin) 단일 재화를 사용하던 힌트 결제 방식 폐기
- 스테이지 클리어 횟수 기반으로 힌트 티켓을 무료 지급하는 방식으로 전환
- 업계 리서치(Wordscapes·Word Trip·Words of Wonders) 기반 밸런싱 결정

| 힌트 | 지급 조건 | 초기 지급 |
|------|---------|---------|
| 첫글자 힌트 | 3회 클리어마다 1회 | 3회 |
| 정답보기 | 5회 클리어마다 1회 | 1회 |

- 티켓 소진 시: 광고 시청 → 해당 티켓 1회 즉시 지급

### [FEAT] HintTicketManager 신규 Autoload 싱글톤
- **파일**: `scripts/autoload/hint_ticket_manager.gd`
- 티켓 잔여 관리, 저장/불러오기(SaveManager 연동), 스테이지 클리어 보상
- `add_on_clear(stage)`: stage % 3 == 0 → 첫글자 +1, stage % 5 == 0 → 정답보기 +1
- `use_first_letter()` / `use_reveal()`: 소비 API (잔여 없으면 false 반환)
- `grant(fl, rv)`: 광고 보상 및 디버그 직접 지급

### [FEAT] 광고 힌트 다이얼로그 팝업 구현
- **파일**: `scripts/ui/screens/game_screen.gd`
- 티켓 소진 시 토스트 메시지 대신 전용 다이얼로그 팝업 표시
- CanvasLayer layer=12 (페이드/팝업 위), 반투명 배경 + 카드 UI
- 버튼 2개: "취소" / "광고 보기 ▶" (핑크)
- 팝업 팝인 애니메이션 (scale 0.85→1.0, 0.18s TRANS_BACK)
- `_grant_ad_hint(type)`: AdMob 연동 시 이 함수에서 실제 보상 처리하도록 설계
- **주의**: 현재 "광고 보기" 탭 시 광고 없이 즉시 지급됨 (stub) — AdMob SDK 연동 후 `_grant_ad_hint()`를 신호 기반으로 교체 예정

### [CHANGE] 게임 화면 상단 코인 UI 제거
- **파일**: `scenes/screens/game_screen.tscn`, `scripts/ui/screens/game_screen.gd`
- `ShopButton` 노드 및 관련 참조 전체 제거 (RightBtns에서 삭제)
- `_on_shop_pressed()` 스텁 함수 제거
- `_setup_styles()`, `_apply_dynamic_layout()` 버튼 루프에서 shop_button 제거
- PowerHintButton 기본 텍스트: "정답보기\n200" → "정답보기\n×1"
- HintButton 기본 텍스트: "첫글자\n100" → "첫글자\n×3"

---

## Phase 2 완성 작업 (2026-03-17)

### [FEAT] SaveManager 전면 재구성 (P02_03)
- 완전한 SaveData 스키마 구현 (30+ 필드: stats, settings, unlocked_themes, best_times, daily_login 등)
- 백업 시스템 추가 (`save_data.backup.json` 자동 생성)
- 복구 전략: 메인 파일 실패 → 백업 → 기본값
- 마이그레이션: v0→v1(last_stage, coins 키 변환), v1→v2(placeholder)
- 전체 typed getter/setter API 추가 (하위 호환 save_value/load_value 유지)
- 시그널 추가: data_loaded, data_saved, data_reset, coin_balance_changed
- **파일**: `scripts/autoload/save_manager.gd`

### [FEAT] GameManager/GameController/GameResult 보완 (P02_01)
- GameMode enum 추가 (CLASSIC, TIME_ATTACK, DAILY_CHALLENGE, BONUS, MARATHON)
- GameState에 IDLE, COMPLETED, FAILED 추가 (TITLE/RESULT는 하위호환 유지)
- GameResult에 mode, theme, is_cleared, is_new_record, words_found, total_words 필드 추가
- GameController에 기획서 시그널 전부 추가 (game_started, game_paused, game_resumed, game_completed, game_failed, game_state_changed)
- fail_game() 함수 신규 추가 (FAILED 상태 처리)
- complete_game()에 update_stats, BestTime 갱신, 테마 해금 체크 연동
- _check_feature_unlocks(): Stage 10/24 기능 해금 팝업 트리거
- **파일**: `scripts/autoload/game_manager.gd`, `scripts/autoload/game_controller.gd`, `scripts/resources/game_result.gd`

### [FEAT] 스테이지 진행 시스템 보완 (P02_02)
- ThemeUnlockChecker 신규 생성 (8테마 해금 조건: default, classic_clears, time_attack_clears, daily_streak, all_themes_used)
- ResultScreen: FAILED 시 Next 버튼 숨김, Retry 버튼 추가, 신기록 배너 추가, 단어 진행도 표시
- result_screen.tscn: NewRecordLabel, RetryButton, WordsLabel 노드 추가
- **파일**: `scripts/game/theme_unlock_checker.gd`, `scripts/ui/screens/result_screen.gd`, `scenes/screens/result_screen.tscn`

### [FEAT] ScreenManager open_popup 편의 메서드 추가
- open_popup(name, data): "settings" | "profile" | "avatar_select" | "feature_unlock" 이름으로 팝업 열기
- is_popup_open() 추가
- **파일**: `scripts/autoload/screen_manager.gd`

### [FEAT] 팝업 3종 구현 (P02_01)
- SettingsPopup: 사운드/음악/다크모드/언어/폰트 크기 설정 (SaveManager 즉시 저장)
- ProfilePopup: 아바타, 닉네임, 스탯(클리어수/단어수/플레이시간/코인/최고기록) 표시
- AvatarSelectPopup: 0~20번 아바타 그리드 선택
- **파일**: `scripts/ui/popups/`, `scenes/popups/` (설정/프로필/아바타 .gd + .tscn 6개)

### [FEAT] 튜토리얼 시스템 구현 (P02_04)
- TutorialManager Autoload: start_tutorial(), on_tutorial_stage_cleared(), show_guide()
- TutorialPuzzles: Stage 1(3×3 EN/KO 고정), Stage 2(4×4 EN/KO 고정), Stage 3(랜덤)
- GuideOverlay: 스포트라이트 셰이더(spotlight.gdshader) + 손 애니메이션 루프 + 툴팁
- 언어 선택 화면 (LanguageSelectScreen): EN/KO 선택
- 프로필 설정 화면 (ProfileSetupScreen): 닉네임 입력 + 스킵 가능
- FirstRunManager: tutorial_completed 확인 → 언어선택 화면 진입
- ReturningUserChecker: 3일 이상 미접속 감지 → 복귀 유저 팝업
- main_scene.gd: _post_init()에서 FirstRun/ReturningUser 체크
- **파일**: `scripts/autoload/tutorial_manager.gd`, `scripts/game/tutorial_puzzles.gd`, `scripts/ui/guide_overlay.gd`, `shaders/spotlight.gdshader`, `scenes/ui/guide_overlay.tscn`, `scripts/ui/screens/language_select_screen.gd`, `scripts/ui/screens/profile_setup_screen.gd`, `scenes/screens/language_select_screen.tscn`, `scenes/screens/profile_setup_screen.tscn`, `scripts/utils/first_run_manager.gd`, `scripts/utils/returning_user_checker.gd`

### [FEAT] ToastManager + 기능 해금 팝업 (P02_04)
- ToastManager Autoload: 상단 슬라이드인 Toast, 큐 방식, 3초 표시 후 슬라이드아웃
- FeatureUnlockPopup: Time Attack / Daily Challenge / 복귀 유저 3종
- project.godot: TutorialManager, ToastManager Autoload 등록
- **파일**: `scripts/autoload/toast_manager.gd`, `scripts/ui/popups/feature_unlock_popup.gd`, `scenes/popups/feature_unlock_popup.tscn`

---

## 버그 수정

### [BUG-FIX] 튜토리얼 그리드 크기·필러 문자 문제 (2026-03-17)
- **증상 1**: 한국어 튜토리얼 그리드에 알파벳 "Z" 표시 (한국어 글자가 아님)
- **증상 2**: 모든 UI(ThemeBanner, WordBank, BottomActionBar)가 정상 스테이지보다 좁고 작음
- **원인 분석**:
  - viewport = 1080×1920, MAX_CELL_SIZE = 160px
  - 정상 스테이지 5×5: `grid_px.x = 160×5 + 8 = 808px`
  - 튜토리얼 3×3: `grid_px.x = 160×3 + 4 = 484px` (약 40% 더 좁음)
  - `_update_button_layout()`이 ThemeBanner/WordBank/BottomActionBar 너비를 `grid_px.x` 기준으로 계산하기 때문에 그리드가 좁으면 UI도 함께 좁아짐
- **수정**: `tutorial_puzzles.gd` — 3×3→5×5, 4×4→5×5로 확장 및 한국어 필러를 실제 한글 음절로 교체
  - Stage 1 KO: 고양이 + 강아지 (5×5)
  - Stage 1 EN: CAT + DOG (5×5)
  - Stage 2 KO: 하늘 + 바다 + 나무 (5×5)
  - Stage 2 EN: SUN + SEA (5×5)
- **파일**: `scripts/game/tutorial_puzzles.gd`

### [BUG-FIX] 닉네임 설정 화면이 매 실행마다 반복 표시 (2026-03-17)
- **증상**: 게임 실행 시 매번 언어 선택 → 닉네임 입력 화면이 표시됨
- **원인**: `tutorial_completed = true` 저장 경로가 3곳에서 차단됨
  1. `profile_setup_screen._start_tutorial()` — `set_tutorial_completed(true)` 미호출
  2. `game_screen._on_stage_complete()` — `TutorialManager.on_tutorial_stage_cleared()` 미호출 → `_finish_tutorial()` 미실행
  3. `game_screen.enter()` — `tutorial_grid` 무시 → word_pack_path="" 로 start_stage 호출
- **수정**:
  - `profile_setup_screen._start_tutorial()`: `set_tutorial_completed(true)` 선저장 (안전망)
  - `game_screen.enter()`: `tutorial_grid is GridData` 분기 추가
  - `game_screen.start_stage()`: 3번째 파라미터 `prebuilt_grid: GridData = null` 추가, 튜토리얼/일반 경로 분리
  - `game_screen._on_stage_complete()`: `TutorialManager.is_in_tutorial()` 체크 → `on_tutorial_stage_cleared()` 호출 분기
- **파일**: `scripts/ui/screens/profile_setup_screen.gd`, `scripts/ui/screens/game_screen.gd`

### [BUG-FIX] 인게임 버튼(힌트/뒤로가기) 입력 불가 (2026-03-17)
- **증상**: 게임 화면에서 힌트 버튼, 셔플 버튼, 뒤로가기 버튼이 전혀 반응하지 않음. 격자 드래그는 정상 작동.
- **원인**: `_setup_debug_panel()`에서 생성한 `root` Control이 `PRESET_FULL_RECT`(전체화면) + 기본값 `MOUSE_FILTER_STOP`으로 설정됨. CanvasLayer(layer=128) 위에 있어 화면 전체 GUI 이벤트를 소비. Button들의 `_gui_input()`에 이벤트가 전달되지 않음. GridInputHandler는 `_input()` 사용이라 드래그만 정상 작동.
- **수정**: `root.mouse_filter = Control.MOUSE_FILTER_IGNORE` 추가
- **파일**: `scripts/ui/screens/game_screen.gd`

### [BUG-FIX] tutorial_puzzles.gd 크래시 — GridData/PlacedWord API 오용 (2026-03-17)
- **증상**: 닉네임 설정에서 "스킵" 누를 때 `SCRIPT ERROR: Invalid assignment of property or key 'cells'`
- **원인**: `tutorial_puzzles.gd`에서 `gd.cells = [...]` 사용 → `GridData` 프로퍼티는 `grid`임. 또한 `PlacedWord.new()` + 수동 `start_col`/`start_row` 설정 → `PlacedWord`에 해당 프로퍼티 없음, 반드시 `PlacedWord.create(word, display, Vector2i(col, row), direction)` 팩토리 사용해야 함
- **수정**:
  - `gd.cells` → `gd.grid` (전체 교체)
  - `PlacedWord.new()` + 수동 프로퍼티 → `PlacedWord.create(word, display, Vector2i(col, row), direction)` (전체 교체)
  - 영어 Stage 2: TREE 단어 배치를 불연속(오류) → SUN(가로) + SEA(세로) 2단어 구조로 재설계
- **파일**: `scripts/game/tutorial_puzzles.gd`
- **테스트**: headless 실행 exit code 0, SCRIPT ERROR 0개 확인

### [DEBUG] 인게임 난이도 조절 슬라이더 추가 (2026-03-17)
- **목적**: DDA를 우회해 단어 수를 수동으로 고정 (테스트 편의용)
- **구현**:
  - `game_manager.gd`: `debug_word_count_override: int = 0` 추가. `request_stage()`에서 `OS.is_debug_build() and override > 0`이면 DDA를 건너뛰고 해당 값 사용
  - `game_screen.gd` 디버그 창 "▸ 난이도 (DEBUG)" 섹션 추가:
    - DDA 오프셋 및 스테이지 AUTO 단어 수 표시 레이블
    - HSlider (0=AUTO·DDA, 1~12=고정): `GameManager.debug_word_count_override` 직접 설정
    - "현재 스테이지 재시작" 버튼: `start_stage(_current_stage, ...)` 즉시 호출
  - `_refresh_dda_info(lbl)` 헬퍼 메서드 추가 (`GameController._dda.current_offset` 읽기)
- **릴리즈 영향 없음**: `OS.is_debug_build()` 조건부, 슬라이더 UI는 디버그 창에만 존재
- **파일**: `scripts/autoload/game_manager.gd`, `scripts/ui/screens/game_screen.gd`

### [BUG-FIX] save_manager.gd set_nickname() 파라미터명 Node.name 섀도잉 경고
- **원인**: `set_nickname(name: String)` — `name`은 Node의 built-in 프로퍼티명과 충돌 (GDScript 경고)
- **수정**: 파라미터 `name` → `new_name`
- **파일**: `scripts/autoload/save_manager.gd`

### [BUG-FIX] theme_unlock_checker.gd _is_condition_met() 미사용 파라미터 경고
- **원인**: `unlocked: Array[String]` 파라미터가 함수 내부에서 사용되지 않음
- **수정**: `unlocked` → `_unlocked` (언더스코어 접두사 = 의도적 미사용 표시)
- **파일**: `scripts/game/theme_unlock_checker.gd`

### [BUG-FIX] enter(data) 미사용 파라미터 경고 (다수 파일)
- **원인**: BaseScreen 오버라이드 `enter(data: Dictionary = {})` 에서 data를 실제로 사용하지 않는 화면들
- **수정**: `data` → `_data` (언더스코어 접두사)
- **파일**: `language_select_screen.gd`, `profile_setup_screen.gd`, `avatar_select_popup.gd`, `settings_popup.gd`, `profile_popup.gd`

---

### [BUG-FIX] NOTIFICATION_APPLICATION_PAUSE_REQUEST 존재하지 않는 상수 사용
- **증상**: SaveManager 파싱 실패 → 모든 Autoload의 SaveManager 호출이 Nil 에러 연쇄 발생
- **원인**: Godot 4에는 NOTIFICATION_APPLICATION_PAUSE_REQUEST 상수가 없음. 올바른 상수는 NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST
- **수정**: save_manager.gd _notification() 에서 PAUSE_REQUEST 라인 제거
- **파일**: scripts/autoload/save_manager.gd
- **테스트**: headless 실행 후 SCRIPT ERROR 0개, DDA 테스트 28/28 통과 확인

### [BUG-007] 플레이 버튼 누를 때 타이틀 화면과 게임 화면 겹침
- **증상**: HomeScreen의 "플레이" 버튼을 누르면 HomeScreen이 게임 화면 위에 겹쳐 보임
- **원인**: `push_screen()` 시 TabLayer(layer=0)가 숨겨지지 않아 PushLayer(layer=10)의 게임 화면과 동시에 렌더링됨
- **수정 1**: `ScreenManager.push_screen()` — 스택이 비었을 때 `_tab_layer.visible = false`, `_bottom_tab_bar.visible = false`
- **수정 2**: `ScreenManager.pop_screen()` / `clear_push_stack()` — 스택이 비면 TabLayer/BottomTabBar 복원
- **수정 3**: `push_screen()` — `screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)`으로 화면 크기 강제 설정
- **수정 4**: `ScreenManager.initialize()` — `bottom_tab_bar` 파라미터 추가, `main_scene.gd`에서 전달
- **파일**: `scripts/autoload/screen_manager.gd`, `scripts/ui/main_scene.gd`

### [BUG-006] 드래그 시 마우스가 다음 셀에 진입하기 전에 색이 변하는 이슈
- **증상**: 첫 셀 클릭 후 마우스가 아직 같은 셀 안에 있는데도 인접 셀이 하이라이트됨
- **원인**: `grid_input_handler.gd`의 `cell_dist = maxi(cell_dist, 1)`이 실제 이동 거리가 0이어도 1로 강제 올려 2셀 경로를 생성
- **수정**: 해당 줄 제거. cell_dist=0이면 경로가 시작 셀 하나만 반환되어 변화 없음
- **파일**: `scripts/game/grid_input_handler.gd`

### [BUG-001] LetterCell.setup() Nil 참조 오류
- **증상**: `Invalid assignment of property 'text' on base 'Nil'` 에러 발생
- **원인**: `grid_board.gd`에서 `add_child()` 전에 `setup()`을 호출해 `@onready` 변수가 null
- **수정**: `grid_board.gd`에서 `add_child(cell)` → `set_cell_size()` → `setup()` 순서로 변경
- **파일**: `scripts/game/grid_board.gd`

### [BUG-002] Tween 색상 보간 오류 (Type mismatch: Nil and Color)
- **증상**: 셀 클릭 시 `Cannot call 'set_ease' on null` 에러 발생
- **원인**: `letter_label`의 `font_color` override가 미설정 상태에서 Tween이 초기값을 Nil로 읽음
- **수정**: `letter_cell.gd`의 `_ready()`와 `reset()`에 `letter_label.add_theme_color_override("font_color", ...)` 추가
- **파일**: `scripts/game/letter_cell.gd`

### [BUG-003] 셀 클릭 후 파란색 유지 (DRAGGING 상태 미해제)
- **증상**: 그리드 셀을 클릭 후 마우스를 떼도 파란색이 유지됨
- **원인**: `_on_cell_tapped`에서 셀을 DRAGGING으로 설정했으나, `drag_cancelled` 시 해당 셀이 `_prev_drag_cells`에 없어 복원 안 됨
- **수정 1**: `_on_drag_started`에서 시작 셀을 DRAGGING으로 설정 + `_prev_drag_cells`에 추가
- **수정 2**: `_on_cell_tapped`에서 DRAGGING 상태 변경 제거
- **파일**: `scripts/ui/screens/game_screen.gd`

### [BUG-004] 정답 셀을 드래그하면 색이 흰색으로 초기화됨
- **증상**: FOUND 상태 셀을 다시 클릭/드래그하면 흰색(IDLE)으로 돌아감
- **원인**: `set_visual_state()`의 FOUND 보호 조건이 IDLE/HOVER만 차단하고 DRAGGING은 허용
- **수정**: FOUND 셀은 모든 상태 변경을 차단 (`return` 무조건 처리)
- **파일**: `scripts/game/letter_cell.gd`

### [BUG-005] GDScript 타입 추론 오류 (Cannot infer type)
- **증상**: `:=`로 선언 시 `Cannot infer the type of 'X' variable` 오류
- **원인**: 비타입 `Array`를 순회하면 루프 변수가 `Variant`로 추론되어 메서드 반환값도 Variant
- **수정**: 핵심 Array를 모두 타입 명시로 변경
  - `placed_words: Array[PlacedWord]`
  - `entries: Array[WordEntry]`
  - `cells: Array[Vector2i]`
- **파일**: `scripts/resources/grid_data.gd`, `word_pack.gd`, `placed_word.gd`, `game/grid_generator.gd`

---

## 기획서 외 추가 기능

### [FEAT-001] 드래그 하이라이트 랜덤 색상
- **요청**: 드래그 시 파란색 고정 대신, 매 드래그마다 랜덤 색상 사용
- **구현**: `FOUND_COLORS` 팔레트(12색)에서 드래그 시작 시 랜덤 인덱스 선택
- **파일**: `scripts/ui/screens/game_screen.gd`, `game/grid_board.gd`, `game/letter_cell.gd`

### [FEAT-002] 클릭 즉시 셀 하이라이트
- **요청**: 드래그 시작(마우스 누름) 즉시 첫 셀에 색상 표시 (기존은 이동 후 표시)
- **구현**: `_on_drag_started`에서 시작 셀에 즉시 `set_visual_state(DRAGGING, color_index)` 호출
- **파일**: `scripts/ui/screens/game_screen.gd`

---

## Phase 2: 게임 흐름 & 화면 전환 시스템

### [FEAT-003] ScreenManager Autoload (Tab/Push/Popup 네비게이션)
- **요청**: 5탭 네비게이션 + 게임 화면 Push/Pop 구조 구현
- **구현**: `scripts/autoload/screen_manager.gd` 신규 생성
  - `initialize()`: TabLayer/PushLayer/PopupLayer 등록
  - `switch_tab(index)`: 탭 전환
  - `push_screen(path, data)`: PushLayer에 화면 추가
  - `pop_screen()` / `clear_push_stack()`: 뒤로가기
  - `show_popup()` / `hide_popup()`: PopupLayer 관리
- **파일**: `scripts/autoload/screen_manager.gd`

### [FEAT-004] GameController Autoload (게임 FSM)
- **요청**: 게임 시작/클리어/홈 복귀 흐름 통합 관리
- **구현**: `scripts/autoload/game_controller.gd` 신규 생성
  - `start_game(stage, path)`: GameManager 설정 + push GameScreen
  - `complete_game(result)`: pop GameScreen + push ResultScreen
  - `return_to_home()`: clear_push_stack + switch Home 탭
- **파일**: `scripts/autoload/game_controller.gd`

### [FEAT-005] BaseScreen 추상 기반 클래스
- **요청**: 화면 라이프사이클 인터페이스 표준화
- **구현**: `enter(data)` / `exit()` 가상 메서드 제공
- **파일**: `scripts/ui/base_screen.gd`

### [FEAT-006] GameResult 데이터 클래스
- **요청**: 스테이지 클리어 결과를 ResultScreen에 전달
- **구현**: stage/score/grade/coins_earned/hint_count/clear_time/word_pack_path 필드
- **파일**: `scripts/resources/game_result.gd`

### [FEAT-007] MainScene 루트 씬 (레이어 구조)
- **요청**: TabLayer/PushLayer/PopupLayer + BottomTabBar 구조 구축
- **구현**: TabLayer(0) + PushLayer(10) + PopupLayer(20) + BottomTabBar
  - TabLayer 자식 순서: Daily(0), Team(1), Home(2), Collection(3), Shop(4)
- **파일**: `scenes/main_scene.tscn`, `scripts/ui/main_scene.gd`

### [FEAT-008] BottomTabBar 컴포넌트
- **요청**: 하단 5탭 네비게이션 바
- **구현**: 버튼 5개 동적 생성, 활성 탭 색상 강조, `tab_selected(index)` 시그널
- **파일**: `scenes/components/bottom_tab_bar.tscn`, `scripts/ui/components/bottom_tab_bar.gd`

### [FEAT-009] HomeScreen (타이틀 화면 대체)
- **요청**: BaseScreen 기반 홈 화면, GameController.start_game() 연동
- **구현**: 플레이 버튼 → GameController.start_game(), enter()에서 코인 갱신
- **파일**: `scenes/screens/home_screen.tscn`, `scripts/ui/screens/home_screen.gd`

### [FEAT-010] ResultScreen (스테이지 클리어 결과 화면)
- **요청**: 등급/점수/획득코인 표시 + 홈으로/다음 스테이지 버튼
- **구현**: `enter(data["result"])` → GameResult 파싱, 버튼 → GameController 호출
- **파일**: `scenes/screens/result_screen.tscn`, `scripts/ui/screens/result_screen.gd`

### [FEAT-011] 플레이스홀더 화면 4개
- **요청**: Daily/Team/Collection/Shop 탭 화면 (추후 구현 예정)
- **구현**: "준비 중" 레이블만 표시하는 BaseScreen 상속 씬
- **파일**: `scenes/screens/daily_screen.tscn`, `team_screen.tscn`, `collection_screen.tscn`, `shop_screen.tscn`

### [REFACTOR-003] GameScreen → BaseScreen 기반 리팩터
- **이유**: ScreenManager의 push_screen/pop_screen 라이프사이클 연동
- **변경**:
  - `extends Control` → `extends BaseScreen`
  - `_ready()`의 start_stage 호출 → `enter()` 오버라이드로 이동
  - `_on_stage_complete()`: `await + change_scene` → `GameController.complete_game(result)`
  - `_on_back_pressed()`: 직접 씬 전환 → `GameController.return_to_home()`
- **파일**: `scripts/ui/screens/game_screen.gd`

### [REFACTOR-004] project.godot 메인 씬 변경 + Autoload 추가
- **변경**: `run/main_scene` = `title_screen.tscn` → `main_scene.tscn`
- **추가 Autoload**: ScreenManager, GameController (총 8개)
- **파일**: `project.godot`

---

## 코드 구조 개선

### [REFACTOR-001] call_deferred로 레이아웃 타이밍 수정
- **이유**: `_ready()`에서 즉시 `start_stage()` 호출 시 `GridBoard` 크기가 0일 수 있음
- **수정**: `call_deferred("start_stage", ...)` 사용
- **파일**: `scripts/ui/screens/game_screen.gd`

### [REFACTOR-002] 스테이지 클리어 후 타이틀 복귀 (Phase 1 임시)
- **이유**: 기획서 Phase 2의 ResultPopup이 미구현이므로 임시 처리
- **구현**: 3초 대기 후 타이틀 화면으로 복귀
- **파일**: `scripts/ui/screens/game_screen.gd`
- **비고**: Phase 2 구현 시 ResultPopup으로 교체 예정
