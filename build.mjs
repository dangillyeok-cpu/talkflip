#!/usr/bin/env node
// TalkFlip web build.
//
//   node build.mjs            → talkflip_pwa/cards.js, talkflip_pwa/decks/*.html, sw.js cache version
//   node build.mjs --check    → validate + report only, write nothing
//
// Sources
//   cards.json            core card data (iOS + web). Taboo cards are dropped for the web.
//   data/spicy.json       Spicy deck (web only). Same card shape; vote cards carry `trait`.
//   data/extras.json      web-only extra cards for the core decks (ids end in _xNN).
//   data/traits.json      8 trait definitions + trait for every vote card in cards.json.
//   data/decks.web.json   deck order, colors, and copy for the deck pages.
//
// Output card shape: { id, deck, cardType, ko, en, follow?, trait? }

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const ROOT = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.join(ROOT, "talkflip_pwa");
const CHECK = process.argv.includes("--check");
const SITE = "https://wealthviewlounge.com";

const readJson = (p) => JSON.parse(fs.readFileSync(path.join(ROOT, p), "utf8"));

const core = readJson("cards.json").cards;
const spicy = readJson("data/spicy.json").cards;
const extras = readJson("data/extras.json").cards;
const { traits: TRAITS, voteTraits } = readJson("data/traits.json");
const DECKS = readJson("data/decks.web.json").decks;
const PENALTIES = readJson("data/penalties.json").penalties;

const deckIds = new Set(DECKS.map((d) => d.id));
const traitIds = new Set(Object.keys(TRAITS));
const WEB_TYPES = new Set(["answer", "choice", "vote", "story", "deep_light"]);
const errors = [];
const fail = (m) => errors.push(m);

/* ---------- merge ---------- */
function toWeb(card, source) {
  const out = { id: card.id, deck: card.deck, cardType: card.cardType, ko: card.ko, en: card.en };
  if (card.follow) out.follow = { ko: card.follow.ko, en: card.follow.en };
  if (card.penalty) out.penalty = true;   // "패스하면 벌칙": the app shows a penalty-wheel button on this card
  if (card.cardType === "vote") {
    const tr = card.trait ?? voteTraits[card.id];
    if (!tr) fail(`${card.id}: vote card has no trait (${source})`);
    else if (!traitIds.has(tr)) fail(`${card.id}: unknown trait "${tr}"`);
    out.trait = tr;
  } else if (card.trait) {
    fail(`${card.id}: only vote cards may have a trait`);
  }
  return out;
}

const cards = [
  ...core.filter((c) => c.cardType !== "taboo").map((c) => toWeb(c, "cards.json")),
  ...spicy.map((c) => toWeb(c, "data/spicy.json")),
  ...extras.map((c) => toWeb(c, "data/extras.json")),
];

/* ---------- validate ---------- */
const seen = new Set();
const splitChoice = (s) => s.replace(/[?？]\s*$/, "").split(/\s+vs\s+|\s+or\s+/i);
for (const c of cards) {
  if (seen.has(c.id)) fail(`${c.id}: duplicate id`);
  seen.add(c.id);
  if (!deckIds.has(c.deck)) fail(`${c.id}: unknown deck "${c.deck}"`);
  if (!WEB_TYPES.has(c.cardType)) fail(`${c.id}: unsupported cardType "${c.cardType}"`);
  for (const l of ["ko", "en"]) {
    if (typeof c[l] !== "string" || !c[l].trim()) fail(`${c.id}: empty ${l}`);
  }
  if (c.cardType === "choice") {
    for (const l of ["ko", "en"]) {
      if (splitChoice(c[l]).length !== 2) fail(`${c.id}: choice text (${l}) must have exactly one " vs " or " or ": ${c[l]}`);
    }
  }
}
{
  const pid = new Set();
  for (const p of PENALTIES) {
    if (pid.has(p.id)) fail(`penalty ${p.id}: duplicate id`);
    pid.add(p.id);
    if (!p.ko?.trim() || !p.en?.trim()) fail(`penalty ${p.id}: empty text`);
  }
  if (PENALTIES.length < 8) fail("data/penalties.json: need at least 8 penalties");
}
for (const id of Object.keys(voteTraits)) {
  if (!seen.has(id)) fail(`data/traits.json: voteTraits has unknown card ${id}`);
}
for (const d of DECKS) {
  if (!d.accent || !d.ink) fail(`deck ${d.id}: accent/ink missing`);
  const votes = cards.filter((c) => c.deck === d.id && c.cardType === "vote").length;
  if (votes > 0 && votes < 4) fail(`deck ${d.id}: ${votes} vote cards; a deck with votes needs at least 4 (one group round)`);
}

/* ---------- report ---------- */
const matrix = {};
for (const c of cards) {
  matrix[c.deck] ??= { total: 0 };
  matrix[c.deck][c.cardType] = (matrix[c.deck][c.cardType] ?? 0) + 1;
  matrix[c.deck].total++;
}
console.log(`cards: ${core.length} core (−${core.length - core.filter((c) => c.cardType !== "taboo").length} taboo) + ${spicy.length} spicy + ${extras.length} extras = ${cards.length}`);
console.table(matrix);
const traitCount = {};
for (const c of cards) if (c.trait) traitCount[c.trait] = (traitCount[c.trait] ?? 0) + 1;
console.log("vote cards per trait:", traitCount);

if (errors.length) {
  console.error(`\n${errors.length} problem(s):`);
  for (const e of errors) console.error(" - " + e);
  process.exit(1);
}
if (CHECK) { console.log("\n--check: OK, nothing written."); process.exit(0); }

/* ---------- write cards.js ---------- */
const appDecks = DECKS.map((d) => {
  const o = { id: d.id, ko: d.ko, en: d.en, accent: d.accent, ink: d.ink };
  if (d.players) o.players = d.players;
  if (d.passPenalty) o.passPenalty = true;   // every answer/story/deep card in this deck shows the penalty button
  return o;
});
const cardsJs =
  "/* TalkFlip card data — generated by build.mjs from cards.json + data/*.json. Do not edit; run `node build.mjs`. */\n" +
  "window.TF_DATA = " + JSON.stringify({ decks: appDecks, traits: TRAITS, cards, penalties: PENALTIES.map((p) => ({ ko: p.ko, en: p.en })) }) + ";\n";
fs.writeFileSync(path.join(OUT, "cards.js"), cardsJs);
console.log(`\nwrote talkflip_pwa/cards.js (${(cardsJs.length / 1024).toFixed(1)} KB)`);

/* ---------- write decks/*.html ---------- */
const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const TYPE_LABEL = {
  vote: { ko: "누가 제일", en: "Who's most likely", hint_ko: "다 같이 셋 세고 한 명 찍기", hint_en: "Count to three, everyone points" },
  choice: { ko: "밸런스", en: "This or that", hint_ko: "둘 중 하나, 동시에 고르기", hint_en: "Pick one at the same time" },
  answer: { ko: "답하기", en: "Answer", hint_ko: "한 명씩 돌아가며", hint_en: "Take turns" },
  story: { ko: "썰 풀기", en: "Tell a story", hint_ko: "짧게 한 토막", hint_en: "One short story" },
  deep_light: { ko: "진지하게", en: "For real", hint_ko: "곤란하면 패스", hint_en: "Pass if you want" },
};
const TYPE_ORDER = ["vote", "choice", "answer", "story", "deep_light"];

// Page chrome strings. Static pages exist in ko (x.html) and en (x.en.html) like the rest of the site.
const PG = {
  ko: {
    ext: ".html", play: "▶ 플레이", about: "소개", guides: "플레이 &amp; 가이드", faq: "FAQ", privacy: "개인정보 처리방침", terms: "이용약관", contact: "문의",
    deckTitle: (d, n) => `${d.ko} 덱 질문 ${n}개`, deckH1: (d) => `${d.ko} 덱`, chip: (d, n) => `${d.ko} · ${n}장${d.players ? " · 2명" : ""}`,
    count: (n) => `${n}장`, startTop: "▶ 이 덱으로 바로 시작", startSticky: (d) => `▶ ${d.ko} 덱으로 시작`,
    startNote: "설치 없이 브라우저에서 바로. 링크를 열면 첫 카드가 나와요.", composition: "카드 구성", otherDecks: "다른 덱", more: "더 읽기",
    penaltyLink: "술게임 벌칙 룰렛", guidesLink: "플레이 방법 &amp; 가이드", partyGuide: "모임 질문 게임", coupleGuide: "커플 질문", drinksGuide: "술자리 질문 가이드",
    passPenalty: "패스하면 벌칙", deckDesc: (d, n, summary) => `TalkFlip ${d.ko} 덱 — ${d.tagline_ko} ${n}장 전체 질문 목록. ${summary}.`, sample: "예: ",
    pen: {
      title: (n) => `술게임 벌칙 룰렛 · 벌칙 ${n}가지`, desc: (n) => `술자리·모임에서 바로 쓰는 벌칙 ${n}가지와 랜덤 벌칙 룰렛. 술 없이도 되는 벌칙 위주라 누구나 참여 가능. 버튼 한 번으로 룰렛 돌리기.`,
      chip: (n) => `벌칙 ${n}가지`, h1: "술게임 벌칙 룰렛", lead: "\"벌칙 뭐 하지?\"에서 멈추지 마. 버튼 한 번이면 룰렛이 골라줘.",
      body: "지목 게임에서 제일 많이 찍힌 사람, 밸런스에서 소수파, 질문에 패스한 사람. 벌칙은 필요한데 매번 생각하기 귀찮을 때 쓰는 랜덤 벌칙 룰렛이에요. 술 없이도 되는 벌칙 위주라 안 마시는 사람도, 카페에서도 돼요. 폰 하나면 끝.",
      cta: "▶ 룰렛 돌리기", note: "TalkFlip 게임 안에서 열려요. 지목 카드에서 \"벌칙\" 버튼을 눌러도 같은 룰렛.", howTitle: "이렇게 써요",
      how: ["<b>지목 카드</b>에서 제일 많이 찍힌 사람 → 벌칙 버튼 → 룰렛.", "<b>밸런스</b>에서 소수파 전원 벌칙. 동률이면 다 같이.", "질문에 <b>패스</b>하면 벌칙. 매운맛 덱은 이 룰이 기본.", "선은 지키기. 하기 싫은 벌칙은 \"흑역사 하나 털기\"로 대체."],
      listTitle: (n) => `벌칙 ${n}가지`, seeAlso: "같이 보기", spicyDeck: "매운맛 덱 질문", partyDeck: "파티 덱 질문", howToPlay: "플레이 방법",
    },
  },
  en: {
    ext: ".en.html", play: "▶ Play", about: "About", guides: "How to Play &amp; Guides", faq: "FAQ", privacy: "Privacy Policy", terms: "Terms", contact: "Contact",
    deckTitle: (d, n) => `${d.en} deck: ${n} questions`, deckH1: (d) => `${d.en} deck`, chip: (d, n) => `${d.en} · ${n} cards${d.players ? " · 2 players" : ""}`,
    count: (n) => `${n} cards`, startTop: "▶ Start with this deck", startSticky: (d) => `▶ Start ${d.en}`,
    startNote: "No install, right in the browser. Open the link and the first card is there.", composition: "What's inside", otherDecks: "Other decks", more: "Read more",
    penaltyLink: "Penalty wheel", guidesLink: "How to play &amp; guides", partyGuide: "Party question games", coupleGuide: "Couple questions", drinksGuide: "Drinking questions guide",
    passPenalty: "Pass = penalty", deckDesc: (d, n, summary) => `TalkFlip ${d.en} deck: ${d.tagline_en} All ${n} questions. ${summary}.`, sample: "e.g. ",
    pen: {
      title: (n) => `Drinking Game Penalty Wheel · ${n} penalties`, desc: (n) => `${n} party penalties and a random penalty wheel for drinking games and hangouts. Mostly no-alcohol penalties, so everyone can play. One tap to spin.`,
      chip: (n) => `${n} penalties`, h1: "Penalty Wheel", lead: "Stuck on \"so what's the penalty?\" One tap and the wheel decides.",
      body: "The most-voted person on a point card, the smaller side on a this-or-that, whoever passes on a question. When you need a penalty but can't be bothered to invent one, spin. Most penalties work without alcohol, so non-drinkers and café tables are fine. One phone is all it takes.",
      cta: "▶ Spin the wheel", note: "Opens inside the TalkFlip game. The Penalty button on point cards is the same wheel.", howTitle: "How to use it",
      how: ["<b>Point cards:</b> most-voted person → Penalty button → spin.", "<b>This or that:</b> the smaller side takes a penalty. Tie means everyone.", "<b>Pass</b> on a question, take a penalty. The Spicy deck runs on this rule.", "Keep it decent. Swap any penalty you hate for \"tell one embarrassing story\"."],
      listTitle: (n) => `All ${n} penalties`, seeAlso: "See also", spicyDeck: "Spicy deck questions", partyDeck: "Party deck questions", howToPlay: "How to play",
    },
  },
};
const hreflang = (base) => `<link rel="alternate" hreflang="ko" href="${SITE}/${base}" />
<link rel="alternate" hreflang="en" href="${SITE}/${base}.en" />
<link rel="alternate" hreflang="x-default" href="${SITE}/${base}" />`;
const langSwitch = (koHref, enHref, lang) => `<div class="langswitch"><a${lang === "ko" ? ' class="on"' : ""} href="${koHref}">한국어</a><span>·</span><a${lang === "en" ? ' class="on"' : ""} href="${enHref}">EN</a></div>`;
const footer = (P, up) => `  <footer>
    <nav>
      <a href="${up}">${P.play}</a>
      <a href="${up}about${P.ext}">${P.about}</a>
      <a href="${up}guides${P.ext}">${P.guides}</a>
      <a href="${up}faq${P.ext}">${P.faq}</a>
      <a href="${up}privacy${P.ext}">${P.privacy}</a>
      <a href="${up}terms${P.ext}">${P.terms}</a>
    </nav>
    <div>${P.contact}: dangillyeok@gmail.com</div>
    <div>© 2026 TalkFlip</div>
  </footer>`;
const stickyScript = `  <script>
    // floating start button only once the top one has scrolled away
    (function(){ var s=document.getElementById("sticky"), t=document.getElementById("topCta"); if(!("IntersectionObserver" in window)){ s.classList.add("show"); return; }
      new IntersectionObserver(function(e){ s.classList.toggle("show", !e[0].isIntersecting && e[0].boundingClientRect.top < 0); }).observe(t); })();
  </script>`;

function deckPage(d, lang) {
  const P = PG[lang];
  const name = d[lang];
  const mine = cards.filter((c) => c.deck === d.id);
  const groups = TYPE_ORDER.map((t) => [t, mine.filter((c) => c.cardType === t)]).filter(([, l]) => l.length);
  const summary = groups.map(([t, l]) => `${TYPE_LABEL[t][lang]} ${P.count(l.length)}`).join(" · ");
  const desc = P.deckDesc(d, mine.length, summary);
  const sample = mine.slice(0, 3).map((c) => c[lang]).join(" / ");
  const pageUrl = `${SITE}/decks/${d.id}${lang === "en" ? ".en" : ""}`;
  const appHref = `../?deck=${d.id}${lang === "en" ? "&lang=en" : ""}`;
  const ld = {
    "@context": "https://schema.org",
    "@type": "Article",
    headline: P.deckTitle(d, mine.length),
    description: desc,
    inLanguage: lang,
    dateModified: new Date().toISOString().slice(0, 10),
    author: { "@type": "Organization", name: "TalkFlip" },
    publisher: { "@type": "Organization", name: "TalkFlip" },
    mainEntityOfPage: pageUrl,
  };
  const others = DECKS.filter((x) => x.id !== d.id).map((x) => `<a href="${x.id}${P.ext}">${esc(x[lang])}</a>`).join(" · ");
  const sections = groups.map(([t, l]) => `
  <h2 id="${t}">${esc(TYPE_LABEL[t][lang])} <span class="muted">${P.count(l.length)} · ${esc(TYPE_LABEL[t]["hint_" + lang])}</span></h2>
  <ol class="qs">
${l.map((c) => `    <li>${esc(c[lang])}${c.follow ? `<small>${esc(c.follow[lang])}</small>` : c.penalty ? `<small>${esc(P.passPenalty)}</small>` : ""}</li>`).join("\n")}
  </ol>`).join("\n");

  return `<!DOCTYPE html>
<html lang="${lang}">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>${esc(P.deckTitle(d, mine.length))} · TalkFlip</title>
<meta name="description" content="${esc(desc)}" />
<link rel="canonical" href="${pageUrl}" />
${hreflang(`decks/${d.id}`)}
<meta property="og:type" content="article" />
<meta property="og:site_name" content="TalkFlip" />
<meta property="og:title" content="${esc(P.deckTitle(d, mine.length))} · TalkFlip" />
<meta property="og:description" content="${esc(d["tagline_" + lang])} ${esc(P.sample)}${esc(sample)}" />
<meta property="og:url" content="${pageUrl}" />
<meta property="og:image" content="${SITE}/og.png" />
<meta name="theme-color" content="${d.accent}" />
<link rel="stylesheet" href="../pages.css" />
<style>
  .deckhead{--a:${d.accent};--k:${d.ink}}
  .deckhead .chip{background:var(--a);color:var(--k)}
  .deckhead .cta{background:var(--a);color:var(--k)}
  .best{display:flex;flex-wrap:wrap;gap:8px;margin:14px 0 0;padding:0;list-style:none}
  .best li{font-size:13px;font-weight:700;padding:6px 12px;border-radius:999px;background:var(--surface);border:1px solid var(--line)}
  .qs{padding-left:0;counter-reset:q;list-style:none;margin:0 0 8px}
  .qs li{counter-increment:q;position:relative;padding:12px 0 12px 44px;border-bottom:1px solid var(--line);font-size:16px;font-weight:600;line-height:1.5;word-break:keep-all}
  .qs li::before{content:counter(q);position:absolute;left:0;top:13px;width:30px;text-align:right;font-size:13px;font-weight:800;color:var(--muted)}
  .qs li small{display:block;font-size:13px;font-weight:500;color:var(--muted);margin-top:2px}
  .jump{display:flex;flex-wrap:wrap;gap:8px 14px;margin:8px 0 0;font-size:14px;font-weight:700}
  .jump a{text-decoration:none}
  .sticky{position:sticky;bottom:16px;display:flex;justify-content:center;margin-top:28px;pointer-events:none;opacity:0;transition:opacity .2s}
  .sticky.show{opacity:1}
  .sticky .cta{pointer-events:auto;margin:0;box-shadow:0 10px 30px rgba(0,0,0,.25)}
</style>
<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-5582757393756677" crossorigin="anonymous"></script>
<script type="application/ld+json">
${JSON.stringify(ld, null, 2)}
</script>
</head>
<body>
<div class="topbar"><div class="bar">
  <a class="brand" href="../">TalkFlip</a>
  ${langSwitch(`${d.id}.html`, `${d.id}.en.html`, lang)}
</div></div>
<div class="wrap deckhead">
  <span class="chip">${esc(P.chip(d, mine.length))}</span>
  <h1>${esc(P.deckH1(d))}</h1>
  <p class="lead">${esc(d["tagline_" + lang])}</p>

  <p>${esc(d["desc_" + lang])}</p>
  <ul class="best">${d["best_" + lang].map((b) => `<li>${esc(b)}</li>`).join("")}</ul>

  <a class="cta" id="topCta" href="${appHref}">${P.startTop}</a>
  <p class="muted" style="margin-top:8px">${esc(P.startNote)}</p>

  <h2>${P.composition}</h2>
  <p>${esc(summary)}</p>
  <div class="jump">${groups.map(([t]) => `<a href="#${t}">${esc(TYPE_LABEL[t][lang])}</a>`).join("")}</div>
${sections}

  <div class="sticky" id="sticky"><a class="cta" href="${appHref}" tabindex="-1" aria-hidden="true">${esc(P.startSticky(d))}</a></div>
${stickyScript}

  <h2>${P.otherDecks}</h2>
  <p>${others}</p>
  <p>${P.more}: <a href="../penalty${P.ext}">${P.penaltyLink}</a> · <a href="../guides${P.ext}">${P.guidesLink}</a> · <a href="../guide-party${P.ext}">${P.partyGuide}</a> · <a href="../guide-couple${P.ext}">${P.coupleGuide}</a></p>

${footer(P, "../")}
</div>
</body>
</html>
`;
}

fs.mkdirSync(path.join(OUT, "decks"), { recursive: true });
for (const d of DECKS) for (const lang of ["ko", "en"]) {
  fs.writeFileSync(path.join(OUT, "decks", `${d.id}${PG[lang].ext}`), deckPage(d, lang));
}
console.log(`wrote talkflip_pwa/decks/{${DECKS.map((d) => d.id).join(",")}}.html + .en.html`);

/* ---------- iOS bundle: TalkFlip/TalkFlipApp/cards.json + decks.json ---------- */
// The SwiftUI app (v1 UI) decodes TalkCard { id, deck, cardType, modes, en, ko, follow?, … } and
// Deck { id, name{en,ko}, description{en,ko}, minPlayers?, maxPlayers? }. It gets every card the
// web has (core incl. taboo + extras + spicy); `modes` is derived from cardType for the web-only
// cards. Unknown keys (trait, penalty) are ignored by Codable.
const IOS = path.join(ROOT, "TalkFlip", "TalkFlipApp");
const MODES_BY_TYPE = {
  answer: ["classic_flip", "hot_seat"], story: ["classic_flip", "hot_seat"], deep_light: ["classic_flip", "hot_seat"],
  choice: ["this_or_that"], vote: ["whos_most_likely"], taboo: ["taboo_round"],
};
const iosCard = (c) => {
  const o = { id: c.id, deck: c.deck, cardType: c.cardType, modes: c.modes ?? MODES_BY_TYPE[c.cardType] };
  for (const k of ["minPlayers", "maxPlayers", "tone"]) if (c[k] !== undefined) o[k] = c[k];
  o.en = c.en; o.ko = c.ko;
  if (c.follow) o.follow = { en: c.follow.en, ko: c.follow.ko };
  if (c.bannedEn) o.bannedEn = c.bannedEn;
  if (c.bannedKo) o.bannedKo = c.bannedKo;
  if (!o.modes) fail(`${c.id}: no modes for iOS (cardType ${c.cardType})`);
  return o;
};
const iosCards = [...core, ...spicy, ...extras].map(iosCard);
const rootDecks = readJson("decks.json");
const iosDecks = {
  version: rootDecks.version,
  decks: [
    ...rootDecks.decks,
    ...DECKS.filter((d) => !rootDecks.decks.some((r) => r.id === d.id)).map((d) => ({
      id: d.id, name: { en: d.en, ko: d.ko }, description: { en: d.tagline_en, ko: d.tagline_ko },
      ...(d.players ? { minPlayers: d.players, maxPlayers: d.players } : {}),
    })),
  ],
};
if (fs.existsSync(IOS)) {
  fs.writeFileSync(path.join(IOS, "cards.json"), JSON.stringify({ version: readJson("cards.json").version, cards: iosCards }, null, 2) + "\n");
  fs.writeFileSync(path.join(IOS, "decks.json"), JSON.stringify(iosDecks, null, 2) + "\n");
  console.log(`wrote TalkFlip/TalkFlipApp/cards.json (${iosCards.length} cards) + decks.json (${iosDecks.decks.length} decks)`);
}

/* ---------- write penalty.html (벌칙 룰렛 landing) ---------- */
function penaltyPage(lang) {
  const P = PG[lang], T = P.pen;
  const n = PENALTIES.length;
  const pageUrl = `${SITE}/penalty${lang === "en" ? ".en" : ""}`;
  const appHref = `./?roulette${lang === "en" ? "&lang=en" : ""}`;
  const ld = {
    "@context": "https://schema.org",
    "@type": "Article",
    headline: T.title(n),
    description: T.desc(n),
    inLanguage: lang,
    dateModified: new Date().toISOString().slice(0, 10),
    author: { "@type": "Organization", name: "TalkFlip" },
    publisher: { "@type": "Organization", name: "TalkFlip" },
    mainEntityOfPage: pageUrl,
  };
  return `<!DOCTYPE html>
<html lang="${lang}">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>${esc(T.title(n))} · TalkFlip</title>
<meta name="description" content="${esc(T.desc(n))}" />
<link rel="canonical" href="${pageUrl}" />
${hreflang("penalty")}
<meta property="og:type" content="article" />
<meta property="og:site_name" content="TalkFlip" />
<meta property="og:title" content="${esc(T.title(n))} · TalkFlip" />
<meta property="og:description" content="${esc(T.desc(n))}" />
<meta property="og:url" content="${pageUrl}" />
<meta property="og:image" content="${SITE}/og.png" />
<link rel="stylesheet" href="pages.css" />
<style>
  .qs{padding-left:0;counter-reset:q;list-style:none;margin:0 0 8px}
  .qs li{counter-increment:q;position:relative;padding:12px 0 12px 44px;border-bottom:1px solid var(--line);font-size:16px;font-weight:600;line-height:1.5;word-break:keep-all}
  .qs li::before{content:counter(q);position:absolute;left:0;top:13px;width:30px;text-align:right;font-size:13px;font-weight:800;color:var(--muted)}
  .sticky{position:sticky;bottom:16px;display:flex;justify-content:center;margin-top:28px;pointer-events:none;opacity:0;transition:opacity .2s}
  .sticky.show{opacity:1}
  .sticky .cta{pointer-events:auto;margin:0;box-shadow:0 10px 30px rgba(0,0,0,.25)}
</style>
<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-5582757393756677" crossorigin="anonymous"></script>
<script type="application/ld+json">
${JSON.stringify(ld, null, 2)}
</script>
</head>
<body>
<div class="topbar"><div class="bar">
  <a class="brand" href="./">TalkFlip</a>
  ${langSwitch("penalty.html", "penalty.en.html", lang)}
</div></div>
<div class="wrap">
  <span class="chip">${esc(T.chip(n))}</span>
  <h1>${esc(T.h1)}</h1>
  <p class="lead">${esc(T.lead)}</p>

  <p>${esc(T.body)}</p>

  <a class="cta" id="topCta" href="${appHref}">${T.cta}</a>
  <p class="muted" style="margin-top:8px">${esc(T.note)}</p>

  <h2>${T.howTitle}</h2>
  <ul>
${T.how.map((h) => `    <li>${h}</li>`).join("\n")}
  </ul>

  <h2>${esc(T.listTitle(n))}</h2>
  <ol class="qs">
${PENALTIES.map((p) => `    <li>${esc(p[lang])}</li>`).join("\n")}
  </ol>

  <div class="sticky" id="sticky"><a class="cta" href="${appHref}" tabindex="-1" aria-hidden="true">${T.cta}</a></div>
${stickyScript}

  <h2>${T.seeAlso}</h2>
  <p><a href="decks/spicy${P.ext}">${T.spicyDeck}</a> · <a href="decks/party${P.ext}">${T.partyDeck}</a> · <a href="guide-drinks${P.ext}">${P.drinksGuide}</a> · <a href="guides${P.ext}">${T.howToPlay}</a></p>

${footer(P, "")}
</div>
</body>
</html>
`;
}
for (const lang of ["ko", "en"]) fs.writeFileSync(path.join(OUT, `penalty${PG[lang].ext}`), penaltyPage(lang));
console.log("wrote talkflip_pwa/penalty.html + penalty.en.html");

/* ---------- sw.js cache version = vN + content hash ---------- */
// Old clients keep the previous app shell until the cache name changes. Hash the
// files in the shell so any change to index.html or cards.js rolls the cache.
const swPath = path.join(OUT, "sw.js");
let sw = fs.readFileSync(swPath, "utf8");
const h = crypto.createHash("sha1");
for (const f of ["index.html", "cards.js", "manifest.webmanifest"]) h.update(fs.readFileSync(path.join(OUT, f)));
const hash = h.digest("hex").slice(0, 8);
const m = sw.match(/const CACHE = "talkflip-v(\d+)(?:-[0-9a-f]+)?";/);
if (!m) { console.warn("sw.js: CACHE constant not found, left untouched"); }
else {
  const next = `const CACHE = "talkflip-v${m[1]}-${hash}";`;
  if (sw.slice(m.index, m.index + m[0].length) !== next) {
    sw = sw.slice(0, m.index) + next + sw.slice(m.index + m[0].length);
    fs.writeFileSync(swPath, sw);
    console.log(`sw.js cache → talkflip-v${m[1]}-${hash}`);
  } else console.log("sw.js cache unchanged");
}
console.log("done.");
