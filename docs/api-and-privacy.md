# API and privacy contract

Base URL: `http://localhost:3000/api`. JSON requests and responses. Authentication routes return the user and CSRF token and set an HttpOnly, SameSite=Strict session cookie. Dashboard mutations require `X-CSRF-Token`. Extension routes use `Authorization: Bearer <pairing token>` and do not use dashboard cookies.

## Routes

| Method and path | Input / purpose |
|---|---|
| GET `/health` | PostgreSQL and MongoDB connectivity |
| POST `/auth/register` | email, password (10–128 characters), displayName, timezone |
| POST `/auth/login` | email, password |
| POST `/auth/logout` | Revoke current login session |
| GET `/me` | User, preferences and current CSRF token |
| PATCH `/preferences` | quiet_mode, reduced_motion booleans |
| GET/POST `/projects` | List / create with name |
| GET/POST `/tasks` | List / create with title and optional project_id, parent_task_id, estimated_minutes, due_at |
| PATCH `/tasks/:id` | Required current version; optional title, estimated_minutes, status |
| GET `/tasks/:id/history` | Chronological task event records |
| POST `/tasks/:id/checkpoints` | note, maximum 2,000 characters |
| GET `/plans?date=YYYY-MM-DD` | Revisions for a local date |
| POST `/plans` | date, taskIds array; creates and freezes a new revision |
| GET `/focus` | Latest 30 sessions with calculated elapsed_seconds |
| POST `/focus/start` | taskId, minutes (1–480), requestKey UUID |
| POST `/focus/:id/pause` | Close current work segment |
| POST `/focus/:id/resume` | Open new work segment |
| POST `/focus/:id/finish` | Close segment and finish session |
| GET/POST `/checkins` | List / create optional focus, stress, energy (1–5); at least one required; optional note |
| DELETE `/checkins/:id` | Delete one owned check-in |
| GET/POST `/devices` | List / create with label; creation returns a token once |
| POST `/devices/:id/revoke` | Revoke token and consent |
| GET `/extension/status` | Current device consent and epoch |
| POST `/extension/consent` | enabled boolean; advances consent epoch |
| POST `/extension/events` | epoch and events array, at most 200 |
| DELETE `/activity` | Disable tracking on all devices and delete browser records |
| GET `/reports/daily?date=YYYY-MM-DD` | Combined SQL/MongoDB daily report |
| GET `/export` | Owned records; excludes password/session/token secrets |

Errors return `{ "error": "message" }`: 400 invalid input, 401 unauthenticated, 403 denied request/origin, 404 missing record, 409 conflicting version/session/consent, 422 report limit, 429 rate limit or 500 unexpected failure. Invalid semantic dates may currently return a generic error rather than a field-specific validation message.

## Observation example

Illustrative payload only; use current timestamps when testing:

```json
{
  "epoch": 1,
  "events": [{
    "eventId": "e570ab13-302f-4919-b6fd-a63e1539c610",
    "type": "interval",
    "at": "2026-11-01T08:00:30.000Z",
    "start": "2026-11-01T08:00:00.000Z",
    "end": "2026-11-01T08:00:30.000Z",
    "state": "active",
    "domain": "example.org",
    "category": "study"
  }]
}
```

For idle intervals, domain must be null. Allowed categories: study, necessary, leisure, uncategorized. A tab_switch contains only eventId, type and at. Successful uploads acknowledge accepted IDs. Retry the same validated events with unchanged IDs; discard queued events if consent changes.

## Collection boundaries

The extension requests optional tabs/idle permissions only when Enable is selected. It reads the active tab URL transiently to extract its hostname; full URLs are not queued or sent. It does not read page text, titles, forms, keystrokes, browser history or incognito tabs. There are no content scripts. Localhost and 127.0.0.1 are excluded, as are user-selected domain exclusions and their subdomains.

The worker samples on a 30-second alarm and relevant tab/window/idle changes. It accepts normal focused windows and HTTP/HTTPS pages. Intervals longer than 60 seconds are dropped. Durations are approximations between observations, not continuous tracking. A switch count only compares two eligible active observations with different tab IDs; same-tab navigation is not a tab switch.

Queues contain at most 5,000 events and drop events older than seven days. A backend outage stops new observation until consent can be checked again; previously queued events can retry. Pause clears the queue locally, then attempts server revocation. If offline, pending revocation must run before later collection. Token revocation or epoch mismatch disables the worker and discards queued events.

## Security and retention

Passwords use salted scrypt hashes; session and extension tokens are stored as SHA-256 digests in SQL. Login sessions expire after seven days and pairing tokens after 30 days. The extension stores its bearer token in Chrome local extension storage, restricted to trusted extension contexts. It is still a secret accessible to someone controlling that Chrome profile.

SQL queries use parameters, server routes scope data to the authenticated account, and composite foreign keys prevent cross-owner references. Rate limits and JSON body limits are configured. HTTP is used only for this local demonstration; database ports are not published.

Browser events expire after 30 days. Task and check-in records remain until explicitly removed where deletion is supported. Check-ins are individually deletable; tasks can be abandoned but remain in history. Browser deletion does not delete tasks/check-ins. Export returns up to 100,000 browser events and declares that limit; larger histories require a future paginated export.

Backups, full account erasure, password recovery, production credentials/roles, TLS termination and an independent security review are outside this local release. No external analytics service or advertising integration is included.
