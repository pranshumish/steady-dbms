# Steady

A local task and reflection workspace with ADHD-informed interaction design. Users break work into steps, save a daily plan, run focus sessions, leave a note for their next return, and reflect on their day. Optional Chrome tracking adds domain-level observations. The application does not diagnose ADHD or infer attention from browsing.

**Delivery status:** application source, extension, database schema and automated checks are included. Seven unit tests passed during development. Real PostgreSQL/MongoDB integration and Chrome extension acceptance testing remain pending because Docker is unavailable on the development computer. See [verification status](docs/implementation-status.md).

## Start the application

Requirements: Node.js 22 or later for the setup helper, Docker Desktop with a working engine, and Chrome 120 or later for the optional extension. Initial container builds require internet access.

Run these commands from this `steady` folder:

```sh
node scripts/setup.mjs
docker compose up --build -d
docker compose ps
```

Open **http://localhost:3000**, select **Create an account**, and register with your own email, password and time zone. No account or activity data is preloaded. Email is a login identifier; this demonstration does not send email.

The setup helper generates local database passwords in `.env`. Keep this file private. Containers retain data in named volumes when stopped.

```sh
docker compose logs --tail=100 app
docker compose down
```

The second command stops the application while keeping database data. Do not add `--volumes` unless you intentionally want to erase the databases. Do not share the database volumes or `.env` in a submission archive.

If Docker is unavailable, install or repair Docker Desktop and start its engine before continuing. A static web server cannot replace this backend. The old `steady-demo` sibling folder is a separate illustrative prototype.

## Connect Chrome

1. Open `chrome://extensions`, enable Developer mode, and choose **Load unpacked**.
2. Select this project's `extension` directory.
3. In Steady → Preferences, generate a pairing token. Copy it into the extension popup and select **Pair**.
4. Select **Enable tracking** in the popup and approve its optional browser permissions.
5. Browse a normal HTTP/HTTPS page for at least a minute. Return to Steady and refresh My insights.

Pairing alone does not enable collection. Tokens expire after 30 days. Keep the default localhost port 3000; changing the port also requires changes to the extension's manifest and worker URL. Pause clears unsent records. Revoking a device in Steady rejects further uploads. Incognito access is disabled by the manifest.

## What is included

- Email/password authentication, logout, cookie sessions and request protection.
- Projects, tasks, one level of subtasks, status history and version conflict checks.
- Immutable daily-plan revisions with copied time estimates.
- Focus sessions with pause/resume, retry-safe starts and recorded work segments.
- Resume notes and optional focus/stress/energy check-ins.
- Domain/category event ingestion with explicit consent, upload deduplication and retention.
- Daily/hourly activity, domain totals, tab transitions, recorded focus time, check-in extrema and original-plan completion.
- Data export, browser-record deletion, device revocation, quiet overview and reduced motion.

## Project map

| Folder/file | Responsibility |
|---|---|
| `web/` | Dashboard: HTML, CSS and browser JavaScript; calls the API |
| `api/src/server.js` | HTTP routes, authentication, ownership checks and workflow rules |
| `api/src/db.js` | Database connections, transactions and outbox delivery |
| `api/src/metrics.js` | Time-zone boundaries and interval-based calculations |
| `api/src/security.js` | Password hashing and token generation |
| `db/001_schema.sql` | Relational tables, keys, constraints, indexes and triggers |
| `extension/` | Opt-in Chrome observation and pairing popup |
| `api/test/` | Unit and real-service integration tests |
| `compose.yaml` | Runs PostgreSQL, MongoDB and application containers together |
| `docs/` | Database model, API, privacy, demonstration and verification notes |

## Test commands

Without databases:

```sh
cd api
npm ci --ignore-scripts
npm test
```

With the Compose services healthy, from the project root:

```sh
docker compose exec app npm run test:integration
```

Integration tests create two test accounts and task records in the running database. Use a demonstration instance. They verify account isolation, CSRF rejection, concurrent/retried focus starts, consent enforcement, event deduplication, report totals, deletion and revocation.

## Documentation

Start here: [Complete beginner’s handbook, DBMS purpose assessment and recommended improvements](docs/BEGINNERS_HANDBOOK.md). It explains the project from zero, with examples, setup help, viva answers and official references.

- [Easy explanation, architecture and demonstration](docs/guide.md)
- [Database justification, ER diagram and calculations](docs/database.md)
- [API and privacy contract](docs/api-and-privacy.md)
- [Implemented scope and verification status](docs/implementation-status.md)

Earlier research papers and 26-table diagrams describe a larger proposed system. This implementation follows the subsequently approved core scope. Do not present planned baseline detection, clinical outcomes or unperformed experiments as implemented results.
