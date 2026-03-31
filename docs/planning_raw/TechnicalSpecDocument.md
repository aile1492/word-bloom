# Word Search Puzzle - 기술 명세서

**문서 버전**: v6.0
**작성일**: 2026-03-06
**최종 수정일**: 2026-03-09
**관련 문서**: GameDesignDocument.md, UIDesignDocument.md, SoundDesignDocument.md, Plan_v6_UI_Overhaul.md

---

## 1. 기술 스택

| 항목 | 선택 | 사유 |
|------|------|------|
| 엔진 | Unity 6 LTS (6000.x) | 크로스 플랫폼 빌드, 2D UI 지원 우수 |
| 언어 | C# (.NET Standard 2.1) | Unity 기본 언어 |
| UI 시스템 | Unity UI (uGUI / Canvas) | TextMeshPro 연동, 모바일 터치 최적화 |
| 렌더링 파이프라인 | URP (Universal Render Pipeline) | 모바일 성능 최적화 |
| 상태 저장 | PlayerPrefs + JSON 직렬화 | 서버 불필요, 로컬 저장 |
| 사운드 | Unity AudioSource / AudioClip | 내장 오디오 시스템 |
| 입력 | Unity Input System (New) | 마우스/터치 통합 처리 |
| 텍스트 렌더링 | TextMeshPro (TMP) | 한글 자모 표시, 고품질 폰트 |
| 빌드 대상 | Android / iOS / Windows (WebGL 옵션) | 모바일 우선 |
| 데이터 직렬화 | JsonUtility + ScriptableObject | 단어 데이터 로딩 |

---

## 2. 프로젝트 디렉토리 구조

```
WordSearchPuzzle/
├── Assets/
│   ├── _Project/                       # 게임 전용 에셋 루트
│   │   ├── Scripts/
│   │   │   ├── Core/
│   │   │   │   ├── GameManager.cs          # 전역 싱글톤, 앱 생명주기 관리
│   │   │   │   ├── GameController.cs       # 게임 상태 머신 (FSM)
│   │   │   │   ├── GridGenerator.cs        # 격자 생성 + 단어 배치 알고리즘
│   │   │   │   ├── ScoreManager.cs         # 점수 계산 + 등급 판정
│   │   │   │   ├── TimerManager.cs         # 타이머 (Classic/Time Attack)
│   │   │   │   ├── HintManager.cs          # 힌트 시스템 (v6.0: 코인 기반)
│   │   │   │   ├── CoinManager.cs          # v6.0: 코인 획득/소비/잔액 관리
│   │   │   │   └── AvatarManager.cs        # v6.0: 프리셋 아바타 + 닉네임 + 인사 메시지
│   │   │   ├── Input/
│   │   │   │   ├── GridInputHandler.cs     # 드래그/탭 입력 처리
│   │   │   │   └── DirectionSnapper.cs     # 방향 스냅 알고리즘
│   │   │   ├── Data/
│   │   │   │   ├── WordLoader.cs           # JSON 단어 데이터 로딩
│   │   │   │   ├── ThemeManager.cs         # 테마 해금/관리
│   │   │   │   ├── WordPack.cs             # 단어 팩 데이터 클래스
│   │   │   │   └── GameConstants.cs        # 상수 정의 (ScriptableObject)
│   │   │   ├── UI/
│   │   │   │   ├── Screens/
│   │   │   │   │   ├── ScreenManager.cs        # 화면 전환 관리 (v6.0: Tab Bar 통합)
│   │   │   │   │   ├── TitleScreen.cs          # 홈 화면 (v6.0: 아바타 카드 + 코인 + Play)
│   │   │   │   │   // ModeSelectScreen.cs 제거됨 (v6.0: Bottom Tab Bar로 대체)
│   │   │   │   │   // ThemeSelectScreen.cs 제거됨 (테마 자동 랜덤 선택)
│   │   │   │   │   // DifficultySelectScreen.cs 제거됨 (단일 난이도)
│   │   │   │   │   ├── GameScreen.cs           # 게임 화면 (v6.0: 테마 배너 + 힌트 바)
│   │   │   │   │   ├── ResultScreen.cs         # 결과 화면 (v6.0: 코인 보상 표시)
│   │   │   │   │   ├── StatsScreen.cs          # 통계 화면
│   │   │   │   │   ├── DailyChallengeScreen.cs # v6.0: 캘린더 UI, Streak, 레벨 게이트
│   │   │   │   │   // SettingsScreen.cs -> SettingsPopup.cs 전환 (v6.0)
│   │   │   │   ├── Components/
│   │   │   │   │   ├── GridCell.cs             # 격자 셀 UI 컴포넌트
│   │   │   │   │   ├── GridView.cs             # 격자 전체 뷰
│   │   │   │   │   ├── WordListItem.cs         # 단어 목록 항목
│   │   │   │   │   ├── WordListView.cs         # 단어 목록 뷰 (v6.0: Flow 레이아웃)
│   │   │   │   │   ├── BottomTabBar.cs         # v6.0: 하단 탭 바 (4탭)
│   │   │   │   │   ├── CoinDisplay.cs          # v6.0: 코인 잔액 표시 (pill shape)
│   │   │   │   │   ├── AvatarFrame.cs          # v6.0: 아바타 프레임 (원형 마스크)
│   │   │   │   │   ├── ProgressCard.cs         # v6.0: 스테이지 진행 카드
│   │   │   │   │   ├── CardButton.cs           # 카드형 버튼
│   │   │   │   │   ├── ToggleSwitch.cs         # ON/OFF 토글 스위치
│   │   │   │   │   ├── ProgressBar.cs          # 진행률 바
│   │   │   │   │   └── ToastMessage.cs         # 토스트 메시지
│   │   │   │   ├── Popups/
│   │   │   │   │   ├── PopupManager.cs         # 팝업 관리
│   │   │   │   │   ├── PausePopup.cs           # 일시정지 팝업
│   │   │   │   │   ├── SettingsPopup.cs        # v6.0: 설정 팝업 (SettingsScreen에서 전환)
│   │   │   │   │   ├── AvatarSelectPopup.cs    # v6.0: 아바타 선택 팝업 (3x2 그리드)
│   │   │   │   │   └── HintPopup.cs            # 힌트 팝업 제거됨 (단일 힌트, 팝업 없음)
│   │   │   │   └── Themes/
│   │   │   │       ├── UIThemeData.cs          # UI 테마 데이터 (ScriptableObject)
│   │   │   │       └── UIThemeApplier.cs       # 라이트/다크 테마 적용기
│   │   │   ├── Audio/
│   │   │   │   ├── AudioManager.cs         # SFX/BGM 재생 관리
│   │   │   │   └── AudioLibrary.cs         # 오디오 클립 레퍼런스 (ScriptableObject)
│   │   │   ├── Storage/
│   │   │   │   ├── SaveManager.cs          # 저장/로드 (PlayerPrefs + JSON)
│   │   │   │   └── SaveData.cs             # 저장 데이터 구조체
│   │   │   └── Utils/
│   │   │       ├── HangulUtils.cs          # 한글 자모 분리/조합
│   │   │       └── SeededRandom.cs         # 시드 기반 랜덤 (Daily Challenge)
│   │   ├── Data/
│   │   │   ├── Constants/
│   │   │   │   └── GameConstantsAsset.asset    # 게임 상수 ScriptableObject
│   │   │   ├── Themes/
│   │   │   │   ├── LightTheme.asset            # 라이트 테마
│   │   │   │   └── DarkTheme.asset             # 다크 테마
│   │   │   └── Audio/
│   │   │       └── AudioLibraryAsset.asset     # 오디오 참조
│   │   ├── Prefabs/
│   │   │   ├── UI/
│   │   │   │   ├── GridCell.prefab             # 격자 셀 프리팹
│   │   │   │   ├── WordListItem.prefab         # 단어 항목 프리팹
│   │   │   │   ├── CardButton.prefab           # 카드 버튼 프리팹
│   │   │   │   └── ToastMessage.prefab         # 토스트 프리팹
│   │   │   └── Popups/
│   │   │       └── PausePopup.prefab
│   │   ├── Scenes/
│   │   │   └── MainScene.unity                 # 단일 씬 (화면 전환은 UI로 처리)
│   │   ├── Resources/
│   │   │   ├── Backgrounds/                   # v6.0: 일러스트 배경 이미지 (ASTC 6x6)
│   │   │   │   ├── bg_tropical_beach.png      # BG-01: TitleScreen (해변)
│   │   │   │   ├── bg_tropical_beach_blur.png # BG-02: GameScreen (해변 블러)
│   │   │   │   ├── bg_green_nature.png        # BG-03: DailyChallengeScreen (녹색 자연)
│   │   │   │   └── bg_warm_gradient.png       # BG-04: StatsScreen (웜 그라데이션)
│   │   │   ├── Avatars/                       # v6.0: 프리셋 아바타 이미지 (512x512)
│   │   │   │   ├── avatar_cat.png
│   │   │   │   ├── avatar_dog.png
│   │   │   │   ├── avatar_penguin.png
│   │   │   │   ├── avatar_fox.png
│   │   │   │   ├── avatar_rabbit.png
│   │   │   │   └── avatar_owl.png
│   │   │   └── Words/
│   │   │       ├── en/
│   │   │       │   ├── animals.json
│   │   │       │   ├── food.json
│   │   │       │   ├── space.json
│   │   │       │   ├── sports.json
│   │   │       │   ├── science.json
│   │   │       │   ├── music.json
│   │   │       │   ├── ocean.json
│   │   │       │   └── mythology.json
│   │   │       └── ko/
│   │   │           ├── animals.json
│   │   │           ├── food.json
│   │   │           └── ...
│   │   ├── Audio/
│   │   │   ├── SFX/
│   │   │   │   ├── sfx_tick.ogg
│   │   │   │   ├── sfx_success.ogg
│   │   │   │   ├── sfx_fail.ogg
│   │   │   │   ├── sfx_clear.ogg
│   │   │   │   ├── sfx_gameover.ogg
│   │   │   │   ├── sfx_warning.ogg
│   │   │   │   ├── sfx_hint.ogg
│   │   │   │   ├── sfx_button.ogg
│   │   │   │   ├── sfx_transition.ogg
│   │   │   │   ├── sfx_newrecord.ogg
│   │   │   │   └── sfx_combo.ogg
│   │   │   └── BGM/
│   │   │       ├── bgm_menu.ogg
│   │   │       ├── bgm_play.ogg
│   │   │       ├── bgm_tension.ogg
│   │   │       └── bgm_result.ogg
│   │   ├── Fonts/
│   │   │   ├── NotoSansKR-Regular SDF.asset    # 한글 TMP 폰트
│   │   │   ├── NotoSansKR-Bold SDF.asset
│   │   │   ├── RobotoMono-Bold SDF.asset       # 격자 영문 모노스페이스
│   │   │   └── D2Coding SDF.asset              # 격자 한글 모노스페이스 (대안)
│   │   └── Sprites/
│   │       ├── UI/
│   │       │   ├── btn_primary.png
│   │       │   ├── btn_secondary.png
│   │       │   ├── card_background.png
│   │       │   ├── icon_lock.png
│   │       │   ├── icon_back.png
│   │       │   ├── icon_pause.png
│   │       │   ├── icon_hint.png
│   │       │   └── icon_check.png
│   │       └── Theme/
│   │           ├── bg_title.png
│   │           └── bg_game.png
│   ├── Plugins/                          # 외부 플러그인 (필요 시)
│   ├── Settings/                         # URP, Quality, Input 설정
│   └── TextMesh Pro/                     # TMP 기본 에셋
├── Packages/
│   └── manifest.json                     # Input System, TMP, URP 등
├── ProjectSettings/
├── Tools/                                # 에디터 외부 도구
│   ├── build_english_words.py
│   ├── build_korean_words.py
│   └── validate_words.py
└── WordSearchPuzzle.sln
```

---

## 3. 모듈 설계

### 3.1 모듈 의존성 다이어그램

```
GameManager (Singleton)
  ├── ScreenManager (v6.0: Tab Bar 통합)
  │     ├── BottomTabBar ──── 4 Tabs (Daily/Home/Collection*/Stats)
  │     ├── TitleScreen (Home Tab) ──── AvatarFrame + ProgressCard + CoinDisplay
  │     ├── DailyChallengeScreen (Daily Tab) ──── CalendarView
  │     ├── StatsScreen (Stats Tab)
  │     ├── GameScreen (Push) ──── GridView ──── GridCell[]
  │     │                          ├── WordListView ──── WordListItem[] (Flow 레이아웃)
  │     │                          └── HintBar (4 buttons: Shuffle/Hint100/Hint200/Refresh)
  │     └── ResultScreen (Push) ──── CoinRewardDisplay
  │     // ModeSelectScreen 제거됨 (v6.0)
  │     // SettingsScreen -> SettingsPopup 전환 (v6.0)
  ├── GameController
  │     ├── GridInputHandler ──── DirectionSnapper
  │     ├── ScoreManager
  │     ├── TimerManager
  │     └── HintManager ──── CoinManager (v6.0: 코인 기반 힌트)
  ├── CoinManager (v6.0: 코인 획득/소비/잔액 관리)
  ├── AvatarManager (v6.0: 프리셋 아바타 + 닉네임 + 인사 메시지)
  ├── WordLoader
  │     └── ThemeManager
  ├── PopupManager
  │     ├── PausePopup
  │     ├── SettingsPopup (v6.0: SettingsScreen에서 전환)
  │     └── AvatarSelectPopup (v6.0)
  ├── SaveManager
  ├── AudioManager
  └── UIThemeApplier
```

### 3.2 모듈별 책임

#### 3.2.1 GameManager.cs (싱글톤 진입점)

```csharp
public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }

    // 현재 게임 설정
    [System.Serializable]
    public class GameSettings
    {
        public GameMode Mode;           // Classic, TimeAttack, DailyChallenge
        public string ThemeKey;         // 자동 랜덤 선택된 테마 키 (readonly after selection)
        // Difficulty 필드 제거됨 — 단일 난이도
        // ThemeSelectScreen 제거됨 — 테마 자동 랜덤 선택
        public Language Language;       // EN, KO
        public int StageNumber;         // 1-based, 현재 플레이 중인 스테이지 번호
        public int DDAWordCountOffset;  // DDA 조정값 (-2 ~ +2)
    }

    public GameSettings CurrentSettings { get; private set; }

    // 주요 참조
    [SerializeField] private ScreenManager _screenManager;
    [SerializeField] private AudioManager _audioManager;
    [SerializeField] private GameConstantsAsset _constants;

    private void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
        DontDestroyOnLoad(gameObject);
    }

    public void StartGame(GameSettings settings);
    public void EndGame(GameResult result);
    public void NavigateTo(ScreenType screenType);

    // v6.0 추가
    public CoinManager CoinManager { get; private set; }
    public AvatarManager AvatarManager { get; private set; }
}

public enum GameMode { Classic, TimeAttack, DailyChallenge }
// Difficulty enum 제거됨 — 단일 난이도로 통합
public enum Language { EN, KO }
public enum ScreenType { Title, Game, Result, Stats, DailyChallenge }
// v6.0: ModeSelect 제거됨, Settings -> SettingsPopup 전환됨, DailyChallenge 추가됨
// DifficultySelect 제거됨, ThemeSelect 제거됨 (테마 자동 랜덤 선택)
```

#### 3.2.2 GridGenerator.cs

```csharp
public class GridGenerator
{
    // 단일 난이도: 8방향 전체 + 역순 배치 항상 허용
    private static readonly Vector2Int[] AllDirections = new[]
    {
        new Vector2Int(1,0), new Vector2Int(-1,0),
        new Vector2Int(0,1), new Vector2Int(0,-1),
        new Vector2Int(1,1), new Vector2Int(-1,-1),
        new Vector2Int(1,-1), new Vector2Int(-1,1)
    };
    // 역순 배치: 단어를 뒤집어서(Reversed) 배치하는 것도 AllDirections와 동일하게 허용

    // 공개 메서드
    public GridData Generate(int gridSize, List<WordEntry> wordList, Language language);
    public GridData GenerateWithSeed(int gridSize, List<WordEntry> wordList,
                                     Language language, int seed);

    // 내부 메서드
    private bool TryPlaceWord(char[,] grid, string displayChars,
                              Vector2Int[] allowedDirs, System.Random rng);
    private bool CanPlace(char[,] grid, string chars, Vector2Int pos, Vector2Int dir);
    private void FillEmptyCells(char[,] grid, Language language, System.Random rng);
    private void ValidateGrid(char[,] grid, List<PlacedWord> placedWords);

    private static Vector2Int V(int x, int y) => new Vector2Int(x, y);
}

[System.Serializable]
public class GridData
{
    public int Size;
    public char[,] Grid;
    public List<PlacedWord> PlacedWords;
}

[System.Serializable]
public class PlacedWord
{
    public string OriginalWord;        // "TIGER" 또는 "호랑이"
    public string DisplayChars;        // "TIGER" 또는 "호랑이" (음절 완성형)
    public Vector2Int StartPos;
    public Vector2Int Direction;
    public bool IsFound;
}
```

#### 3.2.3 GameController.cs (핵심 상태 머신)

```csharp
public class GameController : MonoBehaviour
{
    public enum GameState { Idle, Playing, Paused, Completed, Failed }

    public GameState CurrentState { get; private set; } = GameState.Idle;
    public GridData CurrentGrid { get; private set; }

    // 이벤트
    public event System.Action<PlacedWord> OnWordFound;
    public event System.Action<GameResult> OnGameComplete;
    public event System.Action OnGameFail;
    public event System.Action<GameState> OnStateChanged;

    // 의존성
    private ScoreManager _scoreManager;
    private TimerManager _timerManager;
    private HintManager _hintManager;

    // 상태 전이
    public void StartGame(GridData gridData, GameMode mode);  // Difficulty 파라미터 제거됨
    // StartGame은 Idle이 아닌 상태에서 호출 시 자동으로 Idle 리셋 후 시작 (연속 스테이지 지원)
    public void Pause();          // Playing -> Paused
    public void Resume();         // Paused -> Playing
    public void ForceComplete();  // Playing -> Completed (전체 발견)
    public void ForceFail();      // Playing -> Failed (시간 초과)
    public void Abandon();        // Any -> Idle (메인메뉴 복귀, 타이머 정리)

    // 게임 로직
    public bool CheckWord(List<Vector2Int> selectedCells);
    public List<PlacedWord> GetFoundWords();
    public List<PlacedWord> GetRemainingWords();
    public bool IsAllFound();
    public GameResult GetGameResult();
}

[System.Serializable]
public class GameResult
{
    public float TotalTime;
    public int Score;
    public int WordsFound;
    public int TotalWords;
    public int HintsUsed;
    public string Rank;            // "S", "A", "B", "C"
    public bool IsNewRecord;

    // v6.0 코인 보상
    public int CoinReward;         // 총 코인 보상 (클리어 + 보너스 합산)
    public int CoinBreakdown_Clear;    // 스테이지 클리어 보상 (50)
    public int CoinBreakdown_NoHint;   // 힌트 미사용 보너스 (30)
    public int CoinBreakdown_SRank;    // S랭크 보너스 (50)
}
```

#### 3.2.4 GridInputHandler.cs

```csharp
public class GridInputHandler : MonoBehaviour
{
    // v6.0: InputMode enum 유지하되, Drag만 사용 (Tap 모드 설정 UI 제거됨)
    public enum InputMode { Drag, Tap }

    [SerializeField] private GridView _gridView;
    [SerializeField] private InputMode _currentMode = InputMode.Drag;  // v6.0: Drag 고정

    // 이벤트
    public event System.Action<List<Vector2Int>> OnSelectionComplete;
    public event System.Action<List<Vector2Int>> OnSelectionChanged;

    // 드래그 상태
    private bool _isDragging;
    private Vector2Int _startCell;
    private List<Vector2Int> _selectedCells = new List<Vector2Int>();

    // 탭 상태
    private Vector2Int? _tapStart;

    // Unity Input System 콜백
    private void OnPointerDown(Vector2 screenPos);
    private void OnPointerMove(Vector2 screenPos);
    private void OnPointerUp(Vector2 screenPos);

    // 좌표 변환
    private Vector2Int? ScreenToCell(Vector2 screenPos);
}
```

#### 3.2.5 DirectionSnapper.cs

```csharp
public static class DirectionSnapper
{
    // 8방향 정의
    private static readonly Vector2Int[] Directions =
    {
        new Vector2Int( 1, 0),   //   0도: 오른쪽
        new Vector2Int( 1, 1),   //  45도: 우하단
        new Vector2Int( 0, 1),   //  90도: 아래
        new Vector2Int(-1, 1),   // 135도: 좌하단
        new Vector2Int(-1, 0),   // 180도: 왼쪽
        new Vector2Int(-1,-1),   // 225도: 좌상단
        new Vector2Int( 0,-1),   // 270도: 위
        new Vector2Int( 1,-1),   // 315도: 우상단
    };

    /// <summary>
    /// 시작 셀과 현재 셀 사이의 각도를 계산하여 가장 가까운 직선 방향으로 스냅한다.
    /// </summary>
    public static List<Vector2Int> Snap(Vector2Int start, Vector2Int current, int gridSize);

    /// <summary>
    /// 두 셀 사이의 직선 경로에 포함되는 모든 셀 좌표를 반환한다.
    /// </summary>
    public static List<Vector2Int> GetCellsBetween(Vector2Int start, Vector2Int end);
}
```

#### 3.2.6 ScoreManager.cs

```csharp
public class ScoreManager
{
    private int _totalScore;
    private float _lastFindTime;
    private int _comboCount;

    public void AddWordScore(int wordLength, float elapsedSinceLastFind);
    public int GetFinalScore(float remainingTime, int hintsUsed);
    public string GetRank(int finalScore, float totalTime, int hintsUsed, float timeLimit);
    public int GetTotalScore();
    public float GetComboMultiplier();
    public void Reset();
}
```

#### 3.2.7 TimerManager.cs

```csharp
public class TimerManager : MonoBehaviour
{
    public float Elapsed { get; private set; }
    public float Remaining { get; private set; }
    public bool IsRunning { get; private set; }

    // 이벤트
    public event System.Action<float> OnTick;            // 매 프레임 경과 시간
    public event System.Action<float> OnSecondTick;      // 매초 콜백 (UI 갱신용)
    public event System.Action OnWarning;                 // 30초 이하 경고
    public event System.Action OnTimeUp;                  // 시간 초과

    public void StartTimer(GameMode mode);  // Difficulty 파라미터 제거됨, Time Attack 제한 시간 180초 고정
    public void PauseTimer();
    public void ResumeTimer();
    public void StopTimer();
    public void AddBonusTime(float seconds);
    public string GetFormattedTime();                     // "MM:SS" 포맷
}
```

#### 3.2.8 HintManager.cs

힌트는 1종류만 존재한다 (FirstLetter). HintPopup은 제거되고, HINT 버튼 탭 시 즉시 동작한다.
v6.0에서 힌트는 코인을 소모하여 사용한다 (100 코인/회). 기존 "스테이지당 3회 고정 지급" 방식은 폐지되었다.

힌트 셀 상태 관리:
- 힌트 적용 시: 해당 셀 -> CellState.HintFirstLetter (HintColor #FF8F00 배경)
- 플레이어가 힌트 셀에서 드래그 시작: CellState.Dragging으로 전환
- 드래그 종료 - 오답/취소: CellState.HintFirstLetter 복원
- 드래그 종료 - 정답: CellState.Found로 확정 (HintFirstLetter 해제)
- 새 힌트 요청 시 (힌트 표시 중): 기존 힌트 셀 -> CellState.Idle 복원 후, 새 단어 첫 글자 -> CellState.HintFirstLetter 적용

```csharp
public class HintManager
{
    private CoinManager _coinManager;      // v6.0: 코인 매니저 참조
    private int _hintCost;                 // v6.0: 힌트 1회 비용 (기본 100 코인)
    private int _totalUsed;
    private PlacedWord _currentHintWord;   // 현재 힌트 표시 중인 단어 (null이면 힌트 없음)
    private Vector2Int _currentHintCell;   // 현재 힌트 셀 좌표

    public HintManager(CoinManager coinManager, int hintCost = 100);  // v6.0: 코인 기반

    // 힌트 적용: 코인 차감 후 미발견 단어 중 랜덤 1개 선택, 첫 글자 셀 반환
    // 이미 힌트 표시 중이면 기존 힌트 해제 후 새 힌트 적용 (코인 추가 차감)
    public HintResult UseFirstLetter(List<PlacedWord> remainingWords);
    // UseDirection, UseReveal 제거됨 (v5.0: 단일 힌트만 존재)

    // 드래그 시작 시 힌트 셀의 상태를 Dragging으로 전환 (오답 시 복원을 위해 상태 추적)
    public void OnHintCellDragStarted();
    // 드래그 종료 - 오답/취소 시 힌트 셀 상태를 HintFirstLetter로 복원
    public void OnHintCellDragFailed();
    // 드래그 종료 - 정답 시 힌트 상태 완전 해제
    public void OnHintCellDragSucceeded();

    public bool HasActiveHint();           // 현재 힌트가 표시 중인지 확인
    public Vector2Int GetHintCell();       // 현재 힌트 셀 좌표 반환
    public int GetTotalUsed();
    public bool CanUse();                  // v6.0: CoinManager.CanSpend(hintCost) 확인
    public int GetHintCost();              // v6.0: 현재 힌트 비용 반환
}

// HintType enum 제거됨 -- 힌트 종류가 1개이므로 불필요

[System.Serializable]
public class HintResult
{
    public PlacedWord TargetWord;
    public Vector2Int HighlightCell;       // 첫 글자 셀 좌표
}
```

#### 3.2.9 WordLoader.cs

```csharp
public class WordLoader
{
    private Dictionary<string, WordPack> _cache = new Dictionary<string, WordPack>();

    /// <summary>
    /// Resources/Words/{lang}/{theme}.json 에서 단어 팩을 로드한다.
    /// </summary>
    public WordPack LoadTheme(Language language, string themeKey);

    /// <summary>
    /// 조건에 맞는 단어를 랜덤으로 추출한다.
    /// </summary>
    public List<WordEntry> GetRandomWords(WordPack pack, int count,
                                           int minLen, int maxLen, System.Random rng = null);

    /// <summary>
    /// 해당 언어의 교란용 알파벳 셋을 반환한다.
    /// </summary>
    public char[] GetAlphabet(Language language);
}

[System.Serializable]
public class WordPack
{
    public string theme;
    public string language;
    public WordEntry[] words;
}

[System.Serializable]
public class WordEntry
{
    public string word;            // "tiger" 또는 "호랑이"
    public int length;             // 글자 수
    public string display;         // "TIGER" 또는 "호랑이" (음절 완성형, 격자 배치용)
    public string category;        // 하위 분류 (선택)
}
```

#### 3.2.10 SaveManager.cs

```csharp
public static class SaveManager
{
    private const string SAVE_KEY = "WordSearchPuzzle_SaveData";

    public static SaveData Load();
    public static void Save(SaveData data);
    public static void Reset();

    // 편의 메서드
    public static StatsData GetStats();
    public static void UpdateStats(GameResult result);
    public static SettingsData GetSettings();
    public static void UpdateSetting(string key, object value);
    public static List<string> GetUnlockedThemes();
    public static void UnlockTheme(string themeKey);
    public static void UpdateStreak();
    // 단일 난이도 -- Difficulty 파라미터 제거됨
    // 테마 랜덤 선택 -- themeKey 파라미터 제거됨, 모드별 통합 기록
    public static float GetBestTime(GameMode mode);
    public static bool TryUpdateBestTime(GameMode mode, float time);
    public static string GetLastThemeKey();
    public static void SetLastThemeKey(string themeKey);

    // v6.0 코인 관련
    public static int GetCoinBalance();
    public static void SetCoinBalance(int balance);
    public static int GetTotalCoinsEarned();
    public static void AddTotalCoinsEarned(int amount);

    // v6.0 아바타 관련
    public static int GetSelectedAvatarIndex();
    public static void SetSelectedAvatarIndex(int index);
    public static string GetNickname();
    public static void SetNickname(string nickname);
}

[System.Serializable]
public class SaveData
{
    public StatsData Stats;
    public SettingsData Settings;
    public List<string> UnlockedThemes;
    public List<BestTimeEntry> BestTimesList;  // Key: "{Mode}" -- 테마 랜덤이므로 모드별 통합
    public string LastThemeKey;               // 직전 스테이지 테마 (연속 동일 테마 방지용)
    public int DailyStreak;
    public string LastPlayDate;

    // 스테이지 진행 저장
    public int CurrentStage;     // 현재 스테이지 번호 (1부터, 클리어 시마다 +1)
    public int HighestStage;     // 달성한 최고 스테이지

    // v6.0 코인 시스템
    public int CoinBalance;          // 현재 보유 코인 (초기값: 300)
    public int TotalCoinsEarned;     // 누적 획득 코인

    // v6.0 아바타 시스템
    public int SelectedAvatarIndex;  // 선택된 아바타 (0~5, 기본: 0 = Cat)
    public string Nickname;          // 닉네임 (최대 12자, 기본: "Guest_{랜덤5자}")
}

[System.Serializable]
public class StatsData
{
    public int TotalGames;
    public int TotalWordsFound;
    public float TotalPlayTime;
    public int CurrentStreak;
}

[System.Serializable]
public class SettingsData
{
    public bool SoundEnabled = true;
    public bool MusicEnabled = true;
    public bool IsDarkTheme = false;
    public Language Language = Language.EN;
    // v6.0: InputMode 제거됨 (Drag 고정)
}
```

#### 3.2.11 ScreenManager.cs

v6.0에서 화면은 두 가지 유형으로 분류된다:
- **Tab Screen**: Bottom Tab Bar에 의해 전환되는 화면 (TitleScreen, DailyChallengeScreen, StatsScreen). Tab Bar가 표시된다.
- **Push Screen**: Tab Screen 위에 Push되는 화면 (GameScreen, ResultScreen). Tab Bar가 숨김 처리된다.

```csharp
public class ScreenManager : MonoBehaviour
{
    [SerializeField] private BaseScreen[] _screens;       // Inspector에서 할당
    [SerializeField] private BottomTabBar _tabBar;        // v6.0: Tab Bar 참조
    [SerializeField] private float _transitionDuration = 0.3f;

    private BaseScreen _currentScreen;
    private ScreenType _currentType;

    // v6.0: Tab Screen 목록 (Tab Bar 표시 여부 판단용)
    private static readonly HashSet<ScreenType> TabScreenTypes = new HashSet<ScreenType>
    {
        ScreenType.Title, ScreenType.DailyChallenge, ScreenType.Stats
    };

    public void ShowScreen(ScreenType type, object data = null);
    public void GoBack();
    public ScreenType GetCurrentScreen();

    // v6.0: Tab Bar 표시/숨김
    private void UpdateTabBarVisibility(ScreenType type)
    {
        bool isTabScreen = TabScreenTypes.Contains(type);
        _tabBar.SetVisible(isTabScreen);
    }

    // 전환 애니메이션 (Coroutine)
    private IEnumerator TransitionCoroutine(BaseScreen from, BaseScreen to, object data);
}

/// <summary>
/// 모든 화면의 기본 클래스
/// </summary>
public abstract class BaseScreen : MonoBehaviour
{
    [SerializeField] private CanvasGroup _canvasGroup;
    [SerializeField] private RectTransform _rootTransform;

    public virtual void OnShow(object data = null);
    public virtual void OnHide();
    public virtual void OnBack();

    // Fade In/Out
    public Coroutine FadeIn(float duration);
    public Coroutine FadeOut(float duration);
}
```

#### 3.2.12 GridView.cs

```csharp
public class GridView : MonoBehaviour
{
    [SerializeField] private GridLayoutGroup _gridLayout;
    [SerializeField] private RectTransform _gridContainer;
    [SerializeField] private GridCell _cellPrefab;

    private GridCell[,] _cells;
    private int _gridSize;

    /// <summary>
    /// 격자 데이터를 기반으로 UI 셀을 생성/재활용한다.
    /// </summary>
    public void Initialize(GridData gridData, Language language);

    /// <summary>
    /// 화면 크기에 맞춰 셀 크기를 자동 계산한다.
    /// </summary>
    public void RecalculateCellSize();

    /// <summary>
    /// 특정 셀 목록의 시각 상태를 변경한다.
    /// </summary>
    public void HighlightCells(List<Vector2Int> cells, CellState state);
    public void ClearHighlight(List<Vector2Int> cells);
    public void SetCellFound(List<Vector2Int> cells, int colorIndex);

    /// <summary>
    /// 모든 셀 등장 애니메이션을 재생한다.
    /// </summary>
    public IEnumerator PlayAppearAnimation();

    /// <summary>
    /// 클리어 웨이브 애니메이션을 재생한다.
    /// </summary>
    public IEnumerator PlayClearAnimation();

    // 좌표 변환
    public GridCell GetCellAt(Vector2Int pos);
    public Vector2Int? ScreenPosToGridPos(Vector2 screenPos);
}

public enum CellState { Idle, Hover, Dragging, Found, HintFirstLetter }
```

#### 3.2.13 AudioManager.cs

```csharp
public class AudioManager : MonoBehaviour
{
    public static AudioManager Instance { get; private set; }

    [SerializeField] private AudioLibrary _library;
    [SerializeField] private AudioSource _bgmSource;
    [SerializeField] private AudioSource[] _sfxPool;      // SFX 동시 재생 풀 (5개)

    [SerializeField] private float _bgmVolume = 0.25f;    // -12dB 상당
    [SerializeField] private float _sfxVolume = 1.0f;

    // SFX 재생
    public void PlaySFX(SFXType type);
    public void PlaySFXWithPitch(SFXType type, float pitch);   // 콤보 피치 조절용

    // BGM 재생
    public void PlayBGM(BGMType type);
    public void StopBGM(float fadeDuration = 1.0f);
    public void CrossFadeBGM(BGMType type, float duration = 1.0f);

    // 설정
    public void SetSFXEnabled(bool enabled);
    public void SetBGMEnabled(bool enabled);

    // 콤보 피치
    public float GetComboPitch(int comboCount);
    // 1.0 -> 1.05 -> 1.1 -> 1.15 -> 1.2 -> 1.25 -> 1.3 (최대)
}

public enum SFXType { Tick, Success, Fail, Clear, GameOver, Warning, Hint, Button, Transition, NewRecord, Combo }
public enum BGMType { Menu, Play, Tension, Result }
```

#### 3.2.14 HangulUtils.cs

```csharp
public static class HangulUtils
{
    private const int HANGUL_BASE = 0xAC00;
    private const int HANGUL_END = 0xD7A3;

    /// <summary>
    /// 한글 완성형 문자인지 판별한다 (0xAC00 ~ 0xD7A3).
    /// </summary>
    public static bool IsHangul(char c);

    /// <summary>
    /// 문자열을 음절 단위 char 배열로 반환한다.
    /// 한국어: "호랑이" -> ['호','랑','이'] (음절 완성형 유지)
    /// 영어: "TIGER" -> ['T','I','G','E','R']
    /// </summary>
    public static char[] GetDisplayChars(string word, string language);

    /// <summary>
    /// 격자 빈칸 채우기용 한글 음절 화이트리스트를 반환한다.
    /// 초성(14자) x 중성(8자) x 종성없음 조합으로 약 112자 구성.
    /// 허용 초성: ㄱ ㄴ ㄷ ㄹ ㅁ ㅂ ㅅ ㅇ ㅈ ㅊ ㅋ ㅌ ㅍ ㅎ
    /// 허용 중성: ㅏ ㅓ ㅗ ㅜ ㅡ ㅣ ㅐ ㅔ
    /// 종성: 없음(받침 없는 음절만 사용)
    /// 예: 가 나 다 라 마 바 사 아 자 차...
    /// 절대 금지: 0xAC00~0xD7A3 전체 범위 랜덤 사용 (묈,뭏 등 희귀 음절 발생)
    /// </summary>
    public static char[] GetWeightedSyllableAlphabet();

    /// <summary>
    /// 특정 테마의 단어 목록에서 사용된 글자와 유사한 교란 글자를 생성한다.
    /// 동일 초성을 가진 다른 음절을 우선 배치하여 난이도를 높인다.
    /// </summary>
    public static char GetRandomSimilarSyllable(char reference, System.Random rng);
}
```

#### 3.2.15 GameConstantsAsset.cs (ScriptableObject)

```csharp
[CreateAssetMenu(fileName = "GameConstants", menuName = "WordSearch/Game Constants")]
public class GameConstantsAsset : ScriptableObject
{
    // v5.0: 난이도별 Grid/Word/Time 상수 제거됨 — 스테이지 기반 동적 계산으로 대체

    [Header("Score")]
    public int ScoreBase = 50;
    public int ScorePerLetter = 10;
    public float TimeMultiplier = 2f;
    public int NoHintBonus = 100;
    public float ComboThreshold = 10f;       // 10초 이내 연속 발견
    public float ComboMultiplier = 1.5f;

    [Header("Hints (v6.0: 코인 기반)")]
    // InitialHints 제거됨 -- v6.0에서 코인 기반으로 전환
    public int HintCostCoins = 100;          // 힌트 1회당 코인 비용

    [Header("Coins (v6.0)")]
    public int InitialCoins = 300;           // 신규 유저 초기 코인
    public int StageClearReward = 50;        // 스테이지 클리어 보상
    public int NoHintBonusCoins = 30;        // 힌트 미사용 보너스
    public int SRankBonusCoins = 50;         // S랭크 보너스
    public int DailyChallengeReward = 100;   // Daily Challenge 완료 보상
    public int StreakBonusPerDay = 20;       // 연속 출석 보너스 (일당, 최대 7일)

    [Header("Cell Size (UI units)")]
    public float CellSizeMin = 80f;
    public float CellSizeMax = 120f;
    public float CellSizeMinKorean = 88f;
    public float CellGap = 4f;

    [Header("Animation Durations (seconds)")]
    public float FadeInDuration = 0.3f;
    public float FadeOutDuration = 0.2f;
    public float PopupInDuration = 0.25f;
    public float CorrectPulseDuration = 0.4f;
    public float WrongFadeDuration = 0.3f;
    public float GridCellDelay = 0.02f;
    public float HintBlinkInterval = 0.5f;
    public int HintBlinkCount = 3;
    public float ClearWaveDuration = 1.5f;

    [Header("Themes")]
    public string[] ThemeKeys = { "animals", "food", "space", "sports",
                                   "science", "music", "ocean", "mythology" };

    [Header("Unlock Conditions")]
    public ThemeUnlockCondition[] UnlockConditions;

    // 스테이지 기반 성장 상수
    [Header("Stage Progression")]
    public int StartGridWidth     = 5;    // 시작 격자 가로
    public int StartGridHeight    = 5;    // 시작 격자 세로
    public int MaxGridWidth       = 10;   // 격자 가로 상한
    public int MaxGridHeight      = 10;   // 격자 세로 상한
    public int GridGrowIntervalX  = 4;    // x축 증가 스테이지 주기
    public int GridGrowIntervalY  = 4;    // y축 증가 스테이지 주기
    public int StartWordCount     = 4;    // 시작 단어 수
    public int MaxWordCount       = 12;   // 단어 수 상한
    public int WordGrowInterval   = 5;    // 단어 수 증가 스테이지 주기

    [Header("Cell Size")]
    public float CellSizeMin      = 44f;  // 최소 셀 크기 (터치 타겟)
    public float CellSizeMax      = 60f;  // 최대 셀 크기 (작은 격자 과대 방지)

    [Header("Sawtooth Pattern")]
    public int RestStageInterval  = 10;   // 휴식 스테이지 주기 (매 N 스테이지마다)
    public int RestWordReduction  = 2;    // 휴식 스테이지에서 단어 감소량

    [Header("False Lead")]
    public int FalseLeadMinStage  = 11;   // False Lead 활성화 최소 스테이지
    public int FalseLeadMaxCount  = 2;    // 스테이지당 최대 False Lead 수

    [Header("DDA (Dynamic Difficulty Adjustment)")]
    public int DDAHistorySize     = 3;    // 평가 대상 직전 스테이지 수
    public int DDAMaxOffset       = 2;    // 최대 조정 범위 (+-N)
    public float DDAFastThreshold = 90f;  // "빠른 클리어" 기준 (초)
    public int DDAHighHintThreshold = 2;  // "힌트 과다 사용" 기준 (회)

    // 헬퍼 메서드 — 스테이지 번호(1-based)를 받아 동적 값 반환
    public int GetGridWidth(int stage);     // 계산: min(StartGridWidth  + xIncrements(stage), MaxGridWidth)
    public int GetGridHeight(int stage);    // 계산: min(StartGridHeight + yIncrements(stage), MaxGridHeight)
    public int GetWordCount(int stage);     // 계산: min(StartWordCount  + floor((stage-1)/WordGrowInterval), MaxWordCount)
    public float GetTimeLimit();            // Time Attack 고정 180초
    public bool IsRestStage(int stage);     // 휴식 스테이지 판정: stage > 1 && stage % RestStageInterval == 0
    public bool IsFalseLeadEnabled(int stage); // False Lead 활성화 여부: stage >= FalseLeadMinStage

    // 내부 계산 (GetGridWidth/Height에서 사용)
    // groupIndex  = floor((stage - 1) / 4)
    // xIncrements = floor((groupIndex + 1) / 2)
    // yIncrements = floor(groupIndex / 2)
}

[System.Serializable]
public class ThemeUnlockCondition
{
    public string ThemeKey;
    public UnlockType Type;
    public int RequiredCount;

    public enum UnlockType { Default, ClassicClear, TimeAttackClear, Streak, AllThemesClear }
}
```

#### 3.2.16 UIThemeData.cs (ScriptableObject)

```csharp
[CreateAssetMenu(fileName = "UITheme", menuName = "WordSearch/UI Theme")]
public class UIThemeData : ScriptableObject
{
    [Header("Primary Palette")]
    public Color Primary;
    public Color Secondary;
    public Color Background;
    public Color Surface;

    [Header("Text")]
    public Color TextPrimary;
    public Color TextSecondary;

    [Header("Feedback")]
    public Color Success;
    public Color Warning;
    public Color Error;
    public Color Highlight;

    [Header("Word Found Colors (6-color rotation)")]
    public Color[] WordFoundColors = new Color[6];

    // DifficultyEasy/Normal/Hard/Expert 제거됨 — 단일 난이도

    [Header("Hint Colors")]
    public Color HintColor;                // #FF8F00 — 힌트 첫 글자 강조 (주황)

    [Header("Cell Colors")]
    public Color CellBackground;           // #FFFFFF — 격자 셀 배경 (테마 무관)
    public Color CellTextColor;            // #212121 — 격자 셀 텍스트 (테마 무관)
    public Color CellTextColorFound;       // #FFFFFF — 단어 발견 시 셀 텍스트

    [Header("Rank Colors")]
    public Color RankS;
    public Color RankA;
    public Color RankB;
    public Color RankC;
}
```

#### 3.2.17 SeededRandom.cs

```csharp
/// <summary>
/// Daily Challenge용 시드 기반 의사난수 생성기 (LCG).
/// 동일 시드 입력 시 모든 기기에서 동일한 시퀀스를 보장한다.
/// </summary>
public class SeededRandom
{
    private uint _seed;

    public SeededRandom(int seed)
    {
        _seed = (uint)seed;
    }

    /// <summary>
    /// 날짜 기반 시드를 생성한다.
    /// 예: 2026-03-06 -> 20260306
    /// </summary>
    public static int GetDailySeed()
    {
        var today = System.DateTime.Now;
        return today.Year * 10000 + today.Month * 100 + today.Day;
    }

    /// <summary>
    /// 0.0 ~ 1.0 범위의 의사난수를 반환한다.
    /// </summary>
    public float Next()
    {
        _seed = _seed * 1664525u + 1013904223u;
        return (_seed >> 0) / (float)uint.MaxValue;
    }

    /// <summary>
    /// min ~ max (exclusive) 범위의 정수 의사난수를 반환한다.
    /// </summary>
    public int NextInt(int min, int max)
    {
        return min + (int)(Next() * (max - min));
    }
}
```

#### 3.2.18 ThemeRandomizer.cs

스테이지별 테마를 자동 랜덤 선택하는 유틸리티 클래스.

```csharp
public static class ThemeRandomizer
{
    /// <summary>
    /// 해금된 테마 중 랜덤으로 1개를 선택한다.
    /// 직전 테마와 동일한 테마는 가능한 한 피한다 (해금 테마 2개 이상인 경우).
    /// </summary>
    /// <param name="unlockedThemes">해금된 테마 키 목록</param>
    /// <param name="previousTheme">직전 스테이지 테마 (null이면 제한 없음)</param>
    /// <param name="rng">랜덤 생성기 (Daily Challenge 시 SeededRandom 사용)</param>
    public static string SelectTheme(List<string> unlockedThemes, string previousTheme, System.Random rng);

    /// <summary>
    /// Daily Challenge용: 날짜 시드 + 스테이지 번호로 테마 결정
    /// </summary>
    public static string SelectDailyTheme(List<string> unlockedThemes, int dailySeed, int stageNumber);
}
```

#### 3.2.19 DDAManager.cs

경량 Dynamic Difficulty Adjustment 시스템. 직전 3스테이지 성과를 기반으로 단어 수를 미세 조정한다.

```csharp
public class DDAManager
{
    private const int HISTORY_SIZE = 3;       // 평가 대상 직전 스테이지 수
    private const int MAX_OFFSET = 2;         // 최대 조정 범위 (+-2)
    private const float FAST_THRESHOLD = 90f; // "빠른 클리어" 기준 (초)
    private const int HIGH_HINT_THRESHOLD = 2;// "힌트 과다 사용" 기준

    private Queue<StagePerformance> _history;  // 직전 스테이지 성과 기록 (최대 3개)

    [System.Serializable]
    public class StagePerformance
    {
        public float ClearTime;      // 클리어 시간 (실패 시 float.MaxValue)
        public int HintsUsed;        // 힌트 사용 횟수
        public bool IsCleared;       // 클리어 여부
    }

    /// <summary>
    /// 스테이지 완료 시 성과를 기록한다.
    /// </summary>
    public void RecordPerformance(GameResult result);

    /// <summary>
    /// 현재 DDA 조정값을 계산한다.
    /// 직전 3스테이지 모두 힌트 미사용 + 평균 90초 미만: +1
    /// 직전 3스테이지 중 2회 이상 실패 또는 평균 힌트 2회 이상: -1
    /// 그 외: 0
    /// 반환값: -MAX_OFFSET ~ +MAX_OFFSET 범위
    /// </summary>
    public int GetWordCountOffset();

    /// <summary>
    /// 최종 단어 수를 계산한다 (기본 공식 + DDA 조정).
    /// 휴식 스테이지에는 DDA 적용 안 함.
    /// Daily Challenge에는 DDA 적용 안 함.
    /// </summary>
    public int GetAdjustedWordCount(int baseWordCount, int stage, GameMode mode);

    /// <summary>
    /// 성과 기록을 초기화한다.
    /// </summary>
    public void Reset();
}
```

#### 3.2.20 FalseLeadGenerator.cs

빈칸 채우기 시 False Lead(가짜 단서)를 생성하는 유틸리티 클래스.

```csharp
public static class FalseLeadGenerator
{
    /// <summary>
    /// 격자 빈칸에 False Lead를 배치한다.
    /// 스테이지 11 이상에서만 활성화.
    /// 정답 단어의 첫 2~3글자를 연속 배치하되, 정답 완성이 불가하도록 한다.
    /// </summary>
    /// <param name="grid">현재 격자 (빈칸 채우기 전)</param>
    /// <param name="placedWords">배치된 정답 단어 목록</param>
    /// <param name="stage">현재 스테이지 번호</param>
    /// <param name="rng">랜덤 생성기</param>
    /// <returns>배치된 False Lead 수</returns>
    public static int PlaceFalseLeads(char[,] grid, List<PlacedWord> placedWords,
                                       int stage, System.Random rng);

    private const int MIN_STAGE = 11;         // False Lead 활성화 최소 스테이지
    private const int MAX_FALSE_LEADS = 2;    // 스테이지당 최대 False Lead 수
    private const int PREFIX_LENGTH_MIN = 2;  // 가짜 단서 최소 글자 수
    private const int PREFIX_LENGTH_MAX = 3;  // 가짜 단서 최대 글자 수
}
```

#### 3.2.21 CoinManager.cs (v6.0 신규)

게임 내 유일한 재화 "코인"의 획득, 소비, 잔액을 관리한다.

```csharp
public class CoinManager
{
    private int _balance;
    private int _totalEarned;

    // 이벤트
    public event System.Action<int, int> OnBalanceChanged;  // (newBalance, delta)
    public event System.Action<int> OnCoinsEarned;          // (amount)
    public event System.Action<int> OnCoinsSpent;           // (amount)

    public CoinManager()
    {
        var saveData = SaveManager.Load();
        _balance = saveData.CoinBalance;
        _totalEarned = saveData.TotalCoinsEarned;
    }

    // 초기화 (신규 유저)
    public void InitializeNewPlayer()
    {
        _balance = 300;     // 초기 지급
        _totalEarned = 300;
        Save();
    }

    // 코인 획득
    public void Earn(int amount, string source)
    {
        _balance += amount;
        _totalEarned += amount;
        OnCoinsEarned?.Invoke(amount);
        OnBalanceChanged?.Invoke(_balance, amount);
        Save();
    }

    // 코인 소비
    public bool TrySpend(int amount, string purpose)
    {
        if (_balance < amount) return false;
        _balance -= amount;
        OnCoinsSpent?.Invoke(amount);
        OnBalanceChanged?.Invoke(_balance, -amount);
        Save();
        return true;
    }

    // 잔액 확인
    public int GetBalance() => _balance;
    public int GetTotalEarned() => _totalEarned;
    public bool CanSpend(int amount) => _balance >= amount;

    private void Save()
    {
        SaveManager.SetCoinBalance(_balance);
        SaveManager.AddTotalCoinsEarned(0);  // 저장만 갱신
    }
}
```

코인 획득/소비 테이블 (GDD 섹션 8A 참조):

| 경로 | 코인량 | 조건 |
|------|--------|------|
| 스테이지 클리어 | +50 | 매 클리어 시 |
| 힌트 미사용 보너스 | +30 | 해당 스테이지 힌트 미사용 |
| S랭크 보너스 | +50 | S랭크 달성 |
| Daily Challenge 완료 | +100 | 매일 1회 |
| 힌트 사용 | -100 | 1회당 |

#### 3.2.22 AvatarManager.cs (v6.0 신규)

프리셋 아바타 6종 + 닉네임 + 시간대별 인사 메시지를 관리한다.

```csharp
public class AvatarManager
{
    public static readonly string[] AvatarNames = { "Cat", "Dog", "Penguin", "Fox", "Rabbit", "Owl" };
    public const int AVATAR_COUNT = 6;
    public const int MAX_NICKNAME_LENGTH = 12;

    private int _selectedIndex;
    private string _nickname;

    public AvatarManager()
    {
        var saveData = SaveManager.Load();
        _selectedIndex = Mathf.Clamp(saveData.SelectedAvatarIndex, 0, AVATAR_COUNT - 1);
        _nickname = string.IsNullOrEmpty(saveData.Nickname)
                    ? GenerateDefaultNickname()
                    : saveData.Nickname;
    }

    // 아바타 선택
    public void SelectAvatar(int index)
    {
        _selectedIndex = Mathf.Clamp(index, 0, AVATAR_COUNT - 1);
        SaveManager.SetSelectedAvatarIndex(_selectedIndex);
    }

    // 닉네임 설정
    public void SetNickname(string nickname)
    {
        if (string.IsNullOrWhiteSpace(nickname))
            nickname = GenerateDefaultNickname();
        if (nickname.Length > MAX_NICKNAME_LENGTH)
            nickname = nickname.Substring(0, MAX_NICKNAME_LENGTH);
        _nickname = nickname;
        SaveManager.SetNickname(_nickname);
    }

    // 인사 메시지 (시간대별)
    public string GetGreeting(Language language)
    {
        int hour = System.DateTime.Now.Hour;
        if (hour >= 6 && hour < 12)
            return language == Language.KO
                ? $"좋은 아침이에요, {_nickname}!"
                : $"Good morning, {_nickname}!";
        else if (hour >= 12 && hour < 18)
            return language == Language.KO
                ? $"좋은 오후에요, {_nickname}!"
                : $"Good afternoon, {_nickname}!";
        else if (hour >= 18 && hour < 22)
            return language == Language.KO
                ? $"좋은 저녁이에요, {_nickname}!"
                : $"Good evening, {_nickname}!";
        else
            return language == Language.KO
                ? $"아직 안 자요? {_nickname}!"
                : $"Still awake, {_nickname}?";
    }

    // 아바타 스프라이트 경로
    public string GetAvatarSpritePath()
    {
        return $"Avatars/avatar_{AvatarNames[_selectedIndex].ToLower()}";
    }

    public int GetSelectedIndex() => _selectedIndex;
    public string GetNickname() => _nickname;
    public string GetAvatarName() => AvatarNames[_selectedIndex];

    private string GenerateDefaultNickname()
    {
        string suffix = UnityEngine.Random.Range(10000, 99999).ToString();
        return $"Guest_{suffix}";
    }
}
```

#### 3.2.23 BottomTabBar.cs (v6.0 신규)

하단 탭 바 (4탭: Daily / Home / Collection / Stats). UIDesignDocument.md 섹션 9.9 참조.

```csharp
public class BottomTabBar : MonoBehaviour
{
    [System.Serializable]
    public class TabDefinition
    {
        public ScreenType TargetScreen;
        public string LabelKey;         // Localization 키
        public Image Icon;
        public TMP_Text Label;
        public bool IsDisabled;         // Collection 탭용 (Coming Soon)
    }

    [SerializeField] private TabDefinition[] _tabs;
    [SerializeField] private Color _activeColor;        // 선택된 탭 색상
    [SerializeField] private Color _inactiveColor;      // 비선택 탭 색상
    [SerializeField] private Color _disabledColor;      // 비활성 탭 색상

    private int _currentTabIndex = 1;   // 기본: Home (index 1)

    // 이벤트
    public event System.Action<ScreenType> OnTabSelected;

    public void SelectTab(int index);
    public void SetVisible(bool visible);
    public int GetCurrentTabIndex() => _currentTabIndex;

    // Tab Bar 높이: 112 UI units
    // Safe Area 하단 여백 적용
    // HorizontalLayoutGroup: Expand Child Width, Child Height
}
```

#### 3.2.24 CoinDisplay.cs (v6.0 신규)

코인 잔액 표시 컴포넌트 (pill shape). UIDesignDocument.md 섹션 9.10 참조.

```csharp
public class CoinDisplay : MonoBehaviour
{
    [SerializeField] private Image _coinIcon;
    [SerializeField] private TMP_Text _balanceText;
    [SerializeField] private float _countAnimDuration = 0.5f;

    private int _displayedBalance;
    private Coroutine _countAnim;

    public void Initialize(CoinManager coinManager)
    {
        coinManager.OnBalanceChanged += OnBalanceChanged;
        UpdateDisplay(coinManager.GetBalance(), false);
    }

    private void OnBalanceChanged(int newBalance, int delta)
    {
        UpdateDisplay(newBalance, true);
    }

    private void UpdateDisplay(int targetBalance, bool animate)
    {
        if (animate && _countAnim != null) StopCoroutine(_countAnim);
        if (animate)
            _countAnim = StartCoroutine(CountAnimation(_displayedBalance, targetBalance));
        else
        {
            _displayedBalance = targetBalance;
            _balanceText.text = targetBalance.ToString("N0");
        }
    }

    private IEnumerator CountAnimation(int from, int to);
}
```

#### 3.2.25 UIThemeData.cs 확장 (v6.0)

UIThemeData에 화면별 배경 이미지 참조를 추가한다.

```csharp
// UIThemeData.cs에 추가되는 v6.0 필드
[Header("v6.0 Background Images")]
public Sprite BgTitleScreen;           // BG-01: 해변 일러스트
public Sprite BgGameScreen;            // BG-02: 해변 블러
public Sprite BgDailyChallenge;        // BG-03: 녹색 자연
public Sprite BgStatsScreen;           // BG-04: 웜 그라데이션

[Header("v6.0 Tab Bar")]
public Color TabBarBackground;         // Tab Bar 배경 색상
public Color TabActiveColor;           // 선택된 탭 아이콘/레이블 색상
public Color TabInactiveColor;         // 비선택 탭 아이콘/레이블 색상

[Header("v6.0 Coin Display")]
public Color CoinPillBackground;       // 코인 표시 배경 (pill)
public Color CoinTextColor;            // 코인 텍스트 색상
```

---

## 4. 핵심 알고리즘 상세

### 4.1 격자 생성 알고리즘

```
입력: gridSize, wordList, difficulty, language, [seed]
출력: GridData { grid[,], placedWords }

1. rng = (seed 있으면) new SeededRandom(seed) : new System.Random()
2. char[,] grid = new char[gridSize, gridSize]  (null 초기화)
3. wordList를 display 길이 내림차순 정렬
   - 영어: word.Length
   - 한국어: word.Length (음절 수)
4. for each word in wordList:
   a. maxAttempts = 100
   b. allowedDirs = DirectionMap[difficulty]
   c. for attempt in 1..maxAttempts:
      - dir = allowedDirs[rng.NextInt(0, allowedDirs.Length)]
      - startRow = rng.NextInt(0, gridSize)
      - startCol = rng.NextInt(0, gridSize)
      - displayChars = GetDisplayChars(word, language)
      - if CanPlace(grid, displayChars, startRow, startCol, dir):
           PlaceWord(grid, displayChars, startRow, startCol, dir)
           placedWords.Add(new PlacedWord { ... })
           break
   d. if not placed: Debug.LogWarning("Skipped: " + word.word)
5. FillEmptyCells(grid, language, rng)
6. return new GridData { Grid = grid, PlacedWords = placedWords }
```

### 4.2 방향 스냅 알고리즘

```
function Snap(Vector2Int start, Vector2Int current, int gridSize):
    dx = current.x - start.x
    dy = current.y - start.y

    if dx == 0 and dy == 0: return empty list

    angle = Mathf.Atan2(dy, dx) * Mathf.Rad2Deg    // -180 ~ 180

    // 45도 단위로 가장 가까운 방향에 스냅
    snapIndex = Mathf.RoundToInt(angle / 45f)
    if snapIndex < 0: snapIndex += 8
    snapDir = Directions[snapIndex % 8]

    // 스냅된 방향으로 시작점부터 현재 거리만큼의 셀 좌표 계산
    distance = Mathf.Max(Mathf.Abs(dx), Mathf.Abs(dy))
    cells = new List<Vector2Int>()
    for i in 0..distance:
        pos = start + snapDir * i
        if pos is within grid bounds:
            cells.Add(pos)
        else: break
    return cells
```

### 4.3 Daily Challenge 시드 생성

```
int seed = SeededRandom.GetDailySeed();
// 예: 2026-03-06 -> 20260306

var rng = new SeededRandom(seed);
// 이후 모든 랜덤 결정(단어 선택, 격자 배치)에 rng 사용
// 동일 날짜 = 동일 시드 = 모든 유저 동일 퍼즐
```

### 4.4 테마 랜덤 선택 알고리즘

```
function SelectTheme(unlockedThemes, previousTheme, rng):
    candidates = unlockedThemes.Copy()

    if candidates.Count >= 2 AND previousTheme != null:
        candidates.Remove(previousTheme)   // 직전 테마 제외

    index = rng.NextInt(0, candidates.Count)
    return candidates[index]
```

Daily Challenge의 경우:
```
seed = SeededRandom.GetDailySeed() + stageNumber
rng  = new SeededRandom(seed)
theme = SelectTheme(unlockedThemes, previousTheme, rng)
```

### 4.5 Sawtooth(톱니) 휴식 스테이지 판정

```
function IsRestStage(stage):
    return stage > 1 AND stage % 10 == 0

function GetRestWordCount(baseWordCount, startWordCount):
    return max(baseWordCount - 2, startWordCount)
```

### 4.6 경량 DDA 단어 수 조정 알고리즘

```
function GetAdjustedWordCount(baseWordCount, stage, mode, history):
    // Daily Challenge는 DDA 미적용
    if mode == DailyChallenge: return baseWordCount
    // 휴식 스테이지는 DDA 미적용
    if IsRestStage(stage): return GetRestWordCount(baseWordCount, StartWordCount)
    // 기록이 3스테이지 미만이면 조정 없음
    if history.Count < 3: return baseWordCount

    recent3 = history에서 최근 3개
    avgTime = average(recent3.ClearTime)
    avgHints = average(recent3.HintsUsed)
    failCount = count(recent3 where IsCleared == false)

    offset = 0
    if failCount == 0 AND avgHints == 0 AND avgTime < 90:
        offset = +1   // 너무 쉬움 → 단어 추가
    else if failCount >= 2 OR avgHints >= 2:
        offset = -1   // 너무 어려움 → 단어 감소

    // 누적 offset 범위 제한 (-2 ~ +2)
    totalOffset = clamp(currentOffset + offset, -2, +2)
    return clamp(baseWordCount + totalOffset, StartWordCount, MaxWordCount)
```

### 4.7 False Lead 배치 알고리즘

```
function PlaceFalseLeads(grid, placedWords, stage, rng):
    if stage < 11: return 0   // 스테이지 11 미만 비활성

    // 미배치 후보: placedWords에서 랜덤 선택
    candidates = shuffle(placedWords, rng)
    placedCount = 0

    for each word in candidates:
        if placedCount >= MAX_FALSE_LEADS: break

        prefixLen = rng.NextInt(PREFIX_LENGTH_MIN, PREFIX_LENGTH_MAX + 1)
        prefix = word.DisplayChars[0..prefixLen]

        // 격자 빈칸에 prefix를 8방향 중 랜덤 방향으로 배치 시도
        dir = AllDirections[rng.NextInt(0, 8)]
        startPos = 격자 빈칸 중 랜덤 선택

        if CanPlaceFalseLead(grid, prefix, startPos, dir):
            // prefix 글자를 배치하되, 이후 글자는 정답과 다른 글자로 채움
            PlacePrefix(grid, prefix, startPos, dir)
            PlaceWrongSuffix(grid, word, prefixLen, startPos, dir, rng)
            placedCount++

    return placedCount
```

---

## 5. 상태 관리 흐름

### 5.1 게임 상태 머신 (FSM)

```
          StartGame()
  [Idle] ---------> [Playing]
                      |    ^
               Pause()|    |Resume()
                      v    |
                    [Paused]

  [Playing] --IsAllFound()--> [Completed] --StartGame()--> [Idle] -> [Playing]
  [Playing] --OnTimeUp()----> [Failed]   --StartGame()--> [Idle] -> [Playing]
```

스테이지 연속 진행: `StartGame()`은 Idle이 아닌 상태(Completed/Failed)에서 호출되면 자동으로 상태를 Idle로 리셋한 뒤 새 게임을 시작한다.

### 5.2 화면 전환 상태 (v6.0)

v6.0에서는 Bottom Tab Bar 기반 내비게이션을 사용한다. ModeSelectScreen, SettingsScreen은 제거되었다.

```
  === Tab Screens (Tab Bar 표시됨) ===
  [Home (Title)] <--Tab--> [DailyChallenge] <--Tab--> [Stats]
                           [Collection*] (disabled, Coming Soon)

  === Push Screens (Tab Bar 숨김) ===
  [Home] --[Play]--> [Game] --> [Result]
                                  |
                                  +-> [Next] --> [Game] (다음 스테이지)
                                  +-> [Home] --> [Title]
                                  +-> [Retry] --> [Game] (동일 스테이지, 새 격자)

  [DailyChallenge] --[Play]--> [Game (daily seed)] --> [Result]

  === Popups (모달 오버레이) ===
  [Home] --[Settings 아이콘]--> SettingsPopup
  [Home] --[아바타 탭]--> AvatarSelectPopup
  [Game] --[Pause]--> PausePopup
```

### 5.3 데이터 흐름

```
[게임 시작]
    |
    v
WordLoader.LoadTheme(lang, theme)
    |
    v
WordLoader.GetRandomWords(pack, count, minLen, maxLen, rng)
    |
    v
GridGenerator.Generate(gridWidth, gridHeight, wordList, language, stage, pack)
  또는 .GenerateWithSeed(..., seed)   // Daily Challenge
    |
    v
GameController.StartGame(gridData, mode)
    |
    +---> [GameScreen.SetupGame() - 이벤트 연결 필수]
    |     GridInputHandler.OnSelectionChanged += cells =>
    |         GridView.HighlightCells(cells, CellState.Dragging);
    |     GridInputHandler.OnSelectionComplete += cells =>
    |         HandleSelectionComplete(cells);
    |           -> GameController.CheckWord(cells)
    |
    +---> GridInputHandler (사용자 터치/마우스 입력 수신)
    |         |
    |         v (OnSelectionChanged 발생 - 드래그 중)
    |     GridView.HighlightCells(cells, CellState.Dragging)
    |         (파란색 #2196F3 배경, 드래그 경로 셀 전체 즉시 적용)
    |         |
    |         v (OnSelectionComplete 발생 - 드래그 종료)
    |     DirectionSnapper.Snap(start, current, gridWidth, gridHeight)
    |         |
    |         v
    +---> GameController.CheckWord(selectedCells)
    |         |
    |     [정답] -> ScoreManager.AddWordScore()
    |         |     -> GridView.SetCellFound(cells, colorIndex)
    |         |     -> WordListView.MarkFound(word)
    |         |     -> AudioManager.PlaySFX(Success)
    |         |     -> IsAllFound() -> ForceComplete()
    |         |
    |     [오답] -> GridView.ClearHighlight(cells)
    |              -> AudioManager.PlaySFX(Fail)
    |
    +---> TimerManager (매 프레임 갱신)
    |         |
    |     [경고] -> UI 경고 표시 (텍스트 빨강 + 펄스)
    |     [초과] -> GameController.ForceFail()
    |
    v
[게임 종료]
    |
    v
GameController.GetGameResult()
    |
    v
GameManager.EndGame(result)
    |
    ├── SaveManager.UpdateStats(result)
    ├── SaveManager.TryUpdateBestTime(mode, time)  // 클리어 시만
    │     └── result.IsNewRecord = true (신기록 시)
    ├── CoinManager.Earn(stageClearReward)          // v6.0: 코인 보상 지급
    │     ├── +50 (스테이지 클리어)
    │     ├── +30 (힌트 미사용 보너스, 해당 시)
    │     └── +50 (S랭크 보너스, 해당 시)
    |
    v
ScreenManager.ShowScreen(Result, result)
```

---

## 6. Unity UI 구조

### 6.1 씬 계층 구조 (v6.0)

```
MainScene
├── [GameManager]                    # 싱글톤, DontDestroyOnLoad
│   ├── AudioManager
│   │   ├── BGM_Source (AudioSource)
│   │   └── SFX_Pool (AudioSource x5)
│   ├── SaveManager
│   ├── CoinManager                  # v6.0: 코인 관리
│   └── AvatarManager               # v6.0: 아바타 관리
│
├── MainCanvas (Canvas)              # Screen Space - Overlay
│   ├── BackgroundImage (Image)      # v6.0: 전체 화면 배경 이미지 (화면별 전환)
│   │
│   ├── [ScreenManager]
│   │   ├── TitleScreen (Panel)      # v6.0: Home Tab
│   │   │   ├── HeaderBar
│   │   │   │   ├── SettingsButton (Icon)
│   │   │   │   └── CoinDisplay (pill)
│   │   │   ├── AvatarCard
│   │   │   │   ├── AvatarFrame (원형 마스크)
│   │   │   │   └── GreetingText (TMP, 타자기 효과)
│   │   │   ├── ProgressCard
│   │   │   │   ├── LogoImage
│   │   │   │   ├── StageText (TMP)
│   │   │   │   └── ProgressBar
│   │   │   └── PlayButton (Green CTA)
│   │   │
│   │   // ModeSelectScreen 제거됨 (v6.0)
│   │   // ThemeSelectScreen, DifficultySelectScreen 제거됨 (v5.0)
│   │   │
│   │   ├── GameScreen (Panel)       # v6.0: Push Screen
│   │   │   ├── HeaderBar
│   │   │   │   ├── BackButton (Icon)
│   │   │   │   ├── LevelText (TMP)
│   │   │   │   ├── CoinDisplay (pill)
│   │   │   │   └── TimerText (TMP, Time Attack only)
│   │   │   ├── ThemeBanner (PANEL-02)
│   │   │   │   └── ThemeText (TMP)
│   │   │   ├── WordListContainer (Flow 레이아웃)
│   │   │   │   └── WordListView (HorizontalLayoutGroup, wrap)
│   │   │   │       └── WordListItem (Pooled Prefabs)
│   │   │   ├── GridCard (PANEL-01)
│   │   │   │   ├── GridView
│   │   │   │   │   └── GridLayoutGroup
│   │   │   │   │       └── GridCell (Pooled Prefabs)
│   │   │   │   └── GridInputHandler
│   │   │   └── HintBar (HorizontalLayoutGroup)
│   │   │       ├── ShuffleButton
│   │   │       ├── HintButton_200W
│   │   │       ├── HintButton_100W
│   │   │       └── RefreshButton
│   │   │
│   │   ├── ResultScreen (Panel)     # v6.0: Push Screen
│   │   │   └── CoinRewardDisplay
│   │   ├── DailyChallengeScreen (Panel)  # v6.0: Tab Screen
│   │   │   ├── CalendarView
│   │   │   ├── StreakCounter
│   │   │   └── PlayButton / LockOverlay
│   │   └── StatsScreen (Panel)      # v6.0: Tab Screen
│   │   // SettingsScreen 제거됨 -> SettingsPopup (v6.0)
│   │
│   ├── [BottomTabBar]               # v6.0: 하단 탭 바 (4탭)
│   │   ├── DailyTab (Icon + Label)
│   │   ├── HomeTab (Icon + Label)
│   │   ├── CollectionTab (Icon + Label, disabled)
│   │   └── StatsTab (Icon + Label)
│   │
│   └── [PopupManager]
│       ├── PopupOverlay (Image, raycastTarget)
│       ├── PausePopup (Panel)
│       ├── SettingsPopup (Panel)    # v6.0: 설정 팝업
│       └── AvatarSelectPopup (Panel)# v6.0: 아바타 선택 팝업
│
├── EventSystem
│   └── InputSystemUIInputModule
│
└── Camera (Main Camera)
```

### 6.2 Canvas 설정

| 항목 | 값 |
|------|-----|
| Render Mode | Screen Space - Overlay |
| UI Scale Mode | Scale With Screen Size |
| Reference Resolution | 1080 x 1920 (모바일 세로 기준) |
| Screen Match Mode | Match Width Or Height |
| Match | 0.5 (가로/세로 균등 배분) |

### 6.3 격자 셀 크기 동적 계산

```csharp
// GridView.RecalculateCellSize() 구현
float availableWidth = _gridContainer.rect.width - (_gridLayout.padding.left + _gridLayout.padding.right);
float availableHeight = _gridContainer.rect.height - (_gridLayout.padding.top + _gridLayout.padding.bottom);

float maxCellByWidth = (availableWidth - _gridLayout.spacing.x * (_gridSize - 1)) / _gridSize;
float maxCellByHeight = (availableHeight - _gridLayout.spacing.y * (_gridSize - 1)) / _gridSize;

float cellSize = Mathf.Min(maxCellByWidth, maxCellByHeight, _constants.CellSizeMax);
float minSize = (language == Language.KO) ? _constants.CellSizeMinKorean : _constants.CellSizeMin;
cellSize = Mathf.Max(cellSize, minSize);

_gridLayout.cellSize = new Vector2(cellSize, cellSize);
_gridLayout.constraintCount = _gridSize;
```

### 6.4 화면 전환 애니메이션

```csharp
// BaseScreen.FadeIn 구현
private IEnumerator FadeInCoroutine(float duration)
{
    _canvasGroup.alpha = 0f;
    _rootTransform.anchoredPosition = new Vector2(0, -40f);
    gameObject.SetActive(true);

    float elapsed = 0f;
    while (elapsed < duration)
    {
        elapsed += Time.deltaTime;
        float t = elapsed / duration;
        float ease = 1f - Mathf.Pow(1f - t, 3f);    // EaseOutCubic
        _canvasGroup.alpha = ease;
        _rootTransform.anchoredPosition = Vector2.Lerp(new Vector2(0, -40f), Vector2.zero, ease);
        yield return null;
    }

    _canvasGroup.alpha = 1f;
    _rootTransform.anchoredPosition = Vector2.zero;
    _canvasGroup.interactable = true;
    _canvasGroup.blocksRaycasts = true;
}
```

---

## 7. 입력 처리 상세

### 7.1 Unity Input System 설정

Input Actions Asset (`WordSearchInput.inputactions`):

| Action Map | Action | Binding |
|------------|--------|---------|
| UI | Navigate | WASD / Arrow Keys / Gamepad DPad |
| UI | Submit | Enter / Space / Gamepad South |
| UI | Cancel | Escape / Gamepad East |
| Gameplay | PointerPosition | Mouse Position / Touch #0 Position |
| Gameplay | PointerPress | Mouse Left Button / Touch #0 Press |

### 7.2 드래그 입력 처리

**주의사항 (구현 시 필수 확인):**
- GridInputHandler는 반드시 GridView 또는 Grid 루트 오브젝트에 부착하고, IPointerDownHandler / IDragHandler / IPointerUpHandler 인터페이스를 구현하거나 Unity Input System의 콜백을 올바르게 바인딩해야 한다
- EventSystem이 씬에 존재하고, InputSystemUIInputModule이 설정되어 있어야 한다
- GridCell에 Raycast Target이 활성화되어 있어야 한다
- Grid 영역을 덮는 투명 Image 컴포넌트(Raycast Target = true)를 Grid 위에 별도 배치하여 드래그 이벤트를 수신하는 방식을 권장한다 (개별 GridCell로 이벤트 분산 시 드래그 중 셀 전환이 안 되는 문제 방지)
- InputMode.Drag가 기본값이어야 한다

```csharp
// GridInputHandler - 드래그 모드
private void OnPointerDown(InputAction.CallbackContext ctx)
{
    Vector2 screenPos = _pointerPositionAction.ReadValue<Vector2>();
    Vector2Int? cell = _gridView.ScreenPosToGridPos(screenPos);
    if (!cell.HasValue) return;

    _isDragging = true;
    _startCell = cell.Value;
    _selectedCells.Clear();
    _selectedCells.Add(_startCell);
    _gridView.HighlightCells(_selectedCells, CellState.Dragging);
    AudioManager.Instance.PlaySFX(SFXType.Tick);
}

private void Update()
{
    if (!_isDragging || _currentMode != InputMode.Drag) return;

    Vector2 screenPos = _pointerPositionAction.ReadValue<Vector2>();
    Vector2Int? cell = _gridView.ScreenPosToGridPos(screenPos);
    if (!cell.HasValue) return;

    var newSelection = DirectionSnapper.Snap(_startCell, cell.Value, _gridView.GridSize);
    if (!newSelection.SequenceEqual(_selectedCells))
    {
        _gridView.ClearHighlight(_selectedCells);
        _selectedCells = newSelection;
        _gridView.HighlightCells(_selectedCells, CellState.Dragging);
    }
}

private void OnPointerUp(InputAction.CallbackContext ctx)
{
    if (!_isDragging) return;
    _isDragging = false;

    if (_selectedCells.Count >= 2)
    {
        OnSelectionComplete?.Invoke(_selectedCells);
    }
    _gridView.ClearHighlight(_selectedCells);
    _selectedCells.Clear();
}
```

### 7.3 탭 입력 처리

```csharp
// GridInputHandler - 탭 모드
private void OnTap(Vector2 screenPos)
{
    Vector2Int? cell = _gridView.ScreenPosToGridPos(screenPos);
    if (!cell.HasValue) return;

    if (!_tapStart.HasValue)
    {
        _tapStart = cell.Value;
        _gridView.HighlightCells(new List<Vector2Int> { _tapStart.Value }, CellState.Dragging);
        AudioManager.Instance.PlaySFX(SFXType.Tick);
    }
    else
    {
        var cells = DirectionSnapper.GetCellsBetween(_tapStart.Value, cell.Value);
        if (cells.Count >= 2)
        {
            OnSelectionComplete?.Invoke(cells);
        }
        _gridView.ClearHighlight(new List<Vector2Int> { _tapStart.Value });
        _tapStart = null;
    }
}
```

---

## 8. 성능 고려사항

| 항목 | 대응 |
|------|------|
| 격자 셀 풀링 | GridCell 프리팹을 Object Pool로 관리, 격자 크기 변경 시 재활용 |
| UI 리빌드 최소화 | CanvasGroup.alpha로 전환 제어, SetActive 호출 최소화 |
| TextMeshPro 캐싱 | TMP_Text.SetText()보다 text 프로퍼티 직접 할당 (GC 감소) |
| 타이머 | Update()에서 Time.deltaTime 누적, 별도 Coroutine 미사용 |
| JSON 로딩 | Resources.Load<TextAsset>로 1회 로드 후 Dictionary 캐싱 |
| 애니메이션 | DOTween 미사용, Coroutine + Mathf.Lerp로 경량 구현 |
| 메모리 | 격자 데이터 최대 10x10 = 100 char, GC 부담 없음 |
| 빌드 크기 | 오디오 OGG 압축, 스프라이트 Atlas 사용, 목표 50MB 이하 (v6.0: 배경 이미지 추가로 증가) |
| v6.0 배경 이미지 | ASTC 6x6 압축 (1080x1920 원본), 화면 전환 시 Sprite 교체 (메모리 상시 로드 아닌 화면별 로드) |
| v6.0 아바타 이미지 | 512x512 PNG, 투명 배경 (rembg 처리), ASTC 4x4 압축 |
| v6.0 코인 카운트 애니메이션 | int Lerp 기반, Update 대신 Coroutine (UI 반응성 우선) |

---

## 9. 플랫폼별 대응

| 항목 | Android | iOS | Windows |
|------|---------|-----|---------|
| 최소 버전 | API 24 (Android 7.0) | iOS 14.0 | Windows 10 |
| 입력 | Touch | Touch | Mouse + Keyboard |
| 해상도 | 다양 (Safe Area 대응) | 다양 (Notch 대응) | 1280x720 이상 |
| 저장 | PlayerPrefs (SharedPreferences) | PlayerPrefs (NSUserDefaults) | PlayerPrefs (Registry) |
| 오디오 포맷 | OGG Vorbis | OGG Vorbis (Unity 자동 변환) | OGG Vorbis |
| 빌드 | IL2CPP, ARM64 | IL2CPP, ARM64 | Mono, x64 |

### 9.1 Safe Area 대응

```csharp
// SafeAreaHandler.cs - 모든 화면 루트에 부착
public class SafeAreaHandler : MonoBehaviour
{
    private RectTransform _panel;
    private Rect _lastSafeArea;

    private void Update()
    {
        Rect safeArea = Screen.safeArea;
        if (safeArea != _lastSafeArea)
        {
            ApplySafeArea(safeArea);
            _lastSafeArea = safeArea;
        }
    }

    private void ApplySafeArea(Rect area)
    {
        Vector2 anchorMin = area.position;
        Vector2 anchorMax = area.position + area.size;
        anchorMin.x /= Screen.width;
        anchorMin.y /= Screen.height;
        anchorMax.x /= Screen.width;
        anchorMax.y /= Screen.height;

        _panel.anchorMin = anchorMin;
        _panel.anchorMax = anchorMax;
    }
}
```

---

## 10. 보안 및 무결성

| 항목 | 대응 |
|------|------|
| PlayerPrefs 변조 | 클라이언트 전용 게임이므로 치팅은 자기 기록에만 영향, 별도 보안 불필요 |
| Daily Challenge 동일성 | 날짜 기반 시드로 동일 퍼즐 생성, 서버 불필요 |
| 데이터 무결성 | SaveData JSON에 간단한 체크섬(CRC32) 추가 (선택) |
| 난독화 | IL2CPP 빌드로 기본 난독화 (추가 난독화 불필요) |

---

## 11. 테스트 전략

| 테스트 유형 | 대상 | 방법 |
|------------|------|------|
| 단위 테스트 | GridGenerator, ScoreManager, HangulUtils, DirectionSnapper, CoinManager | Unity Test Framework (EditMode) |
| 격자 검증 | 생성된 격자에 모든 단어가 실제로 존재하는지 | 에디터 스크립트로 1000회 생성 후 자동 검증 |
| 입력 테스트 | 드래그 인터랙션 | 실기기 (Android/iOS) 수동 테스트 |
| 반응형 테스트 | 다양한 해상도 레이아웃, Tab Bar + Safe Area | Unity Device Simulator |
| 성능 테스트 | 10x10 격자 생성 시간, 배경 이미지 전환 | Profiler 측정, 목표 100ms 이하 |
| 플레이 테스트 | 전체 게임 플로우 | 1회 플레이 사이클 전체 (홈 -> 게임 -> 결과 -> 통계) |
| v6.0 코인 테스트 | 코인 획득/소비 밸런스 검증 | 10 스테이지 연속 플레이 후 코인 잔액 확인 |
| v6.0 Tab Bar 테스트 | 탭 전환, Push/Pop 시 Tab Bar 표시/숨김 | 수동 테스트 |
| v6.0 아바타 테스트 | 아바타 선택, 닉네임 저장, 인사 메시지 시간대 | 수동 테스트 |
| 빌드 테스트 | Android/iOS 실기기 빌드 | 주 1회 실기기 빌드 및 동작 확인 |

---

*문서 끝*
