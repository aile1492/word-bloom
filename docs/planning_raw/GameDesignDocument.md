# Word Search Puzzle - 게임 기획서

**문서 버전**: v6.0
**작성일**: 2026-03-06
**최종 수정일**: 2026-03-09
**목표 개발 기간**: 7일 (1주일)
**플랫폼**: Unity 6 LTS — Android / iOS / Windows
**관련 문서**: UIDesignDocument.md, TechnicalSpecDocument.md, SoundDesignDocument.md, WordDataPipeline.md, Plan_v6_UI_Overhaul.md

---

## 1. 게임 개요

### 1.1 컨셉

격자(Grid) 안에 숨겨진 단어를 찾아내는 클래식 Word Search 퍼즐 게임.
플레이어는 가로, 세로, 대각선 방향으로 나열된 단어를 드래그(또는 탭)하여 선택한다.
모든 단어를 찾으면 스테이지가 클리어된다.

### 1.2 핵심 재미 요소

| 요소 | 설명 |
|------|------|
| 탐색의 쾌감 | 복잡한 글자 속에서 단어를 발견하는 순간의 만족감 |
| 시간 압박 | 타이머 모드를 통한 긴장감 |
| 코인 수집과 성장 | 스테이지 클리어로 코인 획득, 테마 해금, 통계 기록 |
| 난이도 곡선 | 격자 크기와 단어 수가 점진적으로 증가 |
| 캐릭터 애착 | 프리셋 아바타 선택, 홈 화면 인사 메시지 |

### 1.3 타겟 유저

전 연령대 캐주얼 퍼즐 유저. 특히 단어 게임, 두뇌 훈련에 관심 있는 유저.

---

## 2. 핵심 게임플레이 메카닉

### 2.1 격자(Grid) 시스템 — 스테이지 기반 점진적 성장

난이도는 단일 난이도로 통합하되, 스테이지가 진행될수록 격자 크기와 단어 수가 자동으로 증가한다.

#### 격자 크기 증가 규칙

- 시작 크기: 5×5
- 4스테이지마다 x축(가로) +1칸 증가, 그 다음 4스테이지는 y축(세로) +1칸 증가 (x/y 번갈아 적용)
- 상한: 10×10 (스테이지 약 41 이상은 10×10 고정)

| 스테이지 | 격자 크기 | 단어 수 |
|---------|-----------|---------|
| 1 ~ 4   | 5×5       | 4       |
| 5 ~ 8   | 6×5       | 4       |
| 6 ~ 8   | 6×5       | 5 (6스테이지부터) |
| 9 ~ 12  | 6×6       | 5 ~ 6   |
| 13 ~ 16 | 7×6       | 6 ~ 7   |
| 17 ~ 20 | 7×7       | 7 ~ 8   |
| 21 ~ 24 | 8×7       | 8       |
| 25 ~ 28 | 8×8       | 9       |
| 29 ~ 32 | 9×8       | 9 ~ 10  |
| 33 ~ 36 | 9×9       | 10      |
| 37 ~ 40 | 10×9      | 10 ~ 11 |
| 41+     | 10×10     | 최대 12  |

#### 계산 공식

```
groupIndex  = floor((stage - 1) / 4)
xIncrements = floor((groupIndex + 1) / 2)
yIncrements = floor(groupIndex / 2)
gridWidth   = min(5 + xIncrements, 10)
gridHeight  = min(5 + yIncrements, 10)

wordCount   = min(4 + floor((stage - 1) / 5), 12)
```

예시 검증:

| stage | groupIndex | gridWidth | gridHeight | wordCount |
|-------|-----------|-----------|------------|-----------|
| 1     | 0         | 5         | 5          | 4         |
| 5     | 1         | 6         | 5          | 4         |
| 6     | 1         | 6         | 5          | 5         |
| 9     | 2         | 6         | 6          | 5         |
| 11    | 2         | 6         | 6          | 6         |
| 17    | 4         | 7         | 7          | 7         |
| 25    | 6         | 8         | 8          | 8         |
| 41    | 10        | 10        | 10         | 12        |

#### 단어 최대 길이 제약

단어 길이는 격자 크기에 비례하여 제한한다. 너무 긴 단어는 5×5 격자에 배치가 불가능하기 때문이다.

| 격자 크기 | 영어 단어 최대 길이 | 한국어 단어 최대 음절 |
|----------|-----------------|------------------|
| 5×5      | 5글자           | 4음절            |
| 6×5 ~ 6×6 | 6글자         | 4음절            |
| 7×6 이상  | 7글자           | 5음절            |

### 2.2 단어 배치 방향

단어는 아래 8방향으로 배치될 수 있다. 단일 난이도이므로 모든 방향이 항상 허용된다.

| 방향 | 벡터 |
|------|------|
| 가로 정방향 | (1, 0) |
| 가로 역방향 | (-1, 0) |
| 세로 정방향 | (0, 1) |
| 세로 역방향 | (0, -1) |
| 대각선 우하 | (1, 1) |
| 대각선 좌상 | (-1, -1) |
| 대각선 우상 | (1, -1) |
| 대각선 좌하 | (-1, 1) |

방향 제한: 단일 난이도에서 위 8방향 전체를 항상 사용한다. 역순 배치(단어를 뒤집어서 배치)도 허용한다.

### 2.3 단어 선택 인터랙션

1. **드래그 방식**: 첫 글자에서 마우스/터치를 누른 채 끝 글자까지 드래그
2. **탭 방식**: 첫 글자 탭 → 끝 글자 탭 (모바일 대응)
3. 선택 중 실시간으로 글자가 하이라이트 표시
4. 올바른 단어 선택 시 색상 고정 + 단어 목록에서 체크 표시
5. 잘못된 선택 시 하이라이트 해제 (페널티 없음)

### 2.4 빈 칸 채우기 알고리즘

단어 배치 후 남은 빈 칸은 단순 랜덤이 아닌, 난이도를 높이는 교란 기법을 적용하여 채운다.

#### 2.4.1 기본 채우기 (모든 스테이지)

- 영어: 격자에 배치된 정답 단어에 사용된 알파벳 비율을 반영하여 빈칸을 채운다. 정답에 없는 Q, Z 같은 희귀 글자는 배제하여, 플레이어가 "이 글자는 정답과 무관하다"는 소거법을 사용할 수 없게 한다.
- 한국어: 현재 테마 WordPack에서 추출한 음절 풀 + 동일 초성 교란 글자를 사용한다 (기존 방식 유지).

#### 2.4.2 False Lead (가짜 단서) — 스테이지 11 이상

스테이지 11 이상부터 빈칸 채우기 시 "가짜 단서(False Lead)"를 의도적으로 심는다.

| 항목 | 규칙 |
|------|------|
| 활성화 조건 | stage >= 11 |
| 대상 | 미배치된 정답 단어 중 랜덤 1~2개 |
| 방법 | 해당 단어의 첫 2~3글자를 격자 빈칸에 연속 배치하되, 나머지 글자는 일치하지 않도록 한다 |
| 상한 | 스테이지당 최대 2개의 False Lead |
| 예시 (영어) | 정답 "TIGER"에 대해 "TIG" + 무관한 글자를 배치 |
| 예시 (한국어) | 정답 "호랑이"에 대해 "호랑" + 무관한 음절을 배치 |

False Lead는 단어 발견 난이도를 높이되, 플레이어가 학습하면 극복 가능한 수준으로 제한한다.

#### 2.4.3 검증

의도하지 않은 단어가 우연히 생성되지 않도록 검증 로직을 적용한다.

---

## 3. 게임 모드

### 3.1 Classic Mode (기본 모드)

- 시간 제한 없음
- 모든 단어를 찾으면 클리어
- 소요 시간 기록
- 힌트 사용 가능 (코인 소모)
- **v6.0**: 홈 화면(TitleScreen)의 Play 버튼에서 바로 시작되는 기본 모드

### 3.2 Time Attack Mode

- 단일 난이도 기준 제한 시간 고정

| 항목 | 값 |
|------|----|
| 제한 시간 | 180초 |
| 단어 발견 보너스 | +10초 |

- 단어를 찾을 때마다 보너스 시간 추가 (+10초)
- 시간 내 모든 단어를 찾으면 클리어, 실패 시 게임 오버

### 3.3 Daily Challenge

- 매일 1개의 고정 퍼즐 제공
- 전체 유저 동일 조건
- 완료 시간 기준 랭킹 집계 (로컬 기록)
- 연속 플레이 일수(Streak) 추적
- **v6.0**: Bottom Tab Bar의 전용 탭에서 접근. 레벨 게이트 적용:

| 항목 | 값 |
|------|----|
| 해금 조건 | Classic Mode 스테이지 24 클리어 |
| 잠금 상태 UI | 자물쇠 아이콘 + "레벨 24를 완료하세요!" 메시지 |
| 해금 후 UI | 캘린더 스타일 헤더 + 현재 연속 기록(Streak) + 최고 기록 표시 |

### 3.4 스테이지 연속 진행

클리어 후 결과 화면에서 **[Next]** 버튼을 누르면 다음 스테이지가 즉시 시작된다.
테마는 매 스테이지마다 해금된 테마 중 랜덤으로 자동 선택되며, 직전 스테이지와 다른 테마가 우선 선택된다.

| 항목 | 동작 |
|------|------|
| Next 버튼 | 다음 스테이지 시작 (StageNumber +1, 새 랜덤 테마) |
| Retry 버튼 | 동일 스테이지 번호로 새 퍼즐 시작 (테마 새로 랜덤 선택) |
| Home 버튼 | 타이틀 화면으로 복귀 |
| 실패 시 (Time Attack) | Next 버튼 비활성화, Retry/Home만 표시 |

- 매 스테이지마다 테마가 랜덤으로 바뀌므로 플레이어는 다양한 주제의 단어를 경험한다.
- GameController는 스테이지 전환 시 자동으로 상태를 초기화(Idle)한 뒤 새 게임을 시작한다.

### 3.5 Sawtooth(톱니) 난이도 패턴

스테이지 진행 시 난이도가 단조 증가하면 플레이어 피로감이 누적된다. 이를 방지하기 위해 주기적으로 "휴식 스테이지(Rest Stage)"를 배치하는 Sawtooth 패턴을 적용한다.

| 항목 | 규칙 |
|------|------|
| 패턴 주기 | 매 10 스테이지마다 1회 |
| 휴식 스테이지 번호 | stage % 10 == 0 인 스테이지 (10, 20, 30, 40, ...) |
| 휴식 효과 | wordCount를 2 감소 (최소 StartWordCount=4 이하로 내려가지 않음) |
| 격자 크기 | 변동 없음 (정상 공식 유지) |
| 배치 방향 | 변동 없음 (8방향 + 역순, 단일 난이도 유지) |
| 시각 피드백 | 결과 화면에서 "Bonus Stage!" 표시 |

```
난이도 곡선 (예시):

wordCount
   12 |                                        xxxxxxx
   11 |                                  xxxxxx
   10 |                            xxxxxx
    9 |                      xxxxxx        \
    8 |                xxxxxx        (rest)  ------
    7 |          xxxxxx        \
    6 |    xxxxxx        (rest) ------
    5 | xxxx        \
    4 |        (rest) ------
      +----+----+----+----+----+----+----+----+--->
      1    5   10   15   20   25   30   35   40  stage
```

휴식 스테이지는 플레이어에게 "숨 돌릴 기회"를 제공하여 지루함과 좌절감 사이의 균형을 유지한다.

### 3.6 경량 DDA (Dynamic Difficulty Adjustment)

복잡한 ML 모델 없이, 플레이어의 최근 성과를 기반으로 단어 수를 미세 조정하는 경량 적응형 난이도 시스템을 적용한다.

#### 3.6.1 측정 지표

| 지표 | 수집 방식 |
|------|-----------|
| 클리어 시간 | GameResult.TotalTime |
| 힌트 사용 횟수 | GameResult.HintsUsed |
| 실패 여부 | Time Attack 시간 초과 |

#### 3.6.2 조정 규칙

평가 대상: 직전 3스테이지. stage <= 3일 때는 DDA 조정하지 않음 (기본 공식 유지).

메트릭:
- 평균 클리어 시간 = 직전 3스테이지 TotalTime 합 / 3
- 힌트 사용 여부 = 직전 3스테이지 중 하나라도 HintsUsed > 0

| 조건 | 조정 |
|------|------|
| 직전 3스테이지 모두 힌트 미사용 AND 평균 클리어 시간 < DDA_FAST_CLEAR_THRESHOLD(90초) | wordCount +1 (상한 MaxWordCount 이내) |
| 직전 3스테이지 중 2회 이상 실패 OR 평균 힌트 사용 >= 2회 | wordCount -1 (하한 StartWordCount 이상) |
| 그 외 | 조정 없음 (기본 공식 유지) |

Constants 참조: DDA_FAST_CLEAR_THRESHOLD = 90 (TechSpec GameConstantsAsset에 정의)

#### 3.6.3 제약

- DDA 조정은 기본 공식 대비 **최대 +-2** 범위 내에서만 적용된다
- 절대 하한: StartWordCount (4), 절대 상한: MaxWordCount (12)
- 휴식 스테이지(Rest Stage)에는 DDA 조정을 적용하지 않는다
- Daily Challenge에는 DDA를 적용하지 않는다 (모든 유저 동일 조건 보장)

---

## 4. 콘텐츠 시스템

### 4.1 단어 데이터 소싱 전략

수동으로 단어를 작성하는 방식 대신, 오픈소스 단어 목록을 활용하여 대규모 단어 풀을 확보한다.
모든 단어 데이터는 **빌드 타임에 JSON으로 번들링**하며, 런타임 서버 의존 없이 동작한다.

#### 4.1.1 영어 단어 소스

| 소스 | 설명 | 활용 방식 |
|------|------|-----------|
| [imsky/wordlists](https://github.com/imsky/wordlists) | 주제별로 분류된 영어 단어 목록 | 테마별 JSON 변환 후 내장 |
| [lpmi-13/machine_readable_wordlists](https://github.com/lpmi-13/machine_readable_wordlists) | 13개 카테고리, JSON/YML 포맷 제공 | 동물, 음식, 과학 등 직접 활용 |
| [felixfischer/categorized-words](https://github.com/felixfischer/categorized-words) | ~90,000 단어, 7개 카테고리 분류 | 대규모 풀 보충용 |
| [dwyl/english-words](https://github.com/dwyl/english-words) | 479,000 영어 단어 전체 목록 | 빈 칸 검증용 사전 (의도치 않은 단어 감지) |

#### 4.1.2 한국어 단어 소스

| 소스 | 설명 | 활용 방식 |
|------|------|-----------|
| [acidsound/korean_wordlist](https://github.com/acidsound/korean_wordlist) | 한국어 사전 JSON (단어 + 뜻 포함) | 주제별 필터링 후 JSON 내장 |
| 국립국어원 우리말샘 API | 주제별 검색 가능, 무료 API 키 발급 | **빌드 스크립트**로 사전 수집 → JSON 변환 |
| [ko-nlp/Korpora](https://github.com/ko-nlp/Korpora) | 한국어 코퍼스 모음 (Python 패키지) | 명사 추출 → 주제 분류 스크립트 활용 |

**핵심**: 국립국어원 API는 런타임에 호출하지 않는다. 빌드 시 Python 스크립트로 주제별 단어를 수집하고 JSON 파일로 저장하여 게임에 내장한다. 따라서 서버 의존 없이 동작한다.

#### 4.1.3 단어 데이터 파이프라인

```
[오픈소스 목록 / API]
        |
        v
  빌드 스크립트 (Python)
  - 주제별 필터링
  - 글자 수 필터 (3~12자)
  - 부적절한 단어 제거
  - 중복 제거
        |
        v
  /data/words/en/animals.json
  /data/words/en/food.json
  /data/words/ko/animals.json
  /data/words/ko/food.json
        |
        v
  게임 번들에 포함 (서버 불필요)
```

#### 4.1.4 단어 JSON 포맷

```json
{
  "theme": "animals",
  "language": "en",
  "wordCount": 150,
  "words": [
    { "word": "TIGER", "length": 5 },
    { "word": "DOLPHIN", "length": 7 },
    { "word": "PENGUIN", "length": 7 }
  ]
}
```

한국어 JSON 포맷:

```json
{
  "theme": "animals",
  "language": "ko",
  "wordCount": 120,
  "words": [
    { "word": "호랑이", "length": 3, "display": "호랑이", "displayLength": 3 },
    { "word": "돌고래", "length": 3, "display": "돌고래", "displayLength": 3 },
    { "word": "펭귄", "length": 2, "display": "펭귄", "displayLength": 2 }
  ]
}
```

한국어는 `display` 필드에 자모 분리형을 함께 저장하여, 격자 배치 시 자모 단위로 활용할 수 있도록 한다.

### 4.2 테마별 단어 팩

| 테마 | 영어 예시 | 한국어 예시 | 해금 조건 |
|------|-----------|-------------|-----------|
| Animals | TIGER, EAGLE, DOLPHIN... | 호랑이, 독수리, 돌고래... | 기본 해금 |
| Food | PIZZA, SUSHI, BREAD... | 김밥, 떡볶이, 불고기... | 기본 해금 |
| Space | PLANET, COMET, NEBULA... | 행성, 혜성, 성운... | Classic 5회 클리어 |
| Sports | SOCCER, TENNIS, BOXING... | 축구, 야구, 수영... | Classic 10회 클리어 |
| Science | ATOM, MOLECULE, GRAVITY... | 원자, 분자, 중력... | Classic 20회 클리어 |
| Music | RHYTHM, MELODY, HARMONY... | 리듬, 선율, 화음... | Time Attack 5회 클리어 |
| Ocean | WHALE, CORAL, TRENCH... | 고래, 산호, 해구... | Daily Challenge 7일 연속 |
| Mythology | PHOENIX, HYDRA, TITAN... | 봉황, 해태, 도깨비... | 전체 테마 1회 이상 클리어 |

각 테마는 오픈소스 데이터 기반으로 **최소 100개 이상**의 단어 풀을 확보한다.
플레이 시 스테이지별 필요 단어 수만큼 랜덤 추출하므로, 매 플레이마다 다른 조합이 생성된다.

#### 4.2.1 스테이지별 테마 랜덤 선택

플레이어가 직접 테마를 선택하는 방식을 폐지한다. 대신 매 스테이지마다 해금된 테마 중 랜덤으로 1개가 자동 선택된다.

| 항목 | 규칙 |
|------|------|
| 선택 풀 | 해금된(UnlockedThemes) 테마 목록 |
| 선택 방식 | 랜덤 (직전 스테이지와 동일 테마 회피: 해금 테마 2개 이상이면 직전과 다른 테마 선택) |
| Daily Challenge | SeededRandom으로 테마 결정 (전체 유저 동일) |
| 결과 화면 표시 | 해당 스테이지의 테마명을 표시 |
| 시드 | Classic/TimeAttack: System.Random, Daily: SeededRandom(dailySeed + stageNumber) |
| dailySeed 결정 | SeededRandom.GetDailySeed() = YYYYMMDD 정수 (예: 20260307) |
| Daily Stage N | SeededRandom(dailySeed + stageNumber)로 테마 및 격자 시드 결정 |
| 동일 날짜 보장 | 모든 플레이어가 같은 날짜, 같은 스테이지에서 동일 퍼즐 체험 |

ThemeSelectScreen, DifficultySelectScreen, ModeSelectScreen은 모두 제거된다. v6.0에서는 Bottom Tab Bar 기반 내비게이션을 사용한다:

```
v6.0 화면 플로우:

BottomTabBar (4 tabs: Daily / Home / Collection* / Stats)
  (* = disabled, "Coming Soon")

Home (TitleScreen) --[Play]--> GameScreen (Classic, 테마 자동 선택)
  |                                |
  +-> Settings (popup)             +-> ResultScreen
  +-> Avatar Select (popup)             |
                                        +-> [Next] GameScreen (다음 스테이지)
                                        +-> [Home] TitleScreen

Daily Challenge Tab --[Play]--> GameScreen (daily seed)
Stats Tab --> StatsScreen
```

Note: ModeSelectScreen은 v6.0에서 제거된다. Classic Mode는 홈 화면의 Play 버튼으로 바로 시작하며, Time Attack은 GameScreen 내 모드 토글 또는 홈 화면 서브 메뉴로 접근한다.

### 4.3 다국어 지원

| 버전 | 언어 | 격자 방식 | 데이터 소스 |
|------|------|-----------|-------------|
| v1.0 | 영어 (English) | 알파벳 1글자 = 1칸 | GitHub 오픈소스 목록 |
| v1.1 | 한국어 | **음절 완성형**: 완성된 글자 1자 = 1칸 | 국립국어원 + GitHub |

#### 4.3.1 한국어 격자 처리 방식

한국어는 **음절 완성형**(호, 랑, 이)을 사용한다. 자모 분리형(ㅎ, ㅗ, ㄹ...)은 사용하지 않는다.

이유:
- 자모 분리형은 단어를 시각적으로 인식하기 매우 어렵다
- 완성형 음절 단위가 직관적이며, 플레이어가 단어를 빠르게 판별할 수 있다
- 격자 크기를 적절히 조절(8x8 이상)하면 완성형으로도 충분한 밀도를 확보할 수 있다

예시 (호랑이):
```
음절형: [호][랑][이]         → 3칸 (직관적, 빠른 인식)
자모형: [ㅎ][ㅗ][ㄹ][ㅏ][ㅇ][ㅇ][ㅣ] → 7칸 (인식 어려움, 미사용)
```

#### 4.3.2 한국어 빈 칸 채우기

음절 완성형 방식에서는 빈 칸을 **일상에서 자주 사용하는 한글 완성형 음절**만 사용하여 채운다.

**허용 음절 기준:**
- 일상 생활에서 빈번하게 사용되는 음절만 허용한다
- 예: 가, 나, 다, 라, 마, 바, 사, 아, 자, 차, 카, 타, 파, 하, 고, 노, 도, 로, 모, 보, 소, 오, 조, 호, 구, 누, 두, 루, 무, 부, 수, 우, 주, 추, 쿠, 투, 푸, 후, 기, 니, 디, 리, 미, 비, 시, 이, 지, 치, 키, 티, 피, 히 등
- **금지**: 묈, 뭏, 뭖 같이 실제 사용되지 않는 희귀 조합 음절 배제
- 0xAC00~0xD7A3 전체 범위(11,172자) 중 랜덤 선택 방식 사용 금지

**구현 방식 (WordPack 기반 음절 추출):**
- GridGenerator.FillEmptyCells() 호출 시 현재 테마의 WordPack을 함께 전달한다
- WordPack 내 모든 단어(words[] 배열)에서 음절을 추출하여 고유 음절 풀(HashSet)을 빌드한다
- 예: animals 테마 단어가 호랑이, 돌고래, 코끼리이면 풀 = {호, 랑, 이, 돌, 고, 래, 코, 끼, 리}
- 빈칸은 이 풀에서 랜덤 선택하여 채운다
- 풀이 너무 작을 경우(10자 미만)에는 기본 보조 음절 목록(가,나,다,라,마,바,사,아,자,차,타,파,하,고,노,도,로,모,보,소,오,조,호 등 50자)을 병합한다
- 0xAC00~0xD7A3 전체 범위 랜덤 선택은 절대 금지한다

#### 4.3.3 한국어 격자 크기 조정

음절형은 단어 길이가 짧아지므로, 한국어 모드에서는 격자 크기를 조정한다.

스테이지 기반 성장 방식을 사용한다. 한국어 모드에서도 영어와 동일한 격자 크기 공식을 적용한다.
음절 완성형은 1칸 = 1음절이므로 영어와 칸 수가 동일하며, 단어 길이 제약(최대 5음절)만 별도 적용한다.

| 스테이지 구간 | 격자 크기 | 단어 수 |
|-------------|-----------|---------|
| 1 ~ 4       | 5×5       | 4       |
| 5 ~ 8       | 6×5       | 4~5     |
| 9 ~ 12      | 6×6       | 5~6     |
| 17 ~ 20     | 7×7       | 7~8     |
| 41+         | 10×10     | 12 (상한) |

---

## 5. UI/UX 설계

### 5.1 화면 구성 (v6.0 Game Screen)

```
+--------------------------------------------------+
|  [<]     Level 16      [Coin: 180]  [Cart]       |
+--------------------------------------------------+
|  "74.46% of players solved"                       |
|                                                    |
|  +----------------------------------------------+ |
|  |       [Theme Banner: 매우의 동의어]            | |
|  +----------------------------------------------+ |
|  | 굉장히  극도로  상당히  심하게                  | |
|  | (엄청나게) 지극히  최대로  한없이               | |
|  +----------------------------------------------+ |
|                                                    |
|  +----------------------------------------------+ |
|  |                                              | |
|  |  극  지  극  히  지  극                        | |
|  |  한  극  도  로  심  게                        | |
|  |  없  상  엄  심  나  최                        | |
|  |  이  굉  당  청  하  상                        | |
|  |  대  장  (엄) 히  하  게                       | |
|  |  도  히  최  최  대  로                        | |
|  |                                              | |
|  +----------------------------------------------+ |
|                                                    |
|  [Shuffle]  [Hint:200W]  [Hint:100W]  [Refresh]  |
+--------------------------------------------------+
```

### 5.2 주요 화면 목록 (v6.0)

| 화면 | 유형 | 설명 |
|------|------|------|
| TitleScreen (Home) | Tab Screen | 아바타 카드, 코인 표시, 스테이지 진행 카드, Play 버튼. 일러스트 배경. |
| GameScreen | Push Screen | 테마 배너 + 단어 목록(상단) + 격자 카드(중앙) + 힌트 바(하단, 코인 소모). |
| ResultScreen | Push Screen | 클리어 시간, 점수, 랭크, 코인 보상 표시 + Home / Retry / Next 버튼 |
| DailyChallengeScreen | Tab Screen | 캘린더 UI, Streak 카운터, 레벨 게이트 잠금 (Lv.24). 녹색 자연 배경. |
| StatsScreen | Tab Screen | 누적 통계, 코인 총 획득량, 테마별 진행률 |
| SettingsPopup | Popup | 음악/효과음 토글, 언어 선택, 다크/라이트 테마. 모달 오버레이. |
| AvatarSelectPopup | Popup | 6종 프리셋 아바타 선택 그리드 |

**v6.0 제거된 화면:** ModeSelectScreen, ThemeSelectScreen, DifficultySelectScreen
**v6.0 전환된 화면:** SettingsScreen -> SettingsPopup (전체 화면에서 팝업으로)

### 5.3 Bottom Tab Bar

| 탭 | 아이콘 | 화면 | 상태 |
|----|--------|------|------|
| 매일 도전 | Calendar | DailyChallengeScreen | Active (Lv.24 이후 해금) |
| 홈 | Home | TitleScreen | Active (기본 탭) |
| 컬렉션 | Book | -- | Disabled ("Coming Soon") |
| 통계 | Trophy | StatsScreen | Active |

Tab Bar는 GameScreen, ResultScreen, 팝업 화면에서는 숨김 처리된다.

### 5.3 색상 팔레트 (기본 라이트 테마)

| 용도 | 색상 코드 |
|------|-----------|
| 배경 | #F5F5F5 |
| 격자 배경 | #FFFFFF |
| 글자 기본 | #333333 |
| 선택 중 하이라이트 | #FFD54F (노란색 계열) |
| 찾은 단어 색상 1 | #4CAF50 (녹색) |
| 찾은 단어 색상 2 | #2196F3 (파란색) |
| 찾은 단어 색상 3 | #FF5722 (주황색) |
| 찾은 단어 색상 4 | #9C27B0 (보라색) |
| 찾은 단어 색상 5 | #00BCD4 (청록색) |
| 찾은 단어 색상 6 | #E91E63 (분홍색) |

찾은 단어마다 다른 색상을 순환 적용하여 시각적 구분을 제공한다.

---

## 6. 점수 시스템

### 6.1 점수 계산 공식

#### Classic Mode (시간 제한 없음)

| 항목 | 공식 |
|------|------|
| 기본 단어 점수 | 50 + (글자수 x 10) |
| 연속 발견 배율 | 직전 단어 발견 후 10초 이내 -> x1.5 (기본 단어 점수에 적용) |
| 최종 단어 점수 | 기본 단어 점수 x 연속 발견 배율 |
| 스테이지 클리어 보너스 | 힌트 미사용 시 +100점 (스테이지당 1회) |

#### Time Attack Mode

| 항목 | 공식 |
|------|------|
| 기본 단어 점수 | 50 + (글자수 x 10) |
| 시간 보너스 | 남은 시간(초) x 2 (단어 발견 시점 기준) |
| 연속 발견 배율 | 직전 단어 발견 후 10초 이내 -> x1.5 (기본 단어 점수에만 적용) |
| 최종 단어 점수 | (기본 단어 점수 x 연속 발견 배율) + 시간 보너스 |
| 스테이지 클리어 보너스 | 힌트 미사용 시 +100점 (스테이지당 1회) |

### 6.2 등급 판정

| 등급 | 조건 |
|------|------|
| S | 힌트 미사용 + 90초 이내 클리어 |
| A | 힌트 미사용 + 클리어 |
| B | 힌트 1회 사용 + 클리어 |
| C | 힌트 2회 이상 사용 + 클리어 |

---

## 7. 힌트 시스템

### 7.1 힌트 종류

힌트는 1종류만 제공한다. v6.0에서 힌트는 코인을 소모하여 사용한다.

| 힌트 타입 | 효과 | 비용 |
|-----------|------|------|
| 첫 글자 표시 | 미발견 단어 중 1개를 랜덤 선택하여 첫 글자 셀을 HintColor(주황색)로 강조 표시 | 코인 100개 소모 |

### 7.2 힌트 인터랙션 상세

힌트 버튼을 누르면 미발견 단어 중 랜덤 1개의 첫 번째 글자 셀이 HintColor(#FF8F00, 주황색)로 표시된다.

힌트 셀 인터랙션 흐름:

```
[HINT 버튼 탭]
  → 미발견 단어 중 랜덤 선택
  → 선택된 단어의 첫 글자 셀: HintColor(#FF8F00) 배경으로 전환
  → 힌트 잔여 횟수 -1

[플레이어가 힌트 셀을 드래그 시작]
  → 해당 셀의 색상을 Dragging 색상(#2196F3)으로 전환 (드래그 피드백 동일하게 적용)

[드래그 종료 - 정답]
  → 해당 셀 포함 전체 선택 셀이 Found 색상으로 확정
  → HintColor 해제됨 (정상 정답 처리)

[드래그 종료 - 오답 또는 드래그 취소]
  → 해당 셀 다시 HintColor(#FF8F00)로 복원
  → 힌트 표시 유지 (추가 힌트 소모 없음)
```

힌트가 표시된 상태에서 다시 HINT 버튼을 누르면 기존 힌트를 해제하고 다른 미발견 단어의 첫 글자를 새로 표시한다 (힌트 1회 추가 소모).

### 7.3 힌트 사용 조건 (v6.0 코인 기반)

| 항목 | 값 |
|------|----|
| 힌트 비용 | 100 코인 / 1회 |
| 사용 조건 | 보유 코인 >= 100 |
| 코인 부족 시 | 힌트 버튼 비활성화 (회색 처리) + "코인이 부족합니다" 토스트 |

Note: v5.0의 "스테이지당 3회 고정 지급" 방식은 폐지한다. 코인 획득/소비 상세는 섹션 8A 참조.

---

## 8A. 코인 시스템 (v6.0 신규)

### 8A.1 개요

코인은 게임 내 유일한 재화이다. 스테이지 클리어, Daily Challenge 완료 등으로 획득하며, 힌트 사용 시 소모한다.

### 8A.2 코인 획득

| 획득 경로 | 코인량 | 조건 |
|-----------|--------|------|
| 스테이지 클리어 (Classic) | 50 | 매 클리어 시 |
| 스테이지 클리어 보너스 (힌트 미사용) | +30 | 해당 스테이지에서 힌트를 사용하지 않은 경우 |
| S랭크 클리어 보너스 | +50 | S랭크 달성 시 추가 |
| Daily Challenge 완료 | 100 | 매일 1회 |
| 연속 출석 보너스 (Streak) | +20 x (Streak일수, 최대 7) | 연속 3일 이상 Daily 완료 시 |
| 광고 시청 | 50 | **Deferred** (v6.0에서는 미구현, 향후 추가) |

### 8A.3 코인 소비

| 소비 경로 | 코인량 | 설명 |
|-----------|--------|------|
| 힌트 사용 (첫 글자 표시) | 100 | 1회당 |

### 8A.4 초기 지급

| 항목 | 값 |
|------|----|
| 신규 유저 초기 코인 | 300 |

### 8A.5 밸런스 참고

- 스테이지 1회 클리어(힌트 미사용) = 80 코인 획득
- 힌트 1회 사용 = 100 코인 소모
- 약 1.25 스테이지 클리어당 힌트 1회 사용 가능 (적당히 제한적이지만 너무 가혹하지 않은 수준)
- 초기 300 코인 = 힌트 3회분 (기존 v5.0의 "스테이지당 3회"와 유사한 첫 경험 제공)

---

## 8B. 아바타 시스템 (v6.0 신규)

### 8B.1 개요

홈 화면(TitleScreen)에 표시되는 캐릭터 아바타. 프리셋 6종 중 1개를 선택한다.

### 8B.2 프리셋 목록

| Index | 이름 | 설명 |
|-------|------|------|
| 0 | Cat (기본) | 크림색 고양이, 장난스러운 자세 |
| 1 | Dog | 골든 리트리버 강아지, 행복한 표정 |
| 2 | Penguin | 턱시도 펭귄, 통통한 체형 |
| 3 | Fox | 빨간 여우, 영리한 미소 |
| 4 | Rabbit | 하얀 토끼, 긴 귀 |
| 5 | Owl | 갈색 부엉이, 학자풍 |

### 8B.3 인사 메시지

홈 화면에서 아바타 아래에 시간대별 인사 메시지를 표시한다.

| 시간대 | 한국어 | 영어 |
|--------|--------|------|
| 06:00 ~ 11:59 | "좋은 아침이에요, {닉네임}!" | "Good morning, {nickname}!" |
| 12:00 ~ 17:59 | "좋은 오후에요, {닉네임}!" | "Good afternoon, {nickname}!" |
| 18:00 ~ 21:59 | "좋은 저녁이에요, {닉네임}!" | "Good evening, {nickname}!" |
| 22:00 ~ 05:59 | "아직 안 자요? {닉네임}!" | "Still awake, {nickname}?" |

닉네임은 기본값 "Guest_{랜덤5자}" 형태이며, 아바타 선택 팝업에서 수정 가능하다.

### 8B.4 저장

- `SelectedAvatarIndex`: int (0~5)
- `Nickname`: string (최대 12자, 기본: "Guest_{랜덤}")

---

## 8. 데이터 저장

### 8.1 로컬 저장 (PlayerPrefs + JSON)

현재 단계에서는 PlayerPrefs에 JSON 직렬화하여 로컬 저장한다.
향후 서버 DB 연동 시 동일 데이터 구조를 유지하여 마이그레이션한다.

```json
{
  "Stats": {
    "TotalGames": 0,
    "TotalWordsFound": 0,
    "TotalPlayTime": 0,
    "CurrentStreak": 0,
    "TotalCoinsEarned": 0
  },
  "Settings": {
    "SoundEnabled": true,
    "MusicEnabled": true,
    "IsDarkTheme": false,
    "LanguageIndex": 0
  },
  "CoinBalance": 0,
  "SelectedAvatarIndex": 0,
  "CurrentStage": 1,
  "UnlockedThemes": ["animals", "food"],
  "BestTimesList": [
    { "Key": "Classic", "Time": 45.2 },
    { "Key": "TimeAttack", "Time": 120.3 }
  ],
  "DailyStreak": 0,
  "LastPlayDate": ""
}
```

### 8.2 Best Time 기록 시스템

| 항목 | 설명 |
|------|------|
| 저장 키 형식 | `{모드}` (예: `Classic`, `TimeAttack`) — 테마가 랜덤이므로 모드별 통합 기록 |
| 저장 조건 | 스테이지 클리어 시, 기존 기록보다 빠를 때만 갱신 |
| 표시 위치 | StatsScreen에서 모드별 Best Time 표시 |
| 신기록 표시 | 결과 화면에서 IsNewRecord = true 시 "New Record!" 강조 표시 |
| 저장 방식 (현재) | PlayerPrefs + JSON 직렬화 (로컬) |
| 저장 방식 (향후) | 서버 DB 연동 (동일 데이터 구조 유지) |

### 8.3 저장 시점

- 게임 클리어 시 자동 저장 (통계 + Best Time 갱신)
- 설정 변경 시 즉시 저장
- Daily Challenge 완료 시 저장

---

## 9. 사운드 설계

| 이벤트 | 사운드 타입 | 설명 |
|--------|------------|------|
| 글자 선택 중 | 짧은 틱 사운드 | 드래그 중 글자를 지날 때마다 |
| 단어 발견 | 성공 효과음 | 밝고 경쾌한 차임벨 |
| 잘못된 선택 | 부드러운 실패음 | 불쾌하지 않은 톤 |
| 스테이지 클리어 | 팡파레 | 축하 효과음 |
| 타이머 경고 | 틱톡 가속 | 남은 시간 30초 이하 시 |
| BGM | 잔잔한 루프 | 집중을 방해하지 않는 앰비언트 |

---

## 10. 기술 스택 (1주일 개발 기준)

| 항목 | 선택 |
|------|------|
| 엔진 | Unity 6 LTS (6000.x) |
| 언어 | C# (.NET Standard 2.1) |
| UI | Unity UI (uGUI) + TextMeshPro |
| 렌더링 | URP (Universal Render Pipeline) |
| 입력 | Unity Input System (New) |
| 상태 관리 | PlayerPrefs + JSON 직렬화 (서버 불필요) |
| 빌드 대상 | Android / iOS / Windows |

---

## 11. 1주일 개발 스케줄

| 일차 | 작업 내용 | 산출물 |
|------|-----------|--------|
| Day 1 | 프로젝트 셋업 + 격자 생성 알고리즘 구현 | 격자 자동 생성 + 단어 배치 로직 |
| Day 2 | 단어 선택 인터랙션 (드래그/탭) 구현 | 마우스/터치 이벤트 처리 완료 |
| Day 3 | 게임 로직 완성 (정답 판정, 클리어 조건, 점수) | Classic Mode 플레이 가능 |
| Day 4 | UI 구현 (화면 전환, 메뉴, 결과 화면) | 전체 화면 플로우 완성 |
| Day 5 | Time Attack + Daily Challenge 모드 구현 | 3개 모드 전부 플레이 가능 |
| Day 6 | 테마 시스템 + 통계 + 힌트 시스템 구현 | 콘텐츠 시스템 완성 |
| Day 7 | 폴리싱 (사운드, 애니메이션, 버그 수정, 반응형 테스트) | v1.0 릴리즈 후보 |

---

## 12. 핵심 알고리즘 명세

### 12.1 격자 생성 알고리즘 (Pseudocode)

```
function generateGrid(size, wordList):
    grid = 빈 격자(size x size) 생성
    placedWords = []

    wordList를 길이 내림차순으로 정렬

    for each word in wordList:
        placed = false
        maxAttempts = 100

        for attempt in 1..maxAttempts:
            direction = 난이도에 허용된 방향 중 랜덤 선택
            startPos = 랜덤 위치 선택

            if canPlace(grid, word, startPos, direction):
                placeWord(grid, word, startPos, direction)
                placedWords.append({word, startPos, direction})
                placed = true
                break

        if not placed:
            격자 크기 부족 경고 로그

    빈 칸을 랜덤 글자로 채움
    의도하지 않은 단어 존재 여부 검증

    return {grid, placedWords}
```

### 12.2 단어 충돌 검사

```
function canPlace(grid, word, startPos, direction):
    for i in 0..word.length-1:
        pos = startPos + direction * i

        if pos가 격자 범위 밖:
            return false

        if grid[pos]가 비어있지 않고 grid[pos] != word[i]:
            return false

    return true
```

단어가 교차하는 경우, 교차 지점의 글자가 동일하면 배치를 허용한다.
이를 통해 크로스워드 스타일의 자연스러운 교차가 발생한다.

---

## 13. 향후 확장 계획

| 버전 | 기능 | 우선순위 | 비고 |
|------|------|----------|------|
| v6.1 | 컬렉션 시스템 (우표/스탬프 수집) | 높음 | Bottom Tab "Collection" 탭 활성화 |
| v6.2 | 광고 보상 시스템 | 높음 | 광고 시청 -> 코인 50 지급 |
| v6.3 | 상점 / IAP | 중간 | 코인 패키지, 광고 제거 상품 |
| v7.0 | 온라인 리더보드 (서버 연동) | 중간 | |
| v7.1 | 커스텀 퍼즐 생성기 (유저가 직접 단어 입력) | 중간 | |
| v7.2 | 멀티플레이어 / 팀 기능 | 낮음 | 서버 인프라 필요 |
| v8.0 | 스토리 모드 (챕터별 진행 + 보스 퍼즐) | 낮음 | |

---

## 14. 리스크 및 대응

| 리스크 | 발생 확률 | 대응 방안 |
|--------|-----------|-----------|
| 격자 생성 시 단어 배치 실패 | 중간 | 재시도 로직 + 격자 크기 동적 확장 |
| 모바일 터치 정확도 문제 | 높음 | 글자 셀 최소 크기 40px 보장 + 탭 모드 제공 |
| 의도치 않은 단어 생성 | 낮음 | dwyl/english-words 사전으로 빈 칸 검증 |
| 오픈소스 단어 데이터 품질 문제 | 중간 | 빌드 스크립트에 부적절 단어 필터 + 수동 검수 리스트 관리 |
| 한국어 자모 분리 정확도 | 중간 | 유니코드 한글 자모 분리 라이브러리 활용 (Hangul.js 등) |
| 1주일 내 미완성 | 중간 | Day 3까지 핵심 루프 완성을 최우선, 한국어는 v1.1에서 별도 적용 |

---

## 15. 데이터 로딩 에러 처리

| 상황 | 동작 |
|------|------|
| WordPack JSON 로드 실패 | 게임 시작 불가, Toast: "단어 데이터 로드 실패. 앱 재시작 후 다시 시도해주세요." |
| 테마 단어 풀 부족 (< 50개) | 경고 로그, 기본 테마(Animals) 강제 사용 |
| 빈 칸 채우기 실패 | 경고 로그, 기본 음절(한국어) 또는 A-Z(영어)로 채우기 |
| GridGenerator 배치 실패 (20회 시도) | 경고 로그, 격자 크기 1단계 증가 후 재시도 |

---

## 부록 A: 단어 데이터 소스 상세

### A.1 영어 오픈소스 활용 예시

**imsky/wordlists** 레포지토리 구조:
```
wordlists/
├── animals.txt      → Animals 테마
├── food.txt         → Food 테마
├── sports.txt       → Sports 테마
├── science.txt      → Science 테마
├── music.txt        → Music 테마
└── ...
```

활용 흐름:
1. GitHub에서 raw txt 다운로드
2. 빌드 스크립트로 글자 수 필터링 (3~12자)
3. 대문자 변환 + 중복 제거
4. JSON 포맷으로 변환 후 /data/words/en/ 에 저장

### A.2 한국어 데이터 수집 빌드 스크립트 (예시)

```python
# build_korean_words.py
# 국립국어원 우리말샘 API에서 주제별 단어를 수집하여 JSON으로 저장
# 이 스크립트는 빌드 시에만 1회 실행하며, 결과 JSON을 게임에 내장한다.

import requests
import json

API_KEY = "발급받은_API_KEY"
BASE_URL = "https://opendict.korean.go.kr/api/search"

THEME_QUERIES = {
    "animals": "동물",
    "food": "음식",
    "sports": "운동",
    "science": "과학",
    "space": "우주",
    "ocean": "바다",
}

def fetch_words(query, max_count=200):
    """우리말샘 API에서 주제별 단어를 검색하여 수집"""
    words = []
    params = {
        "key": API_KEY,
        "q": query,
        "req_type": "json",
        "num": 100,
        "start": 1,
    }
    response = requests.get(BASE_URL, params=params)
    data = response.json()
    # 명사만 필터링, 2~6글자 범위
    for item in data.get("channel", {}).get("item", []):
        word = item.get("word", "").strip()
        if 2 <= len(word) <= 6:
            words.append(word)
    return words[:max_count]

def decompose_hangul(text):
    """한글 완성형을 자모로 분리"""
    result = []
    for char in text:
        code = ord(char) - 0xAC00
        if 0 <= code < 11172:
            cho = code // 588
            jung = (code % 588) // 28
            jong = code % 28
            CHO = "ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ"
            JUNG = "ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ"
            JONG = [""] + list("ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ")
            result.append(CHO[cho])
            result.append(JUNG[jung])
            if jong != 0:
                result.append(JONG[jong])
        else:
            result.append(char)
    return "".join(result)

# 실행
for theme, query in THEME_QUERIES.items():
    words = fetch_words(query)
    output = {
        "theme": theme,
        "language": "ko",
        "wordCount": len(words),
        "words": [
            {
                "word": w,
                "length": len(w),
                "display": decompose_hangul(w)
            }
            for w in words
        ]
    }
    with open(f"data/words/ko/{theme}.json", "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)
    print(f"[{theme}] {len(words)}개 단어 저장 완료")
```

### A.3 데이터 디렉토리 구조

```
data/
└── words/
    ├── en/
    │   ├── animals.json      (150+ words)
    │   ├── food.json         (150+ words)
    │   ├── space.json        (100+ words)
    │   ├── sports.json       (100+ words)
    │   ├── science.json      (100+ words)
    │   ├── music.json        (100+ words)
    │   ├── ocean.json        (100+ words)
    │   ├── mythology.json    (100+ words)
    │   └── _validation.json  (빈칸 검증용 전체 사전)
    └── ko/
        ├── animals.json      (120+ words)
        ├── food.json         (120+ words)
        ├── space.json        (80+ words)
        ├── sports.json       (80+ words)
        ├── science.json      (80+ words)
        ├── music.json        (80+ words)
        ├── ocean.json        (80+ words)
        └── mythology.json    (80+ words)
```

---

*문서 끝*
