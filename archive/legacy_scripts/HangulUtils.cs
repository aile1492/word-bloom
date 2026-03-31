using System.Collections.Generic;

namespace WordSearchPuzzle
{
    public static class HangulUtils
    {
        private const int HANGUL_BASE = 0xAC00;
        private const int HANGUL_END = 0xD7A3;
        private const int JUNG_COUNT = 21;
        private const int JONG_COUNT = 28;

        // 허용 초성 인덱스 (14개): ㄱ ㄴ ㄷ ㄹ ㅁ ㅂ ㅅ ㅇ ㅈ ㅊ ㅋ ㅌ ㅍ ㅎ
        // 쌍자음(ㄲ ㄸ ㅃ ㅆ ㅉ) 제외
        private static readonly int[] ALLOWED_CHO =
        {
            0,  // ㄱ
            2,  // ㄴ
            3,  // ㄷ
            5,  // ㄹ
            6,  // ㅁ
            7,  // ㅂ
            9,  // ㅅ
            11, // ㅇ
            12, // ㅈ
            14, // ㅊ
            15, // ㅋ
            16, // ㅌ
            17, // ㅍ
            18  // ㅎ
        };

        // 허용 중성 인덱스 (8개): ㅏ ㅓ ㅗ ㅜ ㅡ ㅣ ㅐ ㅔ
        private static readonly int[] ALLOWED_JUNG =
        {
            0,  // ㅏ
            4,  // ㅓ
            8,  // ㅗ
            13, // ㅜ
            18, // ㅡ
            20, // ㅣ
            1,  // ㅐ
            5   // ㅔ
        };

        // 초성14 x 중성8 x 종성없음 = 112개 화이트리스트 음절 (캐시)
        private static char[] _syllableWhitelist;

        /// <summary>
        /// 한글 완성형 문자인지 판별한다 (U+AC00 ~ U+D7A3).
        /// </summary>
        public static bool IsHangul(char c)
        {
            return c >= HANGUL_BASE && c <= HANGUL_END;
        }

        /// <summary>
        /// 문자열을 격자 배치용 char 배열로 반환한다.
        /// 한국어: "호랑이" -> ['호','랑','이'] (음절 완성형 유지)
        /// 영어: "TIGER" -> ['T','I','G','E','R']
        /// </summary>
        public static char[] GetDisplayChars(string word, string language)
        {
            if (string.IsNullOrEmpty(word))
            {
                return new char[0];
            }

            if (language == "ko" || language == "KO")
            {
                return word.ToCharArray();
            }

            return word.ToUpper().ToCharArray();
        }

        /// <summary>
        /// 격자 빈칸 채우기용 허용 음절 화이트리스트를 반환한다.
        /// 초성(14) x 중성(8) x 종성없음 = 112개의 일상 음절만 포함.
        /// 묈, 뭏, 뭖 등 희귀 조합은 포함되지 않는다.
        /// </summary>
        public static char[] GetWeightedSyllableAlphabet()
        {
            if (_syllableWhitelist != null)
            {
                return _syllableWhitelist;
            }

            _syllableWhitelist = new char[ALLOWED_CHO.Length * ALLOWED_JUNG.Length];
            int idx = 0;

            for (int c = 0; c < ALLOWED_CHO.Length; c++)
            {
                for (int j = 0; j < ALLOWED_JUNG.Length; j++)
                {
                    int code = ALLOWED_CHO[c] * (JUNG_COUNT * JONG_COUNT)
                             + ALLOWED_JUNG[j] * JONG_COUNT
                             + 0; // 종성 없음
                    _syllableWhitelist[idx] = (char)(HANGUL_BASE + code);
                    idx++;
                }
            }

            return _syllableWhitelist;
        }

        /// <summary>
        /// 주어진 참조 음절과 동일 초성을 가진 다른 음절을 랜덤으로 반환한다.
        /// 허용 중성(8개) 중에서만 선택하며, 종성은 포함하지 않는다.
        /// 교란 글자 생성에 사용하여 난이도를 높인다.
        /// </summary>
        public static char GetRandomSimilarSyllable(char reference, System.Random rng)
        {
            if (!IsHangul(reference))
            {
                return reference;
            }

            int code = reference - HANGUL_BASE;
            int choIdx = code / (JUNG_COUNT * JONG_COUNT);

            // 동일 초성 + 허용 중성 중 랜덤 선택 + 종성 없음
            int jungPick = ALLOWED_JUNG[rng.Next(ALLOWED_JUNG.Length)];
            int newCode = choIdx * (JUNG_COUNT * JONG_COUNT) + jungPick * JONG_COUNT + 0;
            char result = (char)(HANGUL_BASE + newCode);

            // 원본과 같으면 다른 중성으로 한 번 더 시도
            if (result == reference)
            {
                int nextPick = ALLOWED_JUNG[(rng.Next(ALLOWED_JUNG.Length - 1) + 1) % ALLOWED_JUNG.Length];
                newCode = choIdx * (JUNG_COUNT * JONG_COUNT) + nextPick * JONG_COUNT + 0;
                result = (char)(HANGUL_BASE + newCode);
            }

            return result;
        }

        /// <summary>
        /// 완성형 한글 문자에서 초성 인덱스를 추출한다.
        /// </summary>
        public static int GetChosung(char c)
        {
            if (!IsHangul(c))
            {
                return -1;
            }

            int code = c - HANGUL_BASE;
            return code / (JUNG_COUNT * JONG_COUNT);
        }

        // 기본 보조 음절 50자 (풀 크기가 10 미만일 때 병합용)
        private static readonly char[] FALLBACK_SYLLABLES =
        {
            '가','나','다','라','마','바','사','아','자','차',
            '카','타','파','하','고','노','도','로','모','보',
            '소','오','조','호','구','누','두','루','무','부',
            '수','우','주','후','기','니','디','리','미','비',
            '시','이','지','히','대','해','세','네','레','메'
        };

        /// <summary>
        /// WordPack의 모든 단어에서 한글 음절을 추출하여 음절 풀을 구성한다.
        /// 풀 크기가 10 미만이면 기본 보조 음절 50자를 병합한다.
        /// </summary>
        public static char[] BuildSyllablePool(WordPack pack)
        {
            HashSet<char> syllables = new HashSet<char>();

            if (pack != null && pack.words != null)
            {
                for (int i = 0; i < pack.words.Length; i++)
                {
                    string word = pack.words[i].word;
                    if (string.IsNullOrEmpty(word))
                    {
                        continue;
                    }

                    for (int j = 0; j < word.Length; j++)
                    {
                        if (IsHangul(word[j]))
                        {
                            syllables.Add(word[j]);
                        }
                    }
                }
            }

            if (syllables.Count < 10)
            {
                for (int i = 0; i < FALLBACK_SYLLABLES.Length; i++)
                {
                    syllables.Add(FALLBACK_SYLLABLES[i]);
                }
            }

            char[] result = new char[syllables.Count];
            syllables.CopyTo(result);
            return result;
        }
    }
}
