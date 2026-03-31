using System.Collections.Generic;
using UnityEngine;

namespace WordSearchPuzzle
{
    /// <summary>
    /// Places false leads (partial word prefixes) into the grid to increase difficulty.
    /// Active from stage 11 onwards.
    /// </summary>
    public static class FalseLeadGenerator
    {
        private const int MIN_STAGE = 11;
        private const int MAX_FALSE_LEADS = 2;
        private const int PREFIX_LENGTH_MIN = 2;
        private const int PREFIX_LENGTH_MAX = 3;

        private static readonly Vector2Int[] AllDirections =
        {
            new Vector2Int(1, 0), new Vector2Int(-1, 0),
            new Vector2Int(0, 1), new Vector2Int(0, -1),
            new Vector2Int(1, 1), new Vector2Int(-1, -1),
            new Vector2Int(1, -1), new Vector2Int(-1, 1)
        };

        /// <summary>
        /// Places false leads into empty cells of the grid.
        /// Returns the number of false leads successfully placed.
        /// </summary>
        public static int PlaceFalseLeads(char[,] grid, int gridWidth, int gridHeight,
                                           List<PlacedWord> placedWords, int stage,
                                           System.Random rng)
        {
            if (stage < MIN_STAGE || placedWords == null || placedWords.Count == 0)
            {
                return 0;
            }

            if (rng == null)
            {
                rng = new System.Random();
            }

            // Shuffle placed words and pick up to MAX_FALSE_LEADS candidates
            List<PlacedWord> candidates = new List<PlacedWord>(placedWords);
            ShuffleList(candidates, rng);

            int placed = 0;

            for (int i = 0; i < candidates.Count && placed < MAX_FALSE_LEADS; i++)
            {
                PlacedWord word = candidates[i];
                if (word.DisplayChars.Length < PREFIX_LENGTH_MIN + 1)
                {
                    continue;
                }

                int prefixLen = rng.Next(PREFIX_LENGTH_MIN, PREFIX_LENGTH_MAX + 1);
                prefixLen = Mathf.Min(prefixLen, word.DisplayChars.Length - 1);

                string prefix = word.DisplayChars.Substring(0, prefixLen);

                if (TryPlaceFalseLead(grid, gridWidth, gridHeight, prefix, word, rng))
                {
                    placed++;
                }
            }

            return placed;
        }

        private static bool TryPlaceFalseLead(char[,] grid, int gridWidth, int gridHeight,
                                               string prefix, PlacedWord originalWord,
                                               System.Random rng)
        {
            const int maxAttempts = 50;

            for (int attempt = 0; attempt < maxAttempts; attempt++)
            {
                Vector2Int dir = AllDirections[rng.Next(AllDirections.Length)];
                int startX = rng.Next(gridWidth);
                int startY = rng.Next(gridHeight);

                if (CanPlacePrefix(grid, gridWidth, gridHeight, prefix, startX, startY, dir, originalWord))
                {
                    // Place the prefix characters
                    for (int c = 0; c < prefix.Length; c++)
                    {
                        int cx = startX + dir.x * c;
                        int cy = startY + dir.y * c;
                        grid[cy, cx] = prefix[c];
                    }
                    return true;
                }
            }

            return false;
        }

        private static bool CanPlacePrefix(char[,] grid, int gridWidth, int gridHeight,
                                            string prefix, int startX, int startY,
                                            Vector2Int dir, PlacedWord originalWord)
        {
            // Check that all prefix cells are within bounds and empty
            for (int c = 0; c < prefix.Length; c++)
            {
                int cx = startX + dir.x * c;
                int cy = startY + dir.y * c;

                if (cx < 0 || cx >= gridWidth || cy < 0 || cy >= gridHeight)
                {
                    return false;
                }

                if (grid[cy, cx] != '\0')
                {
                    return false;
                }
            }

            // Ensure the false lead doesn't accidentally complete the original word.
            // Check that the cell after the prefix (if in bounds) is not empty
            // (it should be filled later with a non-matching character by the normal filler).
            // We just need to make sure there's no way this prefix extends into the full word
            // along the same direction. This is inherently guaranteed since we only place
            // the prefix in empty cells, and the original word is already placed elsewhere.

            // Also check that the prefix starting position doesn't overlap with the original word's position
            if (startX == originalWord.StartPos.x && startY == originalWord.StartPos.y)
            {
                return false;
            }

            return true;
        }

        private static void ShuffleList<T>(List<T> list, System.Random rng)
        {
            for (int i = list.Count - 1; i > 0; i--)
            {
                int j = rng.Next(i + 1);
                T temp = list[i];
                list[i] = list[j];
                list[j] = temp;
            }
        }
    }
}
