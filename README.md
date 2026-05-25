# Streamer Likability

Phoenix app that asks voters to compare two Twitch streamers and updates **Glicko-2** ratings from each choice. A live **Ratings** page shows the leaderboard and rating history over time.

## Setup

```bash
mix setup
```

Requires PostgreSQL (`postgres` / `postgres` on `localhost` by default — see `config/dev.exs`).

## Run

```bash
mix phx.server
```

- **Compare:** http://localhost:4000
- **Ratings:** http://localhost:4000/ratings

## Twitch sync (optional)

Copy `.env.example` to `.env` and fill in your Twitch app credentials (loaded automatically in dev):

```bash
cp .env.example .env
```

Then run:

```bash
mix run -e "ComparisonApp.Streamers.SyncWorker.new(%{}) |> Oban.insert!()"
```

Oban also runs a cron sync every 6 hours when credentials are present.

## Ratings periods

On `/ratings`, filter the top-100 leaderboard and history charts by: All time, Last year, Last 6 months, Last month, Last 7 days, Last 24 hours. Timestamps are shown in UTC.

## Unknown streamer cooldown

If you vote that you don't know a streamer, that streamer is hidden from your comparisons for 24 hours (tracked by hashed IP, not stored in plain text). Set `IP_HASH_SALT` in production.

## How voting maps to Glicko-2

| Choice | Effect |
|--------|--------|
| More likable (left/right) | Both streamers updated; winner score 1.0 / 0.0 |
| Don't know left | Only right streamer updated (score 0.0 for canonical A) |
| Don't know right | Only left streamer updated |
| Don't know both | Comparison logged; no rating change |

## Stack

- Phoenix LiveView + PostgreSQL + Ecto
- [`glicko_rating_system`](https://hex.pm/packages/glicko_rating_system) for ratings
- Oban for Twitch Helix sync (via Req)
- PubSub for live rating updates on `/ratings`
