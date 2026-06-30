import fs from "node:fs";
import path from "node:path";

// JSON Schema validates shape: enums, required fields, ID pattern, and primitive ranges.
// This script validates cross-field product rules: duplicate IDs, ID/field consistency,
// cardType/mode compatibility, player-count resolution, couple deck limits, and content counts.
// Passing cards.schema.json alone does not mean the content is product-valid.

const cardsPath = process.argv[2] ?? "cards.json";
const decksPath = process.argv[3] ?? "decks.json";

const deckIds = new Set(["warm_up", "funny", "deep", "couple", "party"]);
const cardTypes = new Set(["answer", "choice", "vote", "story", "deep_light", "taboo"]);
const modes = new Set(["classic_flip", "this_or_that", "whos_most_likely", "hot_seat", "taboo_round"]);

const defaultModesByType = {
  answer: ["classic_flip", "hot_seat"],
  choice: ["this_or_that"],
  vote: ["whos_most_likely"],
  story: ["classic_flip", "hot_seat"],
  deep_light: ["classic_flip", "hot_seat"],
  taboo: ["taboo_round"],
};

const defaultPlayersByType = {
  answer: { minPlayers: 1, maxPlayers: 8 },
  choice: { minPlayers: 1, maxPlayers: 8 },
  vote: { minPlayers: 3, maxPlayers: 8 },
  story: { minPlayers: 1, maxPlayers: 8 },
  deep_light: { minPlayers: 1, maxPlayers: 8 },
  taboo: { minPlayers: 3, maxPlayers: 8 },
};

// taboo lives only in funny and party (group-explain decks). Not a 5-type matrix entry.
const tabooDecks = new Set(["funny", "party"]);
const targetTabooCounts = { funny: 16, party: 16 };

const targetMatrix = {
  warm_up: { answer: 24, choice: 12, vote: 0, story: 4, deep_light: 0 },
  funny: { answer: 18, choice: 10, vote: 8, story: 4, deep_light: 0 },
  deep: { answer: 10, choice: 4, vote: 0, story: 8, deep_light: 18 },
  couple: { answer: 18, choice: 6, vote: 0, story: 12, deep_light: 4 },
  party: { answer: 8, choice: 10, vote: 18, story: 4, deep_light: 0 },
};

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function fail(message) {
  errors.push(message);
}

function isEqualArray(a, b) {
  return a.length === b.length && a.every((value, index) => value === b[index]);
}

function getDeckLimits(decks) {
  const limits = new Map();
  for (const deck of decks.decks ?? []) {
    if (deck.minPlayers !== undefined || deck.maxPlayers !== undefined) {
      limits.set(deck.id, {
        minPlayers: deck.minPlayers ?? 1,
        maxPlayers: deck.maxPlayers ?? 8,
      });
    }
  }
  return limits;
}

function resolvePlayerLimits(card, deckLimits) {
  const typeDefault = defaultPlayersByType[card.cardType];
  const deckLimit = deckLimits.get(card.deck);
  const minPlayers = Math.max(
    card.minPlayers ?? typeDefault.minPlayers,
    deckLimit?.minPlayers ?? 1,
  );
  const maxPlayers = Math.min(
    card.maxPlayers ?? typeDefault.maxPlayers,
    deckLimit?.maxPlayers ?? 8,
  );
  return { minPlayers, maxPlayers };
}

const errors = [];
const cardsFile = readJson(cardsPath);
const decksFile = readJson(decksPath);
const deckLimits = getDeckLimits(decksFile);
const ids = new Set();
const matrix = {};

for (const deck of deckIds) {
  matrix[deck] = {};
  for (const type of cardTypes) {
    matrix[deck][type] = 0;
  }
}

for (const [index, card] of (cardsFile.cards ?? []).entries()) {
  const label = card.id ?? `card[${index}]`;

  if (!card.id) fail(`${label}: missing id`);
  if (ids.has(card.id)) fail(`${label}: duplicate id`);
  ids.add(card.id);

  if (!deckIds.has(card.deck)) fail(`${label}: invalid deck ${card.deck}`);
  if (!cardTypes.has(card.cardType)) fail(`${label}: invalid cardType ${card.cardType}`);
  if (!Array.isArray(card.modes) || card.modes.length === 0) {
    fail(`${label}: modes must be a non-empty array`);
  } else {
    for (const mode of card.modes) {
      if (!modes.has(mode)) fail(`${label}: invalid mode ${mode}`);
    }
  }

  const expectedIdPrefix = `${card.deck}_${card.cardType}_`;
  if (card.id && !card.id.startsWith(expectedIdPrefix)) {
    fail(`${label}: id must start with ${expectedIdPrefix}`);
  }

  const expectedModes = defaultModesByType[card.cardType] ?? [];
  if (Array.isArray(card.modes) && !isEqualArray([...card.modes].sort(), [...expectedModes].sort())) {
    fail(`${label}: modes ${JSON.stringify(card.modes)} should be ${JSON.stringify(expectedModes)}`);
  }

  const limits = resolvePlayerLimits(card, deckLimits);
  if (limits.minPlayers > limits.maxPlayers) {
    fail(`${label}: minPlayers exceeds maxPlayers after defaults and deck limits`);
  }

  if (card.deck === "couple" && (limits.minPlayers !== 2 || limits.maxPlayers !== 2)) {
    fail(`${label}: couple cards must resolve to exactly 2 players`);
  }

  if (card.en?.trim().length === 0) fail(`${label}: empty en text`);
  if (card.ko?.trim().length === 0) fail(`${label}: empty ko text`);

  // ---- taboo-specific product rules ----
  if (card.cardType === "taboo") {
    if (!tabooDecks.has(card.deck)) {
      fail(`${label}: taboo cards are only allowed in funny or party decks`);
    }
    for (const key of ["bannedKo", "bannedEn"]) {
      const arr = card[key];
      if (!Array.isArray(arr) || arr.length < 3 || arr.length > 5) {
        fail(`${label}: ${key} must have 3-5 words`);
      } else if (new Set(arr.map((w) => w.toLowerCase())).size !== arr.length) {
        fail(`${label}: ${key} has duplicate words`);
      }
    }
    if (Array.isArray(card.bannedKo) && Array.isArray(card.bannedEn) &&
        card.bannedKo.length !== card.bannedEn.length) {
      fail(`${label}: bannedKo and bannedEn must have the same count`);
    }
  } else if (card.bannedKo !== undefined || card.bannedEn !== undefined) {
    fail(`${label}: only taboo cards may have banned word lists`);
  }

  if (deckIds.has(card.deck) && cardTypes.has(card.cardType)) {
    matrix[card.deck][card.cardType] += 1;
  }
}

console.log(`Validated ${cardsFile.cards?.length ?? 0} cards from ${path.basename(cardsPath)}.`);
console.log("\nCurrent deck x cardType counts:");
console.table(matrix);

console.log("Target gaps for 200-card core matrix:");
for (const deck of deckIds) {
  const gaps = {};
  for (const type of cardTypes) {
    const target = targetMatrix[deck][type];
    const current = matrix[deck][type];
    if (target > 0) gaps[type] = target - current;
  }
  console.log(deck, gaps);
}

console.log("Target gaps for 32-card Taboo Round add-on:");
for (const deck of tabooDecks) {
  const target = targetTabooCounts[deck];
  const current = matrix[deck].taboo;
  console.log(deck, { taboo: target - current });
  if (current !== target) {
    fail(`${deck}: taboo count ${current} should be ${target}`);
  }
}

if (errors.length > 0) {
  console.error("\nValidation failed:");
  for (const error of errors) console.error(`- ${error}`);
  process.exit(1);
}

console.log("\nValidation passed.");
