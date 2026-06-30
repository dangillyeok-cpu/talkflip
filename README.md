# TalkFlip Content Data

This folder contains the MVP content guide and data contract for TalkFlip.

## Files

- `TalkFlip_MVP_Card_Guide.md`: product and content rules
- `decks.json`: deck metadata and deck-level player limits
- `cards.schema.json`: JSON Schema for card file shape
- `cards.json`: production v1 card data
- `validate_cards.mjs`: product-rule validator

## Validation

JSON Schema and `validate_cards.mjs` have different jobs.

- JSON Schema checks shape: required fields, enums, ID pattern, primitive ranges.
- `validate_cards.mjs` checks product rules: duplicate IDs, ID/field consistency, `cardType` to `modes`, player-count resolution, `couple` deck limits, the 200-card core matrix, and the 32-card Taboo Round add-on.

Passing `cards.schema.json` alone does not mean the content is product-valid.

Validate the production card file:

```bash
node validate_cards.mjs
```

If schema validation is added to CI with AJV, use the draft 2020-12 build.

Example:

```js
import Ajv2020 from "ajv/dist/2020.js";
```

## MVP Mode Policy

For MVP, a card's `modes` must exactly match its `cardType` default modes.

Do not add one-off mode overrides to individual cards. If a future release needs cross-compatible cards, update the guide, schema, and validator together.
