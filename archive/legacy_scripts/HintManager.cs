using System.Collections.Generic;
using UnityEngine;

namespace WordSearchPuzzle
{
    /// <summary>
    /// v5.0: Single hint type (FirstLetter only). No popup, direct application.
    /// Tracks active hint cell state for drag interaction.
    /// </summary>
    public class HintManager
    {
        private int _remainingHints;
        private int _totalUsed;
        private int _firstLetterCost = 1;

        private PlacedWord _currentHintWord;
        private Vector2Int _currentHintCell;
        private bool _hasActiveHint;

        public HintManager(int initialHints)
        {
            _remainingHints = initialHints;
            _totalUsed = 0;
            _hasActiveHint = false;

            if (GameManager.Instance != null && GameManager.Instance.Constants != null)
            {
                _firstLetterCost = GameManager.Instance.Constants.FirstLetterCost;
            }
        }

        /// <summary>
        /// Selects a random unfound word and returns its first letter cell.
        /// If a hint is already active, clears it first (costs an additional use).
        /// </summary>
        public HintResult UseFirstLetter(List<PlacedWord> remainingWords)
        {
            if (!CanUse())
            {
                return null;
            }

            if (remainingWords == null || remainingWords.Count == 0)
            {
                return null;
            }

            PlacedWord target = remainingWords[Random.Range(0, remainingWords.Count)];

            _remainingHints -= _firstLetterCost;
            _totalUsed += _firstLetterCost;

            _currentHintWord = target;
            _currentHintCell = target.StartPos;
            _hasActiveHint = true;

            return new HintResult
            {
                TargetWord = target,
                HighlightCell = target.StartPos
            };
        }

        /// <summary>
        /// Called when the player starts dragging from the hint cell.
        /// </summary>
        public void OnHintCellDragStarted()
        {
            // State tracking only; GridCell transitions to Dragging externally
        }

        /// <summary>
        /// Called on drag end with wrong/cancelled result. Restores hint cell to HintFirstLetter.
        /// </summary>
        public void OnHintCellDragFailed()
        {
            // Hint stays active; GridCell should restore HintFirstLetter externally
        }

        /// <summary>
        /// Called on drag end with correct result. Clears hint state completely.
        /// </summary>
        public void OnHintCellDragSucceeded()
        {
            ClearActiveHint();
        }

        /// <summary>
        /// Returns true if a hint is currently displayed.
        /// </summary>
        public bool HasActiveHint()
        {
            return _hasActiveHint;
        }

        /// <summary>
        /// Returns the cell position of the current active hint.
        /// </summary>
        public Vector2Int GetHintCell()
        {
            return _currentHintCell;
        }

        /// <summary>
        /// Clears the active hint state.
        /// </summary>
        public void ClearActiveHint()
        {
            _currentHintWord = null;
            _hasActiveHint = false;
        }

        public int GetRemaining()
        {
            return _remainingHints;
        }

        public int GetTotalUsed()
        {
            return _totalUsed;
        }

        public bool CanUse()
        {
            // v6.0: Coin check is handled by GameScreen before calling UseFirstLetter()
            return true;
        }
    }
}
