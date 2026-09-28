-- Balance ("this or that") card tallies. a = left/top option, b = right/bottom option.
CREATE TABLE IF NOT EXISTS choice_stats (
  card_id    TEXT PRIMARY KEY,
  a          INTEGER NOT NULL DEFAULT 0,
  b          INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL
);

-- One submission per (card, device, day). voter = sha256(ip + salt + day); rows older than 2 days are pruned.
CREATE TABLE IF NOT EXISTS choice_seen (
  card_id TEXT NOT NULL,
  voter   TEXT NOT NULL,
  day     TEXT NOT NULL,
  PRIMARY KEY (card_id, voter, day)
);
CREATE INDEX IF NOT EXISTS choice_seen_day ON choice_seen(day);
