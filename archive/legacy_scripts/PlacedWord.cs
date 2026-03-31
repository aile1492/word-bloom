using UnityEngine;

namespace WordSearchPuzzle
{
    [System.Serializable]
    public class PlacedWord
    {
        public string OriginalWord;
        public string DisplayChars;
        public Vector2Int StartPos;
        public Vector2Int Direction;
        public bool IsFound;
    }
}
