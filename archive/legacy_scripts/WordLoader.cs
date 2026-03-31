using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace WordSearchPuzzle
{
    public class WordLoader
    {
        private Dictionary<string, WordPack> _cache = new Dictionary<string, WordPack>();

        private static readonly char[] EnglishAlphabet =
        {
            'A','B','C','D','E','F','G','H','I','J','K','L','M',
            'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'
        };

        /// <summary>
        /// Resources/Words/{lang}/{theme}.json 에서 단어 팩을 로드한다.
        /// 캐시가 있으면 캐시를 반환한다.
        /// </summary>
        public WordPack LoadTheme(Language language, string themeKey)
        {
            string cacheKey = $"{language}_{themeKey}";

            if (_cache.TryGetValue(cacheKey, out WordPack cached))
            {
                return cached;
            }

            string langFolder = (language == Language.EN) ? "en" : "ko";
            string path = $"Words/{langFolder}/{themeKey}";

            TextAsset textAsset = Resources.Load<TextAsset>(path);
            if (textAsset == null)
            {
                Debug.LogError($"[WordLoader] Word data not found: {path}");
                return null;
            }

            WordPack pack = JsonUtility.FromJson<WordPack>(textAsset.text);
            _cache[cacheKey] = pack;

            Resources.UnloadAsset(textAsset);
            return pack;
        }

        /// <summary>
        /// 조건에 맞는 단어를 Fisher-Yates 셔플로 랜덤 추출한다.
        /// display 길이 기준으로 minLen~maxLen 범위를 필터링한 뒤, count개를 반환한다.
        /// </summary>
        public List<WordEntry> GetRandomWords(WordPack pack, int count,
                                               int minLen, int maxLen,
                                               System.Random rng = null)
        {
            if (pack == null || pack.words == null || pack.words.Length == 0)
            {
                Debug.LogWarning("[WordLoader] WordPack is null or empty.");
                return new List<WordEntry>();
            }

            if (rng == null)
            {
                rng = new System.Random();
            }

            List<WordEntry> filtered = pack.words
                .Where(w => w.display != null
                         && w.display.Length >= minLen
                         && w.display.Length <= maxLen)
                .ToList();

            // Fisher-Yates Shuffle
            for (int i = filtered.Count - 1; i > 0; i--)
            {
                int j = rng.Next(i + 1);
                WordEntry temp = filtered[i];
                filtered[i] = filtered[j];
                filtered[j] = temp;
            }

            int takeCount = Mathf.Min(count, filtered.Count);
            return filtered.GetRange(0, takeCount);
        }

        /// <summary>
        /// 해당 언어의 교란용 알파벳 셋을 반환한다.
        /// 영어: A-Z, 한국어: 고빈도 완성형 음절 배열.
        /// </summary>
        public char[] GetAlphabet(Language language)
        {
            if (language == Language.KO)
            {
                return HangulUtils.GetWeightedSyllableAlphabet();
            }

            return EnglishAlphabet;
        }

        /// <summary>
        /// 캐시를 전부 비운다.
        /// </summary>
        public void ClearCache()
        {
            _cache.Clear();
        }
    }
}
