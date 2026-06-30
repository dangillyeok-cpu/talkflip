# TalkFlip MVP Card Guide v0.5

Date: 2026-06-29

Change note:

- v0.2 separates `deck`, `game mode`, and `cardType` more strictly.
- v0.2 replaces the old content target with a deck x cardType matrix.
- v0.2 adds player-count rules, ID naming rules, and KOR + ENG layout notes.
- v0.3 adds mode x deck availability rules to prevent empty or too-small play pools.
- v0.3 clarifies Hot Seat card selection and expansion-buffer imbalance.
- v0.4 aligns availability checks with player-count filtering.
- v0.4 defines Quick Round and makes the Couple deck explicitly 2-player only.
- v0.5 resolves the threshold conflict between 14.4, 14.4.1, 14.6, and 14.7 so each
  mode x deck combination has exactly one availability verdict.
- v0.5 reclassifies `this_or_that` + `deep` (4 cards) as disabled, and
  `this_or_that` + `couple` (6 cards) as the canonical Quick Round example.
- v0.5 unifies Couple handling to a single rule: hidden unless the session has exactly 2 players.

## 1. Product Summary

TalkFlip is a random question card game for friends, couples, and hangouts.

It is not positioned as a language-learning app. Korean, English, and KOR + ENG display modes are part of the play experience, not the main educational promise.

Korean positioning:

> 친구, 커플, 모임에서 랜덤 카드를 뽑으며 즐기는 질문 게임.

English positioning:

> A random question card game for friends, couples, and hangouts.

## 2. Core Product Loop

```text
Choose Game Mode
-> Choose Deck
-> Choose Language Display
-> Draw Random Card
-> Answer / Vote / Choose / Pass
-> Next Round
```

The user should feel like they are drawing a card, not browsing a question list.

## 2.1 Core Content Axes

TalkFlip content is organized across three separate axes.

```text
Game Mode = how people play
Deck = the vibe or situation
Card Type = the interaction shape
```

These axes should not be mixed.

### Game Modes

- `classic_flip`
- `this_or_that`
- `whos_most_likely`
- `hot_seat`
- `taboo_round`

### Decks

- `warm_up`
- `funny`
- `deep`
- `couple`
- `party`

### Card Types

- `answer`
- `choice`
- `vote`
- `story`
- `deep_light`

Example:

```text
User selects:
Mode = this_or_that
Deck = warm_up

App filters:
deck == warm_up
cardType == choice
modes includes this_or_that
```

`This or That` and `Who's Most Likely` are game modes, not decks.

## 3. MVP Game Modes

### 3.1 Classic Flip

Simple turn-based question mode.

Rules:

- One player draws a card.
- The player answers the question.
- Move to the next player.
- Players may pass if the group allows it.

Best for:

- First meetings
- Small friend groups
- Casual dates
- Light hangouts

Recommended card types:

- `answer`
- `story`
- `deep_light`

Player count:

- `minPlayers`: 1
- `recommendedPlayers`: 2-6

### 3.2 This or That

Fast A/B choice mode.

Rules:

- A card shows two choices.
- Everyone picks one.
- The minority side explains first.
- If everyone picks the same side, one person explains the obvious choice.

Best for:

- Fast party play
- Warm-up rounds
- Groups that do not want heavy questions

Recommended card type:

- `choice`

Player count:

- `minPlayers`: 1
- `recommendedPlayers`: 2-8

### 3.3 Who's Most Likely

Group voting mode.

Rules:

- A card asks who is most likely to do something.
- Everyone points to or names one person.
- The most-voted person gives a short defense.

Best for:

- Friend groups
- Parties
- Groups that already know each other

Recommended card type:

- `vote`

Player count:

- `minPlayers`: 3
- `recommendedPlayers`: 3-8

Safety rule:

- Vote cards must target harmless behavior, not appearance, income, intelligence, popularity, trauma, or sexual history.

### 3.4 Hot Seat

Focused question mode for one player at a time.

Rules:

- One player is in the Hot Seat.
- Draw 3 cards.
- The Hot Seat player answers 2 of them.
- Then the turn moves to the next player.

Best for:

- Close friends
- Couples
- Deeper hangouts

Recommended card types:

- `answer`
- `story`
- `deep_light`

Selection preference:

- Prefer `deep_light` and `story` slightly more than Classic Flip.
- Use `answer` as filler when the selected deck has too few deeper cards.

Player count:

- `minPlayers`: 2
- `recommendedPlayers`: 2-6

### 3.5 Taboo Round

Describe-and-catch mode. One player explains a topic out loud while avoiding a short list of banned words. Everyone else listens and catches slips.

Rules:

- One player draws a `taboo` card and sees the topic plus its banned words.
- That player describes or talks through the topic out loud.
- If they say any banned word, the listeners catch it and that player takes a penalty.
- Then the turn moves to the next player.

Judging:

- Judging is done by people, not the app. The app only displays the topic and the banned word list.
- This is deliberate: it avoids fragile automatic word-matching, which is especially unreliable in Korean because of conjugation and particles (e.g. "피곤", "피곤한", "피곤해서"). Players decide what counts.

Best for:

- Parties and lively groups
- Fast, social rounds with lots of reactions

Recommended card type:

- `taboo`

Player count:

- `minPlayers`: 3
- `recommendedPlayers`: 3-8
- Needs at least one explainer plus listeners to catch slips, so it does not work below 3 players.

Deck availability:

- `taboo` cards exist only in the `funny` and `party` decks.
- Other decks are disabled for Taboo Round (see 14.4).

## 4. MVP Decks

### 4.1 Warm Up

Purpose:

- Easy first cards.
- Low pressure.
- Everyone can answer within 3 seconds.

Tone:

- Light, friendly, safe.

### 4.2 Funny

Purpose:

- Create laughter.
- Encourage harmless self-recognition.
- Include a small amount of current internet language.

Tone:

- Playful, slightly witty, not childish.

### 4.3 Deep

Purpose:

- Create a more meaningful conversation without feeling like therapy.

Tone:

- Warm, reflective, optional.

### 4.4 Couple

Purpose:

- Help couples or people dating talk without forcing confessions.
- Designed for exactly 2 players, or a clearly defined pair within a group.

Tone:

- Sweet, curious, light.

Player count:

- `minPlayers`: 2
- `maxPlayers`: 2
- The Couple deck is shown only when the active session has exactly 2 players.
- If the session has more or fewer than 2 players, hide the Couple deck in MVP.
- Pair selection within a larger group is a post-MVP feature, not part of the first release.

### 4.5 Party

Purpose:

- Group reactions, voting, fast laughter.

Tone:

- Social, energetic, safe.

## 5. Language Display Modes

### EN

Show English only.

### KR

Show Korean only.

### KOR + ENG

Show both languages on the same card.

Recommended display rule:

- If the app UI language is Korean: show Korean first, English second.
- If the app UI language is English: show English first, Korean second.

Button labels:

- `EN`
- `KR`
- `KOR + ENG`

Korean UI labels:

- `영어`
- `한국어`
- `KOR + ENG`

KOR + ENG layout notes:

- Combined Korean + English text should ideally fit within 5-7 total lines on the card.
- If both texts are long, reduce secondary-language emphasis before shrinking both texts.
- Primary language may use a larger font; secondary language may use a smaller font and softer color.
- Avoid scrollable question cards in MVP if possible.
- During content QA, review KOR + ENG cards side by side because translation mismatches are more visible in this mode.

## 6. What Makes a Good TalkFlip Card

TalkFlip cards are designed to create reactions, not collect information.

A good card should create at least one of these:

- Laughter
- A quick choice
- A vote
- A short story
- A small disagreement
- A "me too" moment
- A safe personal reveal

## 7. Card Writing Rules

### Rule 1: The answer should appear within 3 seconds

Weak:

- What is your life philosophy?

Better:

- What tiny thing instantly improves your mood?

### Rule 2: Avoid questions that sound like homework

Weak:

- What is the meaning of friendship?

Better:

- What friend behavior instantly makes you trust someone?

### Rule 3: Add mild tension, not discomfort

Good:

- What tiny thing annoys you more than it should?

Avoid:

- Questions about trauma, body, income, sexual history, politics, religion, or family wounds.

### Rule 4: Make the situation visible

Weak:

- What food do you like?

Better:

- What food could rescue a bad day at 11 p.m.?

### Rule 5: Let others jump in

Good:

- Who here would survive best without their phone for a week?

### Rule 6: Keep it short

Recommended length:

- Korean: around 20-40 characters when possible.
- English: around 8-16 words when possible.

### Rule 7: Use memes as seasoning

Use terms like `rizz`, `aura`, `NPC`, `brain rot`, `도파민`, or `럭키비키` sparingly.

Recommended ratio:

- Across the full 232-card v1 set, 10-15% of cards may include current internet language.
- If the 40-card expansion buffer is added, keep the same 10-15% target across the full 240-card set.
- Within the `funny` deck, internet-language cards may go slightly higher, but should still stay under 25%.
- 75-90% of cards should remain timeless, depending on deck.

## 8. Card Types

### answer

One player answers.

Example:

- EN: What tiny thing instantly improves your mood?
- KO: 기분을 바로 좋아지게 만드는 작은 일은 뭐야?

### choice

Everyone chooses A or B.

Example:

- EN: Perfect timing or perfect charm?
- KO: 완벽한 타이밍 vs 완벽한 매력?

### vote

Everyone points to or names one person.

Example:

- EN: Who here is most likely to disappear from the group chat?
- KO: 여기서 단톡방 잠수탈 가능성이 가장 높은 사람은?

### story

One player tells a short story.

Example:

- EN: What is a small embarrassing moment you still remember?
- KO: 아직도 기억나는 사소하게 민망한 순간은?

### deep_light

A reflective card that stays safe.

Example:

- EN: When do you feel most like yourself?
- KO: 언제 가장 나답다고 느껴?

### taboo

One player describes a topic out loud while avoiding a short list of banned words. People judge slips, not the app.

Unlike other card types, a `taboo` card carries two extra fields: `bannedEn` and `bannedKo` (3-5 banned words each, matched in count). The `en`/`ko` fields hold the topic to describe.

Example:

- EN: Describe what you did last weekend
- KO: 주말에 뭐 했는지 설명하기
- bannedEn: home, sleep, tired, phone
- bannedKo: 집, 잠, 피곤, 폰

`taboo` exists only in the `funny` and `party` decks and is played in Taboo Round (3.5).

## 9. Safety Rules

Avoid these in MVP cards:

- Direct sexual experience questions
- Body or appearance ranking
- Income, wealth, or job comparison
- Politics
- Religion
- Family trauma
- Mental health diagnosis
- Alcohol pressure
- Forced physical contact
- Insults such as "ugliest", "dumbest", "least popular"
- Anything likely to be inappropriate for minors

For `taboo` cards specifically: the topic must be a neutral, everyday subject to describe (food, weekend, hometown, an object). Do not use topics that push toward appearance, income, trauma, politics, or religion. Banned words should be the obvious core words of the topic, never sensitive terms.

## 10. Korean and English Tone

### Korean

Use casual 반말 for game energy.

Good:

- 뭐야?
- 누구야?
- 골라봐
- 말해봐

Use carefully:

- ㅋㅋ
- 개-
- 미친
- 존맛

Default MVP cards should avoid overly aggressive slang.

### English

Use short, natural phrasing.

Good starts:

- What is...
- What is your...
- Who here...
- Would you rather...
- Pick one...
- Rate...

Avoid making every card sound like Gen Z slang.

## 11. Data Structure

Recommended JSON shape:

```json
{
  "id": "funny_vote_001",
  "deck": "funny",
  "cardType": "vote",
  "modes": ["whos_most_likely"],
  "minPlayers": 3,
  "maxPlayers": 8,
  "tone": "funny",
  "en": "Who here is most likely to turn a small problem into a full drama?",
  "ko": "여기서 작은 문제를 대형 드라마로 만들 가능성이 가장 높은 사람은?"
}
```

Recommended fields:

- `id`: unique card id
- `deck`: warm_up, funny, deep, couple, party
- `cardType`: answer, choice, vote, story, deep_light, taboo
- `modes`: allowed game modes
- `minPlayers`: minimum player count for the card
- `maxPlayers`: optional maximum player count for the card
- `tone`: optional sub-tone. Use only when it adds information beyond `deck`
- `en`: English card text (for `taboo`, this is the topic to describe)
- `ko`: Korean card text (for `taboo`, this is the topic to describe)
- `follow`: optional `{ en, ko }` follow-up action shown after the card is answered. Used mainly in `deep` and `couple` to extend the moment into a reaction. Each side under ~120 chars.
- `bannedEn` / `bannedKo`: required only for `taboo` cards. Arrays of 3-5 banned words each, matched in count between languages. Forbidden on all non-taboo cards.

A `follow` field turns a one-way "ask and answer" card into a short loop ("answer, then react"). Example:

```json
{
  "id": "deep_deep_light_001",
  "deck": "deep",
  "cardType": "deep_light",
  "modes": ["classic_flip", "hot_seat"],
  "en": "When do you feel most like yourself?",
  "ko": "언제 가장 나답다고 느껴?",
  "follow": {
    "en": "Ask the answerer one more question — just one.",
    "ko": "답한 사람에게 딱 하나만 더 물어봐."
  }
}
```

A `taboo` card example:

```json
{
  "id": "party_taboo_001",
  "deck": "party",
  "cardType": "taboo",
  "modes": ["taboo_round"],
  "minPlayers": 3,
  "maxPlayers": 8,
  "en": "Describe what you did last weekend",
  "ko": "주말에 뭐 했는지 설명하기",
  "bannedEn": ["home", "sleep", "tired", "phone"],
  "bannedKo": ["집", "잠", "피곤", "폰"]
}
```

### 11.1 ID Naming Convention

Use this format:

```text
{deck}_{cardType}_{number}
```

Examples:

- `warm_up_answer_001`
- `funny_choice_001`
- `party_vote_001`
- `couple_story_001`
- `deep_deep_light_001`
- `party_taboo_001`

Avoid mode-only IDs such as:

- `choice_001`
- `vote_001`
- `deep_001`

The card ID should tell us the deck and card type without opening the full object.

### 11.2 Tone Field Rule

`tone` is optional.

If `tone` is always identical to `deck`, omit it in production data or treat it as a derived value.

Keep `tone` only when the same deck intentionally mixes sub-tones.

Example:

```json
{
  "deck": "party",
  "cardType": "vote",
  "tone": "chaotic_light"
}
```

### 11.3 Translation QA Rule

KOR + ENG mode makes translation mismatch obvious.

For every final production card, check:

- The Korean and English ask the same thing.
- The tone is similar in both languages.
- Slang is adapted, not literally forced.
- Neither side is much longer than the other without a reason.

## 12. Random Draw Rules

MVP random rules:

- Cards are shuffled at session start.
- A card should not repeat within the same session.
- Passed cards move to the back of the current session.
- When all cards are used, show `Deck complete`.
- User can choose `Shuffle again` or `Change deck`.

Suggested labels:

English:

- Draw a card
- Flip it
- Next round
- Pass
- Shuffle again
- Deck complete

Korean:

- 카드 뽑기
- 뒤집기
- 다음 라운드
- 패스
- 다시 섞기
- 덱 완료

## 13. Sample Cards v0.1

These are initial content samples for testing tone and UI. They are not final production content.

### 13.1 Warm Up

```json
[
  {
    "id": "warm_up_answer_001",
    "deck": "warm_up",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "light",
    "en": "What tiny thing instantly improves your mood?",
    "ko": "기분을 바로 좋아지게 만드는 작은 일은 뭐야?"
  },
  {
    "id": "warm_up_answer_002",
    "deck": "warm_up",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "light",
    "en": "What app do you open way too often?",
    "ko": "너무 자주 열게 되는 앱은 뭐야?"
  },
  {
    "id": "warm_up_answer_003",
    "deck": "warm_up",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "light",
    "en": "What food could rescue a bad day?",
    "ko": "힘든 날을 살려주는 음식은 뭐야?"
  },
  {
    "id": "warm_up_answer_004",
    "deck": "warm_up",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "light",
    "en": "What is a small win you had recently?",
    "ko": "최근에 있었던 작지만 기분 좋은 승리는?"
  },
  {
    "id": "warm_up_answer_005",
    "deck": "warm_up",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "light",
    "en": "If today had a title, what would it be?",
    "ko": "오늘 하루에 제목을 붙이면 뭐라고 할래?"
  },
  {
    "id": "warm_up_answer_006",
    "deck": "warm_up",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "light",
    "en": "What is one thing you never regret buying?",
    "ko": "사고 나서 후회한 적 없는 물건은 뭐야?"
  },
  {
    "id": "warm_up_answer_007",
    "deck": "warm_up",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "light",
    "en": "What is your current comfort show or video?",
    "ko": "요즘 편하게 틀어두는 영상이나 콘텐츠는?"
  },
  {
    "id": "warm_up_answer_008",
    "deck": "warm_up",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "light",
    "en": "What small routine makes your day feel better?",
    "ko": "하루를 조금 낫게 만드는 작은 루틴은?"
  },
  {
    "id": "warm_up_answer_009",
    "deck": "warm_up",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "light",
    "en": "What is something you are surprisingly good at?",
    "ko": "생각보다 내가 잘하는 건 뭐야?"
  },
  {
    "id": "warm_up_answer_010",
    "deck": "warm_up",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "light",
    "en": "What is your go-to snack lately?",
    "ko": "요즘 자주 찾는 간식은 뭐야?"
  }
]
```

### 13.2 Funny

```json
[
  {
    "id": "funny_answer_001",
    "deck": "funny",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "funny",
    "en": "What is your most useless but impressive talent?",
    "ko": "쓸모는 없지만 묘하게 자랑스러운 재능은?"
  },
  {
    "id": "funny_answer_002",
    "deck": "funny",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "funny",
    "en": "What is your strongest NPC behavior?",
    "ko": "내가 봐도 가장 NPC 같은 행동은?"
  },
  {
    "id": "funny_answer_003",
    "deck": "funny",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "funny",
    "en": "What tiny problem makes you way too dramatic?",
    "ko": "별일 아닌데 내가 너무 드라마틱해지는 순간은?"
  },
  {
    "id": "funny_answer_004",
    "deck": "funny",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "funny",
    "en": "If your brain had a loading tip, what would it say?",
    "ko": "내 머릿속 로딩 화면에 팁이 뜬다면 뭐라고 나올까?"
  },
  {
    "id": "funny_answer_005",
    "deck": "funny",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "funny",
    "en": "What opinion would you defend for no good reason?",
    "ko": "딱히 이유는 없지만 끝까지 주장하고 싶은 의견은?"
  },
  {
    "id": "funny_answer_006",
    "deck": "funny",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "funny",
    "en": "What is your most harmless red flag?",
    "ko": "내 가장 무해한 레드 플래그는 뭐야?"
  },
  {
    "id": "funny_answer_007",
    "deck": "funny",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "funny",
    "en": "What gives you fake confidence for no reason?",
    "ko": "이유 없이 자신감 생기게 하는 건 뭐야?"
  },
  {
    "id": "funny_answer_008",
    "deck": "funny",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "funny",
    "en": "What is something you pretend to hate but secretly enjoy?",
    "ko": "싫어하는 척하지만 사실 은근 좋아하는 건?"
  },
  {
    "id": "funny_answer_009",
    "deck": "funny",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "funny",
    "en": "What is your personal brain-rot habit?",
    "ko": "나만의 무의미한 콘텐츠 소비 습관은 뭐야?"
  },
  {
    "id": "funny_answer_010",
    "deck": "funny",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "funny",
    "en": "What is the most random thing you take seriously?",
    "ko": "쓸데없는데 괜히 진지해지는 건 뭐야?"
  }
]
```

### 13.3 This or That

```json
[
  {
    "id": "warm_up_choice_001",
    "deck": "warm_up",
    "cardType": "choice",
    "modes": ["this_or_that"],
    "tone": "light",
    "en": "Unlimited snacks or unlimited sleep?",
    "ko": "간식 무제한 vs 잠 무제한?"
  },
  {
    "id": "funny_choice_001",
    "deck": "funny",
    "cardType": "choice",
    "modes": ["this_or_that"],
    "tone": "funny",
    "en": "Main character energy or peaceful background character?",
    "ko": "주인공 모드 vs 평화로운 배경 인물?"
  },
  {
    "id": "funny_choice_002",
    "deck": "funny",
    "cardType": "choice",
    "modes": ["this_or_that"],
    "tone": "funny",
    "en": "Perfect timing or perfect charm?",
    "ko": "완벽한 타이밍 vs 완벽한 매력?"
  },
  {
    "id": "party_choice_001",
    "deck": "party",
    "cardType": "choice",
    "modes": ["this_or_that"],
    "tone": "party",
    "en": "Group chat legend or real-life legend?",
    "ko": "단톡방 레전드 vs 현실 레전드?"
  },
  {
    "id": "warm_up_choice_002",
    "deck": "warm_up",
    "cardType": "choice",
    "modes": ["this_or_that"],
    "tone": "light",
    "en": "Always early or always lucky?",
    "ko": "항상 일찍 도착하기 vs 항상 운 좋기?"
  },
  {
    "id": "funny_choice_003",
    "deck": "funny",
    "cardType": "choice",
    "modes": ["this_or_that"],
    "tone": "funny",
    "en": "Never lose your keys or never lose your charger?",
    "ko": "열쇠 절대 안 잃어버리기 vs 충전기 절대 안 잃어버리기?"
  },
  {
    "id": "deep_choice_001",
    "deck": "deep",
    "cardType": "choice",
    "modes": ["this_or_that"],
    "tone": "deep",
    "en": "Know the truth or keep the peace?",
    "ko": "진실 알기 vs 평화 지키기?"
  },
  {
    "id": "couple_choice_001",
    "deck": "couple",
    "cardType": "choice",
    "modes": ["this_or_that"],
    "tone": "couple",
    "en": "A planned date or a surprise date?",
    "ko": "계획된 데이트 vs 깜짝 데이트?"
  },
  {
    "id": "party_choice_002",
    "deck": "party",
    "cardType": "choice",
    "modes": ["this_or_that"],
    "tone": "party",
    "en": "Host the party or leave early?",
    "ko": "파티 주최하기 vs 일찍 빠지기?"
  },
  {
    "id": "warm_up_choice_003",
    "deck": "warm_up",
    "cardType": "choice",
    "modes": ["this_or_that"],
    "tone": "light",
    "en": "Coffee at midnight or ramen at midnight?",
    "ko": "밤 12시 커피 vs 밤 12시 라면?"
  }
]
```

### 13.4 Who's Most Likely

```json
[
  {
    "id": "party_vote_001",
    "deck": "party",
    "cardType": "vote",
    "modes": ["whos_most_likely"],
    "tone": "party",
    "en": "Who here is most likely to disappear from the group chat for a week?",
    "ko": "여기서 단톡방을 일주일 동안 잠수탈 가능성이 가장 높은 사람은?"
  },
  {
    "id": "party_vote_002",
    "deck": "party",
    "cardType": "vote",
    "modes": ["whos_most_likely"],
    "tone": "party",
    "en": "Who here would survive best without their phone?",
    "ko": "여기서 폰 없이 가장 잘 버틸 사람은?"
  },
  {
    "id": "funny_vote_001",
    "deck": "funny",
    "cardType": "vote",
    "modes": ["whos_most_likely"],
    "tone": "funny",
    "en": "Who here is most likely to make a tiny problem dramatic?",
    "ko": "작은 문제를 가장 드라마틱하게 만들 사람은?"
  },
  {
    "id": "party_vote_003",
    "deck": "party",
    "cardType": "vote",
    "modes": ["whos_most_likely"],
    "tone": "party",
    "en": "Who here would accidentally become the group leader?",
    "ko": "어쩌다 보니 리더가 될 것 같은 사람은?"
  },
  {
    "id": "funny_vote_002",
    "deck": "funny",
    "cardType": "vote",
    "modes": ["whos_most_likely"],
    "tone": "funny",
    "en": "Who here gives the strongest 'I have a story' face?",
    "ko": "지금 가장 '나 할 말 있어' 표정인 사람은?"
  },
  {
    "id": "party_vote_004",
    "deck": "party",
    "cardType": "vote",
    "modes": ["whos_most_likely"],
    "tone": "party",
    "en": "Who here would plan a trip and ignore the plan?",
    "ko": "여행 계획을 짜놓고 안 지킬 것 같은 사람은?"
  },
  {
    "id": "funny_vote_003",
    "deck": "funny",
    "cardType": "vote",
    "modes": ["whos_most_likely"],
    "tone": "funny",
    "en": "Who here would become obsessed with a random hobby overnight?",
    "ko": "갑자기 이상한 취미에 진심 될 사람은?"
  },
  {
    "id": "party_vote_005",
    "deck": "party",
    "cardType": "vote",
    "modes": ["whos_most_likely"],
    "tone": "party",
    "en": "Who here would give the best advice at 2 a.m.?",
    "ko": "새벽 2시에 제일 좋은 조언을 해줄 사람은?"
  },
  {
    "id": "funny_vote_004",
    "deck": "funny",
    "cardType": "vote",
    "modes": ["whos_most_likely"],
    "tone": "funny",
    "en": "Who here would name the group chat something weird?",
    "ko": "단톡방 이름을 제일 이상하게 지을 사람은?"
  },
  {
    "id": "party_vote_006",
    "deck": "party",
    "cardType": "vote",
    "modes": ["whos_most_likely"],
    "tone": "party",
    "en": "Who here has the most chaotic good energy?",
    "ko": "여기서 가장 선한데 정신없는 에너지를 가진 사람은?"
  }
]
```

### 13.5 Couple

```json
[
  {
    "id": "couple_answer_001",
    "deck": "couple",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "couple",
    "en": "What small thing I do makes you feel cared for?",
    "ko": "내가 하는 작은 행동 중 챙김받는 느낌이 드는 건?"
  },
  {
    "id": "couple_story_002",
    "deck": "couple",
    "cardType": "story",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "couple",
    "en": "What random moment with me do you still remember?",
    "ko": "아직도 기억나는 우리 둘의 사소한 순간은?"
  },
  {
    "id": "couple_answer_003",
    "deck": "couple",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "couple",
    "en": "What should we do more often together?",
    "ko": "우리가 같이 더 자주 했으면 하는 건?"
  },
  {
    "id": "couple_answer_004",
    "deck": "couple",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "couple",
    "en": "What was your honest first impression of me?",
    "ko": "솔직히 나의 첫인상은 어땠어?"
  },
  {
    "id": "couple_answer_005",
    "deck": "couple",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "couple",
    "en": "What kind of date feels most like us?",
    "ko": "어떤 데이트가 가장 우리답다고 느껴져?"
  },
  {
    "id": "couple_answer_006",
    "deck": "couple",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "couple",
    "en": "What tiny habit of mine do you secretly like?",
    "ko": "내 습관 중 은근히 마음에 드는 건?"
  },
  {
    "id": "couple_answer_007",
    "deck": "couple",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "couple",
    "en": "What is one thing we are surprisingly good at together?",
    "ko": "우리가 같이 하면 생각보다 잘하는 건?"
  },
  {
    "id": "couple_answer_008",
    "deck": "couple",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "couple",
    "en": "What should our next small adventure be?",
    "ko": "우리의 다음 작은 모험은 뭐가 좋을까?"
  },
  {
    "id": "couple_story_009",
    "deck": "couple",
    "cardType": "story",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "couple",
    "en": "What is a memory of us that feels like a movie scene?",
    "ko": "영화 장면처럼 느껴지는 우리 기억은?"
  },
  {
    "id": "couple_answer_010",
    "deck": "couple",
    "cardType": "answer",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "couple",
    "en": "What is one simple thing that makes you feel closer to me?",
    "ko": "나와 더 가까워진다고 느끼게 하는 작은 일은?"
  }
]
```

### 13.6 Deep

```json
[
  {
    "id": "deep_deep_light_001",
    "deck": "deep",
    "cardType": "deep_light",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "deep",
    "en": "When do you feel most like yourself?",
    "ko": "언제 가장 나답다고 느껴?"
  },
  {
    "id": "deep_deep_light_002",
    "deck": "deep",
    "cardType": "deep_light",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "deep",
    "en": "What kind of person makes you feel safe?",
    "ko": "어떤 사람과 있을 때 마음이 편해져?"
  },
  {
    "id": "deep_deep_light_003",
    "deck": "deep",
    "cardType": "deep_light",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "deep",
    "en": "What is something you care less about now?",
    "ko": "예전보다 덜 신경 쓰게 된 건 뭐야?"
  },
  {
    "id": "deep_deep_light_004",
    "deck": "deep",
    "cardType": "deep_light",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "deep",
    "en": "What belief have you changed your mind about?",
    "ko": "생각이 바뀐 믿음이나 가치관은?"
  },
  {
    "id": "deep_deep_light_005",
    "deck": "deep",
    "cardType": "deep_light",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "deep",
    "en": "What part of your life feels different from what people see?",
    "ko": "사람들이 보는 모습과 실제로 다른 부분은?"
  },
  {
    "id": "deep_deep_light_006",
    "deck": "deep",
    "cardType": "deep_light",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "deep",
    "en": "What is a worry you are slowly letting go of?",
    "ko": "조금씩 내려놓고 있는 걱정은 뭐야?"
  },
  {
    "id": "deep_deep_light_007",
    "deck": "deep",
    "cardType": "deep_light",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "deep",
    "en": "What makes you feel quietly proud of yourself?",
    "ko": "조용히 스스로가 뿌듯해지는 순간은?"
  },
  {
    "id": "deep_deep_light_008",
    "deck": "deep",
    "cardType": "deep_light",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "deep",
    "en": "What kind of compliment stays with you?",
    "ko": "오래 기억에 남는 칭찬은 어떤 칭찬이야?"
  },
  {
    "id": "deep_deep_light_009",
    "deck": "deep",
    "cardType": "deep_light",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "deep",
    "en": "What is something you want to protect about yourself?",
    "ko": "내 안에서 지키고 싶은 부분은 뭐야?"
  },
  {
    "id": "deep_deep_light_010",
    "deck": "deep",
    "cardType": "deep_light",
    "modes": ["classic_flip", "hot_seat"],
    "tone": "deep",
    "en": "What does a good day feel like to you lately?",
    "ko": "요즘 나에게 좋은 하루는 어떤 느낌이야?"
  }
]
```

## 14. Content Target

For v1 content production, use a 232-card baseline:

- 200 core cards across 5 decks.
- 32 Taboo Round cards as a separate high-replay add-on.

`This or That` and `Who's Most Likely` are game modes, so they should not be counted as decks.

Use this deck x core cardType matrix as the production target:

| Deck | answer | choice | vote | story | deep_light | Total |
|---|---:|---:|---:|---:|---:|---:|
| `warm_up` | 24 | 12 | 0 | 4 | 0 | 40 |
| `funny` | 18 | 10 | 8 | 4 | 0 | 40 |
| `deep` | 10 | 4 | 0 | 8 | 18 | 40 |
| `couple` | 18 | 6 | 0 | 12 | 4 | 40 |
| `party` | 8 | 10 | 18 | 4 | 0 | 40 |
| **Total** | **78** | **42** | **26** | **32** | **22** | **200** |

For the first full release, 200 strong core cards plus 32 focused Taboo Round cards are better than 240 weak general cards.

Taboo Round add-on target:

| Deck | taboo |
|---|---:|
| `funny` | 16 |
| `party` | 16 |
| **Total** | **32** |

If the app later needs more core cards, add an expansion buffer:

| Expansion Area | Added Cards |
|---|---:|
| More `funny_choice` | 8 |
| More `party_vote` | 12 |
| More `couple_story` | 8 |
| More `warm_up_answer` | 6 |
| More `deep_deep_light` | 6 |
| **Total Added** | **40** |

The expansion buffer intentionally makes deck sizes uneven:

```text
warm_up: 46
funny: 48
deep: 46
couple: 48
party: 52
```

This is acceptable because expansion should strengthen high-replay areas rather than preserve equal deck counts.

Total:

```text
200 core cards
232 v1 cards including Taboo Round
240 core cards with expansion buffer
272 cards including Taboo Round and expansion buffer
```

Resulting 200-card core ratio:

```text
answer: 39%
choice: 21%
vote: 13%
story: 16%
deep_light: 11%
```

The ratio is a result, not a rule.

The matrix is the actual production guide.

### 14.1 Why This Matrix Works

- `couple` avoids `vote` because 2-player sessions make voting awkward.
- `deep` avoids `vote` because voting can break the reflective tone.
- `party` has the highest `vote` count because group pointing is the core fun.
- `warm_up` focuses on `answer` and `choice` because first cards must be easy.
- `funny` mixes `answer`, `choice`, and `vote` because it supports both solo answers and group reactions.

### 14.2 Player Count Defaults by Card Type

If a card does not override player count, use these defaults:

| cardType | minPlayers | maxPlayers | Notes |
|---|---:|---:|---|
| `answer` | 1 | 8 | Works in most modes |
| `choice` | 1 | 8 | Better with 2+ |
| `vote` | 3 | 8 | Do not show under 3 players |
| `story` | 1 | 8 | Works in Classic Flip and Hot Seat |
| `deep_light` | 1 | 8 | Works with larger groups, but feels better in smaller groups |
| `taboo` | 3 | 8 | Requires listeners to catch slips |

Deck-level player count override:

| Deck | minPlayers | maxPlayers | Notes |
|---|---:|---:|---|
| `couple` | 2 | 2 | Pair mode only |

If a deck-level limit and card-level limit both exist, use the stricter rule.

Note on current data:

- With these defaults, `vote` and `taboo` cards require 3+ players, and the
  `couple` deck is exactly 2 players.
- All other card types span 1-8, so for the current v1 set the runtime pool
  equals the 14.4 upper-bound pool except for those player-count limits.
- If future cards add tighter `maxPlayers` values, revisit the 14.4 availability
  table, because more combinations could then shrink at runtime.

### 14.3 Mode Compatibility Defaults

| cardType | Default Modes |
|---|---|
| `answer` | `classic_flip`, `hot_seat` |
| `choice` | `this_or_that` |
| `vote` | `whos_most_likely` |
| `story` | `classic_flip`, `hot_seat` |
| `deep_light` | `classic_flip`, `hot_seat` |
| `taboo` | `taboo_round` |

MVP policy:

- Cards must use exactly the default modes for their `cardType`.
- Do not add mode overrides in the first release.
- If a future card needs to work across multiple mode families, either add a new `cardType` or update this table, the schema, and the validator together.

### 14.4 Mode x Deck Availability

Because the MVP uses strict `mode`, `deck`, and `cardType` filtering, not every mode works well with every deck.

The app should prevent empty or too-small combinations before the player starts a session.

Assuming the 200-card core matrix, the 32-card Taboo Round add-on, and default mode compatibility, the playable card pools **before** player-count filtering are:

| Mode / Deck | `warm_up` | `funny` | `deep` | `couple` | `party` |
|---|---:|---:|---:|---:|---:|
| `classic_flip` | 28 | 22 | 36 | 34 | 12 |
| `hot_seat` | 28 | 22 | 36 | 34 | 12 |
| `this_or_that` | 12 | 10 | 4 | 6 | 10 |
| `whos_most_likely` | 0 | 8 | 0 | 0 | 18 |
| `taboo_round` | 0 | 16 | 0 | 0 | 16 |

This table is a pre-player-count upper bound. The runtime pool is computed after
applying player-count and deck-level limits (see 14.2).

`taboo` cards are a separate pool added on top of the 200-card core matrix (funny 16, party 16),
not part of the five-type matrix counts. Like `whos_most_likely`, `taboo_round` is only
enabled for the decks that actually contain its card type — `funny` and `party`. All other
decks are disabled for Taboo Round. Taboo Round also requires 3+ players (see 3.5).

#### How to read an availability verdict

For any mode x deck combination, compute the runtime pool, then apply exactly one
threshold rule based on mode:

1. `hot_seat` -> use the Hot Seat thresholds in 14.6.
2. `this_or_that` -> use the This or That thresholds in 14.7.
3. `classic_flip`, `whos_most_likely`, and `taboo_round` -> use the general thresholds below.

General thresholds (Classic Flip, Who's Most Likely, Taboo Round):

- `0` cards: hidden / disabled.
- `1-5` cards: disabled.
- `6-7` cards: enabled, show a "Small deck" label.
- `8+` cards: enabled, normal session.

Mode-specific thresholds live in 14.6 (Hot Seat) and 14.7 (This or That), and they
override the general thresholds for those two modes. Quick Round is defined in 14.4.1
and is only ever invoked by 14.7.

Additional hard rules (apply regardless of pool size):

- Do not show `whos_most_likely` for `warm_up`, `deep`, or `couple` in MVP (0 cards anyway).
- Show the `couple` deck only when the active session has exactly 2 players (see 4.4).

Recommended MVP deck availability by mode:

| Mode | Enabled Decks | Disabled or Limited Decks |
|---|---|---|
| `classic_flip` | `warm_up`, `funny`, `deep`, `couple` (2P only), `party` | `party` (12) shows "Small deck" |
| `hot_seat` | `warm_up`, `funny`, `deep`, `couple` (2P only) | `party` (12) shows "Short round"; see 14.6 |
| `this_or_that` | `warm_up`, `funny`, `party` | `couple` (6, 2P only) is Quick Round; `deep` (4) disabled |
| `whos_most_likely` | `funny`, `party` | `warm_up`, `deep`, `couple` disabled |
| `taboo_round` | `funny`, `party` | `warm_up`, `deep`, `couple` disabled; requires 3+ players |

Recommended UI behavior:

```text
Step 1: User selects Game Mode.
Step 2: App computes the runtime pool for each deck (after player-count + deck limits).
Step 3: App applies the mode's threshold rule and shows only enabled decks.
Step 4: Disabled decks may appear dimmed with a short reason.
```

Example disabled-state / label copy:

English:

- Not enough cards for this mode
- Best with 3+ players
- Small deck
- Quick Round only

Korean:

- 이 모드에 맞는 카드가 부족해요
- 3명 이상 추천
- 카드가 적은 덱
- 짧은 라운드용

### 14.4.1 Quick Round

Quick Round is not a separate game mode.

It is a short-session option used when the selected mode x deck combination has a small but playable card pool, as decided by the This or That thresholds in 14.7.

Quick Round behavior:

- Session target: 5 cards.
- Quick Round is only offered when the runtime pool has `5-7` cards.
- If fewer than `5` cards are available, disable the combination instead.
- Repeats are still disabled within the Quick Round.
- At the end, show `Round complete` instead of `Deck complete`.
- Offer `Play another quick round` only if enough unused cards remain.

Canonical Quick Round example:

- `this_or_that` + `couple` (6 cards, 2-player only).

Do not use Quick Round for:

- `this_or_that` + `deep` (4 cards) -> disabled, not Quick Round.
- Any combination with `0-4` playable cards.

Suggested labels:

English:

- Quick Round
- 5-card round
- Round complete

Korean:

- 짧은 라운드
- 5장 라운드
- 라운드 완료

### 14.5 When to Expand Thin Combinations

MVP should start with disabled combinations rather than forcing every mode to work with every deck.

After QA, add more cards within the existing `cardType -> mode` mapping where the session feels too short.

For MVP, do not make individual cards cross-compatible by adding extra modes outside their `cardType` defaults.

Good candidates:

- Add more `party_answer` or `party_story` if Classic Flip + Party feels too thin.
- Add more `funny_vote` if Who's Most Likely + Funny feels too short.
- Add more `warm_up_choice` if This or That + Warm Up becomes a popular entry point.
- Add a few `deep_choice` cards if This or That + Deep is worth enabling later
  (it needs at least `5` cards to become a Quick Round, and `8` for a normal session).

Avoid:

- Adding `vote` to `couple` just to fill Who's Most Likely.
- Adding `vote` to `deep` if it breaks the reflective tone.
- Making every deck support every mode at the cost of product clarity.
- Adding extra modes to a card as a one-off workaround.

### 14.6 Hot Seat Draw Speed

Hot Seat draws 3 cards per turn and asks the player to answer 2.

This means the deck can dry out faster than Classic Flip.

Hot Seat thresholds (runtime pool, after filtering):

- `18+` cards: normal session.
- `12-17` cards: enabled, label as a short round.
- `0-11` cards: disable that deck for Hot Seat.

Other rules:

- Put unanswered third cards at the back of the session instead of discarding them permanently.

This keeps Hot Seat from reaching `Deck complete` too quickly.

Threshold priority:

- Hot Seat always uses the thresholds in this section.
- This or That always uses the thresholds in 14.7.
- Classic Flip, Who's Most Likely, and Taboo Round use the general thresholds in 14.4.
- Each combination receives exactly one verdict from exactly one of these sources.

### 14.7 This or That Draw Speed

This or That consumes 1 card per group round, so small pools end quickly.

This or That thresholds (runtime pool, after filtering):

- `8+` cards: normal session.
- `5-7` cards: Quick Round only (see 14.4.1).
- `0-4` cards: disabled.

Current data outcomes for This or That:

- `warm_up` (12): normal.
- `funny` (10): normal.
- `party` (10): normal.
- `couple` (6, 2P only): Quick Round.
- `deep` (4): disabled.

## 15. MVP Implementation Notes

Minimum app behavior:

- Load local JSON card data.
- Ask or infer player count before showing mode/deck combinations that require more players.
- After mode selection, compute each deck's runtime pool, then show only decks that pass that mode's threshold rule.
- Filter cards by selected mode, deck, card type, and player count.
- Apply deck-level player count limits such as `couple` being 2-player only, and hide `couple` unless the session has exactly 2 players.
- Treat the 14.4 mode x deck table as a pre-player-count upper bound, not the final runtime count.
- Apply exactly one threshold source per mode: Hot Seat -> 14.6, This or That -> 14.7, Classic Flip / Who's Most Likely / Taboo Round -> 14.4 general thresholds.
- Disable empty combinations and label small combinations before session start.
- Shuffle cards at session start.
- Prevent repeats within one session.
- Move passed cards to the end.
- Support EN, KR, and KOR + ENG display.
- In KOR + ENG mode, keep the card readable without scroll by using primary/secondary language hierarchy.
- Support favorite cards locally.
- Support share text.
- Show deck complete state.
- Log lightweight per-card stats locally (see 15.1) so weak cards can be found by data, not guesswork.

### 15.1 Per-Card Stats Logging

Content quality cannot be fully judged before launch. The validator and content review catch broken or duplicate cards, but they cannot tell which cards people actually enjoy. The only honest answer to "does this card make people want to play again?" is real usage. To get that, the app should log a few lightweight counters per card, locally, from the first release.

Track per card (`cardId`):

- `shown`: how many times the card was drawn and displayed.
- `passed`: how many times players hit Pass on it.
- `favorited`: how many times it was saved as a favorite.

Derived signals:

- Pass rate = `passed / shown`. A persistently high pass rate flags a card that lands flat or feels awkward.
- Favorite rate = `favorited / shown`. A high rate flags a hook card worth keeping or imitating.

Keep it private and simple:

- Store counters locally on device. No login or server sync is required for MVP.
- Counters are anonymous aggregate counts, not a record of individual answers. Do not log what players actually said.
- Optionally let the player reset or clear local stats.

How this feeds content updates:

- After launch, review cards with the highest pass rates first — these are the candidates to rewrite or replace, the same way deck-level weak spots were handled during content review.
- Cross-check low replay decks against their cards' stats before deciding the deck itself is weak; often a few flat cards drag a deck down.
- Treat the current 232-card set as the v1 baseline. Stats turn the next content revision from opinion into evidence.

This is intentionally minimal. Richer analytics (per-mode engagement, session length, sharing funnels) are post-MVP and are not required for the first release.

First release can exclude:

- Login
- Server sync
- Multiplayer networking
- User-generated public cards
- Push notifications
- Android
- Premium deck marketplace
