using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.EventSystems;

namespace WordSearchPuzzle
{
    /// <summary>
    /// 격자 드래그 입력을 처리한다.
    /// IPointerDownHandler / IDragHandler / IPointerUpHandler를 구현하여
    /// EventSystem 기반으로 동작한다.
    /// 이 컴포넌트가 부착된 오브젝트에는 Raycast Target이 활성화된
    /// Image 컴포넌트가 필요하다 (투명 이미지로 Grid 전체를 덮는다).
    /// </summary>
    public class GridInputHandler : MonoBehaviour,
        IPointerDownHandler, IDragHandler, IPointerUpHandler
    {
        [SerializeField] private GridView _gridView;

        // Events
        public event System.Action<List<Vector2Int>> OnSelectionComplete;
        public event System.Action<List<Vector2Int>> OnSelectionChanged;

        private const float DRAG_DEADZONE = 10f;

        // Drag state
        private bool _isDragging;
        private bool _isDragStarted;
        private Vector2 _dragStartScreenPos;
        private Vector2Int _startCell;
        private List<Vector2Int> _selectedCells = new List<Vector2Int>();
        private int _gridWidth;
        private int _gridHeight;

        private void Awake()
        {
            if (_gridView == null)
            {
                _gridView = GetComponentInChildren<GridView>();
            }

            if (_gridView == null)
            {
                _gridView = GetComponent<GridView>();
            }
        }

        /// <summary>
        /// GridView 참조와 격자 크기를 설정한다.
        /// GridView.Initialize() 후에 호출해야 한다.
        /// </summary>
        public void Initialize(GridView gridView)
        {
            _gridView = gridView;
            _gridWidth = gridView != null ? gridView.GridWidth : 0;
            _gridHeight = gridView != null ? gridView.GridHeight : 0;
        }

        /// <summary>
        /// 격자 크기만 갱신한다. Legacy square grid.
        /// </summary>
        public void SetGridSize(int gridSize)
        {
            _gridWidth = gridSize;
            _gridHeight = gridSize;
        }

        public void OnPointerDown(PointerEventData eventData)
        {
            if (_gridView == null)
            {
                return;
            }

            Vector2Int? cell = _gridView.ScreenPosToGridPos(eventData.position);

            if (!cell.HasValue)
            {
                return;
            }

            _isDragging = true;
            _isDragStarted = false;
            _dragStartScreenPos = eventData.position;
            _startCell = cell.Value;
            _selectedCells.Clear();
            _selectedCells.Add(_startCell);
            OnSelectionChanged?.Invoke(new List<Vector2Int>(_selectedCells));
        }

        public void OnDrag(PointerEventData eventData)
        {
            if (!_isDragging || _gridView == null)
            {
                return;
            }

            if (!_isDragStarted)
            {
                float distance = Vector2.Distance(eventData.position, _dragStartScreenPos);
                if (distance < DRAG_DEADZONE)
                {
                    return;
                }

                _isDragStarted = true;
            }

            Vector2Int? cell = _gridView.ScreenPosToGridPos(eventData.position);

            if (!cell.HasValue)
            {
                return;
            }

            List<Vector2Int> newSelection = DirectionSnapper.Snap(
                _startCell, cell.Value, _gridWidth, _gridHeight);

            if (!newSelection.SequenceEqual(_selectedCells))
            {
                _selectedCells = newSelection;
                OnSelectionChanged?.Invoke(new List<Vector2Int>(_selectedCells));
            }
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            if (!_isDragging)
            {
                return;
            }

            _isDragging = false;

            if (_selectedCells.Count >= 2)
            {
                OnSelectionComplete?.Invoke(new List<Vector2Int>(_selectedCells));
            }

            _selectedCells.Clear();
            OnSelectionChanged?.Invoke(new List<Vector2Int>());
        }

        private void OnDisable()
        {
            _isDragging = false;
            _selectedCells.Clear();
        }
    }
}
