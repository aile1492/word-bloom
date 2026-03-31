using System.Collections.Generic;

namespace WordSearchPuzzle
{
    [System.Serializable]
    public class GridData
    {
        public int Width;
        public int Height;
        public char[,] Grid;
        public List<PlacedWord> PlacedWords;

        /// <summary>
        /// Legacy square grid compat. Returns Width.
        /// </summary>
        public int Size => Width;
    }
}
