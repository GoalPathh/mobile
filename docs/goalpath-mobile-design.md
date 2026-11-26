# GoalPath Mobile Design

## Goal

Build an Android-first Flutter client in mobile/ that uses the existing GoalPath REST API and feels like the current product, with layouts designed specifically for a phone.

## Approach

Create a new Flutter client. Reuse the website's logo, lavender and violet palette, product language, API routes, and feature order. Keep the Next.js website unchanged. Flutter screens are native mobile layouts, not embedded website pages.

The initial app includes login/register and Today, Goals, Progress, Coach, Profile, and Pricing/trial entry points. Today leads with daily progress and habits. Profile displays subscription status and trial eligibility. Premium pricing stays reachable from the app menu.

## Data and session handling

- Use POST /auth/login and POST /auth/register; read the Supabase session from the { data } response.
- Store access and refresh tokens with platform secure storage.
- Send the access token as Authorization: Bearer <token> to private API routes; refresh through POST /auth/refresh.
- Read the API origin from API_BASE_URL; Android emulator development defaults to http://10.0.2.2:4000/api/v1.
- Use existing /today, /goals/dashboard, /progress/overview, /coach/*, /me, and /subscription/* routes.

## Visual direction

Reading this as: mobile habit and goal tracker for existing GoalPath users, using the site's lavender and deep-violet identity, ENERGY 2 / RHYTHM 2 / MOTION 1.

Use the existing light and dark color tokens, compact but readable cards, a persistent bottom navigation bar, and one clear primary action per screen. Include loading, empty, error, and form validation states. Keep touch targets comfortable and support text scaling.

## Out of scope

The first implementation does not publish an APK, create GitHub Actions release automation, or change the Next.js site's mobile layout.
