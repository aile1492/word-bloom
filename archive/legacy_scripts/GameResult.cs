namespace WordSearchPuzzle
{
    [System.Serializable]
    public class GameResult
    {
        public float TotalTime;
        public int Score;
        public int WordsFound;
        public int TotalWords;
        public int HintsUsed;
        public string Rank;
        public bool IsNewRecord;
        public int MaxCombo;
        public int CoinReward;
        public int CoinBreakdown_Clear;
        public int CoinBreakdown_NoHint;
        public int CoinBreakdown_SRank;
    }
}
