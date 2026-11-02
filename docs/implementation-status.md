# Implementation and verification status

Updated: 1 November 2026.

## Confirmed scope

The user selected the core end-to-end project, local Docker Compose, email/password login, Chrome only, and opt-in domain/category tracking. Page contents, keystrokes, full URLs and incognito tracking are excluded.

## Implemented source

The `steady` directory contains the real Express backend, PostgreSQL schema, MongoDB event storage, API-connected dashboard, Chrome extension, Compose deployment, tests and documentation. It does not use the earlier localStorage demo as its data source.

Tasks, subtasks, plans, focus sessions, resume notes, check-ins, device consent and reports have implementation code. This statement describes source coverage; it does not certify successful runtime acceptance.

## Verification evidence

| Check | Status |
|---|---|
| Unit tests: interval merging/clipping, empty intervals, daylight-saving days, invalid dates, report boundaries, password salts and token digests | 7 passed |
| JavaScript parser checks | Passed for authored JavaScript |
| Dependency installation and lockfile | Completed |
| PostgreSQL migration on a clean real server | Pending |
| API integration test against PostgreSQL and MongoDB | Written; not run successfully yet |
| Chrome extension permissions, foreground behavior, idle detection, incognito exclusion and retries | Requires manual Chrome acceptance |
| Authenticated dashboard interaction and visual review | Requires running backend |
| Persistence after container restart and outbox failure/recovery | Pending |

The current machine has no usable Docker engine. On the latest check, `docker` was unavailable through PATH and the application resource executable was missing. The existing `/usr/local/bin/docker` entry does not provide a working installation. This blocks real-service verification; unit tests are not a substitute.

## Acceptance checklist once Docker works

- Run the README startup commands and verify all services are healthy.
- Run `docker compose exec app npm run test:integration` and inspect failures.
- Complete the demonstration in `guide.md` using the dashboard.
- In Chrome, verify no uploads before consent, then normal-page domain capture after consent.
- Verify paused, excluded, incognito and browser-unfocused periods do not create active-domain records.
- Disable the backend temporarily, then reconnect; verify unknown gaps, bounded queue and duplicate-safe retry.
- Pause while offline; reconnect and verify pending revocation is sent before any collection resumes.
- Revoke and delete records while the extension has queued events; verify stale consent epochs are rejected.
- Restart containers without removing volumes; verify tasks, plans and check-ins persist.
- Stop MongoDB temporarily and create/update a task; verify SQL events/outbox persist and the mirror catches up after restart.
- Inspect the browser console and extension service worker for errors.

## Scope departures from earlier proposals

The larger research design's baseline detection, clinical correlations, weekly/30-day trends, sleep quality, initiation-difficulty ratings and automatic interruption attribution are not included in this approved core release. Task initiation timestamps and history exist, but a dedicated initiation-delay analytics screen is not implemented. Category labels are stored; the current dashboard reports per-domain totals rather than category productivity scores.

Earlier research documents remain proposals and must not be cited as empirical validation of this build. No Turnitin verification has been performed.
