# Supabase setup

## Migrations

Run `supabase/migrations/001_visits_analytics.sql` in [Supabase SQL Editor](https://supabase.com/dashboard/project/_/sql) or via `supabase db push` if using Supabase CLI.

## iOS analytics

To enable visit tracking on iOS:

1. Copy `IslamicDayDial/Config.xcconfig.example` to `IslamicDayDial/Config.xcconfig`
2. Fill in your Supabase URL and anon key
3. `Config.xcconfig` is gitignored — your keys won't be committed

(Same values as `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` for web.)

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
