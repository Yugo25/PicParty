# PicParty

**Time-limited, themed photo & video sharing.**

Create a *Party* around a theme, set a countdown, and let everyone post photos and videos until time runs out. When the timer ends, the Party closes to new uploads.

Built with **Flutter** (iOS / Android / Web) and **Supabase**.

---

## Features

- **Parties** — themed events with a title, category, countdown style, privacy level (Public / Unlisted / Private) and duration
- **Live countdown** — Parties go from LIVE to ENDED; uploads stop at the end time
- **Feed & Explore** — browse active Parties, search and filter
- **Posts** — upload photos and videos, like and comment
- **Social** — profiles, follows, inbox (activity + messages)
- **Sharing** — share links and QR codes for Parties
- **Languages** — English and Simplified Chinese
- **Demo Mode** — runs without a backend, with local sample data

## Tech Stack

| Layer | Tools |
|---|---|
| App | Flutter (Dart ≥ 3.3), go_router |
| Backend | Supabase (Auth, Postgres, Storage, Edge Functions) |
| Notifications | Firebase Cloud Messaging |
| Localization | Flutter gen-l10n (`lib/l10n/`) |

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- A [Supabase](https://supabase.com) project *(optional — without it the app runs in Demo Mode)*

### 1. Install dependencies

```bash
flutter pub get
flutter gen-l10n
```

### 2. Configure Supabase *(optional)*

Copy the example file and fill in your project's URL and anon key:

```bash
cp .env.example .env
```

```env
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

> `.env` is git-ignored. Never commit real keys.

### 3. Run

```bash
# With Supabase
flutter run --dart-define-from-file=.env

# Demo Mode (no backend, data stays on the device)
flutter run
```

---

## Backend Setup

Run these SQL migrations in the Supabase SQL Editor, **in this order**:

1. `supabase/migrations/000_core.sql`
2. `supabase/migrations/114_new_ui.sql`
3. `supabase/migrations/115_signup.sql`

> `109`–`113` are notes only and do not need to be run.

Edge Functions live in `supabase/functions/` (`process-media`, `send-push`, `translate-content`). They are placeholders for now.

See [docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md) for the full step-by-step guide.

---

## Project Structure

```
lib/
├── config/         # App & Supabase configuration
├── core/           # Shared utilities (time, validation, errors)
├── l10n/           # Translation files (.arb)
├── models/         # Data models
├── repositories/   # Supabase data access
├── routing/        # App routes (go_router)
├── screens/        # UI screens
├── services/       # Controllers, demo/mock data, push, preferences
├── theme/          # Colors, tokens, theme
└── widgets/        # Reusable UI components
supabase/
├── migrations/     # Database schema (SQL)
└── functions/      # Edge Functions
docs/               # Setup, deploy and release guides
test/               # Unit & widget tests
```

---

## Testing

```bash
flutter test
```

A manual beta checklist is in [docs/TESTING.md](docs/TESTING.md).

---

## Documentation

| Guide | Description |
|---|---|
| [SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md) | Set up the Supabase backend |
| [WEB_DEPLOY.md](docs/WEB_DEPLOY.md) | Build and publish the web version (use it on iPhone) |
| [APP_STORE_RELEASE.md](docs/APP_STORE_RELEASE.md) | Release to the App Store |
| [TESTING.md](docs/TESTING.md) | Beta test checklist |
