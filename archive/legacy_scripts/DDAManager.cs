using System.Collections.Generic;

namespace WordSearchPuzzle
{
    /// <summary>
    /// Lightweight Dynamic Difficulty Adjustment.
    /// Evaluates recent stage performance to adjust word count by +-1 (clamped to +-MAX_OFFSET).
    /// </summary>
    public class DDAManager
    {
        private readonly int _historySize;
        private readonly int _maxOffset;
        private readonly float _fastThreshold;
        private readonly int _highHintThreshold;

        private Queue<StagePerformance> _history;
        private int _currentOffset;

        [System.Serializable]
        public class StagePerformance
        {
            public float ClearTime;
            public int HintsUsed;
            public bool IsCleared;
        }

        public DDAManager(int historySize = 3, int maxOffset = 2,
                          float fastThreshold = 90f, int highHintThreshold = 2)
        {
            _historySize = historySize;
            _maxOffset = maxOffset;
            _fastThreshold = fastThreshold;
            _highHintThreshold = highHintThreshold;
            _history = new Queue<StagePerformance>();
            _currentOffset = 0;
        }

        public void RecordPerformance(GameResult result)
        {
            StagePerformance perf = new StagePerformance
            {
                ClearTime = result.TotalTime,
                HintsUsed = result.HintsUsed,
                IsCleared = result.WordsFound == result.TotalWords
            };

            _history.Enqueue(perf);

            while (_history.Count > _historySize)
            {
                _history.Dequeue();
            }

            RecalculateOffset();
        }

        /// <summary>
        /// Returns the current DDA word count offset (-MAX_OFFSET to +MAX_OFFSET).
        /// </summary>
        public int GetWordCountOffset()
        {
            return _currentOffset;
        }

        /// <summary>
        /// Calculates adjusted word count for a given stage.
        /// Rest stages and Daily Challenge bypass DDA.
        /// </summary>
        public int GetAdjustedWordCount(int baseWordCount, int stage, GameMode mode,
                                         GameConstantsAsset constants)
        {
            if (mode == GameMode.DailyChallenge)
            {
                return baseWordCount;
            }

            if (constants != null && constants.IsRestStage(stage))
            {
                int restCount = baseWordCount - constants.RestWordReduction;
                int minCount = constants != null ? constants.StartWordCount : 4;
                return restCount < minCount ? minCount : restCount;
            }

            int adjusted = baseWordCount + _currentOffset;
            int startWord = constants != null ? constants.StartWordCount : 4;
            int maxWord = constants != null ? constants.MaxWordCount : 12;

            if (adjusted < startWord) adjusted = startWord;
            if (adjusted > maxWord) adjusted = maxWord;

            return adjusted;
        }

        public void Reset()
        {
            _history.Clear();
            _currentOffset = 0;
        }

        private void RecalculateOffset()
        {
            if (_history.Count < _historySize)
            {
                return;
            }

            float totalTime = 0f;
            int totalHints = 0;
            int failCount = 0;
            bool allNoHints = true;

            foreach (StagePerformance perf in _history)
            {
                totalTime += perf.ClearTime;
                totalHints += perf.HintsUsed;

                if (!perf.IsCleared)
                {
                    failCount++;
                }

                if (perf.HintsUsed > 0)
                {
                    allNoHints = false;
                }
            }

            float avgTime = totalTime / _historySize;
            float avgHints = (float)totalHints / _historySize;

            // Too easy: all cleared, no hints, fast average
            if (allNoHints && avgTime < _fastThreshold)
            {
                _currentOffset++;
            }
            // Too hard: 2+ failures or high hint usage
            else if (failCount >= 2 || avgHints >= _highHintThreshold)
            {
                _currentOffset--;
            }

            // Clamp to max offset range
            if (_currentOffset > _maxOffset) _currentOffset = _maxOffset;
            if (_currentOffset < -_maxOffset) _currentOffset = -_maxOffset;
        }
    }
}
