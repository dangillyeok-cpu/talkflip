# talkflip-stats — 밸런스 카드 전국 통계 (Cloudflare Worker + D1)

카드ID별로 A/B를 고른 사람 수를 세고, 앱이 답한 뒤 "전국 62% vs 38%"를 보여줄 때 씁니다.
데이터는 Cloudflare D1(SQLite)에 쌓이고, 이 폴더에는 코드와 설정만 있습니다.

## 처음 한 번
```bash
cd worker
npm install
npx wrangler login                                                  # 브라우저 로그인 (한 번)
npx wrangler d1 execute talkflip-stats --remote --file=schema.sql   # 테이블 생성
npx wrangler secret put SALT                                        # 아무 긴 문자열 (IP 해시용)
npx wrangler deploy
```
`wrangler.toml`의 `routes`가 `wealthviewlounge.com/api/*`를 이 Worker로 보냅니다. 도메인 존이 Cloudflare에
있어야 합니다. 없으면 `routes`를 지우고, deploy가 출력하는 `*.workers.dev` 주소를 `index.html`의 `STATS_API`에 넣으세요.

## 확인
```bash
curl https://wealthviewlounge.com/api/health
curl "https://wealthviewlounge.com/api/stats?cards=party_choice_001"
curl -X POST https://wealthviewlounge.com/api/vote -H "content-type: application/json" -d "{\"card\":\"party_choice_001\",\"a\":1,\"b\":0}"
```

## 로컬 개발
```bash
cd worker
npx wrangler d1 execute talkflip-stats --local --file=schema.sql
npx wrangler dev          # http://localhost:8787 (로컬 D1, 실데이터 아님)
```
`index.html`은 localhost에서 열면 자동으로 `http://localhost:8787/api`를 씁니다.

## 규칙
- 한 기기(IP 해시)는 카드당 하루 1회만 집계. 한 폰으로 4명이 답하면 손 든 수(a=3, b=1)가 한 번에 들어감.
- `DEDUP = "0"`으로 두면 중복 제한 없음.
- 저장하는 것: 카드ID, A/B 수, IP 해시(이틀 뒤 삭제). 이름·질문 내용은 안 보냄.
