# WordPuzzle UI 아이콘 아트 컨셉
> 나노바나나2 생성용 프롬프트 가이드
> 작성일: 2026-03-18

---

## 1. 아트 컨셉 요약

| 항목 | 내용 |
|------|------|
| 타겟 | 여성 (25~45세) |
| 레퍼런스 | Wordscapes, June's Journey, Gardenscapes |
| 스타일 | 세미플랫 일러스트 + 소프트 글로우 |
| 무드 | 힐링, 고급스러움, 따뜻함 |
| 배경 | 실사 자연 배경 위 반투명 다크 UI |
| 아이콘 | 둥글고 귀여운 심볼, 보석톤 컬러 |

---

## 2. 색상 팔레트 (반드시 준수)

```
■ 메인 퍼플       #6140BF  rgb(97, 64, 191)
■ 소프트 라벤더   #C4B5F4  rgb(196, 181, 244)
■ 액티브 오렌지   #FF8C00  rgb(255, 140, 0)
■ 골든 허니       #F5C842  rgb(245, 200, 66)
■ 화이트 글로우   #FFFFFF  rgb(255, 255, 255)
■ 소프트 민트     #7DD4C0  rgb(125, 212, 192)
■ 로즈 핑크       #FFB5B5  rgb(255, 181, 181)
■ 다크 베이스     #1A1A2E  rgb(26, 26, 46)
```

---

## 3. 아이콘 스타일 공통 프롬프트 (모든 아이콘에 앞에 붙여넣기)

```
masterpiece, best quality, ultra detailed,
game UI icon, flat illustration style, soft gradient shading,
rounded soft shapes, gentle glow outline,
purple and gold color palette, jewel tone accent,
clean white background, centered composition,
no text, no letters, simple clear symbol,
2D icon design, mobile game asset,
pastel soft colors, feminine cute style,
```

---

## 4. 공통 네거티브 프롬프트 (모든 아이콘에 동일 적용)

```
text, letters, words, alphabet, numbers,
realistic photo, 3d render, sketch, rough lines,
dark background, complex background,
blurry, low quality, noise, artifacts,
human face, body, character,
multiple objects, busy composition,
watermark, signature, border frame
```

---

## 5. 아이콘별 생성 프롬프트

### 5-1. 바텀 탭 아이콘 (5개)
> 생성 사이즈: **512 × 512**
> 최종 사이즈: **44 × 44** (Godot 내 자동 리사이즈)
> 저장 경로: `assets/icons/tabs/`

---

#### 🏠 홈 탭 (home.png)
```
[공통프롬프트]
cute small house icon,
soft purple roof with warm golden window light,
rounded cozy house shape, front door with heart detail,
soft lavender and gold colors, gentle purple glow outline
```

---

#### ☀️ 데일리 탭 (icon_tab_daily.png)
```
[공통프롬프트]
sun calendar daily challenge icon,
shining golden sun with soft rays, small calendar page below,
warm golden yellow and soft orange colors,
sparkle star accents, cheerful bright symbol
```

---

#### 👥 팀 탭 (icon_tab_team.png)
```
[공통프롬프트]
team friends group icon,
two cute round silhouette figures side by side,
soft lavender and mint color,
gentle glow, friendship symbol, rounded soft shapes
```

---

#### 🏆 컬렉션 탭 (icon_tab_collection.png)
```
[공통프롬프트]
trophy collection achievement icon,
elegant golden trophy cup,
star sparkles around it,
warm golden honey color, purple accent glow,
achievement reward symbol
```

---

#### 🛍️ 상점 탭 (icon_tab_shop.png)
```
[공통프롬프트]
shopping bag store icon,
cute rounded shopping bag with small star tag,
soft purple bag with golden handle,
small sparkle accents, shop symbol
```

---

### 5-2. UI 버튼 아이콘 (4개)
> 생성 사이즈: **512 × 512**
> 최종 사이즈: **64 × 64** (top bar 버튼 내부)
> 저장 경로: `assets/icons/ui/`

---

#### ← 뒤로가기 (icon_back.png)
```
[공통프롬프트]
left arrow back button icon,
clean bold left-pointing arrow, chevron style,
soft white color with gentle purple glow outline,
minimal simple shape, navigation symbol
```

---

#### ⚙️ 설정 (icon_settings.png)
```
[공통프롬프트]
settings gear icon,
single smooth gear cogwheel shape,
soft lavender purple color with golden center dot,
gentle glow, clean minimal gear symbol
```

---

#### 💡 힌트 (icon_hint.png)
```
[공통프롬프트]
hint lightbulb icon,
glowing light bulb with warm golden light,
soft glow rays around it, small sparkle accents,
golden and warm white colors, idea symbol
```

---

#### 🪙 코인 (icon_coin.png)
```
[공통프롬프트]
gold coin currency icon,
shiny metallic golden coin, slight 3/4 angle view,
star or sparkle on coin face, golden shimmer,
warm gold and honey yellow colors, coin stack hint
```

---

### 5-3. 탑바 우측 버튼 아이콘 (3개)
> 생성 사이즈: **512 × 512**
> 최종 사이즈: **64 × 64**
> 저장 경로: `assets/icons/ui/`

---

#### 📅 데일리 버튼 (icon_daily.png)
```
[공통프롬프트]
daily challenge star burst icon,
shining star with calendar lines,
golden star with sparkle rays,
bright warm yellow and gold color, daily reward symbol
```

---

#### ✅ 미션/태스크 (icon_task.png)
```
[공통프롬프트]
task checklist mission icon,
small clipboard with checkmark,
soft mint green checkmark, light purple clipboard,
completion achievement symbol, clean minimal
```

---

#### 🎁 선물 (icon_gift.png)
```
[공통프롬프트]
gift present reward icon,
cute wrapped gift box with bow ribbon on top,
soft purple box with golden ribbon bow,
sparkle accents, reward surprise symbol
```

---

## 6. 앱 아이콘 (스토어용)
> 생성 사이즈: **1024 × 1024**
> 저장 경로: `assets/ui/app_icon.png`

```
[공통프롬프트 제외 — 단독 프롬프트 사용]

masterpiece, best quality, ultra detailed,
mobile game app icon design,
word puzzle letter tiles arranged in cross/plus pattern,
soft frosted glass tiles with letters W O R D on them,
purple gradient background with soft golden glow,
jewel tone purple and gold color palette,
rounded square app icon shape,
elegant feminine game logo style,
sparkle light particles, premium feel,
no background outside rounded square,
clean sharp edges on tile letters
```

네거티브:
```
blurry, low quality, ugly, deformed,
dark muddy colors, busy cluttered,
realistic photo, human face, body
```

---

## 7. 생성 후 처리 파이프라인

```
나노바나나2 생성 (512×512 또는 1024×1024)
         ↓
  배경 제거 (rembg)
         ↓
  리사이즈
    탭 아이콘    → 44×44
    UI 아이콘    → 64×64
    앱 아이콘    → 1024×1024 (배경 유지)
         ↓
  Godot 프로젝트 복사
    assets/icons/tabs/
    assets/icons/ui/
    assets/ui/
```

---

## 8. 스타일 일관성 체크리스트

생성 후 아래 항목 확인:

- [ ] 모든 아이콘이 같은 "둥글고 부드러운" 느낌인가
- [ ] 퍼플·골드 컬러 팔레트가 일관되게 사용됐는가
- [ ] 배경이 깨끗하게 제거됐는가 (투명)
- [ ] 작은 크기(44px)에서도 심볼이 인식 가능한가
- [ ] 텍스트/글자가 포함되어 있지 않은가
