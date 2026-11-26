
# GoalPath Mobile Implementation Plan

> **For agentic workers:** This plan is being executed inline in this session.

**Goal:** Build the first usable Android-first GoalPath Flutter client in mobile/.

**Architecture:** Flutter owns the mobile UI and calls the existing Express REST API. Auth uses bearer tokens stored with secure storage; the website remains unchanged.

**Tech Stack:** Flutter, Dart, http, flutter_secure_storage.

**Spec:** docs/goalpath-mobile-design.md

## Global Constraints

- Android APK is the initial distribution target.
- API root is configurable using API_BASE_URL.
- Private API calls use a Supabase access token in the Bearer header.
- Reuse the existing GoalPath logo and visual tokens.
- Do not put signing keys or production secrets in the repository.

## Review Focus

- Missing/expired access token: restore using refresh token or return to login.
- Unavailable API: show a recoverable error state.
- New or empty account: show a helpful empty state without fabricated metrics.
- Small screens and large text: keep content scrollable and controls reachable.
- Trial not eligible or API rejects trial: show subscription status and response clearly.

---

### Task 1: Bootstrap the Flutter Android project

**Files:**
- Create/update: pubspec.yaml, lib/, android/, .gitignore, and Flutter project metadata under mobile/.
- Copy: ../frontend/public/goalpath-logo.webp into assets/.

**Deliverable:** Flutter project with app identity, API base configuration, and the existing logo.

### Task 2: API and auth

**Files:**
- Create: lib/data/api_client.dart, lib/features/auth/login_screen.dart.

**Deliverable:** Login/register, secure token persistence, bearer requests, refresh, logout, and human-readable API errors.

### Task 3: Mobile shell and theme

**Files:**
- Create: lib/app.dart, lib/theme/app_theme.dart, lib/navigation/app_shell.dart.

**Deliverable:** Light/dark themes and phone navigation for Today, Goals, Progress, Coach, and Profile, with Pricing reachable from the menu.

### Task 4: Core user screens

**Files:**
- Create: lib/features/today/today_screen.dart, lib/features/goals/goals_screen.dart, lib/features/progress/progress_screen.dart.

**Deliverable:** Load real API data, complete a habit, show goal progress, and include loading/error/empty states.

### Task 5: Coach and subscription screens

**Files:**
- Create: lib/features/coach/coach_screen.dart, lib/features/profile/profile_screen.dart, lib/features/pricing/pricing_screen.dart.

**Deliverable:** Basic Coach session and messaging, profile/subscription status, and eligible Premium trial action.

### Task 6: Developer handoff

**Files:**
- Update: README.md.

**Deliverable:** Local setup, API URL configuration for emulator/device, and future release APK instructions.
