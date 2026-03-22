# Supabase setup

## Migrations

Run `supabase/migrations/001_visits_analytics.sql` in [Supabase SQL Editor](https://supabase.com/dashboard/project/_/sql) or via `supabase db push` if using Supabase CLI.

## iOS analytics

To enable visit tracking on iOS:

1. Copy `IslamicDayDial/Config.xcconfig.example` to `IslamicDayDial/Config.xcconfig`
2. Fill in your Supabase URL and anon key
3. `Config.xcconfig` is gitignored — your keys won't be committed

(Same values as `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` for web.)
