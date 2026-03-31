# Word Bloom — 프로젝트 핵심 정보

이 문서는 프로젝트에서 사용한 계정, ID, URL 등 잊어버리면 안 되는 정보를 모아놓은 문서입니다.

---

## 앱 정보

| 항목 | 값 |
|------|-----|
| 앱 이름 | **Word Bloom** |
| 패키지명 | `com.wordpuzzle.game` |
| 엔진 | Godot 4.6.1 Stable (GDScript, GL Compatibility) |
| 플랫폼 | Android, iOS (예정) |
| 장르 | 퍼즐 / 단어 검색 |

---

## 계정

### Google (공통)
| 항목 | 값 |
|------|-----|
| 이메일 | `mingwan1492@gmail.com` |
| 이름 | KIM MIN GWAN |

### Google Play Console
| 항목 | 값 |
|------|-----|
| 계정 유형 | 개인 |
| 계정 ID | `9080327853792958070` |
| 등록비 | $25 (결제 완료) |
| URL | [play.google.com/console](https://play.google.com/console) |

### AdMob
| 항목 | 값 |
|------|-----|
| URL | [admob.google.com](https://admob.google.com) |
| 앱 ID (Android) | `ca-app-pub-4172930503672560~1405241383` |

### GitHub
| 항목 | 값 |
|------|-----|
| 아이디 | `aile1492` |
| URL | [github.com/aile1492](https://github.com/aile1492) |

---

## 광고 단위 ID (AdMob — Android)

| 유형 | 광고 단위 ID |
|------|-------------|
| 배너 | `ca-app-pub-4172930503672560/5128863971` |
| 전면 (Interstitial) | `ca-app-pub-4172930503672560/1273646341` |
| 보상형 (Rewarded) | `ca-app-pub-4172930503672560/9503490153` |

> iOS 광고 단위는 Apple Developer 등록 후 별도 생성 필요.

---

## 인앱결제 (IAP)

| 항목 | 값 |
|------|-----|
| 상품 ID | `remove_ads` |
| 유형 | 비소모품 (한 번 구매, 영구) |
| 가격 | 미정 (권장 $2.99~$4.99) |
| 결제 시스템 | Google Play Billing (v8.3.0) |

---

## 공개 URL

| 용도 | URL |
|------|-----|
| Privacy Policy | https://aile1492.github.io/word-bloom-policy/#privacy |
| Terms of Service | https://aile1492.github.io/word-bloom-policy/#terms |
| 정책 레포 | https://github.com/aile1492/word-bloom-policy |

---

## 로컬 경로

| 항목 | 경로 |
|------|------|
| 프로젝트 루트 | `C:/Users/0/ai프로젝트/wordPuzzle_Godot/Puzzle/word-puzzle` |
| Godot 엔진 | `C:/Users/0/Downloads/Godot_v4.6.1-stable_win64.exe/Godot_v4.6.1-stable_win64.exe` |
| JDK 17 | `C:/tmp/jdk17_extracted/jdk-17.0.18+8` |
| Android SDK | `C:/Users/0/AppData/Local/Android/Sdk` |
| APK 빌드 출력 | `C:/tmp/godot_build/` |
| 기획서 (읽기 전용) | `C:/Users/0/ai프로젝트/wordPuzzle_Godot/기획서 최종본/` |
| 단어 데이터 원본 | `C:/Users/0/ai프로젝트/wordPuzzle_Godot/단어데이터/` |
| 정책 페이지 로컬 | `C:/Users/0/ai프로젝트/wordPuzzle_Godot/word-bloom-policy/` |
| DEVLOG | `C:/Users/0/ai프로젝트/wordPuzzle_Godot/DEVLOG.md` |
| 커맨드(Skills) | `C:/Users/0/.claude/commands/` |

---

## 테스트 기기

| 항목 | 값 |
|------|-----|
| 기종 | Samsung |
| 시리얼 | `R3CY10AHMKJ` |
| 연결 | USB (무선 불가 — LAN/WiFi 네트워크 분리) |
| ADB 경로 | `C:/Users/0/AppData/Local/Android/Sdk/platform-tools` |

---

## Keystore

| 항목 | 값 |
|------|-----|
| Debug | Godot 자동 생성 (기본 debug keystore) |
| Release | 미생성 (출시 전 생성 필요 — `/release-build` 참고) |

> ⚠️ Release keystore 생성 후 비밀번호를 이 문서에 기록하거나 안전한 곳에 보관할 것. 분실 시 앱 업데이트 불가!

---

## 광고 정책 설정

| 항목 | 값 |
|------|-----|
| 무광고 레벨 | 1~4 (AD_FREE_LEVELS = 4) |
| 배너 시작 | Lv.5부터 (BANNER_START_LEVEL = 5) |
| 전면 빈도 | 3스테이지마다 (INTERSTITIAL_INTERVAL = 3) |
| 전면 쿨다운 | 90초 (INTERSTITIAL_COOLDOWN = 90.0) |
| 보상형 | 힌트 부족 시 자발적 시청 (제한 없음) |
| 광고 제거 시 | 배너 + 전면 제거, 보상형은 유지 |

---

## 현재 진행 상태 (2026-03-20)

- [x] 기획서 27개 문서 완성
- [x] Godot 프로젝트 세팅 + Phase 0~1 완료
- [x] AdMob 플러그인 탑재 + 광고 단위 등록
- [x] IAP 코드 구현 완료
- [x] Privacy Policy + Terms of Service 배포
- [x] Google Play Console 개발자 등록
- [ ] Google 신원 확인 대기 중
- [ ] 연락처 전화번호 인증 (신원 확인 후)
- [ ] Play Console에서 앱 만들기 + 인앱 상품 등록
- [ ] 릴리즈 Keystore 생성
- [ ] AAB 릴리즈 빌드 + 스토어 업로드
- [ ] 스토어 스크린샷 4장 촬영
- [ ] iOS Apple Developer 등록 ($99/년)

---

*마지막 업데이트: 2026-03-20*
