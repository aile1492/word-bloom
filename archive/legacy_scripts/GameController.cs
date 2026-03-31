using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace WordSearchPuzzle
{
    public class GameController : MonoBehaviour
    {
        public enum GameState
        {
            Idle,
            Playing,
            // Paused removed in v6.1 (no timer)
            Completed,
            Failed
        }

        public GameState CurrentState { get; private set; } = GameState.Idle;
        public GridData CurrentGrid { get; private set; }
        public GameMode CurrentMode { get; private set; }
        public Difficulty CurrentDifficulty { get; private set; }

        // Events
        public event System.Action<PlacedWord> OnWordFound;
        public event System.Action<GameResult> OnGameComplete;
        public event System.Action OnGameFail;
        public event System.Action<GameState> OnStateChanged;

        // Dependencies
        [SerializeField] private ScoreManager _scoreManager;
        // TimerManager removed in v6.1

        private HintManager _hintManager;
        private float _gameStartTime;
        private float _lastFindTime;

        /// <summary>
        /// 게임을 시작한다. Idle 상태에서만 호출 가능하다.
        /// </summary>
        public void StartGame(GridData gridData, GameMode mode, Difficulty difficulty)
        {
            if (CurrentState != GameState.Idle)
            {
                // Reset to Idle so a new game can start (e.g. next stage, retry)
                CurrentGrid = null;
                SetState(GameState.Idle);
            }

            CurrentGrid = gridData;
            CurrentMode = mode;
            CurrentDifficulty = difficulty;

            int initialHints = 3;
            if (GameManager.Instance != null && GameManager.Instance.Constants != null)
            {
                initialHints = GameManager.Instance.Constants.InitialHints;
            }
            _hintManager = new HintManager(initialHints);

            if (_scoreManager != null)
            {
                _scoreManager.Reset();
            }

            _gameStartTime = Time.time;
            _lastFindTime = Time.time;

            // Timer start removed in v6.1

            SetState(GameState.Playing);
        }

        /// <summary>
        /// Pause/Resume removed in v6.1 (no timer).
        /// Methods kept as empty stubs for backward compatibility.
        /// </summary>
        public void Pause()
        {
            // No-op: timer removed in v6.1
        }

        public void Resume()
        {
            // No-op: timer removed in v6.1
        }

        /// <summary>
        /// Playing -> Completed 전이. 모든 단어를 찾았을 때 호출한다.
        /// </summary>
        public void ForceComplete()
        {
            if (CurrentState != GameState.Playing)
            {
                return;
            }

            SetState(GameState.Completed);

            GameResult result = GetGameResult();
            OnGameComplete?.Invoke(result);
        }

        /// <summary>
        /// 게임을 중단하고 Idle 상태로 복귀한다.
        /// 메인메뉴 복귀 시 호출한다.
        /// </summary>
        public void Abandon()
        {
            CurrentGrid = null;
            SetState(GameState.Idle);
        }

        /// <summary>
        /// Playing -> Failed 전이. 시간 초과 시 호출한다.
        /// </summary>
        public void ForceFail()
        {
            if (CurrentState != GameState.Playing)
            {
                return;
            }

            SetState(GameState.Failed);
            OnGameFail?.Invoke();
        }

        /// <summary>
        /// 선택된 셀 좌표 목록이 미발견 단어와 일치하는지 검사한다.
        /// 일치하면 해당 단어를 찾음 상태로 변경하고 true를 반환한다.
        /// </summary>
        public bool CheckWord(List<Vector2Int> selectedCells)
        {
            if (CurrentState != GameState.Playing || CurrentGrid == null)
            {
                return false;
            }

            if (selectedCells == null || selectedCells.Count < 2)
            {
                return false;
            }

            for (int w = 0; w < CurrentGrid.PlacedWords.Count; w++)
            {
                PlacedWord pw = CurrentGrid.PlacedWords[w];

                if (pw.IsFound)
                {
                    continue;
                }

                List<Vector2Int> wordCells = GetWordCells(pw);

                // 정방향 일치 체크
                if (CellsMatch(selectedCells, wordCells))
                {
                    MarkWordFound(pw);
                    return true;
                }

                // 역방향 일치 체크
                List<Vector2Int> reversed = new List<Vector2Int>(wordCells);
                reversed.Reverse();
                if (CellsMatch(selectedCells, reversed))
                {
                    MarkWordFound(pw);
                    return true;
                }
            }

            return false;
        }

        /// <summary>
        /// 발견된 단어 목록을 반환한다.
        /// </summary>
        public List<PlacedWord> GetFoundWords()
        {
            if (CurrentGrid == null)
            {
                return new List<PlacedWord>();
            }

            return CurrentGrid.PlacedWords.Where(pw => pw.IsFound).ToList();
        }

        /// <summary>
        /// 미발견 단어 목록을 반환한다.
        /// </summary>
        public List<PlacedWord> GetRemainingWords()
        {
            if (CurrentGrid == null)
            {
                return new List<PlacedWord>();
            }

            return CurrentGrid.PlacedWords.Where(pw => !pw.IsFound).ToList();
        }

        /// <summary>
        /// 모든 단어를 찾았는지 반환한다.
        /// </summary>
        public bool IsAllFound()
        {
            if (CurrentGrid == null)
            {
                return false;
            }

            return CurrentGrid.PlacedWords.All(pw => pw.IsFound);
        }

        /// <summary>
        /// 현재 게임 결과를 계산하여 반환한다.
        /// </summary>
        public GameResult GetGameResult()
        {
            float totalTime = Time.time - _gameStartTime;
            int hintsUsed = _hintManager != null ? _hintManager.GetTotalUsed() : 0;

            float remainingTime = 0f;
            // Timer removed in v6.1, remainingTime always 0

            int finalScore = 0;
            string rank = "C";

            if (_scoreManager != null)
            {
                finalScore = _scoreManager.GetFinalScore(remainingTime, hintsUsed);

                float timeLimit = 0f;
                if (GameManager.Instance != null && GameManager.Instance.Constants != null)
                {
                    timeLimit = GameManager.Instance.Constants.GetTimeLimit(CurrentDifficulty);
                }
                rank = _scoreManager.GetRank(finalScore, totalTime, hintsUsed, timeLimit);
            }

            int wordsFound = CurrentGrid != null
                ? CurrentGrid.PlacedWords.Count(pw => pw.IsFound)
                : 0;

            int totalWords = CurrentGrid != null
                ? CurrentGrid.PlacedWords.Count
                : 0;

            return new GameResult
            {
                TotalTime = totalTime,
                Score = finalScore,
                WordsFound = wordsFound,
                TotalWords = totalWords,
                HintsUsed = hintsUsed,
                Rank = rank,
                IsNewRecord = false
            };
        }

        /// <summary>
        /// 힌트 매니저에 대한 접근자를 제공한다.
        /// </summary>
        public HintManager GetHintManager()
        {
            return _hintManager;
        }

        private void MarkWordFound(PlacedWord pw)
        {
            pw.IsFound = true;

            float elapsed = Time.time - _lastFindTime;
            _lastFindTime = Time.time;

            if (_scoreManager != null)
            {
                _scoreManager.AddWordScore(pw.DisplayChars.Length, elapsed);
            }

            // Time Attack bonus removed in v6.1

            OnWordFound?.Invoke(pw);

            if (IsAllFound())
            {
                ForceComplete();
            }
        }

        // HandleTimeUp removed in v6.1 (no timer)

        private void SetState(GameState newState)
        {
            CurrentState = newState;
            OnStateChanged?.Invoke(newState);
        }

        /// <summary>
        /// PlacedWord가 차지하는 셀 좌표 목록을 반환한다.
        /// </summary>
        private List<Vector2Int> GetWordCells(PlacedWord pw)
        {
            List<Vector2Int> cells = new List<Vector2Int>(pw.DisplayChars.Length);

            for (int i = 0; i < pw.DisplayChars.Length; i++)
            {
                int cx = pw.StartPos.x + pw.Direction.x * i;
                int cy = pw.StartPos.y + pw.Direction.y * i;
                cells.Add(new Vector2Int(cx, cy));
            }

            return cells;
        }

        /// <summary>
        /// 두 셀 목록이 동일한지 비교한다.
        /// </summary>
        private bool CellsMatch(List<Vector2Int> a, List<Vector2Int> b)
        {
            if (a.Count != b.Count)
            {
                return false;
            }

            for (int i = 0; i < a.Count; i++)
            {
                if (a[i] != b[i])
                {
                    return false;
                }
            }

            return true;
        }

        // OnDestroy timer cleanup removed in v6.1
    }
}
