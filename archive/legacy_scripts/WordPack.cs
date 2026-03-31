namespace WordSearchPuzzle
{
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
        public string word;
        public int length;
        public string display;
        public string category;
    }
}
