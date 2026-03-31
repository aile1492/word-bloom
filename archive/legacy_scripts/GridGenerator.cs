using System.Collections.Generic;
using UnityEngine;

namespace WordSearchPuzzle
{
    public class GridGenerator
    {
        // v5.0: All 8 directions always allowed (single difficulty, stage-based progression)
        private static readonly Vector2Int[] AllDirections =
        {
            V(1, 0), V(-1, 0), V(0, 1), V(0, -1),
            V(1, 1), V(-1, -1), V(1, -1), V(-1, 1)
        };

        // Legacy direction map kept for backward compatibility
        private static readonly Dictionary<Difficulty, Vector2Int[]> DirectionMap =
            new Dictionary<Difficulty, Vector2Int[]>
        {
            { Difficulty.Easy,   new[] { V(1, 0), V(0, 1) } },
            { Difficulty.Normal, new[] { V(1, 0), V(-1, 0), V(0, 1), V(0, -1) } },
            { Difficulty.Hard,   new[] { V(1, 0), V(-1, 0), V(0, 1), V(0, -1), V(1, 1), V(1, -1) } },
            { Difficulty.Expert, AllDirections }
        };

        /// <summary>
        /// v5.0: Non-square grid generation with stage-based parameters.
        /// Uses all 8 directions. Integrates FalseLead for stage >= 11.
        /// </summary>
        public GridData Generate(int gridWidth, int gridHeight,
                                 List<WordEntry> wordList, Language language,
                                 int stage = 1, WordPack pack = null)
        {
            System.Random rng = new System.Random();
            return GenerateInternal(gridWidth, gridHeight, wordList, language, rng, stage, pack);
        }

        /// <summary>
        /// v5.0: Seeded non-square grid generation.
        /// </summary>
        public GridData GenerateWithSeed(int gridWidth, int gridHeight,
                                          List<WordEntry> wordList, Language language,
                                          int seed, int stage = 1, WordPack pack = null)
        {
            System.Random rng = new System.Random(seed);
            return GenerateInternal(gridWidth, gridHeight, wordList, language, rng, stage, pack);
        }

        /// <summary>
        /// Legacy: Square grid generation with difficulty-based directions.
        /// </summary>
        public GridData Generate(int gridSize, List<WordEntry> wordList,
                                 Difficulty difficulty, Language language,
                                 WordPack pack = null)
        {
            System.Random rng = new System.Random();
            return GenerateInternalLegacy(gridSize, wordList, difficulty, language, rng, pack);
        }

        /// <summary>
        /// Legacy: Seeded square grid generation with difficulty-based directions.
        /// </summary>
        public GridData GenerateWithSeed(int gridSize, List<WordEntry> wordList,
                                         Difficulty difficulty, Language language, int seed,
                                         WordPack pack = null)
        {
            System.Random rng = new System.Random(seed);
            return GenerateInternalLegacy(gridSize, wordList, difficulty, language, rng, pack);
        }

        private GridData GenerateInternal(int gridWidth, int gridHeight,
                                           List<WordEntry> wordList, Language language,
                                           System.Random rng, int stage, WordPack pack)
        {
            char[,] grid = new char[gridHeight, gridWidth];
            List<PlacedWord> placedWords = new List<PlacedWord>();

            List<WordEntry> sorted = new List<WordEntry>(wordList);
            sorted.Sort((a, b) =>
            {
                int lenA = GetDisplayChars(a, language).Length;
                int lenB = GetDisplayChars(b, language).Length;
                return lenB.CompareTo(lenA);
            });

            for (int w = 0; w < sorted.Count; w++)
            {
                WordEntry entry = sorted[w];
                string displayChars = GetDisplayChars(entry, language);

                bool placed = TryPlaceWord(grid, gridWidth, gridHeight, displayChars, AllDirections, rng,
                                           out Vector2Int startPos, out Vector2Int direction);

                if (placed)
                {
                    PlacedWord pw = new PlacedWord
                    {
                        OriginalWord = entry.word,
                        DisplayChars = displayChars,
                        StartPos = startPos,
                        Direction = direction,
                        IsFound = false
                    };
                    placedWords.Add(pw);
                }
                else
                {
                    Debug.LogWarning($"[GridGenerator] Skipped: {entry.word} (could not place after 100 attempts)");
                }
            }

            // v5.0: Place false leads before filling empty cells
            if (stage >= 11)
            {
                FalseLeadGenerator.PlaceFalseLeads(grid, gridWidth, gridHeight, placedWords, stage, rng);
            }

            FillEmptyCells(grid, gridWidth, gridHeight, language, rng, pack, placedWords);
            ValidateGrid(grid, placedWords);

            return new GridData
            {
                Width = gridWidth,
                Height = gridHeight,
                Grid = grid,
                PlacedWords = placedWords
            };
        }

        private GridData GenerateInternalLegacy(int gridSize, List<WordEntry> wordList,
                                                 Difficulty difficulty, Language language,
                                                 System.Random rng, WordPack pack)
        {
            char[,] grid = new char[gridSize, gridSize];
            List<PlacedWord> placedWords = new List<PlacedWord>();

            List<WordEntry> sorted = new List<WordEntry>(wordList);
            sorted.Sort((a, b) =>
            {
                int lenA = GetDisplayChars(a, language).Length;
                int lenB = GetDisplayChars(b, language).Length;
                return lenB.CompareTo(lenA);
            });

            Vector2Int[] allowedDirs = DirectionMap.ContainsKey(difficulty)
                ? DirectionMap[difficulty]
                : AllDirections;

            for (int w = 0; w < sorted.Count; w++)
            {
                WordEntry entry = sorted[w];
                string displayChars = GetDisplayChars(entry, language);

                bool placed = TryPlaceWord(grid, gridSize, gridSize, displayChars, allowedDirs, rng,
                                           out Vector2Int startPos, out Vector2Int direction);

                if (placed)
                {
                    PlacedWord pw = new PlacedWord
                    {
                        OriginalWord = entry.word,
                        DisplayChars = displayChars,
                        StartPos = startPos,
                        Direction = direction,
                        IsFound = false
                    };
                    placedWords.Add(pw);
                }
                else
                {
                    Debug.LogWarning($"[GridGenerator] Skipped: {entry.word} (could not place after 100 attempts)");
                }
            }

            FillEmptyCells(grid, gridSize, gridSize, language, rng, pack, placedWords);
            ValidateGrid(grid, placedWords);

            return new GridData
            {
                Width = gridSize,
                Height = gridSize,
                Grid = grid,
                PlacedWords = placedWords
            };
        }

        private bool TryPlaceWord(char[,] grid, int gridWidth, int gridHeight, string displayChars,
                                  Vector2Int[] allowedDirs, System.Random rng,
                                  out Vector2Int outStart, out Vector2Int outDir)
        {
            const int maxAttempts = 100;

            outStart = Vector2Int.zero;
            outDir = Vector2Int.zero;

            for (int attempt = 0; attempt < maxAttempts; attempt++)
            {
                Vector2Int dir = allowedDirs[rng.Next(allowedDirs.Length)];
                int startRow = rng.Next(gridHeight);
                int startCol = rng.Next(gridWidth);
                Vector2Int pos = new Vector2Int(startCol, startRow);

                if (CanPlace(grid, gridWidth, gridHeight, displayChars, pos, dir))
                {
                    for (int i = 0; i < displayChars.Length; i++)
                    {
                        int cx = pos.x + dir.x * i;
                        int cy = pos.y + dir.y * i;
                        grid[cy, cx] = displayChars[i];
                    }

                    outStart = pos;
                    outDir = dir;
                    return true;
                }
            }

            return false;
        }

        private bool CanPlace(char[,] grid, int gridWidth, int gridHeight, string chars,
                              Vector2Int pos, Vector2Int dir)
        {
            for (int i = 0; i < chars.Length; i++)
            {
                int cx = pos.x + dir.x * i;
                int cy = pos.y + dir.y * i;

                if (cx < 0 || cx >= gridWidth || cy < 0 || cy >= gridHeight)
                {
                    return false;
                }

                char existing = grid[cy, cx];
                if (existing != '\0' && existing != chars[i])
                {
                    return false;
                }
            }

            return true;
        }

        /// <summary>
        /// v5.0: English filler uses placed word character frequency distribution.
        /// </summary>
        private void FillEmptyCells(char[,] grid, int gridWidth, int gridHeight,
                                    Language language, System.Random rng, WordPack pack,
                                    List<PlacedWord> placedWords)
        {
            if (language == Language.KO)
            {
                FillEmptyCellsKorean(grid, gridWidth, gridHeight, rng, pack);
            }
            else
            {
                FillEmptyCellsEnglish(grid, gridWidth, gridHeight, rng, placedWords);
            }
        }

        private void FillEmptyCellsEnglish(char[,] grid, int gridWidth, int gridHeight,
                                            System.Random rng, List<PlacedWord> placedWords)
        {
            // Build frequency-weighted alphabet from placed words
            Dictionary<char, int> freq = new Dictionary<char, int>();
            for (int w = 0; w < placedWords.Count; w++)
            {
                foreach (char c in placedWords[w].DisplayChars)
                {
                    char upper = char.ToUpper(c);
                    if (upper >= 'A' && upper <= 'Z')
                    {
                        if (freq.ContainsKey(upper))
                        {
                            freq[upper]++;
                        }
                        else
                        {
                            freq[upper] = 1;
                        }
                    }
                }
            }

            // Build weighted pool
            List<char> pool = new List<char>();
            if (freq.Count > 0)
            {
                foreach (var kvp in freq)
                {
                    int weight = Mathf.Max(kvp.Value, 1);
                    for (int i = 0; i < weight; i++)
                    {
                        pool.Add(kvp.Key);
                    }
                }
            }
            else
            {
                // Fallback to full alphabet
                for (char c = 'A'; c <= 'Z'; c++)
                {
                    pool.Add(c);
                }
            }

            for (int y = 0; y < gridHeight; y++)
            {
                for (int x = 0; x < gridWidth; x++)
                {
                    if (grid[y, x] == '\0')
                    {
                        grid[y, x] = pool[rng.Next(pool.Count)];
                    }
                }
            }
        }

        private void FillEmptyCellsKorean(char[,] grid, int gridWidth, int gridHeight,
                                           System.Random rng, WordPack pack)
        {
            List<char> placedChars = new List<char>();
            for (int y = 0; y < gridHeight; y++)
            {
                for (int x = 0; x < gridWidth; x++)
                {
                    if (grid[y, x] != '\0' && HangulUtils.IsHangul(grid[y, x]))
                    {
                        placedChars.Add(grid[y, x]);
                    }
                }
            }

            char[] syllablePool = HangulUtils.BuildSyllablePool(pack);

            for (int y = 0; y < gridHeight; y++)
            {
                for (int x = 0; x < gridWidth; x++)
                {
                    if (grid[y, x] == '\0')
                    {
                        if (placedChars.Count > 0 && rng.Next(2) == 0)
                        {
                            char reference = placedChars[rng.Next(placedChars.Count)];
                            grid[y, x] = HangulUtils.GetRandomSimilarSyllable(reference, rng);
                        }
                        else
                        {
                            grid[y, x] = syllablePool[rng.Next(syllablePool.Length)];
                        }
                    }
                }
            }
        }

        private void ValidateGrid(char[,] grid, List<PlacedWord> placedWords)
        {
#if UNITY_EDITOR || DEVELOPMENT_BUILD
            for (int w = 0; w < placedWords.Count; w++)
            {
                PlacedWord pw = placedWords[w];
                for (int i = 0; i < pw.DisplayChars.Length; i++)
                {
                    int cx = pw.StartPos.x + pw.Direction.x * i;
                    int cy = pw.StartPos.y + pw.Direction.y * i;
                    char expected = pw.DisplayChars[i];
                    char actual = grid[cy, cx];

                    if (actual != expected)
                    {
                        Debug.LogError(
                            $"[GridGenerator] Validation failed for '{pw.OriginalWord}' " +
                            $"at ({cx},{cy}): expected '{expected}', got '{actual}'");
                    }
                }
            }
#endif
        }

        /// <summary>
        /// v6.0: Re-fill empty (non-word) cells with new random characters.
        /// Used by shuffle feature to randomize filler letters without moving placed words.
        /// </summary>
        public void ReFillEmptyCells(GridData gridData)
        {
            if (gridData == null || gridData.Grid == null)
            {
                return;
            }

            int gridWidth = gridData.Width;
            int gridHeight = gridData.Height;
            char[,] grid = gridData.Grid;

            // Build a set of all cells occupied by placed words
            HashSet<long> wordCells = new HashSet<long>();
            for (int w = 0; w < gridData.PlacedWords.Count; w++)
            {
                PlacedWord pw = gridData.PlacedWords[w];
                for (int i = 0; i < pw.DisplayChars.Length; i++)
                {
                    int cx = pw.StartPos.x + pw.Direction.x * i;
                    int cy = pw.StartPos.y + pw.Direction.y * i;
                    wordCells.Add((long)cy * gridWidth + cx);
                }
            }

            // Clear non-word cells
            for (int y = 0; y < gridHeight; y++)
            {
                for (int x = 0; x < gridWidth; x++)
                {
                    long key = (long)y * gridWidth + x;
                    if (!wordCells.Contains(key))
                    {
                        grid[y, x] = '\0';
                    }
                }
            }

            // Detect language from placed words
            bool isKorean = false;
            if (gridData.PlacedWords.Count > 0)
            {
                string firstChars = gridData.PlacedWords[0].DisplayChars;
                if (firstChars.Length > 0 && HangulUtils.IsHangul(firstChars[0]))
                {
                    isKorean = true;
                }
            }

            // Re-fill with new random characters
            System.Random rng = new System.Random();
            FillEmptyCells(grid, gridWidth, gridHeight,
                isKorean ? Language.KO : Language.EN,
                rng, null, gridData.PlacedWords);
        }

        private string GetDisplayChars(WordEntry entry, Language language)
        {
            if (!string.IsNullOrEmpty(entry.display))
            {
                return entry.display;
            }

            string langStr = (language == Language.KO) ? "ko" : "en";
            char[] chars = HangulUtils.GetDisplayChars(entry.word, langStr);
            return new string(chars);
        }

        private static Vector2Int V(int x, int y)
        {
            return new Vector2Int(x, y);
        }
    }
}
