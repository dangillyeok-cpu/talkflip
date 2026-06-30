# TalkFlip PWA — 배포 방법

이 폴더(`talkflip_pwa/`)가 그대로 배포 단위입니다. 정적 호스팅에 폴더 통째로 올리면 됩니다.

## 폴더 구성
- `index.html` — 게임(PWA)
- `about.html` / `how-to-play.html` / `privacy.html` / `terms.html` — 지원 페이지(애드센스 심사용, 게임과 같은 도메인)
- `manifest.webmanifest`, `sw.js`, `pages.css`, `icons/` — PWA·페이지 자원

## Vercel + 가비아 도메인 (권장 경로)
1. **Vercel 배포**: vercel.com → 새 프로젝트 → 이 폴더 업로드(또는 `npx vercel`). 정적 사이트로 자동 인식됩니다.
2. **가비아 도메인 연결**: Vercel 프로젝트 → Settings → Domains에 도메인 추가 → 안내된 레코드를 **가비아 DNS**에 입력(보통 A 레코드 `76.76.21.21` 또는 CNAME `cname.vercel-dns.com`). HTTPS 인증서는 Vercel이 자동 발급.
3. 배포 후 `https://내도메인/` = 게임, `https://내도메인/privacy.html` 등으로 페이지가 한 사이트에 묶입니다 → 애드센스에 이 도메인 하나만 신청.

## 출시 전 교체할 것
- `index.html` 상단 `const SHARE_URL = "talkflip.app";` → **실제 도메인**.
- 모든 페이지의 문의 이메일 `hello@talkflip.app` → **실제 이메일**(`about/privacy/terms/how-to-play.html` + 게임 설정 안에도 동일 표기).
- 광고 켜기: `const ADSENSE_CLIENT = "";` → 승인된 `ca-pub-...`. 승인 후 도메인 루트에 `ads.txt` 추가.

## 빠른 배포 (택1)
- **Netlify**: netlify.com → "Add new site" → 이 폴더를 드래그&드롭. 즉시 HTTPS 주소 발급.
- **Vercel**: `npx vercel` 이 폴더에서 실행.
- **GitHub Pages**: 레포에 폴더 올리고 Pages 활성화.
- 사내 서버라면 정적 파일로 서빙(HTTPS 필수).

## 중요
- **PWA 기능(오프라인·홈 화면 추가)은 HTTPS(또는 localhost)에서만 동작**합니다. 파일을 더블클릭(`file://`)하면 게임은 되지만 PWA 기능은 비활성입니다.
- 로컬 점검: 이 폴더에서 `python3 -m http.server 8080` 실행 후 `http://localhost:8080` 접속.

## 출시 전 1가지
- `index.html` 상단의 `const SHARE_URL = "talkflip.app";` 를 **실제 배포 주소**로 바꾸세요. 공유 카드 이미지에 박히는 설치 링크입니다.

## 설치 경험
- iOS Safari: 공유 → "홈 화면에 추가" → 앱 아이콘으로 전체화면 실행.
- Android Chrome: 주소창의 "설치" 배너 또는 메뉴 → "앱 설치".

## 광고(AdSense H5 Games Ads) 켜기
1. AdSense 계정 승인 + 배포 도메인을 AdSense에 사이트로 추가, H5 Games Ads 사용 설정.
2. `index.html` 상단의 `const ADSENSE_CLIENT = "";` 를 본인 퍼블리셔 ID(`ca-pub-XXXXXXXXXXXXXXXX`)로 설정.
3. **HTTPS 실도메인**에 배포해야 실제 광고가 나옵니다(`file://`·localhost는 광고 안 뜸).
4. 테스트는 `const ADS_TEST = true;` 로.
- 현재 배치: **세션 종료(다시 하기/설정으로 이동) 시 전면광고 1회**(최소 90초 간격). 카드 넘김·공유/리캡 구간엔 광고 없음(바이럴 보호).
- 리워드 광고 헬퍼(`showRewarded`)는 준비돼 있어, 나중에 "보너스 팩 열기" 같은 옵트인 보상에 연결할 수 있습니다.
- `ADSENSE_CLIENT`가 비어 있으면 앱은 완전히 광고 없이 정상 동작합니다.

## 나중에 앱스토어로 가려면
이 PWA를 그대로 Capacitor 같은 래퍼로 감싸 iOS/Android 앱으로 제출할 수 있습니다(코드 재작성 없음). 트래픽이 검증된 뒤 진행하는 것을 권장합니다.
