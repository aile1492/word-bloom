# WordPuzzle Godot — Claude Code 가이드

## 프로젝트 기본 정보

- **엔진**: Godot 4.6 Stable (Standard, **NOT .NET**)
- **렌더러**: GL Compatibility (GLES3)
- **언어**: GDScript
- **플랫폼**: Android, iOS, Android TV, Fire TV
- **프로젝트 경로**: `C:/Users/0/ai프로젝트/wordPuzzle_Godot/Puzzle/word-puzzle`
- **기획서 경로**: `C:/Users/0/ai프로젝트/wordPuzzle_Godot/기획서 최종본/` — **읽기 전용, 수정 금지**

## 실행 방법

Godot 에디터에서 프로젝트를 열고 F5로 실행한다.
CLI 실행이 필요하면 `godot --path .` 사용.

## 폴더 구조

```
res://
├── scenes/
│   ├── screens/      # 화면별 .tscn (title_screen, game_screen 등)
│   ├── game/         # 게임 컴포넌트 (letter_cell.tscn 등)
│   ├── components/   # 재사용 컴포넌트
│   └── popups/       # 팝업
├── scripts/
│   ├── autoload/     # 싱글톤 6개 (항상 로드됨)
│   ├── game/         # 게임 핵심 로직
│   ├── ui/screens/   # 화면 컨트롤러
│   ├── resources/    # GDScript Resource 정의
│   └── utils/        # 유틸리티
├── data/
│   ├── words/ko/     # 한국어 단어 JSON (8테마)
│   └── words/en/     # 영어 단어 JSON (8테마)
└── assets/
    ├── fonts/
    ├── icons/
    ├── audio/
    └── backgrounds/  # 실사 사진 (테마별 .jpg)
```

## Autoload 싱글톤

| 이름 | 역할 |
|------|------|
| `GameManager` | 씬 전환, 스테이지 상태 관리 |
| `SaveManager` | `user://save_data.json` 읽기/쓰기 |
| `AudioManager` | BGM/SFX 재생 |
| `CoinManager` | 코인 잔액, 힌트 소비 (HINT_COST=100) |
| `AdManager` | 광고 스텁 (AdMob 미연동) |
| `LayoutManager` | 입력 모드 감지 (TOUCH/MOUSE/DPAD) |

## 핵심 설계 결정

- **통화**: 코인(Coin) 단일. Gem 없음. 힌트 1회 = 100코인
- **하단 탭 5개**: Daily(0) | Team(1) | Home(2, 기본) | Collection(3) | Shop(4)
- **배경**: 실사 사진 (Unsplash/Pexels CC0, 테마별)
- **팀 기능**: Lv.44 해금 (현재는 잠금)
- **입력**: 터치/마우스 드래그, 8방향 스냅 (22.5° bin)
- **격자**: 스테이지 4개 단위로 크기 증가 (GridCalculator)

## 코딩 표준

### 타입 명시 (필수)
```gdscript
# 항상 Array 원소 타입을 명시한다
var placed_words: Array[PlacedWord] = []   # ✅
var placed_words: Array = []               # ❌

# Variant에서 메서드 호출 시 := 사용 금지
var upper_ch: String = ch.to_upper()      # ✅
var upper_ch := ch.to_upper()             # ❌ (ch가 Variant인 경우)
```

### 네이밍
- 클래스명: `PascalCase` (`GridBoard`, `WordPack`)
- 함수/변수: `snake_case`
- 시그널 핸들러: `_on_노드명_시그널명()` 형태
- private: `_` 접두사

### 씬-스크립트 연결
- `@onready` 경로는 `.tscn` 노드 구조와 반드시 일치해야 함
- 새 씬 생성 시 스크립트의 `@onready` 변수 경로를 먼저 확인

### call_deferred 사용
- `_ready()`에서 레이아웃 크기 의존 코드는 `call_deferred()`로 지연 호출

## 단어 데이터 JSON 포맷

```json
{
  "theme": "animals",
  "language": "ko",
  "words": [
    {"word": "호랑이", "length": 3, "display": "호랑이", "category": ""}
  ]
}
```

- `length`, `display` 필드는 `WordPack`이 자체 계산하므로 없어도 무관
- 영어 단어는 대문자로 저장 (`"TIGER"`)

## Android 빌드 (CRITICAL)

**UID 충돌 방지를 위해 반드시 클린 빌드 도구 사용:**
```bash
python "C:\Users\0\ai프로젝트\_build_tools\godot_clean_build.py" wordPuzzle_Godot --apk
python "C:\Users\0\ai프로젝트\_build_tools\godot_clean_build.py" wordPuzzle_Godot --aab
python "C:\Users\0\ai프로젝트\_build_tools\godot_clean_build.py" wordPuzzle_Godot --install
```

**절대 하지 말 것:**
- `.godot/imported/` 삭제 금지
- `gradlew clean` 후 `local.properties` 복구 안 하는 것 금지
- `android/build/build.gradle`의 `assetPacks` 주석 해제 금지
- `android/build/settings.gradle`의 `assetPackInstallTime` 주석 해제 금지

**빌드 결과물 위치:**
- APK: `C:\Users\0\ai프로젝트\wordPuzzle_Godot\build\apk\`
- AAB: `C:\Users\0\ai프로젝트\wordPuzzle_Godot\build\aab\`
- 패키지명: `com.wordbloom.game`

## 금지 사항

- 기획서 파일 수정 금지 (읽기만 허용)
- `.godot/` 폴더 수동 수정 금지 (에디터가 자동 관리)
- `export_presets.cfg` 커밋 금지 (`.gitignore`에 포함됨)
- 민감 정보(키스토어, API 키) 커밋 금지
