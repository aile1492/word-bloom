namespace WordSearchPuzzle
{
    /// <summary>
    /// Daily Challenge용 시드 기반 의사난수 생성기 (LCG).
    /// 동일 시드 입력 시 모든 기기에서 동일한 시퀀스를 보장한다.
    /// LCG 파라미터: a = 1664525, c = 1013904223 (Numerical Recipes 계열).
    /// </summary>
    public class SeededRandom
    {
        private const uint LCG_A = 1664525u;
        private const uint LCG_C = 1013904223u;

        private uint _seed;

        public SeededRandom(int seed)
        {
            _seed = (uint)seed;
        }

        /// <summary>
        /// 날짜 기반 시드를 생성한다.
        /// 예: 2026-03-06 -> 20260306
        /// </summary>
        public static int GetDailySeed()
        {
            System.DateTime today = System.DateTime.Now;
            return today.Year * 10000 + today.Month * 100 + today.Day;
        }

        /// <summary>
        /// 0.0 ~ 1.0 범위의 의사난수를 반환한다.
        /// </summary>
        public float Next()
        {
            _seed = _seed * LCG_A + LCG_C;
            return (_seed >> 0) / (float)uint.MaxValue;
        }

        /// <summary>
        /// min (inclusive) ~ max (exclusive) 범위의 정수 의사난수를 반환한다.
        /// </summary>
        public int NextInt(int min, int max)
        {
            if (min >= max)
            {
                return min;
            }

            return min + (int)(Next() * (max - min));
        }
    }
}
