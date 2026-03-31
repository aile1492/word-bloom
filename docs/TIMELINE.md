# Word Bloom - Project Timeline

## Phase 1: Game Development (Core)
- Godot 4.6.1 프로젝트 세팅 (GL Compatibility 렌더러)
- GDScript로 게임 핵심 로직 구현
  - 단어 퍼즐 시스템 (8방향 스냅, 드래그 입력)
  - GridCalculator: 스테이지별 격자 크기 자동 조정
  - 200+ 레벨 데이터 (한국어/영어 8테마)
- UI 시스템 구현
  - 하단 탭바 5개 (Daily, Team, Home, Collection, Shop)
  - 홈 화면, 게임 화면, 스테이지 클리어 팝업
  - 설정 팝업, 힌트 시스템 (첫 글자/전체 공개)
- 배경 이미지 시스템 (테마별 실사 사진)
- 코인 시스템 (힌트 1회 = 100코인)
- SaveManager: user://save_data.json 로컬 저장

## Phase 2: UI/UX Polish
- 반복적인 UI 버그 수정 (레이아웃, 팝업 위치, 폰트)
- 배경 이미지 적용 및 테마별 전환
- 하단 탭바 아이콘 디자인 및 애니메이션
- 스테이지 클리어 연출
- 반응형 레이아웃 (다양한 해상도 대응)

## Phase 3: Monetization - AdMob Integration
- Poing Studios AdMob 플러그인 설치
- 광고 단위 3개 등록 (배너/전면/보상형) 및 정책 설계
  - Banner / Interstitial / Rewarded Ad Units 구성 완료
- ad_config.gd: 광고 정책 설정 (AD_FREE_LEVELS=4, INTERSTITIAL_INTERVAL=3)
- ad_manager.gd: GDPR/UMP 동의 + iOS ATT + SDK 초기화
- 광고 등급 제한: G (전체이용가)
- 테스트/프로덕션 ID 전환 시스템 구축

## Phase 4: In-App Purchase (IAP)
- GodotGooglePlayBilling 플러그인 설치
- iap_manager.gd: 구매 흐름 구현
  - 제품: remove_ads (비소모성)
  - 구매 → 광고 제거 → SaveManager에 저장
- Play Console에 인앱 상품 등록 완료

## Phase 5: Android Build System
- Android Gradle 빌드 환경 구축 (JDK 17)
- **UID 충돌 문제 발견 및 해결** (주요 기술적 도전 과제)
  - 원인: android/build/ 내 Gradle 산출물을 Godot가 프로젝트 리소스로 인식
  - 해결: .gdignore 파일 전략적 배치로 충돌 회피
- 빌드 스크립트 고도화 (godot_clean_build.py)
  - 자동 클린 → .gdignore 생성 → Gradle 설정 검증 → 빌드 자동화
  - 실시간 진행률 및 빌드 상태 시각화

## Phase 6: Firebase Analytics
- Firebase 프로젝트 연동 및 분석 시스템 구축
- analytics_manager.gd: 커스텀 이벤트 추적 시스템
  - 스테이지 클리어율, 아이템 사용 빈도, 광고 시청 전환율 측정
- Measurement Protocol API 폴백 구현

## Phase 7: Legal & Compliance
- Privacy Policy + Terms of Service 배포
- CREDITS.md 및 오픈소스 라이선스 고지 준수
- COPPA 및 GDPR 규정 준수 설정

## Phase 8: Google Play Console
- 개발자 계정 관리 및 앱 등록 프로세스 수행
- 스토어 등록정보 최적화 (ASO 고려)
  - 앱 아이콘, 그래픽 이미지, 다국어 스토어 설명 작성
- 데이터 보안 선언 및 콘텐츠 등급 심사 완료

## Phase 9: Testing & Distribution
- 내부 테스트 및 QA 진행 (v1.0.0 ~ v1.0.7)
- 비공개 테스트 (Beta Test) 운영 및 피드백 반영
- 웹 데모 배포를 통한 접근성 확장

## Phase 10: DevOps & Tooling
- 프로젝트 공통 빌드 도구 개발 및 자산화
- 기술 문서화 (CLAUDE.md, PROJECT_INFO.md)를 통한 유지보수성 확보
- Custom Skills 설계를 통한 개발 생산성 자동화

## Current Status
- **Android**: 프로덕션 빌드 완료 및 스토어 검토 대기
- **Web**: 데모 배포 완료
- **iOS**: 배포 환경 준비 중

---
*본 타임라인은 AI와 협업하여 달성한 고속 개발 프로세스의 기록입니다.*
