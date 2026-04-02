# Supabase setup

## Migrations

Run `supabase/migrations/001_visits_analytics.sql` in [Supabase SQL Editor](https://supabase.com/dashboard/project/_/sql) or via `supabase db push` if using Supabase CLI.

## Web analytics

Supabase is currently used for the public web dashboard only.

Set these environment variables for the web build:

1. `VITE_SUPABASE_URL`
2. `VITE_SUPABASE_ANON_KEY`

## Surface semantics

Visits now support a nullable `surface` field in addition to `platform`.

Recommended `surface` values:

- `ios_app`
- `ios_widget`
- `watch_app`
- `watch_complication`

Current app behavior:

- the iPhone app tracks `surface = ios_app`
- the watch app tracks `surface = watch_app`
- widget / complication refreshes are intentionally not tracked yet, to avoid noisy and battery-unfriendly analytics
