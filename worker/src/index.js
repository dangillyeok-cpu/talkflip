/* TalkFlip stats API (Cloudflare Worker + D1)
 *
 *   POST /api/vote   { card: "party_choice_001", a: 3, b: 1 }   → { card, a, b, n, pa, pb, counted }
 *   GET  /api/stats?cards=id1,id2,...                           → { id1: {a,b,n,pa,pb}, ... }
 *
 * a/b are how many people picked each side on one phone (group round), or 1/0 for a solo pick.
 * One submission per card per device per day (ip hash), so a group of four counts once.
 */

const CARD_ID = /^[a-z_]+_choice_(\d{3}|x\d{2})$/;
const MAX_PER_SIDE = 8;          // max players on one phone
const MAX_CARDS_PER_GET = 40;

export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    const path = url.pathname.replace(/^\/api/, "");
    const cors = corsHeaders(req, env);
    if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });

    try {
      if (req.method === "GET" && path === "/stats") return json(await getStats(url, env), 200, cors);
      if (req.method === "POST" && path === "/vote") return json(await postVote(req, env), 200, cors);
      if (req.method === "GET" && path === "/health") return json({ ok: true }, 200, cors);
      return json({ error: "not found" }, 404, cors);
    } catch (e) {
      if (e instanceof HttpError) return json({ error: e.message }, e.status, cors);
      console.error(e);
      return json({ error: "server error" }, 500, cors);
    }
  },
};

class HttpError extends Error { constructor(status, msg) { super(msg); this.status = status; } }

function corsHeaders(req, env) {
  const origin = req.headers.get("Origin") || "";
  const allowed = (env.ALLOWED_ORIGINS || "").split(",").map((s) => s.trim()).filter(Boolean);
  const h = {
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Max-Age": "86400",
    "Cache-Control": "no-store",
    "Vary": "Origin",
  };
  if (allowed.includes(origin)) h["Access-Control-Allow-Origin"] = origin;
  return h;
}

function json(body, status, headers) {
  return new Response(JSON.stringify(body), { status, headers: { ...headers, "Content-Type": "application/json; charset=utf-8" } });
}

function shape(row) {
  const a = row?.a ?? 0, b = row?.b ?? 0, n = a + b;
  const pa = n ? Math.round((a / n) * 100) : 0;
  return { a, b, n, pa, pb: n ? 100 - pa : 0 };
}

async function getStats(url, env) {
  const ids = (url.searchParams.get("cards") || "").split(",").map((s) => s.trim()).filter((s) => CARD_ID.test(s));
  if (!ids.length) throw new HttpError(400, "cards required");
  if (ids.length > MAX_CARDS_PER_GET) throw new HttpError(400, `max ${MAX_CARDS_PER_GET} cards`);
  const placeholders = ids.map(() => "?").join(",");
  const { results } = await env.DB.prepare(`SELECT card_id, a, b FROM choice_stats WHERE card_id IN (${placeholders})`).bind(...ids).all();
  const out = {};
  for (const id of ids) out[id] = shape(null);
  for (const r of results) out[r.card_id] = shape(r);
  return out;
}

async function postVote(req, env) {
  let body;
  try { body = await req.json(); } catch { throw new HttpError(400, "json body required"); }
  const card = String(body.card || "");
  const a = toCount(body.a), b = toCount(body.b);
  if (!CARD_ID.test(card)) throw new HttpError(400, "bad card id");
  if (a + b === 0) throw new HttpError(400, "nothing to count");

  const now = Date.now();
  const day = new Date(now).toISOString().slice(0, 10);
  let counted = true;

  if (env.DEDUP !== "0") {
    const voter = await sha256((req.headers.get("CF-Connecting-IP") || "0.0.0.0") + "|" + (env.SALT || "talkflip") + "|" + day);
    // INSERT OR IGNORE tells us atomically whether this device already submitted this card today
    const ins = await env.DB.prepare("INSERT OR IGNORE INTO choice_seen (card_id, voter, day) VALUES (?, ?, ?)").bind(card, voter, day).run();
    counted = (ins.meta?.changes ?? 0) > 0;
    // prune old dedup rows now and then (about 1 in 50 requests)
    if (Math.random() < 0.02) {
      const cutoff = new Date(now - 2 * 86400000).toISOString().slice(0, 10);
      await env.DB.prepare("DELETE FROM choice_seen WHERE day < ?").bind(cutoff).run();
    }
  }

  let row;
  if (counted) {
    row = await env.DB.prepare(
      `INSERT INTO choice_stats (card_id, a, b, updated_at) VALUES (?, ?, ?, ?)
       ON CONFLICT(card_id) DO UPDATE SET a = a + excluded.a, b = b + excluded.b, updated_at = excluded.updated_at
       RETURNING a, b`
    ).bind(card, a, b, now).first();
  } else {
    row = await env.DB.prepare("SELECT a, b FROM choice_stats WHERE card_id = ?").bind(card).first();
  }
  return { card, ...shape(row), counted };
}

function toCount(v) {
  const n = Number(v ?? 0);
  if (!Number.isInteger(n) || n < 0 || n > MAX_PER_SIDE) throw new HttpError(400, "a/b must be integers 0..8");
  return n;
}

async function sha256(s) {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
  return [...new Uint8Array(buf)].map((x) => x.toString(16).padStart(2, "0")).join("");
}
