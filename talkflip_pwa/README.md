# TalkFlip v2 — 게임 UI 리디자인 (1차)

`talkflip_pwa/` 폴더에 이 4개 파일을 **덮어쓰면** 끝. 나머지(about/guides/privacy/terms, icons, og.png 등)는 그대로.

- `index.html` — 새 게임 UI (카드 / 지목 / 결과). 기존 파일 대체.
- `cards.js` — 카드 데이터. **생성 파일** — 루트에서 `node build.mjs`. cards.json + `data/spicy.json`(매운맛 50장) + `data/extras.json`(추가 카드)을 합치고, 지목 카드마다 칭호(`trait`) 태그를 붙임(`data/traits.json`). 금지어 카드는 제외.
- `decks/{party,spicy,funny,warm_up,deep,couple}.html` + `.en.html` — 덱별 정적 페이지(설명 + 질문 전체 + 시작 버튼), 한/영. **생성 파일**. 시작 버튼은 `../?deck=spicy` 로 들어오고, index.html이 이 파라미터로 덱을 고른 뒤 URL에서 지움.
- `penalty.html` / `penalty.en.html` — 술게임 벌칙 룰렛 랜딩(한/영)(벌칙 30개 목록 + 룰렛 버튼 `./?roulette`). **생성 파일**, 소스는 `data/penalties.json`.
- `sw.js` — 캐시 이름은 `talkflip-v21-<해시>`. 해시는 index.html·cards.js·manifest 내용에서 빌드가 자동 계산하므로, 빌드만 돌리면 기존 사용자도 새 화면을 받음. 문구 등을 손으로 고쳤을 때도 배포 전에 `node build.mjs` 한 번.
- `manifest.webmanifest` — 테마색만 다크로.

## 흐름
1. 링크 열면 바로 카드. 기본 덱 파티. 위로 스와이프(또는 하단 화살표) = 다음.
2. 첫 지목 카드 직전에 이름 입력 시트가 한 번 뜸. 3명 미만이면 지목 카드는 건너뜀.
3. 10장 후 결과 카드. 4명 이상 → 칭호, 2명(또는 커플 덱) → 케미 %, 혼자 → 완료 카드.
4. "스토리에 올리기" = 1080×1600 이미지 생성 → 시스템 공유 / 저장.
5. "한 판 더" = 전면광고 1회(90초 쿨다운) 후 새 라운드.
6. 벌칙 룰렛 = 지목 카드 하단 "벌칙" 버튼(제일 많이 찍힌 사람 이름이 제목에), 설정 시트의 "벌칙 룰렛", 또는 `?roulette`로 진입. 시트 하나라 새 화면 아님.

## 밸런스 전국 통계
밸런스 카드에 답하면 `/api/vote`로 이 폰의 답(손 든 수)을 보내고, 카드 아래에 "전국 62% vs 38% · 1,204명"이 뜹니다.
API는 `worker/`(Cloudflare Worker + D1). 배포 전엔 `worker/README.md`의 "처음 한 번"을 따라 D1 테이블·SALT·deploy를 한 번 해야 하고,
그 전까지는 통신이 실패해도 게임은 그대로 진행됩니다. 로컬은 `wrangler dev`(8787)를 자동으로 봅니다. 주소를 바꾸려면
`localStorage.setItem("tf2.api", "https://….workers.dev/api")`.
커플 모드는 둘 다 고른 뒤 "같은 답!/다른 답"과 각자 고른 쪽이 표시되고, 스와이프로 넘어갑니다(자동 넘김 아님).

## 매운맛 덱 수위
술자리·커플용 찐 질문(전 애인·거짓말·돈·첫인상·비밀). 애드센스 때문에 성적 콘텐츠·외모 비하·정치·종교는 금지, "선 넘을락 말락"에서 멈춤. 카드 추가는 `data/spicy.json`에서, 지목 카드는 `trait` 필수.

## 칭호 8종 (`cards.js`의 `traits`)
ghost 잠수왕 · hype 2차 선동가 · npc 단톡 NPC · drama 드라마 주인공 · counselor 새벽 상담사 · leader 어쩌다 리더 · chaos 인간 변수 · star 미래의 셀럽
캐릭터 이미지는 결과 카드의 `.charslot` 자리에 넣으면 됨(지금은 display:none).

## 로컬 확인
```
cd talkflip_pwa && python3 -m http.server 8080
```
폰에서 같은 와이파이로 열어보는 게 제일 정확함(스와이프·공유 시트).

## 빌드
```
node build.mjs          # cards.js + decks/*.html 생성, sw.js 캐시 버전 갱신
node build.mjs --check  # 검증만
```
카드 문구는 `cards.json` / `data/*.json`에서 고치고 빌드. cards.js와 decks/*.html은 직접 편집하지 말 것.

## 다음 단계
- 실제 폰에서 3~4명이 한 판 돌려보고 문구/템포 조정
- 밸런스 전국 통계(Workers + KV)
- 결과 카드 `.charslot` 캐릭터 이미지 8장
