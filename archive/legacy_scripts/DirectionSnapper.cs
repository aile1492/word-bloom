using System.Collections.Generic;
using UnityEngine;

namespace WordSearchPuzzle
{
    /// <summary>
    /// 드래그/탭 입력을 8방향 직선으로 스냅하는 정적 유틸리티.
    /// Section 4.2 pseudocode에 따라 Mathf.Atan2로 각도를 계산하고 45도 단위로 스냅한다.
    /// </summary>
    public static class DirectionSnapper
    {
        /// <summary>
        /// 8방향 정의. 인덱스 0 = 0도(오른쪽)부터 45도 간격으로 시계 방향.
        /// </summary>
        private static readonly Vector2Int[] Directions =
        {
            new Vector2Int( 1,  0),    //   0도: 오른쪽
            new Vector2Int( 1,  1),    //  45도: 우하단
            new Vector2Int( 0,  1),    //  90도: 아래
            new Vector2Int(-1,  1),    // 135도: 좌하단
            new Vector2Int(-1,  0),    // 180도: 왼쪽
            new Vector2Int(-1, -1),    // 225도: 좌상단
            new Vector2Int( 0, -1),    // 270도: 위
            new Vector2Int( 1, -1),    // 315도: 우상단
        };

        /// <summary>
        /// 시작 셀과 현재 셀 사이의 각도를 계산하여 가장 가까운 직선 방향으로 스냅한 뒤,
        /// 해당 방향의 셀 좌표 목록을 반환한다.
        /// </summary>
        public static List<Vector2Int> Snap(Vector2Int start, Vector2Int current, int gridSize)
        {
            return Snap(start, current, gridSize, gridSize);
        }

        public static List<Vector2Int> Snap(Vector2Int start, Vector2Int current,
                                             int gridWidth, int gridHeight)
        {
            int dx = current.x - start.x;
            int dy = current.y - start.y;

            if (dx == 0 && dy == 0)
            {
                return new List<Vector2Int> { start };
            }

            float angle = Mathf.Atan2(dy, dx) * Mathf.Rad2Deg;

            int snapIndex = Mathf.RoundToInt(angle / 45f);
            if (snapIndex < 0)
            {
                snapIndex += 8;
            }
            Vector2Int snapDir = Directions[snapIndex % 8];

            int distance = Mathf.Max(Mathf.Abs(dx), Mathf.Abs(dy));

            List<Vector2Int> cells = new List<Vector2Int>(distance + 1);

            for (int i = 0; i <= distance; i++)
            {
                int px = start.x + snapDir.x * i;
                int py = start.y + snapDir.y * i;

                if (px < 0 || px >= gridWidth || py < 0 || py >= gridHeight)
                {
                    break;
                }

                cells.Add(new Vector2Int(px, py));
            }

            return cells;
        }

        /// <summary>
        /// 두 셀 사이의 직선 경로에 포함되는 모든 셀 좌표를 반환한다.
        /// 두 셀이 직선(가로/세로/대각선) 관계가 아니면 빈 목록을 반환한다.
        /// </summary>
        public static List<Vector2Int> GetCellsBetween(Vector2Int start, Vector2Int end)
        {
            int dx = end.x - start.x;
            int dy = end.y - start.y;

            if (dx == 0 && dy == 0)
            {
                return new List<Vector2Int> { start };
            }

            // 직선 관계 검증: 가로, 세로, 또는 대각선(|dx| == |dy|)
            int absDx = Mathf.Abs(dx);
            int absDy = Mathf.Abs(dy);

            if (absDx != 0 && absDy != 0 && absDx != absDy)
            {
                // 직선이 아닌 경우 빈 목록 반환
                return new List<Vector2Int>();
            }

            int steps = Mathf.Max(absDx, absDy);

            // 단위 방향 벡터 계산
            int stepX = 0;
            int stepY = 0;

            if (dx != 0)
            {
                stepX = dx > 0 ? 1 : -1;
            }
            if (dy != 0)
            {
                stepY = dy > 0 ? 1 : -1;
            }

            List<Vector2Int> cells = new List<Vector2Int>(steps + 1);

            for (int i = 0; i <= steps; i++)
            {
                cells.Add(new Vector2Int(start.x + stepX * i, start.y + stepY * i));
            }

            return cells;
        }
    }
}
