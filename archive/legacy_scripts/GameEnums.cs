namespace WordSearchPuzzle
{
    public enum GameMode
    {
        Classic,
        TimeAttack,
        DailyChallenge
    }

    public enum Difficulty
    {
        Easy,
        Normal,
        Hard,
        Expert
    }

    public enum Language
    {
        EN,
        KO
    }

    public enum ScreenType
    {
        Title,
        Game,
        Result,
        DailyChallenge,
        Stats
    }

    public enum CellState
    {
        Idle,
        Hover,
        Dragging,
        Found,
        HintFirstLetter
    }

    public enum SFXType
    {
        Tick,
        Success,
        Fail,
        Clear,
        GameOver,
        Warning,
        Hint,
        Button,
        Transition,
        NewRecord,
        Combo
    }

    public enum BGMType
    {
        Menu,
        Play,
        Tension,
        Result
    }

    public enum UnlockType
    {
        Default,
        ClassicClear,
        TimeAttackClear,
        Streak,
        AllThemesClear
    }
}
