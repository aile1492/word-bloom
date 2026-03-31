# CC_05: 분석 및 KPI 시스템 (Analytics & KPI System)

| 항목 | 내용 |
|------|------|
| **문서 ID** | CC_05 |
| **버전** | v1.0 |
| **작성일** | 2026-03-11 |
| **엔진** | Godot 4.6 Stable (GDScript) |
| **프로젝트** | 낱말 찾기(Word Search) 퍼즐 게임 |
| **분류** | Cross-Cutting (횡단 관심사) |
| **상태** | 초안 |

---

## 관련 문서

| 문서 ID | 제목 | 관계 |
|---------|------|------|
| P06_01 | 수익화 및 경제 시스템 | 수익 KPI 연동, IAP/광고 이벤트 정의 |
| P07_01 | 리텐션 시스템 | 리텐션 KPI 연동, 스트릭/출석 이벤트 정의 |
| P02_03 | 세이브 시스템 | 유저 프로퍼티 원본 데이터 |
| P05_01 | 게임모드 설계 | 모드별 플레이 이벤트 정의 |
| P04_01 | 힌트 시스템 | 힌트 사용 이벤트 정의 |
| P02_04 | 튜토리얼 | 튜토리얼 퍼널 분석 |
| CC_02 | TV 플랫폼 적응 | TV 환경 분석 제약사항 |
| P10_01 | 빌드 및 출시 | 스토어 콘솔 분석 연동 |

---

## 목차

1. [분석 전략 개요](#1-분석-전략-개요)
2. [핵심 KPI 정의](#2-핵심-kpi-정의)
3. [분석 이벤트 설계](#3-분석-이벤트-설계)
4. [유저 프로퍼티](#4-유저-프로퍼티)
5. [Firebase Analytics 구현](#5-firebase-analytics-구현)
6. [AnalyticsManager 구현 (GDScript)](#6-analyticsmanager-구현-gdscript)
7. [대시보드 설계](#7-대시보드-설계)
8. [A/B 테스트 프레임워크](#8-ab-테스트-프레임워크)
9. [프라이버시 및 규정 준수](#9-프라이버시-및-규정-준수)
10. [TV 플랫폼 분석](#10-tv-플랫폼-분석)
11. [알림 및 경보 설정](#11-알림-및-경보-설정)
12. [데이터 흐름 아키텍처](#12-데이터-흐름-아키텍처)
13. [참조 문서](#13-참조-문서)
14. [변경 이력](#14-변경-이력)

---

## 1. 분석 전략 개요

### 1.1 분석 목표

데이터 기반 의사결정(Data-Driven Decision Making)을 통해 게임의 품질, 수익, 유저 경험을 지속적으로 개선한다.

| 목표 | 설명 |
|------|------|
| **유저 행동 이해** | 어떤 모드를 선호하고, 어디서 이탈하는지 파악 |
| **수익 최적화** | 광고 빈도, IAP 가격, 힌트 경제의 최적점 탐색 |
| **리텐션 개선** | D1/D7/D30 리텐션 병목 구간 식별 및 개선 |
| **콘텐츠 방향** | 인기 테마, 적정 난이도, 모드별 수요 파악 |
| **기술 안정성** | 크래시율, 로딩 시간, 성능 문제 조기 감지 |

### 1.2 분석 도구 스택

```
[핵심 도구]
  Firebase Analytics (무료, 모바일 표준)
  ├── 이벤트 로깅
  ├── 유저 프로퍼티
  ├── Funnel 분석
  ├── Cohort 분석
  └── Remote Config (A/B 테스트)

[보조 도구]
  Google Play Console (Android)
  ├── 설치/제거 통계
  ├── 평점/리뷰 분석
  ├── ANR/크래시 리포트
  └── Acquisition 채널 분석

  App Store Connect (iOS)
  ├── 다운로드/매출 통계
  ├── 앱 분석 (App Analytics)
  └── 크래시 리포트

[크래시 추적]
  Firebase Crashlytics
  ├── 실시간 크래시 리포트
  ├── 스택 트레이스
  └── 영향받은 유저 수
```

### 1.3 핵심 설계 원칙

1. **최소 수집 원칙**: 의사결정에 필요한 데이터만 수집한다
2. **프라이버시 우선**: GDPR/CCPA 준수, 분석 동의 확보
3. **오프라인 지원**: Firebase 기본 제공 오프라인 캐싱 활용
4. **비용 효율**: 무료 티어(Firebase) 범위 내에서 운영
5. **플랫폼 대응**: 모바일/TV 환경별 분석 전략 분리

### 1.4 데이터 흐름 개요

```
[게임 클라이언트]                    [분석 백엔드]
 AnalyticsManager ──(Firebase SDK)──► Firebase Analytics
        │                                    │
        │                                    ▼
        │                            Firebase Console
        │                            ├── 대시보드
        │                            ├── Funnel
        │                            ├── Cohort
        │                            └── BigQuery Export (선택)
        │
        └──(로컬 캐시)──► 오프라인 이벤트 큐
                          (네트워크 복구 시 자동 전송)
```

---

## 2. 핵심 KPI 정의

### 2.1 사용자 지표 (User Metrics)

| KPI | 정의 | 목표 | 측정 주기 | 비고 |
|-----|------|------|-----------|------|
| **DAU** | 일일 활성 사용자 (Daily Active Users) | - | 일간 | 하루 1회 이상 세션 시작한 유니크 유저 |
| **MAU** | 월간 활성 사용자 (Monthly Active Users) | - | 월간 | 한 달간 1회 이상 접속한 유니크 유저 |
| **DAU/MAU Ratio** | 스티키니스 (Stickiness) | > 20% | 월간 | 높을수록 유저가 매일 방문 |
| **신규 설치** | 일일 신규 설치 수 (New Installs) | - | 일간 | 스토어 콘솔 데이터 교차 검증 |
| **세션 수** | 일일 평균 세션 수/유저 (Sessions per User) | > 2 | 일간 | 짧고 빈번한 세션이 이상적 |
| **세션 길이** | 평균 세션 시간 (Avg. Session Duration) | 5-10분 | 일간 | 너무 짧으면 콘텐츠 부족, 너무 길면 피로 |

**DAU/MAU Ratio 해석 기준:**

| 비율 | 평가 | 대응 |
|------|------|------|
| < 10% | 위험 | 일일 콘텐츠(Daily Challenge) 강화, Push 알림 검토 |
| 10-20% | 보통 | 출석 보상 개선, 알림 최적화 |
| 20-30% | 양호 | 현재 전략 유지, 세부 최적화 |
| > 30% | 우수 | 퍼즐 게임 상위 수준, 수익화 기회 확대 |

### 2.2 리텐션 지표 (Retention Metrics)

| KPI | 정의 | 목표 | 비고 |
|-----|------|------|------|
| **D1 Retention** | 설치 다음날 복귀율 | 40%+ | 첫 경험 품질의 직접 지표 |
| **D3 Retention** | 3일 후 복귀율 | 30%+ | 초기 루프 매력도 |
| **D7 Retention** | 7일 후 복귀율 | 20%+ | 핵심 루프 검증 |
| **D14 Retention** | 14일 후 복귀율 | 15%+ | 중기 콘텐츠 소비 패턴 |
| **D30 Retention** | 30일 후 복귀율 | 10%+ | 장기 리텐션 성공 기준 |
| **Churn Rate** | 이탈률 | < 60% (D1) | 1 - D1 Retention |
| **Resurrection Rate** | 7일+ 미접속 후 복귀율 | 추적 | Welcome-Back 시스템 효과 측정 |

**리텐션 퍼널 시각화 (P07_01 연동):**

```
100% ─── 설치
 │
 ▼
 40% ─── D1  (튜토리얼 완료, Daily Challenge 예고)
 │
 ▼
 30% ─── D3  (스트릭 보너스 +10%, 첫 업적 해금)
 │
 ▼
 20% ─── D7  (7일 출석 프리미엄 보상, 스트릭 +25%)
 │
 ▼
 15% ─── D14 (시즌 이벤트 참여, 컬렉션 진행)
 │
 ▼
 10% ─── D30 (스트릭 +100% 보너스, Gold 업적 도전)
```

**리텐션 저하 시 진단 체크리스트:**

| 구간 | 주요 원인 | 대응 |
|------|----------|------|
| D0→D1 이탈 | 튜토리얼 이탈, 첫 경험 불만 | 튜토리얼 간소화, 초반 보상 증가 |
| D1→D7 이탈 | 반복 피로, 콘텐츠 부족 | 모드 다양성 노출, 업적 시스템 활성화 |
| D7→D30 이탈 | 진행 정체, 과금 압박 | 난이도 조절, 무과금 경로 보완 |

### 2.3 수익 지표 (Revenue Metrics)

| KPI | 정의 | 목표 | 비고 |
|-----|------|------|------|
| **ARPDAU** | 일일 유저당 평균 수익 (Average Revenue Per Daily Active User) | $0.03+ | (총 일일 수익) / DAU |
| **ARPPU** | 과금 유저당 수익 (Average Revenue Per Paying User) | $5+ | (총 수익) / 과금 유저 수 |
| **Conversion Rate** | 과금 전환율 | 2-5% | (과금 유저) / (전체 유저) |
| **LTV** | 유저 생애 가치 (Lifetime Value) | > CAC | ARPDAU x 평균 수명(일) |
| **광고 eCPM** | 1000회 노출당 수익 (Effective Cost Per Mille) | 추적 | 광고 네트워크별 비교 |
| **광고 Fill Rate** | 광고 요청 대비 실제 노출 비율 | > 90% | 낮으면 네트워크 추가 검토 |
| **IAP 매출 비중** | 전체 수익 중 IAP 비율 | 추적 | 광고/IAP 밸런스 확인 |

**LTV 산출 공식:**

```
LTV = ARPDAU x (1 / (1 - D1_Retention)) x 보정계수

  간이 산출: LTV = ARPDAU x 평균_활동_일수

  예시:
    ARPDAU = $0.05
    평균 활동 일수 = 30일
    LTV = $0.05 x 30 = $1.50
```

**수익 구조 목표 (P06_01 연동):**

| 수익원 | 비중 목표 | 설명 |
|--------|----------|------|
| Rewarded Ad | 50-60% | 보상형 광고 (유저 자발적 시청) |
| Interstitial Ad | 15-20% | 전면 광고 (자연 전환점) |
| IAP (Coin/Gem) | 15-25% | 재화 구매 |
| Premium Pass | 5-10% | 구독 상품 |

### 2.4 게임플레이 지표 (Gameplay Metrics)

| KPI | 정의 | 목표 | 비고 |
|-----|------|------|------|
| **스테이지 클리어율** | 스테이지별 클리어 비율 | > 80% | 80% 미만 시 난이도 조정 검토 |
| **평균 클리어 시간** | 스테이지별 평균 완료 시간 | 추적 | 목표 시간 대비 편차 확인 |
| **힌트 사용률** | 힌트 사용 스테이지 비율 | 30-50% | 30% 미만: 너무 쉬움, 50% 초과: 너무 어려움 |
| **Daily Challenge 참여율** | DAU 대비 Daily 플레이 비율 | > 30% | 핵심 리텐션 드라이버 |
| **모드별 플레이 비율** | Classic / Time Attack / Daily / Marathon | 추적 | 콘텐츠 투자 방향 결정 |
| **Combo 발생률** | 연속 단어 발견 빈도 | 추적 | 게임 만족도 간접 지표 |
| **테마별 인기도** | 테마별 선택/클리어 횟수 | 추적 | 신규 테마 개발 방향 |
| **그리드 사이즈별 선호도** | 각 그리드 크기 플레이 비율 | 추적 | 난이도 커브 설계 참고 |

**스테이지 난이도 자동 진단 기준:**

```
스테이지 X의 건강 상태 진단:

  클리어율 < 50%  → [위험] 즉시 난이도 하향 검토
  클리어율 < 70%  → [주의] 힌트 가용성 확인, 단어 배치 검토
  클리어율 70-90% → [양호] 적정 난이도
  클리어율 > 95%  → [주의] 너무 쉬움, 보상 조정 또는 난이도 상향 검토

  힌트 사용률 > 60% → [주의] 해당 스테이지 단어 난이도 과도
  평균 클리어 시간 > 목표 x 2 → [주의] 격자 크기 또는 단어 수 조정
```

---

## 3. 분석 이벤트 설계

### 3.1 자동 이벤트 (Firebase 기본 제공)

Firebase Analytics가 자동으로 수집하는 이벤트이다. 별도 구현이 필요 없다.

| 이벤트 | 설명 | 활용 |
|--------|------|------|
| `first_open` | 앱 최초 실행 | 신규 유저 추적 |
| `session_start` | 세션 시작 | DAU, 세션 수 계산 |
| `screen_view` | 화면 전환 | 화면별 체류 시간, 네비게이션 패턴 |
| `app_update` | 앱 업데이트 | 업데이트 채택률 추적 |
| `app_remove` | 앱 삭제 (Android) | 이탈 시점 분석 |
| `os_update` | OS 업데이트 | 호환성 이슈 추적 |

### 3.2 커스텀 이벤트 목록

#### 3.2.1 튜토리얼 이벤트

| 이벤트 | 파라미터 | 트리거 시점 | 분석 목적 |
|--------|----------|------------|----------|
| `tutorial_step` | `step_number`: int, `completed`: bool | 튜토리얼 각 단계 시작/완료 | 튜토리얼 이탈 구간 식별 |
| `tutorial_complete` | `total_time`: float (초) | 튜토리얼 전체 완료 | 튜토리얼 완료율, 소요 시간 |
| `tutorial_skip` | `skipped_at_step`: int | 튜토리얼 건너뛰기 | 건너뛰기 비율 및 이후 리텐션 비교 |

#### 3.2.2 게임플레이 이벤트

| 이벤트 | 파라미터 | 트리거 시점 | 분석 목적 |
|--------|----------|------------|----------|
| `stage_start` | `mode`: string, `stage`: int, `theme`: string, `grid_size`: string | 스테이지 시작 | 모드/테마별 플레이 빈도 |
| `stage_complete` | `mode`: string, `stage`: int, `time`: float, `score`: int, `grade`: string, `hints_used`: int, `words_found`: int | 스테이지 클리어 | 클리어율, 성과 분포 |
| `stage_fail` | `mode`: string, `stage`: int, `time`: float, `reason`: string (timeout/quit) | 스테이지 실패 | 실패 원인 분석, 난이도 조정 |
| `word_found` | `mode`: string, `stage`: int, `word_length`: int, `combo_count`: int, `time_since_last`: float | 단어 발견 시 | Combo 패턴, 단어 발견 속도 |

#### 3.2.3 힌트/아이템 이벤트

| 이벤트 | 파라미터 | 트리거 시점 | 분석 목적 |
|--------|----------|------------|----------|
| `hint_used` | `hint_type`: string, `stage`: int, `coins_spent`: int | 힌트 사용 | 힌트 수요, 재화 소모 패턴 |

#### 3.2.4 경제 이벤트

| 이벤트 | 파라미터 | 트리거 시점 | 분석 목적 |
|--------|----------|------------|----------|
| `coin_earned` | `source`: string (clear/daily/ad/achievement), `amount`: int | 코인 획득 | 코인 유입 경로별 비중 |
| `coin_spent` | `purpose`: string (hint/theme/customize), `amount`: int | 코인 소모 | 코인 소비처별 비중 |
| `gem_earned` | `source`: string (iap/event), `amount`: int | 젬 획득 | 젬 유입량 추적 |
| `gem_spent` | `purpose`: string (coin_convert/premium_item/streak_protect), `amount`: int | 젬 소모 | 젬 소비처별 비중 |

#### 3.2.5 광고 이벤트

| 이벤트 | 파라미터 | 트리거 시점 | 분석 목적 |
|--------|----------|------------|----------|
| `ad_shown` | `ad_type`: string (rewarded/interstitial/banner), `placement`: string | 광고 노출 | 광고 노출 빈도, Fill Rate |
| `ad_clicked` | `ad_type`: string, `placement`: string | 광고 클릭 | CTR (Click-Through Rate) |
| `ad_rewarded` | `reward_type`: string, `amount`: int | 보상형 광고 완료 | 보상형 광고 완주율 |
| `ad_failed` | `ad_type`: string, `error`: string | 광고 로드 실패 | Fill Rate 문제 진단 |

#### 3.2.6 IAP 이벤트

| 이벤트 | 파라미터 | 트리거 시점 | 분석 목적 |
|--------|----------|------------|----------|
| `iap_initiated` | `product_id`: string, `price`: float | 구매 시작 (상품 선택) | 구매 퍼널 시작점 |
| `iap_completed` | `product_id`: string, `price`: float, `currency`: string | 구매 완료 | 실제 매출, 인기 상품 |
| `iap_failed` | `product_id`: string, `error`: string | 구매 실패 | 실패 원인 분석 |
| `iap_restored` | `product_id`: string | 구매 복원 | 복원 빈도 추적 |

#### 3.2.7 리텐션 관련 이벤트

| 이벤트 | 파라미터 | 트리거 시점 | 분석 목적 |
|--------|----------|------------|----------|
| `daily_login` | `day_in_cycle`: int, `streak_count`: int | 일일 로그인 보상 수령 | 출석 패턴, 스트릭 분포 |
| `streak_broken` | `streak_count`: int, `last_play_date`: string | 스트릭 끊김 감지 | 이탈 시점 분석 |
| `streak_protected` | `streak_count`: int, `gems_spent`: int | 스트릭 보호 사용 | 스트릭 보호 수요 |
| `welcome_back` | `days_away`: int, `bonus_received`: string | 복귀 유저 보너스 수령 | Welcome-Back 효과 측정 |

#### 3.2.8 진행도/수집 이벤트

| 이벤트 | 파라미터 | 트리거 시점 | 분석 목적 |
|--------|----------|------------|----------|
| `achievement_unlocked` | `achievement_id`: string, `tier`: string (bronze/silver/gold) | 업적 달성 | 업적 달성 분포 |
| `theme_unlocked` | `theme_id`: string, `method`: string (progress/purchase) | 테마 해금 | 테마 해금 경로 분석 |
| `collection_milestone` | `total_words`: int, `percentage`: float | 컬렉션 마일스톤 달성 | 수집 진행도 분포 |

#### 3.2.9 설정/시스템 이벤트

| 이벤트 | 파라미터 | 트리거 시점 | 분석 목적 |
|--------|----------|------------|----------|
| `settings_changed` | `setting_name`: string, `old_value`: string, `new_value`: string | 설정 변경 | 유저 선호도 파악 |
| `language_changed` | `from`: string, `to`: string | 언어 변경 | 다국어 수요 파악 |
| `share_result` | `platform`: string, `mode`: string | 결과 공유 | 바이럴 효과 추적 |
| `notification_permission` | `granted`: bool | 알림 권한 응답 | 알림 허용률 |
| `analytics_consent` | `granted`: bool, `region`: string | 분석 동의 응답 | GDPR 동의율 |

### 3.3 이벤트 네이밍 규칙

```
규칙:
  - snake_case 사용 (Firebase 표준)
  - 동사_명사 형태 (예: stage_complete, hint_used)
  - 이벤트 이름 최대 40자
  - 파라미터 이름 최대 40자
  - 파라미터 값(문자열) 최대 100자
  - 이벤트당 파라미터 최대 25개

금지:
  - firebase_, google_, ga_ 접두사 (Firebase 예약어)
  - 공백, 특수문자 (밑줄 제외)
  - 개인 식별 정보 (PII) 포함
```

### 3.4 이벤트 볼륨 예상

| 이벤트 그룹 | DAU 1,000명 기준 일일 예상 | 비고 |
|------------|--------------------------|------|
| 세션 관련 | ~2,500건 | 유저당 2.5세션 |
| 스테이지 관련 | ~5,000건 | 유저당 5스테이지 |
| 단어 발견 | ~30,000건 | 스테이지당 6단어 |
| 경제 관련 | ~3,000건 | 코인 획득/소모 |
| 광고 관련 | ~1,500건 | 유저당 1.5회 노출 |
| **합계** | **~42,000건/일** | Firebase 무료 한도(500건/유저/일) 내 |

---

## 4. 유저 프로퍼티

Firebase User Properties를 통해 유저를 세분화(Segmentation)하고 Cohort 분석에 활용한다.

### 4.1 유저 프로퍼티 정의

| 프로퍼티 | 타입 | 값 예시 | 설명 | 업데이트 시점 |
|---------|------|--------|------|--------------|
| `player_level` | int | 15 | 현재 도달 스테이지 | 스테이지 클리어 시 |
| `total_games` | int | 87 | 총 플레이 횟수 (모든 모드) | 스테이지 완료 시 |
| `preferred_mode` | string | "classic" | 가장 많이 플레이한 모드 | 세션 종료 시 재계산 |
| `language` | string | "ko" | 현재 게임 언어 | 언어 변경 시 |
| `is_premium` | bool | false | 구독/광고 제거 구매 여부 | 구매/구독 상태 변경 시 |
| `platform_type` | string | "mobile" | 플랫폼 (mobile/tv) | 앱 시작 시 |
| `days_since_install` | int | 14 | 설치 후 경과 일수 | 매 세션 시작 시 |
| `total_spend` | string | "0" | 총 과금 금액 (달러) | IAP 완료 시 |
| `spender_tier` | string | "none" | 과금 티어 (none/minnow/dolphin/whale) | IAP 완료 시 |
| `streak_best` | int | 12 | 최고 연속 플레이 일수 | 스트릭 갱신 시 |
| `ad_consent` | string | "granted" | 광고 추적 동의 여부 | 동의 팝업 응답 시 |

### 4.2 과금 티어 분류 기준

| 티어 | 총 과금 금액 | 비율 예상 | 설명 |
|------|------------|----------|------|
| **none** | $0 | ~95% | F2P 유저 |
| **minnow** | $0.01 - $9.99 | ~3% | 소액 과금 |
| **dolphin** | $10 - $49.99 | ~1.5% | 중액 과금 |
| **whale** | $50+ | ~0.5% | 고액 과금 |

### 4.3 유저 세그먼트 활용 예시

```
세그먼트 예시:

  [신규 유저]      days_since_install <= 3
  [핵심 유저]      days_since_install >= 14 AND total_games >= 50
  [이탈 위험]      days_since_install >= 7 AND total_games < 10
  [과금 유저]      spender_tier != "none"
  [TV 유저]        platform_type == "tv"
  [한국어 유저]    language == "ko"
  [하드코어]       preferred_mode == "time_attack" AND total_games >= 100
```

---

## 5. Firebase Analytics 구현

### 5.1 Godot Firebase 플러그인 설정

#### 5.1.1 플러그인 선택

| 항목 | 내용 |
|------|------|
| **플러그인** | godot-firebase (Android/iOS Native Plugin) |
| **지원 버전** | Godot 4.x |
| **설치 방법** | AssetLib 또는 GitHub Release |

#### 5.1.2 필수 설정 파일

```
[Android]
  android/build/google-services.json
  ← Firebase Console > 프로젝트 설정 > Android 앱에서 다운로드

[iOS]
  ios/GoogleService-Info.plist
  ← Firebase Console > 프로젝트 설정 > iOS 앱에서 다운로드
```

#### 5.1.3 프로젝트 설정 (project.godot)

```ini
[autoload]
AnalyticsManager="*res://scripts/managers/analytics_manager.gd"

[firebase]
; Firebase 플러그인 활성화
enabled=true
analytics_enabled=true
crashlytics_enabled=true
remote_config_enabled=true
```

#### 5.1.4 Android 빌드 설정 (build.gradle 추가)

```groovy
// android/build/build.gradle
dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-crashlytics'
    implementation 'com.google.firebase:firebase-config'
}

apply plugin: 'com.google.gms.google-services'
apply plugin: 'com.google.firebase.crashlytics'
```

### 5.2 Firebase Console 기본 설정

| 설정 항목 | 값 | 설명 |
|----------|-----|------|
| 데이터 보존 기간 | 14개월 | GDPR 권장 기간 |
| 인구통계/관심사 보고서 | 비활성화 | 프라이버시 보호 |
| Google 신호 데이터 | 비활성화 | 개인정보 최소 수집 |
| BigQuery 연동 | 필요 시 활성화 | 심층 분석용 (무료 티어 내) |
| 전환 이벤트 | `iap_completed`, `tutorial_complete` | 핵심 퍼널 이벤트 지정 |

---

## 6. AnalyticsManager 구현 (GDScript)

### 6.1 analytics_manager.gd (Autoload Singleton)

```gdscript
## AnalyticsManager - Firebase Analytics 래퍼 (Autoload Singleton)
## 모든 분석 이벤트를 중앙에서 관리한다.
## 경로: res://scripts/managers/analytics_manager.gd
class_name AnalyticsManager
extends Node

# ─── 상수 ───────────────────────────────────────────────
const MAX_PARAM_STRING_LENGTH := 100
const MAX_EVENT_NAME_LENGTH := 40
const MAX_PARAMS_PER_EVENT := 25

# ─── Firebase 플러그인 참조 ──────────────────────────────
var _firebase_analytics: Object = null
var _is_available := false
var _consent_granted := false

# ─── 디버그 ─────────────────────────────────────────────
@export var debug_mode := false  ## true 시 이벤트를 콘솔에 출력

# ─── 오프라인 큐 (Firebase 내장 캐싱 보완) ────────────────
var _offline_queue: Array[Dictionary] = []


func _ready() -> void:
	_initialize_firebase()
	_load_consent_state()
	_set_default_user_properties()


# ─── 초기화 ─────────────────────────────────────────────

func _initialize_firebase() -> void:
	"""Firebase Analytics 플러그인을 초기화한다."""
	if Engine.has_singleton("FirebaseAnalytics"):
		_firebase_analytics = Engine.get_singleton("FirebaseAnalytics")
		_is_available = true
		if debug_mode:
			print("[Analytics] Firebase Analytics 초기화 완료")
	else:
		_is_available = false
		if debug_mode:
			print("[Analytics] Firebase Analytics 사용 불가 (에디터 또는 미지원 플랫폼)")


func _load_consent_state() -> void:
	"""저장된 분석 동의 상태를 불러온다."""
	var save_data := SaveManager.get_save_data() if Engine.has_singleton("SaveManager") else {}
	_consent_granted = save_data.get("analytics_consent", false)


func _set_default_user_properties() -> void:
	"""기본 유저 프로퍼티를 설정한다."""
	var platform := "tv" if _is_tv_platform() else "mobile"
	set_user_property("platform_type", platform)
	set_user_property("language", TranslationServer.get_locale().substr(0, 2))


func _is_tv_platform() -> bool:
	"""TV 플랫폼 여부를 감지한다. (CC_02 PlatformDetector 연동)"""
	if Engine.has_singleton("PlatformDetector"):
		return Engine.get_singleton("PlatformDetector").is_tv()
	# Fallback: 화면 크기 기반 추정
	var screen_size := DisplayServer.screen_get_size()
	return screen_size.x >= 1920 and not DisplayServer.is_touchscreen_available()


# ─── 핵심 API ───────────────────────────────────────────

func log_event(event_name: String, params: Dictionary = {}) -> void:
	"""
	분석 이벤트를 로깅한다.
	동의하지 않은 경우 이벤트를 무시한다.
	"""
	if not _consent_granted:
		if debug_mode:
			print("[Analytics] 동의 미확보 - 이벤트 무시: %s" % event_name)
		return

	# 이벤트 이름 검증
	event_name = _sanitize_event_name(event_name)

	# 파라미터 검증 및 정제
	var sanitized_params := _sanitize_params(params)

	if debug_mode:
		print("[Analytics] Event: %s | Params: %s" % [event_name, str(sanitized_params)])

	if _is_available and _firebase_analytics:
		_firebase_analytics.log_event(event_name, sanitized_params)
	elif debug_mode:
		# 에디터 환경에서는 콘솔 출력만
		pass


func set_user_property(property_name: String, value: String) -> void:
	"""유저 프로퍼티를 설정한다."""
	if not _consent_granted:
		return

	if debug_mode:
		print("[Analytics] UserProperty: %s = %s" % [property_name, value])

	if _is_available and _firebase_analytics:
		_firebase_analytics.set_user_property(property_name, value)


func set_screen(screen_name: String) -> void:
	"""현재 화면 이름을 설정한다 (screen_view 이벤트 자동 연동)."""
	if not _consent_granted:
		return

	if debug_mode:
		print("[Analytics] Screen: %s" % screen_name)

	if _is_available and _firebase_analytics:
		_firebase_analytics.set_screen_name(screen_name)


func set_consent(granted: bool) -> void:
	"""분석 동의 상태를 설정한다."""
	_consent_granted = granted

	if _is_available and _firebase_analytics:
		_firebase_analytics.set_analytics_collection_enabled(granted)

	# 동의 상태 저장
	log_event("analytics_consent", {
		"granted": granted,
		"region": _get_user_region()
	})

	if debug_mode:
		print("[Analytics] 동의 상태 변경: %s" % str(granted))


# ─── 검증/정제 유틸리티 ──────────────────────────────────

func _sanitize_event_name(name: String) -> String:
	"""이벤트 이름을 Firebase 규칙에 맞게 정제한다."""
	name = name.to_lower().strip_edges()
	# 예약 접두사 제거
	for prefix in ["firebase_", "google_", "ga_"]:
		if name.begins_with(prefix):
			name = "custom_" + name
			break
	# 길이 제한
	if name.length() > MAX_EVENT_NAME_LENGTH:
		name = name.substr(0, MAX_EVENT_NAME_LENGTH)
	return name


func _sanitize_params(params: Dictionary) -> Dictionary:
	"""파라미터를 Firebase 규칙에 맞게 정제한다."""
	var result := {}
	var count := 0

	for key in params:
		if count >= MAX_PARAMS_PER_EVENT:
			if debug_mode:
				push_warning("[Analytics] 파라미터 수 초과 (최대 %d): %s" % [MAX_PARAMS_PER_EVENT, key])
			break

		var value = params[key]

		# 문자열 값 길이 제한
		if value is String and value.length() > MAX_PARAM_STRING_LENGTH:
			value = value.substr(0, MAX_PARAM_STRING_LENGTH)

		# bool → int 변환 (Firebase는 bool 미지원)
		if value is bool:
			value = 1 if value else 0

		result[key] = value
		count += 1

	return result


func _get_user_region() -> String:
	"""유저의 지역 코드를 반환한다 (ISO 3166-1 alpha-2)."""
	return OS.get_locale_language()  # Fallback: 시스템 로케일 기반


# ─── 편의 메서드: 튜토리얼 ──────────────────────────────

func log_tutorial_step(step_number: int, completed: bool) -> void:
	log_event("tutorial_step", {
		"step_number": step_number,
		"completed": completed,
	})


func log_tutorial_complete(total_time: float) -> void:
	log_event("tutorial_complete", {
		"total_time": snapped(total_time, 0.1),
	})


func log_tutorial_skip(skipped_at_step: int) -> void:
	log_event("tutorial_skip", {
		"skipped_at_step": skipped_at_step,
	})


# ─── 편의 메서드: 게임플레이 ──────────────────────────────

func log_stage_start(mode: String, stage: int, theme: String, grid_size: String) -> void:
	log_event("stage_start", {
		"mode": mode,
		"stage": stage,
		"theme": theme,
		"grid_size": grid_size,
	})


func log_stage_complete(mode: String, stage: int, time: float, score: int,
		grade: String, hints_used: int, words_found: int) -> void:
	log_event("stage_complete", {
		"mode": mode,
		"stage": stage,
		"time": snapped(time, 0.1),
		"score": score,
		"grade": grade,
		"hints_used": hints_used,
		"words_found": words_found,
	})

	# 유저 프로퍼티 업데이트
	set_user_property("player_level", str(stage))
	_increment_total_games()


func log_stage_fail(mode: String, stage: int, time: float, reason: String) -> void:
	log_event("stage_fail", {
		"mode": mode,
		"stage": stage,
		"time": snapped(time, 0.1),
		"reason": reason,  # "timeout" 또는 "quit"
	})


func log_word_found(mode: String, stage: int, word_length: int,
		combo_count: int, time_since_last: float) -> void:
	log_event("word_found", {
		"mode": mode,
		"stage": stage,
		"word_length": word_length,
		"combo_count": combo_count,
		"time_since_last": snapped(time_since_last, 0.1),
	})


# ─── 편의 메서드: 힌트 ───────────────────────────────────

func log_hint_used(hint_type: String, stage: int, coins_spent: int) -> void:
	log_event("hint_used", {
		"hint_type": hint_type,
		"stage": stage,
		"coins_spent": coins_spent,
	})


# ─── 편의 메서드: 경제 ───────────────────────────────────

func log_coin_earned(source: String, amount: int) -> void:
	log_event("coin_earned", {
		"source": source,  # "clear", "daily", "ad", "achievement"
		"amount": amount,
	})


func log_coin_spent(purpose: String, amount: int) -> void:
	log_event("coin_spent", {
		"purpose": purpose,  # "hint", "theme", "customize"
		"amount": amount,
	})


func log_gem_earned(source: String, amount: int) -> void:
	log_event("gem_earned", {
		"source": source,
		"amount": amount,
	})


func log_gem_spent(purpose: String, amount: int) -> void:
	log_event("gem_spent", {
		"purpose": purpose,
		"amount": amount,
	})


# ─── 편의 메서드: 광고 ───────────────────────────────────

func log_ad_shown(ad_type: String, placement: String) -> void:
	log_event("ad_shown", {
		"ad_type": ad_type,  # "rewarded", "interstitial", "banner"
		"placement": placement,
	})


func log_ad_clicked(ad_type: String, placement: String) -> void:
	log_event("ad_clicked", {
		"ad_type": ad_type,
		"placement": placement,
	})


func log_ad_rewarded(reward_type: String, amount: int) -> void:
	log_event("ad_rewarded", {
		"reward_type": reward_type,
		"amount": amount,
	})


func log_ad_failed(ad_type: String, error: String) -> void:
	log_event("ad_failed", {
		"ad_type": ad_type,
		"error": error,
	})


# ─── 편의 메서드: IAP ────────────────────────────────────

func log_iap_initiated(product_id: String, price: float) -> void:
	log_event("iap_initiated", {
		"product_id": product_id,
		"price": price,
	})


func log_iap_completed(product_id: String, price: float, currency: String) -> void:
	log_event("iap_completed", {
		"product_id": product_id,
		"price": price,
		"currency": currency,
	})

	# 과금 티어 업데이트
	_update_spender_tier(price)


func log_iap_failed(product_id: String, error: String) -> void:
	log_event("iap_failed", {
		"product_id": product_id,
		"error": error,
	})


# ─── 편의 메서드: 리텐션 ──────────────────────────────────

func log_daily_login(day_in_cycle: int, streak_count: int) -> void:
	log_event("daily_login", {
		"day_in_cycle": day_in_cycle,
		"streak_count": streak_count,
	})

	set_user_property("streak_best", str(streak_count))


func log_streak_broken(streak_count: int, last_play_date: String) -> void:
	log_event("streak_broken", {
		"streak_count": streak_count,
		"last_play_date": last_play_date,
	})


func log_welcome_back(days_away: int, bonus_received: String) -> void:
	log_event("welcome_back", {
		"days_away": days_away,
		"bonus_received": bonus_received,
	})


# ─── 편의 메서드: 진행도 ──────────────────────────────────

func log_achievement_unlocked(achievement_id: String, tier: String) -> void:
	log_event("achievement_unlocked", {
		"achievement_id": achievement_id,
		"tier": tier,  # "bronze", "silver", "gold"
	})


func log_theme_unlocked(theme_id: String, method: String) -> void:
	log_event("theme_unlocked", {
		"theme_id": theme_id,
		"method": method,  # "progress", "purchase"
	})


# ─── 편의 메서드: 설정 ───────────────────────────────────

func log_settings_changed(setting_name: String, old_value: String, new_value: String) -> void:
	log_event("settings_changed", {
		"setting_name": setting_name,
		"old_value": old_value,
		"new_value": new_value,
	})


func log_language_changed(from_lang: String, to_lang: String) -> void:
	log_event("language_changed", {
		"from": from_lang,
		"to": to_lang,
	})

	set_user_property("language", to_lang)


func log_share_result(platform: String, mode: String) -> void:
	log_event("share_result", {
		"platform": platform,
		"mode": mode,
	})


# ─── 내부 유틸리티 ───────────────────────────────────────

var _total_games_cache := 0

func _increment_total_games() -> void:
	"""총 플레이 횟수를 증가시키고 유저 프로퍼티를 업데이트한다."""
	_total_games_cache += 1
	set_user_property("total_games", str(_total_games_cache))


var _total_spend_cache := 0.0

func _update_spender_tier(price: float) -> void:
	"""과금 금액 누적 및 과금 티어를 업데이트한다."""
	_total_spend_cache += price
	set_user_property("total_spend", str(snapped(_total_spend_cache, 0.01)))

	var tier := "none"
	if _total_spend_cache >= 50.0:
		tier = "whale"
	elif _total_spend_cache >= 10.0:
		tier = "dolphin"
	elif _total_spend_cache > 0.0:
		tier = "minnow"

	set_user_property("spender_tier", tier)


func update_days_since_install() -> void:
	"""설치 후 경과 일수를 업데이트한다. 매 세션 시작 시 호출."""
	var save_data := SaveManager.get_save_data() if Engine.has_singleton("SaveManager") else {}
	var install_date: String = save_data.get("install_date", "")

	if install_date.is_empty():
		set_user_property("days_since_install", "0")
		return

	# ISO 8601 날짜 기준 경과일 계산
	var now := Time.get_date_dict_from_system()
	var now_unix := Time.get_unix_time_from_system()
	# 간이 계산: install_date를 unix로 변환하여 차이 계산
	set_user_property("days_since_install", str(int(now_unix / 86400.0)))


func update_preferred_mode(mode_play_counts: Dictionary) -> void:
	"""가장 많이 플레이한 모드를 유저 프로퍼티로 설정한다."""
	if mode_play_counts.is_empty():
		return

	var max_mode := ""
	var max_count := 0

	for mode in mode_play_counts:
		if mode_play_counts[mode] > max_count:
			max_count = mode_play_counts[mode]
			max_mode = mode

	if not max_mode.is_empty():
		set_user_property("preferred_mode", max_mode)
```

### 6.2 호출 예시

```gdscript
# ─── 튜토리얼에서의 호출 예시 ──────────────────────────────
# tutorial_scene.gd

func _on_tutorial_step_completed(step: int) -> void:
	AnalyticsManager.log_tutorial_step(step, true)


func _on_tutorial_finished() -> void:
	var elapsed: float = Time.get_ticks_msec() / 1000.0 - _tutorial_start_time
	AnalyticsManager.log_tutorial_complete(elapsed)


# ─── 게임플레이에서의 호출 예시 ──────────────────────────────
# game_board.gd

func _on_stage_started() -> void:
	AnalyticsManager.log_stage_start(
		current_mode,         # "classic"
		current_stage,        # 15
		current_theme,        # "animals"
		"%dx%d" % [grid_w, grid_h]  # "8x8"
	)


func _on_word_discovered(word: String, combo: int) -> void:
	var time_gap: float = Time.get_ticks_msec() / 1000.0 - _last_word_time
	AnalyticsManager.log_word_found(
		current_mode,
		current_stage,
		word.length(),
		combo,
		time_gap
	)
	_last_word_time = Time.get_ticks_msec() / 1000.0


func _on_stage_cleared() -> void:
	AnalyticsManager.log_stage_complete(
		current_mode,
		current_stage,
		_elapsed_time,
		_current_score,
		_calculated_grade,   # "S", "A", "B", "C"
		_hints_used_count,
		_words_found_count
	)


# ─── 광고에서의 호출 예시 ─────────────────────────────────
# ad_manager.gd

func _on_rewarded_ad_completed(reward_type: String, amount: int) -> void:
	AnalyticsManager.log_ad_rewarded(reward_type, amount)
	AnalyticsManager.log_coin_earned("ad", amount)


# ─── IAP에서의 호출 예시 ──────────────────────────────────
# iap_manager.gd

func _on_purchase_completed(product: Dictionary) -> void:
	AnalyticsManager.log_iap_completed(
		product.id,
		product.price,
		product.currency
	)
```

### 6.3 에디터 디버그 모드

개발 중에는 `debug_mode = true`로 설정하여 모든 이벤트를 Output 패널에서 확인할 수 있다.

```
[Analytics] Event: stage_start | Params: {mode: classic, stage: 5, theme: animals, grid_size: 8x8}
[Analytics] Event: word_found | Params: {mode: classic, stage: 5, word_length: 5, combo_count: 2, time_since_last: 3.2}
[Analytics] Event: hint_used | Params: {hint_type: reveal_letter, stage: 5, coins_spent: 80}
[Analytics] Event: stage_complete | Params: {mode: classic, stage: 5, time: 45.3, score: 1200, grade: A, hints_used: 1, words_found: 6}
[Analytics] UserProperty: player_level = 5
[Analytics] UserProperty: total_games = 12
```

---

## 7. 대시보드 설계

Firebase Console 및 Google Analytics 4 대시보드를 활용하여 핵심 지표를 실시간 모니터링한다.

### 7.1 일일 대시보드 (Daily Dashboard)

매일 확인하는 핵심 운영 지표이다.

```
┌──────────────────────────────────────────────────────────────┐
│                    일일 대시보드 (Daily)                       │
├──────────────┬──────────────┬──────────────┬────────────────┤
│     DAU      │  신규 설치    │  세션 수/유저  │  평균 세션 시간 │
│   [숫자]     │   [숫자]     │   [숫자]      │    [분:초]      │
│  (전일 대비%) │ (전일 대비%) │ (전일 대비%)   │  (전일 대비%)   │
├──────────────┴──────────────┴──────────────┴────────────────┤
│                     수익 요약                                │
│  총 수익: $___  │  광고: $___  │  IAP: $___  │  ARPDAU: $___  │
├─────────────────────────────────────────────────────────────┤
│                   게임플레이 요약                              │
│  스테이지 클리어: ___건  │  실패: ___건  │  힌트 사용: ___건  │
│  Daily Challenge 참여: ___명 (DAU 대비 __%)                  │
└─────────────────────────────────────────────────────────────┘
```

**일일 확인 항목:**

| 지표 | 확인 포인트 | 이상 기준 |
|------|------------|----------|
| DAU | 전일 대비 변화 | -20% 이상 감소 시 원인 조사 |
| 신규 설치 | 설치 추세 | 급감 시 ASO/스토어 확인 |
| 수익 | 광고 + IAP 합산 | -30% 이상 감소 시 경보 |
| 크래시율 | Firebase Crashlytics | 1% 초과 시 즉시 대응 |

### 7.2 주간 대시보드 (Weekly Dashboard)

주 1회 팀 미팅에서 검토하는 추세 분석 대시보드이다.

```
┌──────────────────────────────────────────────────────────────┐
│                    주간 대시보드 (Weekly)                      │
├─────────────────────────────────────────────────────────────┤
│  [라인 차트] D1 / D7 Retention 추세 (7일간)                   │
│                                                              │
│  D1: 38% → 41% → 39% → 42% → 40% → 43% → 41%             │
│  D7: 18% → 19% → 20% → 19% → 21% → 20% → 22%             │
├─────────────────────────────────────────────────────────────┤
│  [파이 차트] 모드별 플레이 비율                                │
│                                                              │
│  Classic: 45%  │  Time Attack: 20%  │  Daily: 25%  │  기타: 10% │
├─────────────────────────────────────────────────────────────┤
│  [바 차트] 코인 경제 밸런스                                    │
│                                                              │
│  획득: 스테이지 40% / 광고 30% / 출석 20% / 업적 10%          │
│  소모: 힌트 60% / 테마 25% / 커스텀 15%                       │
│  순 유입량: +___  (건전한 범위: 유입 > 소모 x 1.2)             │
├─────────────────────────────────────────────────────────────┤
│  [히트맵] 힌트 사용 패턴                                      │
│                                                              │
│  스테이지별 힌트 사용률: 1-10 (15%) / 11-20 (35%) / 21+ (55%)│
│  힌트 타입별: reveal_letter 60% / highlight_word 30% / 기타 10% │
└─────────────────────────────────────────────────────────────┘
```

**주간 검토 항목:**

| 항목 | 분석 내용 | 액션 기준 |
|------|----------|----------|
| Retention 추세 | D1/D7 상승/하락 패턴 | 2주 연속 하락 시 원인 분석 |
| 모드별 비율 | 특정 모드 쏠림 여부 | 비인기 모드 개선 또는 폐지 검토 |
| 코인 밸런스 | 인플레이션/디플레이션 | 획득량 or 소비처 조정 |
| 힌트 패턴 | 난이도 적정성 | 힌트 사용률 60% 초과 스테이지 리밸런싱 |

### 7.3 월간 대시보드 (Monthly Dashboard)

월 1회 경영/전략 리뷰에서 활용하는 종합 분석이다.

```
┌──────────────────────────────────────────────────────────────┐
│                    월간 대시보드 (Monthly)                     │
├─────────────────────────────────────────────────────────────┤
│  MAU: ___  │  D30 Retention: ___%  │  DAU/MAU: ___%         │
├─────────────────────────────────────────────────────────────┤
│  [라인 차트] LTV 추세 (월간)                                  │
│  [라인 차트] ARPDAU 추세 (월간)                               │
├─────────────────────────────────────────────────────────────┤
│  [퍼널 차트] 유저 전환 퍼널                                    │
│                                                              │
│  설치 (100%)                                                 │
│    → 튜토리얼 완료 (85%)                                     │
│      → 스테이지 5 도달 (60%)                                 │
│        → 스테이지 20 도달 (30%)                              │
│          → 첫 과금 (5%)                                      │
│            → 반복 과금 (2%)                                  │
├─────────────────────────────────────────────────────────────┤
│  [표] Cohort 분석 (설치 월별 리텐션)                           │
│                                                              │
│  Cohort   │ M0   │ M1   │ M2   │ M3                         │
│  1월 설치  │ 100% │ 25%  │ 18%  │ 12%                        │
│  2월 설치  │ 100% │ 28%  │ 20%  │ -                          │
│  3월 설치  │ 100% │ 30%  │ -    │ -                          │
├─────────────────────────────────────────────────────────────┤
│  [바 차트] 수익 구조                                          │
│                                                              │
│  Rewarded Ad: 55%  │  Interstitial: 18%  │  IAP: 22%  │  구독: 5% │
└─────────────────────────────────────────────────────────────┘
```

**월간 핵심 퍼널 상세:**

| 퍼널 단계 | 목표 전환율 | 이탈 시 대응 |
|----------|------------|-------------|
| 설치 → 튜토리얼 완료 | 85%+ | 튜토리얼 UX 개선, 스킵 옵션 |
| 튜토리얼 → 스테이지 5 | 60%+ | 초반 난이도 하향, 보상 증가 |
| 스테이지 5 → 스테이지 20 | 30%+ | 콘텐츠 다양성, 목표 시스템 강화 |
| 스테이지 20 → 첫 과금 | 5%+ | IAP 가치 제안 개선, 할인 이벤트 |
| 첫 과금 → 반복 과금 | 40%+ | 정기 구독 제안, VIP 혜택 |

---

## 8. A/B 테스트 프레임워크

### 8.1 Firebase Remote Config 활용

Firebase Remote Config를 사용하여 서버 배포 없이 클라이언트 파라미터를 동적으로 변경하고 A/B 테스트를 실행한다.

#### 8.1.1 Remote Config 기본 구조

```gdscript
## remote_config_manager.gd - Firebase Remote Config 래퍼
## 경로: res://scripts/managers/remote_config_manager.gd
class_name RemoteConfigManager
extends Node

# 기본값 (Firebase 연결 불가 시 사용)
var _defaults := {
	# 힌트 가격
	"hint_reveal_letter_cost": 80,
	"hint_highlight_word_cost": 120,

	# 광고 빈도
	"interstitial_interval_stages": 3,
	"rewarded_ad_coin_reward": 50,

	# 일일 보상
	"daily_reward_base_coins": 100,
	"streak_bonus_multiplier": 0.1,

	# 튜토리얼
	"tutorial_total_steps": 3,

	# 경제 밸런스
	"stage_clear_base_coins": 50,
	"daily_challenge_bonus_coins": 200,
}

var _firebase_remote_config: Object = null
var _is_available := false
var _cached_values: Dictionary = {}


func _ready() -> void:
	_cached_values = _defaults.duplicate()
	_initialize_remote_config()


func _initialize_remote_config() -> void:
	if Engine.has_singleton("FirebaseRemoteConfig"):
		_firebase_remote_config = Engine.get_singleton("FirebaseRemoteConfig")
		_firebase_remote_config.set_defaults(_defaults)
		_is_available = true
		fetch_and_activate()


func fetch_and_activate() -> void:
	"""서버에서 최신 설정을 가져오고 적용한다."""
	if not _is_available:
		return

	_firebase_remote_config.fetch()
	# fetch 완료 후 콜백에서 activate 호출
	# _firebase_remote_config.activate()


func get_int(key: String) -> int:
	if _is_available and _firebase_remote_config:
		return _firebase_remote_config.get_int(key)
	return _defaults.get(key, 0)


func get_float(key: String) -> float:
	if _is_available and _firebase_remote_config:
		return _firebase_remote_config.get_float(key)
	return _defaults.get(key, 0.0)


func get_string(key: String) -> String:
	if _is_available and _firebase_remote_config:
		return _firebase_remote_config.get_string(key)
	return _defaults.get(key, "")
```

### 8.2 A/B 테스트 계획

#### 8.2.1 테스트 대상 및 가설

| 테스트 ID | 대상 | 변형 | 가설 | 성공 지표 |
|----------|------|------|------|----------|
| **AB_001** | 힌트 가격 | A: 80코인 / B: 100코인 / C: 120코인 | 가격이 낮을수록 사용률 증가, 높을수록 수익 증가 | ARPDAU, 힌트 사용률 |
| **AB_002** | 광고 빈도 | A: 3스테이지마다 / B: 5스테이지마다 | 빈도 낮으면 리텐션 개선, 높으면 수익 증가 | D7 Retention, 광고 수익 |
| **AB_003** | 일일 보상 금액 | A: 100코인 / B: 150코인 / C: 200코인 | 보상 증가 시 Daily Login 비율 개선 | DAU/MAU, daily_login 이벤트 수 |
| **AB_004** | 튜토리얼 길이 | A: 2단계 / B: 3단계 | 짧을수록 이탈 감소, 길수록 이해도 증가 | tutorial_complete율, D1 Retention |
| **AB_005** | 첫 구매 할인 | A: 할인 없음 / B: 50% 할인 팝업 | 할인 시 Conversion Rate 증가 | Conversion Rate, 첫 구매까지 시간 |

#### 8.2.2 테스트 운영 규칙

```
A/B 테스트 운영 원칙:

  1. 최소 표본 크기: 그룹당 1,000+ MAU
  2. 테스트 기간: 최소 7일, 권장 14일
  3. 동시 테스트: 최대 2개 (교차 영향 방지)
  4. 유의 수준: p < 0.05 (95% 신뢰구간)
  5. 트래픽 분할: 50/50 (2변형) 또는 33/33/34 (3변형)
  6. 신규 유저 우선: 기존 유저 경험 일관성 유지
```

#### 8.2.3 테스트 결과 판정 프로세스

```
[테스트 시작]
     │
     ▼
[최소 7일 대기, 표본 1000+ 확보]
     │
     ▼
[통계적 유의성 확인 (p < 0.05)]
     │
     ├─ 유의하지 않음 → [7일 연장 또는 테스트 종료 (기본값 유지)]
     │
     └─ 유의함 → [승자 그룹 확인]
                     │
                     ▼
              [부작용 확인]
              (리텐션, 수익, 만족도 교차 검증)
                     │
                     ├─ 부작용 있음 → [트레이드오프 분석 후 결정]
                     │
                     └─ 부작용 없음 → [승자 값으로 전체 적용]
                                        │
                                        ▼
                                 [Remote Config 업데이트]
```

---

## 9. 프라이버시 및 규정 준수

### 9.1 관련 규정

| 규정 | 적용 대상 | 핵심 요구사항 |
|------|----------|-------------|
| **GDPR** | EU/EEA 유저 | 사전 동의, 데이터 접근/삭제 권리 |
| **CCPA** | 캘리포니아 유저 | 수집 데이터 고지, 옵트아웃 권리 |
| **COPPA** | 13세 미만 | 부모 동의 (해당 시), 데이터 수집 제한 |
| **Google Play 정책** | Android 전체 | 개인정보처리방침 필수 |
| **App Store 정책** | iOS 전체 | App Tracking Transparency (ATT) |

### 9.2 분석 동의 플로우

```
[앱 최초 실행]
     │
     ▼
[지역 확인 (IP 기반 또는 시스템 로케일)]
     │
     ├─ EU/EEA 유저 → [GDPR 동의 팝업 표시]
     │                     │
     │                     ├─ "동의" → analytics_consent = true
     │                     │            분석 수집 활성화
     │                     │
     │                     └─ "거부" → analytics_consent = false
     │                                  분석 수집 비활성화
     │                                  게임 플레이는 정상 가능
     │
     ├─ 캘리포니아 유저 → [CCPA 고지 + 옵트아웃 링크]
     │                      기본 수집 허용, 옵트아웃 시 비활성화
     │
     └─ 기타 지역 → [개인정보처리방침 링크 제공]
                       기본 수집 허용
```

### 9.3 동의 팝업 UI (EU 유저)

```
┌──────────────────────────────────────────┐
│                                          │
│       개인정보 수집 동의                   │
│                                          │
│  본 게임은 서비스 개선을 위해              │
│  익명화된 게임 플레이 데이터를             │
│  수집합니다.                              │
│                                          │
│  수집 항목:                               │
│  - 게임 진행 데이터                        │
│  - 앱 사용 패턴                           │
│  - 기기 정보 (모델, OS 버전)               │
│                                          │
│  [개인정보처리방침 전문 보기]               │
│                                          │
│  ┌──────────┐    ┌──────────┐           │
│  │   거부   │    │   동의   │           │
│  └──────────┘    └──────────┘           │
│                                          │
│  * 거부하셔도 게임을 정상적으로             │
│    이용하실 수 있습니다.                   │
│  * 설정에서 언제든 변경할 수 있습니다.      │
│                                          │
└──────────────────────────────────────────┘
```

### 9.4 데이터 관리 정책

| 항목 | 정책 | 비고 |
|------|------|------|
| **데이터 보존 기간** | 14개월 | Firebase Console에서 설정 |
| **PII 수집** | 수집하지 않음 | 이름, 이메일, 전화번호 등 미수집 |
| **기기 식별자** | Firebase Instance ID만 사용 | IDFA/GAID 수집 안 함 |
| **데이터 삭제 요청** | 지원 | 설정 > 데이터 삭제 요청 메뉴 |
| **데이터 이동 요청** | 지원 (GDPR 20조) | 이메일 통한 수동 처리 |
| **개인정보처리방침** | 스토어 등록 + 앱 내 링크 | 필수 |

### 9.5 iOS App Tracking Transparency (ATT)

```gdscript
## iOS에서 ATT 프레임워크 동의를 요청한다.
## 이 팝업은 iOS 14.5+ 에서 광고 추적 전 반드시 표시해야 한다.

func request_att_permission() -> void:
	if OS.get_name() != "iOS":
		return

	if Engine.has_singleton("AppTrackingTransparency"):
		var att = Engine.get_singleton("AppTrackingTransparency")
		att.request_tracking_authorization()
		# 결과는 콜백으로 수신
		# authorized → 광고 ID 수집 가능
		# denied → 광고 ID 수집 불가 (게임 동작에는 영향 없음)
```

---

## 10. TV 플랫폼 분석

### 10.1 TV 환경 제약사항

TV 플랫폼(Android TV, Fire TV)에서는 Firebase Analytics의 일부 기능이 제한된다.

| 항목 | 모바일 | TV | 대응 |
|------|--------|-----|------|
| Firebase Analytics | 완전 지원 | 부분 지원 | Google Analytics 4 웹 연동 또는 자체 로그 |
| Google Play Services | 사용 가능 | 제한적 | Fire TV에서는 미제공 |
| 광고 ID | GAID 사용 가능 | 제한적 | Firebase Instance ID 대체 |
| Push 알림 | FCM 지원 | 미지원 | TV에서는 알림 비활성화 |

### 10.2 TV 전용 분석 전략

#### 10.2.1 Firebase 사용 가능한 경우 (Android TV + Google Play Services)

기존 모바일 이벤트 체계를 그대로 사용하되, `platform_type` 유저 프로퍼티로 구분한다.

#### 10.2.2 Firebase 사용 불가한 경우 (Fire TV 등)

자체 로컬 로그를 수집하고, 앱 업데이트 시 집계한다.

```gdscript
## tv_analytics_fallback.gd - TV 환경 자체 로그 시스템
## Firebase 불가 시 로컬에 이벤트를 저장한다.

const LOG_FILE_PATH := "user://analytics_log.json"
const MAX_LOG_ENTRIES := 5000

var _log_entries: Array[Dictionary] = []


func log_event_local(event_name: String, params: Dictionary) -> void:
	"""이벤트를 로컬 파일에 기록한다."""
	var entry := {
		"event": event_name,
		"params": params,
		"timestamp": Time.get_unix_time_from_system(),
	}

	_log_entries.append(entry)

	# 최대 크기 초과 시 오래된 항목 제거
	if _log_entries.size() > MAX_LOG_ENTRIES:
		_log_entries = _log_entries.slice(MAX_LOG_ENTRIES / 2)

	_save_log()


func _save_log() -> void:
	var file := FileAccess.open(LOG_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_log_entries))


func _load_log() -> void:
	if FileAccess.file_exists(LOG_FILE_PATH):
		var file := FileAccess.open(LOG_FILE_PATH, FileAccess.READ)
		if file:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK:
				_log_entries = json.data
```

### 10.3 TV 전용 이벤트

| 이벤트 | 파라미터 | 설명 |
|--------|----------|------|
| `tv_session_start` | `device_model`: string, `os_version`: string | TV 세션 시작 |
| `dpad_navigation` | `screen`: string, `direction`: string, `count`: int | D-pad 네비게이션 패턴 |
| `tv_input_mode` | `mode`: string (dpad/gamepad/remote) | 입력 장치 유형 |

---

## 11. 알림 및 경보 설정

### 11.1 자동 경보 규칙

운영상 즉각적인 대응이 필요한 상황에 대해 자동 경보를 설정한다.

| 경보 | 조건 | 심각도 | 채널 | 대응 |
|------|------|--------|------|------|
| **DAU 급감** | 전일 대비 -30% | 높음 | Slack + 이메일 | 스토어 상태 확인, 크래시 확인, 서버 상태 확인 |
| **크래시율 급등** | 크래시율 > 1% | 긴급 | Slack 즉시 | Crashlytics 확인, 핫픽스 준비 |
| **수익 급감** | 전일 대비 -50% | 높음 | 이메일 | 광고 네트워크 상태, IAP 상태 확인 |
| **튜토리얼 이탈 급증** | 완료율 < 70% | 중간 | Slack (주간) | 업데이트 후 튜토리얼 깨짐 확인 |
| **광고 Fill Rate 하락** | Fill Rate < 70% | 중간 | 이메일 | 광고 네트워크 설정 확인, 대체 네트워크 검토 |
| **D1 Retention 하락** | D1 < 30% (7일 평균) | 높음 | Slack + 이메일 | 첫 경험 퍼널 전면 재검토 |
| **IAP 실패율 급증** | 실패율 > 20% | 높음 | Slack 즉시 | 결제 시스템 장애 확인 |

### 11.2 경보 구현 방법

```
[Firebase Cloud Functions (선택적)]
     │
     ├── BigQuery 스케줄 쿼리 → 임계치 초과 감지
     │                              │
     │                              ▼
     │                        Slack Webhook 전송
     │
     └── Firebase Crashlytics → Velocity Alert (자동)
                                       │
                                       ▼
                                 이메일 자동 발송
```

**초기 단계 (무료 방안):**

Firebase Console의 기본 알림 기능을 활용한다.

| 도구 | 기능 | 비용 |
|------|------|------|
| Firebase Console 알림 | 크래시율 급등 시 이메일 | 무료 |
| Google Play Console 알림 | ANR/크래시/평점 하락 | 무료 |
| App Store Connect 알림 | 크래시/리뷰 | 무료 |
| 수동 대시보드 확인 | 매일 아침 일일 대시보드 검토 | 무료 |

### 11.3 주간 리포트 자동화

```
주간 리포트 항목 (매주 월요일 발송):

  1. 주간 DAU 평균 및 추세
  2. D1/D7 Retention (전주 대비)
  3. 주간 수익 합산 (광고 + IAP)
  4. 상위 5개 이탈 스테이지
  5. A/B 테스트 중간 결과 (진행 중인 경우)
  6. 크래시 Top 5
  7. 유저 리뷰 요약 (평점 3 이하)
```

---

## 12. 데이터 흐름 아키텍처

### 12.1 전체 데이터 흐름도

```
┌───────────────────────────────────────────────────────────────────┐
│                        게임 클라이언트                              │
│                                                                    │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐          │
│  │  GameBoard   │   │  IAP Manager │   │  Ad Manager  │          │
│  │  (게임플레이)  │   │  (인앱결제)   │   │  (광고)      │          │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘          │
│         │                   │                   │                  │
│         └─────────┬─────────┴─────────┬─────────┘                 │
│                   │                   │                            │
│                   ▼                   ▼                            │
│         ┌──────────────────────────────────┐                      │
│         │       AnalyticsManager           │                      │
│         │       (Autoload Singleton)       │                      │
│         │                                  │                      │
│         │  - 동의 확인 (consent check)      │                      │
│         │  - 이벤트 검증 (validation)       │                      │
│         │  - 파라미터 정제 (sanitization)   │                      │
│         │  - 디버그 로깅 (editor only)      │                      │
│         └──────────────┬───────────────────┘                      │
│                        │                                          │
└────────────────────────┼──────────────────────────────────────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │   Firebase SDK      │
              │                     │
              │  - 오프라인 캐싱     │
              │  - 배치 전송        │
              │  - 자동 재시도      │
              └──────────┬──────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │  Firebase Analytics │
              │  (Google Cloud)     │
              │                     │
              │  ┌───────────────┐  │
              │  │  대시보드      │  │
              │  │  Funnel       │  │
              │  │  Cohort       │  │
              │  │  Remote Config│  │
              │  └───────────────┘  │
              │                     │
              │  ┌───────────────┐  │
              │  │  BigQuery     │  │ ← 선택적 연동
              │  │  (심층 분석)   │  │
              │  └───────────────┘  │
              └─────────────────────┘
```

### 12.2 이벤트 처리 순서

```
1. 게임 이벤트 발생 (예: 스테이지 클리어)
     │
2. 해당 Manager가 AnalyticsManager 편의 메서드 호출
     │
3. AnalyticsManager.log_event() 진입
     │
4. 동의 상태 확인 (_consent_granted)
     │
     ├─ 미동의 → 이벤트 무시 (return)
     │
     └─ 동의 → 계속
              │
5. 이벤트 이름 정제 (_sanitize_event_name)
     │
6. 파라미터 정제 (_sanitize_params)
     │
7. 디버그 모드 시 콘솔 출력
     │
8. Firebase SDK로 전달
     │
     ├─ 온라인 → 즉시 배치 큐에 추가 (SDK 내부)
     │
     └─ 오프라인 → SDK 내부 캐시에 저장
                     (네트워크 복구 시 자동 전송)
```

### 12.3 파일 구조

```
res://scripts/managers/
  ├── analytics_manager.gd        # 분석 이벤트 메인 매니저 (Autoload)
  ├── remote_config_manager.gd    # Remote Config / A/B 테스트 (Autoload)
  └── tv_analytics_fallback.gd    # TV 전용 로컬 분석 폴백
```

---

## 13. 참조 문서

| 분류 | 문서 | 용도 |
|------|------|------|
| **Firebase** | [Firebase Analytics 문서](https://firebase.google.com/docs/analytics) | 이벤트/프로퍼티 구현 |
| **Firebase** | [Firebase Remote Config](https://firebase.google.com/docs/remote-config) | A/B 테스트 설정 |
| **Firebase** | [Firebase Crashlytics](https://firebase.google.com/docs/crashlytics) | 크래시 추적 |
| **Godot** | [Godot Firebase 플러그인](https://github.com/nicemicro/godot-firebase) | Godot-Firebase 연동 |
| **규정** | [GDPR 공식 사이트](https://gdpr.eu/) | EU 개인정보보호 규정 |
| **규정** | [CCPA 공식 사이트](https://oag.ca.gov/privacy/ccpa) | 캘리포니아 소비자 프라이버시법 |
| **내부** | P06_01 수익화 및 경제 시스템 | 재화/IAP/광고 이벤트 연동 |
| **내부** | P07_01 리텐션 시스템 | 스트릭/출석/리텐션 이벤트 연동 |
| **내부** | CC_02 TV 플랫폼 적응 | TV 분석 제약사항 |

---

## 14. 변경 이력

| 버전 | 날짜 | 변경 내용 | 작성자 |
|------|------|----------|--------|
| v1.0 | 2026-03-11 | 최초 작성 | Game Design Team |
