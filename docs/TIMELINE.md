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
- 광고 단위 3개 등록 (배너/전면/보상형)
  - Banner: ca-app-pub-4172930503672560/5128863971
  - Interstitial: ca-app-pub-4172930503672560/1273646341
  - Rewarded: ca-app-pub-4172930503672560/9503490153
- ad_config.gd: 광고 정책 설정 (AD_FREE_LEVELS=4, INTERSTITIAL_INTERVAL=3)
- ad_manager.gd: GDPR/UMP 동의 + iOS ATT + SDK 초기화
- 광고 등급 제한: G (전체이용가)
- 테스트/프로덕션 ID 전환 시스템

## Phase 4: In-App Purchase (IAP)
- GodotGooglePlayBilling 플러그인 설치
- iap_manager.gd: 구매 흐름 구현
  - 제품: remove_ads (비소모성, $2.99)
  - 구매 → 광고 제거 → SaveManager에 저장
- Play Console에 인앱 상품 등록 완료

## Phase 5: Android Build System
- Android Gradle 빌드 환경 구축 (JDK 17)
- **UID 충돌 문제 발견 및 해결** (가장 큰 기술적 도전)
  - 원인: android/build/ 내 Gradle 산출물을 Godot가 프로젝트 리소스로 인식
  - 해결: .gdignore 파일 5곳에 배치
  - assetPacks 비활성화 시 PCK 누락 문제 발견 → 재활성화
  - exclude_filter="android/*" 사용 시 PCK 누락 → 제거
- 릴리즈 키스토어 생성 및 서명 설정
- 빌드 스크립트 개발 (godot_clean_build.py)
  - 자동 클린 → .gdignore 생성 → Gradle 설정 검증 → 빌드
  - 실시간 진행률 표시 (스피너 + 경과 시간)
  - 빌드 완료 자동 감지 + Gradle 데몬 자동 종료
  - 출력 파일명에 버전 자동 포함
- BAT 파일 시스템 (CMD 창에서 시각적 확인)
  - build_apk.bat, build_aab.bat, build_both.bat

## Phase 6: Firebase Analytics
- Firebase 프로젝트 생성 (word-bloom-393a3)
- google-services.json 연동 (com.wordbloom.game)
- Gradle에 Firebase BOM + Analytics 의존성 추가
- analytics_manager.gd: 이벤트 추적 시스템
  - session_start/end, app_open
  - level_complete (레벨, 단어수, 시간, 힌트)
  - hint_used, ad_watched, purchase
- Measurement Protocol API 폴백 (비Android용)

## Phase 7: Legal & Compliance
- Privacy Policy + Terms of Service 작성
  - GitHub Pages 호스팅: https://aile1492.github.io/word-bloom-policy/
- CREDITS.md 작성 (Godot, 플러그인, 폰트 라이선스)
- 폰트 OFL 라이선스 파일 추가
- COPPA 설정 (아동 대상 아님, G등급 광고 제한)
- 앱 콘텐츠 선언 (광고 ID, 데이터 보안, 금융 기능 없음)

## Phase 8: Google Play Console
- 개발자 계정 생성 (개인, KIM MIN GWAN)
- 앱 등록 (Word Bloom, 퍼즐 카테고리, 무료)
- 스토어 등록정보 작성
  - 앱 아이콘 (512x512), 그래픽 이미지 (1024x500)
  - 스크린샷 (홈, 게임플레이, 레벨 선택, 상점)
  - 간단한 설명 + 자세한 설명 (영어)
- 콘텐츠 등급: IARC 3+ (전체이용가)
- 타겟층: 18세 이상 (마케팅 대상)
- 데이터 보안: 진단 + 기기 ID 수집 선언
- 한국 개발자 추가 정보 제공
- 판매자 계정 설정 (결제 프로필)
- 15% 서비스 수수료 프로그램 등록

## Phase 9: Testing & Distribution
- 내부 테스트: v1.0.0 ~ v1.0.7 (6회 업로드)
  - PCK 누락 문제 발견 및 해결 (v1.0.2~1.0.5)
  - 패키지명 변경 com.wordpuzzle.game → com.wordbloom.game
- 비공개 테스트 (Beta Test) 트랙 생성 → 검토 제출
- 웹 데모 배포: https://aile1492.github.io/word-bloom-web/
  - class_name 충돌 해결 (웹 빌드 전용)
  - 커스텀 HTML 셸 (세로 비율 고정)
  - Service Worker 캐시 정리

## Phase 10: DevOps & Tooling
- 공통 빌드 도구 (_build_tools/godot_clean_build.py)
  - 모든 프로젝트에서 공유 가능
  - UID 충돌 자동 방지
  - 실시간 빌드 진행률 표시
- BAT 파일 시스템 (한글 경로 인코딩 해결)
- 글로벌 CLAUDE.md: 빌드 규칙, 경로, 도구 정보 기록
- 프로젝트별 CLAUDE.md: 코딩 표준, 폴더 구조, 금지 사항
- PROJECT_INFO.md: 계정 정보, URL, 진행 상태 마스터 문서
- Custom Skills (17개): 빌드, 배포, 디버깅, 코딩 패턴 등

## Current Status (2026-03-25)
- **APK**: v1.0.7 정상 작동 (기기 테스트 완료)
- **AAB**: v1.0.7 Play Console 업로드 완료
- **비공개 테스트**: 검토 중 (승인 대기)
- **프로덕션 출시**: 비공개 테스트 14일 운영 후 신청 예정

## Pending
- [ ] 비공개 테스트 테스터 12명 모집
- [ ] 14일 비공개 테스트 운영
- [ ] 프로덕션 액세스 신청
- [ ] AdMob ↔ 앱 스토어 연결 (프로덕션 출시 후)
- [ ] Firebase ↔ AdMob 수익 연동 확인
