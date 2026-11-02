# Steady: the complete beginner’s handbook

**A task-continuity and trustworthy planning-record system using PostgreSQL and MongoDB**

Prepared for the implemented core project · 1 November 2026

## How to use this handbook

You do not need programming knowledge to begin. Read sections 1–5 for the purpose, 6–12 for databases, and 13–18 for running and explaining the project. Code blocks are examples or commands, not text you must memorize. “Implemented” means code exists in this project; it does not mean every live workflow has passed testing. Recommendations are explicitly separated from the current implementation.

The companion [database document](database.md) contains the ER diagram. The [API contract](api-and-privacy.md) lists each available operation. The [verification record](implementation-status.md) records what has and has not been tested.

## 1. What problem are we solving?

Imagine you intend to finish an assignment. You create a task, start work, get interrupted, postpone it and return later. A basic checklist may only show “incomplete.” A screen-time tool may show “45 minutes in a browser.” Neither necessarily explains what you planned, which work was recorded, what changed, or what the next step was.

Steady stores those pieces together. The user can break a task into smaller steps, save a plan, start and pause recorded work, write a resume note, and review their own check-ins alongside optional browser observations.

**The central problem is preserving a trustworthy record of planned work, actual recorded work and task continuity despite interruptions, edits, duplicate requests and missing observations.**

This is suitable for a DBMS project because the answer depends on correct relationships, historical records, transactions and queries. A visually attractive timer would not, by itself, demonstrate these ideas.

The intended audience remains students who want support with task initiation and returning to work, including students with ADHD. ADHD is a design context here, not a diagnosis made by the system. No diagnosis is required to use the application. We have not established clinical effectiveness or measured an improvement in users’ functioning.

### A concrete example

All numbers below are invented solely to explain the workflow, not study findings.

| Event | Record created | Why it matters |
|---|---|---|
| 09:00: plan “Database assignment,” estimate 60 minutes | Daily plan and membership | Preserves what was intended |
| 09:20: start work | Focus session and first segment | Establishes recorded start |
| 09:40: pause | Segment closes | Prevents counting the break as work |
| 09:41: write “Next: create the foreign keys” | Resume checkpoint | Provides a concrete return point |
| 10:00: resume | Second segment opens | Adds another period of recorded work |
| 10:25: finish | Segment and session close | Total recorded work is 45 minutes |
| Later: change the estimate to 90 minutes | Task edit | Does not rewrite the saved 60-minute plan estimate |

The original plan remains 60 minutes. The recorded work is 20 + 25 = 45 minutes. The elapsed clock time between 09:20 and 10:25 is 65 minutes, but includes a 20-minute pause. These are different quantities.

## 2. Is this meaningful specifically as a DBMS project?

**Yes, provided the presentation centers on trustworthy task records and explains the database rules.** The value is not the number of tables. It is the wrong outcomes the database prevents and the useful answers the records support.

| Real problem | DBMS concept used | Implemented mechanism | User benefit |
|---|---|---|---|
| Two clicks create two running timers | Concurrency control and conditional uniqueness | Per-user transaction lock and partial unique index | One consistent unfinished session |
| A request saves a session but fails before its time record | Atomic transaction | Session, segment, task history and outbox written together | No half-created start workflow |
| A task accidentally refers to another person’s project | Referential integrity | Composite owner/project foreign key | Accounts’ records remain correctly associated |
| Editing a plan changes the original success target | Temporal versioning and triggers | Frozen revisions plus immutable memberships | Honest comparison against original intentions |
| An upload retries after a lost response | Idempotency and unique index | Stable event IDs plus unique MongoDB key | The same interval is not stored twice |
| A pause is counted as working time | Relational modeling and aggregation | Separate work segments | More faithful recorded work totals |
| Tracking continues after permission changes | Versioned consent and serialized updates | Consent epoch checked during upload | Old queued events are rejected |
| MongoDB is unavailable during a task update | Transactional outbox | Durable SQL event and retryable mirror delivery | SQL history survives a temporary mirror outage |
| There is no observation for an hour | Explicit missing-data semantics | Report does not turn absence into idle time | Avoids a misleading interpretation |

Some totals are calculated in JavaScript after querying the databases, particularly interval union. Do not say every calculation runs inside SQL. Database design still supplies the correct records, ownership and query boundaries.

### What is weak today?

The current report is more descriptive than actionable. It shows times and events but does not yet provide a complete per-task explanation of delay, repeated postponement or changes across weeks. The task-event mirror demonstrates recovery but currently has limited user-facing utility. SQL alone could support the whole project. These are limitations to acknowledge, not hide behind additional tables.

### Recommended refined project purpose

> Steady is a database-backed task-continuity workspace that preserves original plans, records work in resumable segments, and maintains consent-controlled browser observations so users can review their day without losing history or counting the same activity twice.

This is a defensible engineering purpose. Whether it improves everyday functioning would require a separate, ethically designed user evaluation.

## 3. Basic vocabulary before we discuss code

| Term | Plain meaning | Steady example |
|---|---|---|
| Data | A recorded fact | A task title or start time |
| Database | An organized collection of stored facts | Stored tasks and sessions |
| DBMS | Software that manages a database and its rules | PostgreSQL or MongoDB |
| Table | Rows with defined columns | `tasks` |
| Row / record | One stored item | One assignment task |
| Column / field | One property of an item | `title` or `status` |
| Schema | The structure and rules for data | Tables, field types and keys |
| Query | A request to retrieve or change data | “Show my incomplete tasks” |
| SQL | A language for relational databases | `SELECT title FROM tasks` |
| Document | A structured object stored in a document database | One browser interval |
| Collection | A group of MongoDB documents | `activity_events` |
| Frontend | Screens running in the browser | Dashboard and forms |
| Backend | Server code that processes requests | Express API |
| API | Agreed operations that software can request | Create a task, pause a session |
| JSON | A text format for structured data | `{ "title": "Read chapter" }` |
| Endpoint / route | An API address and operation | `POST /api/tasks` |
| Server | A program listening for requests | Node.js application |
| Localhost | This computer | `http://localhost:3000` |
| Port | Number identifying a network service | `3000` for Steady |
| Container | A packaged runtime for a program | PostgreSQL container |
| Volume | Persistent container storage | Saved database files |
| Migration | A controlled database structure change | Initial schema SQL |
| UUID | A widely unique identifier | Task ID, not the task’s title |
| NULL | Missing or not supplied | A check-in without an energy rating |

A database is not the same thing as Excel. A spreadsheet can hold tables, but a DBMS provides structured relationships, concurrent access, transactional updates and constraints that applications can rely on.

## 4. What happens when you click a button?

Example: creating a task.

1. The dashboard collects the title and optional estimate.
2. Browser JavaScript sends a JSON request to the backend.
3. The backend checks the login session and request token.
4. Input validation checks that the title and estimate are allowed.
5. PostgreSQL inserts the task and history inside a transaction.
6. Database constraints reject invalid relationships.
7. The backend returns the saved record, including its ID.
8. The dashboard reloads data and displays the result.

The browser does not connect directly to PostgreSQL. A user could modify their browser’s requests, so the server must enforce the rules even when the interface already validates a form.

For browser observations, the extension sends permitted event documents to dedicated API routes. The backend checks the paired device and consent before writing MongoDB.

## 5. Technology stack and file map

| Component | What it does in this project | Where to look |
|---|---|---|
| HTML | Defines page structure | `web/index.html` |
| CSS | Defines appearance and layout | `web/styles.css` |
| Browser JavaScript | Handles forms, API calls and rendering | `web/app.js` |
| Node.js | Runs JavaScript outside the browser | API container runtime |
| Express | Routes HTTP requests to backend functions | `api/src/server.js` |
| Zod | Checks request shapes and values | Backend route validation |
| PostgreSQL 17 | Stores related workflow records | `db/001_schema.sql` |
| `pg` library | Sends parameterized SQL from Node | `api/src/db.js` and routes |
| MongoDB 8 | Stores observation documents | `api/src/db.js` |
| MongoDB driver | Lets Node query MongoDB | `api/src/db.js` |
| Luxon | Converts local dates and time zones | `api/src/metrics.js` |
| Node crypto / scrypt | Hashes passwords and creates tokens | `api/src/security.js` |
| Helmet and rate limiter | Set security headers and limit requests | Server setup |
| Chrome Manifest V3 | Defines extension permissions and worker | `extension/manifest.json` |
| Docker Compose | Coordinates the three local services | `compose.yaml` |
| Node test runner | Runs automated tests | `api/test/` |

`package.json` lists dependencies and scripts. `package-lock.json` records resolved dependency versions for repeatable installation. The Dockerfile defines the application image. `.env` contains local credentials; `.env.example` shows the required setting names.

Compose describes services, networks and persistent volumes in one configuration. Read [Docker’s Compose application model](https://docs.docker.com/compose/intro/compose-application-model/) for the underlying terms.

## 6. Understand the relational data model

There are 16 SQL tables, including one technical migration ledger. The ER diagram is in [database.md](database.md). “One-to-many” means one record can be associated with several records; it does not require that any already exist.

| Table | One row represents | Important fields and meaning |
|---|---|---|
| `users` | One account | ID, unique email, password hash, name, time zone |
| `auth_sessions` | One logged-in session | User, token hash, request token, expiration |
| `user_preferences` | One account’s display preferences | Quiet overview and reduced motion |
| `projects` | A named group of work | User and project name |
| `tasks` | A task or subtask | Owner, optional project and parent, status, estimate, first start, version |
| `task_events` | A recorded task action | Task, type, old/new state and timestamp |
| `daily_plans` | One revision of a day’s plan | User, date, revision number and freeze time |
| `plan_tasks` | One task’s membership in a plan revision | Plan, task, position and copied estimate |
| `focus_sessions` | One deliberate work session | Task, target duration, state and request key |
| `work_segments` | One unpaused work interval | Session, start and optional end |
| `task_checkpoints` | One saved resume note | Task, note and creation time |
| `checkins` | One optional self-report | Focus, stress, energy and timestamp |
| `devices` | One paired extension identity | Token hash, consent state, expiry and revocation |
| `consent_events` | One consent change | Device, granted/revoked state and epoch |
| `outbox_events` | One durable delivery record | Task event, payload and processed timestamp |
| `schema_migrations` | One schema version marker | Version and application time |

### Why not put everything into the users table?

A person can have many tasks. Each task can have many work segments and notes. Columns such as `task1`, `task2`, `task3` impose an arbitrary limit and make queries awkward. Separate tables represent those repeating facts naturally.

### Keys, explained with the assignment example

A primary key identifies a row. Two people may both create “DBMS assignment,” so the title is not a dependable identifier. A foreign key connects a row to an existing row. A session references a task ID. A composite key uses more than one column: plan membership is identified by both its plan and task.

Steady additionally checks owner identity in several relationships. Merely proving that a project exists is insufficient; the task and project must belong to the same person. This is why the SQL contains pairs such as `(user_id, project_id)` referring to `(user_id, id)`.

For the formal rules, see [PostgreSQL constraints](https://www.postgresql.org/docs/17/ddl-constraints.html). The source SQL is the authority for this project’s exact constraints.

## 7. Normalization without jargon overload

Normalization is a way of arranging relational data so the same fact is not unnecessarily repeated in many places. It reduces inconsistent edits.

Suppose every work segment repeated the user’s email, task title, project name and all previous notes. Renaming a project would require updating many rows; forgetting one would create contradictory names.

A better arrangement stores the project name once in `projects`, the task title in `tasks`, and segment times in `work_segments`. IDs connect the facts. A JOIN brings them together when needed.

Introductory normal forms can be understood as:

- **First normal form:** avoid repeating groups such as task1/task2 columns; each field has a defined value for its row.
- **Second normal form:** with a composite identifier, attributes should describe the whole identified relationship, not just one part. A plan membership’s position describes that membership; a task title belongs to the task.
- **Third normal form:** avoid storing another entity’s descriptive facts through an intermediate dependency. Project name belongs to the project, not every task row.

These are learning explanations, not a formal proof that every table is in strict 3NF. This schema intentionally repeats owner IDs for integrity and copies planned estimates for historical meaning. A rigorous normalization submission should list candidate keys and functional dependencies table by table, including this intentional redundancy.

## 8. Transactions: why starting focus is a database operation

A transaction treats several writes as one unit. In Steady, starting focus updates the task, appends a history event, creates an outbox record, creates a session and opens a segment. If one required write fails, the SQL transaction rolls back. This prevents a session without its first segment.

The common acronym **ACID** means atomicity (all or none), consistency (declared rules remain satisfied), isolation (concurrent operations are controlled) and durability (committed data is retained according to the database’s guarantees). Durability is not a substitute for backups or working storage.

Steady uses transactions and application locks; it does not claim that every operation runs at PostgreSQL’s Serializable isolation level. See the [PostgreSQL transaction tutorial](https://www.postgresql.org/docs/17/tutorial-transactions.html).

### Two browser tabs start work at once

Without coordination, both requests might see “no session” and both create one. Steady serializes cooperating operations for an account using an advisory transaction lock. A partial unique index independently disallows more than one unfinished session for that user. Advisory locks are cooperative: code bypassing the agreed lock is not automatically protected by it. See [PostgreSQL locking](https://www.postgresql.org/docs/17/explicit-locking.html).

### An old screen overwrites a newer edit

Each task has a version. The browser sends the version it saw. If another operation has changed the task, the server rejects the stale update and asks the user to refresh. This is optimistic concurrency control. It avoids silently replacing a newer edit with an older view.

## 9. History, frozen plans and trustworthy comparisons

The current task status answers “What is its state now?” History answers “What changes were recorded?” If postponed is overwritten by completed, the current row alone loses the earlier postponement. Task events preserve it.

A daily plan is a versioned snapshot of membership and estimated minutes. A database trigger rejects changes after freezing. A later plan is another revision. This is useful when evaluating intentions: changing the original denominator after seeing the outcome would make a completion percentage misleading.

The current original-plan report uses the first revision and completion events after that plan was frozen, before the day ends. It is not a general historical reconstruction of every task’s final state. If a task is completed and later reopened, its earlier completion event still counts under the current rule. This definition must be explained when presenting results.

History is not automatically a tamper-proof audit system. A database administrator has broad privileges, and the current schema does not make all history tables append-only against direct administrative edits.

## 10. Indexes, performance and constraints

An index is a maintained lookup structure. Instead of inspecting every event, a database may use an index to locate one user’s events in a time range. Indexes consume storage and add write work, so more indexes are not automatically better.

A partial unique index applies uniqueness only to rows matching a condition. Steady’s unfinished-session index applies to active or paused sessions. It allows many historical finished sessions while limiting the unfinished set. See [PostgreSQL partial indexes](https://www.postgresql.org/docs/17/indexes-partial.html).

Performance needs measurement. `EXPLAIN` shows the chosen query plan; `EXPLAIN ANALYZE` also executes the query. A small table may reasonably use a sequential scan even when an index exists. Do not claim a speedup without measured results on a documented dataset. See [PostgreSQL EXPLAIN](https://www.postgresql.org/docs/17/using-explain.html).

## 11. Why MongoDB is present, and what it does not prove

MongoDB stores browser event documents. An interval needs start, end, state, domain and category. A tab transition needs fewer fields. Documents provide a convenient representation of these event variants. The application validates exact shapes; the collection also has a basic schema validator.

A unique index on user, device and event ID prevents storing a retried event twice. Validation and unique indexes solve different problems: validation checks allowed structure; uniqueness checks repeated identities. See [MongoDB unique indexes and schema validation](https://www.mongodb.com/docs/manual/tutorial/unique-indexes-schema-validation/).

An expiration timestamp and TTL index allow browser events to age out. TTL cleanup runs asynchronously, so expiration does not promise physical deletion at the exact second. Steady’s report queries also exclude expired records. See [MongoDB TTL indexes](https://www.mongodb.com/docs/manual/core/index-ttl/).

**Honest justification:** both PostgreSQL and MongoDB are useful in this educational design, but neither is uniquely capable of its assigned role. PostgreSQL could store these events, including JSON. MongoDB adds an event-store boundary and a second data model, but also deployment and consistency complexity. Do not claim that NoSQL means “no schema,” that MongoDB is necessarily faster, or that two databases automatically make the project scalable.

### The outbox, step by step

The backend saves a task event and a delivery record in the same SQL transaction. A worker later copies a small event representation into MongoDB, then marks the SQL delivery complete. If it crashes after the copy but before the mark, the next attempt uses the same outbox ID. MongoDB upserts that ID instead of creating another mirror event.

This is eventual consistency: the mirror may lag. It is not a distributed all-or-nothing transaction. The mirror is currently an engineering demonstration; the dashboard primarily uses authoritative SQL task records. A future event-analysis feature would give this mirror a stronger product role.

## 12. How reports are calculated

### Recorded work versus browser activity

Recorded focus is the duration of user-started work segments. Browser activity is sampled foreground browser observation. A user may work offline, and a timer may be left running accidentally. Neither quantity is a direct measurement of attention.

### Overlap and double counting

Suppose two recorded intervals are 10:00–10:10 and 10:05–10:15. Adding both produces 20 minutes, but their union covers 15 minutes. Steady merges overlaps for overall totals.

For a report window W, duration is the length of `union(intervals intersect W)`. Intersection means keep only the part inside the day; union means combine overlapping parts. Domain totals are calculated separately, so they can overlap across devices and need not add up to total active time.

### Dates and hours

The report day uses the account’s time zone. Records use timestamps, while the reporting window uses local midnight boundaries. Some zones have daylight-saving days lasting 23 or 25 hours. Unit tests cover this case.

### Self-reports and missing values

A focus rating of 2/5 means the user entered that value at that time. No entry means unknown, not zero. “Highest reported stress at 16:00” means the highest among submitted check-ins; the unobserved maximum could have occurred elsewhere.

Browser transitions, self-reported stress and task completion are distinct variables. A relationship between them would not prove causation. The current build does not implement a statistical correlation or personal baseline detector.

### Current and proposed metrics

| Metric | Current state |
|---|---|
| Recorded work, active browser intervals, observed idle intervals | Implemented calculations |
| Hourly tab transitions and domain totals | Implemented calculations |
| Completion events and first-plan completion | Implemented calculations with definitions above |
| Highest entered stress and lowest entered focus | Implemented display of sampled extrema |
| Task initiation delay | Required timestamps exist; dedicated report proposed |
| Repeated postponements per task | History exists; dedicated report proposed |
| Resume-gap duration and latest unfinished step | Proposed combined task report |
| Personal baseline / 7-day or 30-day trend detector | Not implemented |
| ADHD symptom severity, distraction diagnosis | Not a project output |

## 13. Authentication, privacy and consent

Authentication asks “Who is making the request?” Authorization asks “May that person use this record?” A valid login is not permission to read another account’s tasks.

A password hash is a one-way derived representation; it is not a password encrypted for later display. The backend uses salted scrypt. A session cookie keeps the user logged in. A request token protects dashboard mutations against certain unwanted cross-site requests. Extension pairing uses a separate bearer token with narrower routes.

Tracking is off until explicitly enabled. Pairing alone does not start it. The worker reads a tab URL transiently to extract a domain but does not send or store the full URL. Page content, keystrokes and incognito tracking are excluded. Domain names can still reveal sensitive interests, so optionality and deletion matter.

Each consent change advances an epoch, meaning a version number. Events queued under an old epoch are rejected after consent changes. Pause clears unsent data; offline pause also records a pending server revocation. Browser-record deletion disables tracking before deleting events.

Chrome service workers are event-driven and may stop between events. Persistent queue state matters for that reason. See [Chrome’s service-worker lifecycle](https://developer.chrome.com/docs/extensions/develop/concepts/service-workers/lifecycle). This does not guarantee perfect sampling: delays and missing intervals remain possible.

The implementation is for local demonstration. Full account erasure, password reset, email verification, deployment hardening and independent security review are not implemented. Read the [full privacy contract](api-and-privacy.md) before using real personal data.

## 14. Run it from the beginning

You need Node.js 22 or later, a working Docker Desktop engine, and Chrome for the optional extension. Current project verification is blocked by the unavailable Docker installation on this computer.

Open a terminal. A terminal is a text interface where you enter commands. `cd` changes the working folder. Run:

```sh
cd /Users/pranshumishra/Documents/Codex/2026-10-04/st/steady
node scripts/setup.mjs
docker compose up --build -d
docker compose ps
```

The setup helper creates random local database passwords in `.env` if it does not exist. `up` starts the services; `--build` builds the app image; `-d` runs in the background. `ps` shows service status. Initial downloads require internet access.

Open `http://localhost:3000`. Create an account and choose the correct time zone. Add a task before trying a focus session. Save a plan if you want original-plan completion results.

To inspect recent app messages:

```sh
docker compose logs --tail=100 app
```

To stop without deleting stored database volumes:

```sh
docker compose down
```

Do not add `--volumes` unless you intend to erase stored database data. Named volumes preserve data across ordinary container recreation; they are not backups against disk loss.

### Load the extension

Open `chrome://extensions`, enable Developer mode, choose Load unpacked and select `steady/extension`. In Steady Preferences generate a token, paste it into the popup, pair, and then choose Enable tracking. Grant the optional permissions only if you want collection. Browse an ordinary page for a minute, then refresh My insights.

The extension expects localhost port 3000. The old page on port 4173 is a different static prototype. It is not evidence that this backend is running.

## 15. Common failures and how to interpret them

| What you see | What it usually means | Next action |
|---|---|---|
| `docker: command not found` | No usable Docker CLI on PATH | Install/repair Docker Desktop |
| Cannot connect to Docker daemon | Engine is not running or installation is broken | Open Docker Desktop and wait for engine readiness |
| Browser cannot open localhost:3000 | App is not serving | Check `compose ps` and app logs |
| App container repeatedly restarts | Startup/database error | Read logs; do not erase volumes as the first fix |
| “Task changed. Refresh and retry.” | Your screen has an old task version | Refresh and repeat the edit |
| “Finish your current focus session first” | One unfinished session already exists | Open Focus space and finish or resume it |
| No browser data | No permitted observations arrived | Check pairing, explicit opt-in, normal page, server and date |
| Zero minutes after a brief test | UI rounds down seconds to minutes | Observe longer or inspect hourly seconds |
| Session expired / revoked | Token no longer valid | Log in or pair again, as appropriate |
| Another owner’s record rejected | Ownership enforcement worked | Use an ID from the current account |

Do not share `.env`, pairing tokens, passwords or private exports when asking for help. A safe error report includes the action, visible error, relevant non-secret logs and service status.

## 16. Learn SQL using this project

Open the SQL console only after the database is running:

```sh
docker compose exec postgres psql -U steady -d steady
```

Then inspect tables and leave the console:

```text
\dt
\d tasks
\q
```

The following read-only examples are for a demonstration database and show records across accounts. Application routes must scope their queries to the logged-in owner.

```sql
-- SELECT chooses columns. FROM names the table.
SELECT title, status FROM tasks ORDER BY created_at;

-- JOIN connects related records; LEFT JOIN keeps tasks with no project.
SELECT t.title, p.name AS project
FROM tasks t LEFT JOIN projects p ON p.id = t.project_id;

-- GROUP BY collects rows with the same status; COUNT counts each group.
SELECT status, count(*) AS number_of_tasks
FROM tasks GROUP BY status;

-- A useful proposed report query: count recorded postponements per task.
SELECT t.id, t.title, count(e.id) AS postponements
FROM tasks t
LEFT JOIN task_events e ON e.task_id=t.id
  AND e.user_id=t.user_id AND e.new_status='postponed'
GROUP BY t.id, t.title
ORDER BY postponements DESC;
```

The last query is an educational query over existing records, not a claim that a corresponding dashboard feature is implemented. These handbook queries have not been executed against a live database in this environment.

Parameterized queries use placeholders such as `$1` and supply values separately. This avoids treating a user’s title or ID as SQL code. Never construct queries by joining untrusted user text into an SQL string.

## 17. How to demonstrate that the DBMS contribution works

A feature list is not enough. Prepare a small, labelled test dataset and show expected results before testing.

| Experiment | Expected evidence | Status today |
|---|---|---|
| Start twice using the same request key | Same session ID returned | Integration test written; runtime pending |
| Concurrently start different sessions | Only one unfinished session succeeds | Integration test written; runtime pending |
| Reference another account’s task | Request rejected; no cross-account mutation | Integration test written; runtime pending |
| Pause then resume | Only unpaused segments contribute | Code exists; full timing acceptance pending |
| Repeat a browser-event upload | Stored duration remains unchanged | Integration test written; runtime pending |
| Revoke consent then retry old queue | Stale upload rejected | Integration test written; runtime pending |
| Edit a frozen plan directly | Database trigger rejects mutation | Live SQL experiment pending |
| Stop/restart without removing volumes | Records remain | Pending |
| Temporarily stop MongoDB after startup | SQL outbox waits and later catches up | Pending |
| Compare query plans at documented sizes | Evidence of actual cost and timing | Not benchmarked |

Run unit tests from `steady/api` with `npm test`. Run integration tests against healthy Compose services from `steady` using `docker compose exec app npm run test:integration`. Integration tests create test accounts and records. They are not a clinical evaluation.

Seven unit tests passed in the recorded development run: overlap/clipping, empty intervals, daylight-saving boundaries, invalid dates, report boundaries, password checks and token checks. Syntax checks also passed. Real database, extension and full UI acceptance remain pending. Do not describe the system as fully tested until those checks run successfully.

## 18. Changes that would make the project stronger

Recommended priority order; these are proposals, not completed features.

### Priority 1: a task-continuity report

Give each task one readable page showing its original estimate, recorded segments, first start, postponement events, latest note and next incomplete subtask. The user can choose to resume or split the task. This uses JOINs, grouping, ordering and historical records to answer a useful question: “What happened to this work, and where can I restart?”

Define initiation delay as first recorded focus start minus task creation, labelled “time before first recorded start.” It includes nights and time before the task was intended to begin, so it must not be called wasted time or clinical difficulty. Define resume gaps only for explicitly paused/resumed sessions and distinguish unfinished gaps.

### Priority 2: fair planned-versus-recorded comparisons

Use the frozen plan estimate as the denominator. Display recorded work and the difference, with missing estimates shown as unknown. Distinguish a completed task from one still in progress. Do not declare an overrun while the task remains unfinished. Make the current completion-event rule visible or implement a clearly specified end-of-day state reconstruction.

### Priority 3: evidence behind each report

Let a user open a metric and see its window, definition, source record IDs and missing-data caveats. A later report-run table could save calculation version, generation time and source cutoff. This would demonstrate reproducibility and provenance. Define retention and deletion behavior before storing long-lived derived data.

### Priority 4: stronger recovery and ownership demonstrations

Add executed rollback/failure tests, frozen-plan tests, persistence checks and query-plan experiments. Consider row-level security and a restricted app database role after the core works. These improvements strengthen DBMS evidence more than adding unrelated features.

### Priority 5: make the NoSQL component earn its place

The existing activity collection already serves browser reports. A future useful extension is a bounded, consent-aware event timeline around recorded focus sessions. Join time windows through the backend, not fictional cross-database foreign keys. Explain that temporal overlap is context, not proof of interruption. Either give the task-event mirror a documented analytical consumer or present it solely as a recovery experiment.

Personal baseline detection can wait. It requires sufficient history, a defined observation-quality rule and careful handling of missing days. Adding it now merely to sound advanced would weaken the project’s claims.

## 19. Viva questions and clear answers

**What does your project solve?** It helps users preserve plans, return to interrupted tasks and review recorded work while keeping the underlying records consistent.

**Where is DBMS essential?** In transactions for multi-step changes, keys for ownership, immutable plan revisions, history, duplicate-safe ingestion and queries that combine related records.

**Why is this more than CRUD?** CRUD means create/read/update/delete. The project also enforces concurrency invariants, preserves history, versions intentions, handles retries and coordinates two stores. These must be demonstrated, not merely listed.

**Why not use a spreadsheet?** A spreadsheet can prototype the data, but this application needs controlled concurrent requests, owner isolation, keys and transactional changes through a server.

**Why SQL and NoSQL?** SQL owns related workflow facts and constraints; MongoDB holds event documents with unique identities and retention. Two stores are a chosen educational architecture, not a technical necessity.

**Is your database fully normalized?** It separates entity facts and repeating records, but deliberately repeats owner IDs and historical estimates. We should show dependencies rather than claim strict 3NF without analysis.

**Do switches measure ADHD?** No. They measure recorded tab transitions. The project does not diagnose or score symptoms.

**Have you proved that users benefit?** No controlled user study has been completed. The project demonstrates an engineering approach and proposes user-facing utility.

**What is the main remaining engineering risk?** Live database and Chrome acceptance are not yet verified because the current Docker environment is unavailable.

## 20. Suggested learning sequence and references

Day 1: read sections 1–5, create a task and explain the request flow aloud. Day 2: study the ER diagram, primary keys, foreign keys and the sample JOIN. Day 3: explain why a focus start is a transaction and what happens on a double click. Day 4: study history, plan snapshots, event IDs and consent. Day 5: run the tests and demonstrate real outcomes with a labelled sample account.

Official references used for technical explanations:

1. [PostgreSQL 17: Transactions](https://www.postgresql.org/docs/17/tutorial-transactions.html) — all-or-nothing groups of operations.
2. [PostgreSQL 17: Constraints](https://www.postgresql.org/docs/17/ddl-constraints.html) — primary, foreign, unique and check constraints.
3. [PostgreSQL 17: Explicit locking](https://www.postgresql.org/docs/17/explicit-locking.html) — locks and cooperating concurrent operations.
4. [PostgreSQL 17: Partial indexes](https://www.postgresql.org/docs/17/indexes-partial.html) — indexing a conditional subset.
5. [PostgreSQL 17: Using EXPLAIN](https://www.postgresql.org/docs/17/using-explain.html) — interpreting query plans.
6. [MongoDB: Unique indexes and schema validation](https://www.mongodb.com/docs/manual/tutorial/unique-indexes-schema-validation/) — separate structural and uniqueness guarantees.
7. [MongoDB: TTL indexes](https://www.mongodb.com/docs/manual/core/index-ttl/) — automatic expiration and its timing limits.
8. [Chrome: Extension service-worker lifecycle](https://developer.chrome.com/docs/extensions/develop/concepts/service-workers/lifecycle) — event-driven runtime and lifecycle constraints.
9. [Docker: Compose application model](https://docs.docker.com/compose/intro/compose-application-model/) — services, configuration and storage.

References explain platform behavior; they do not validate Steady’s implementation or demonstrate clinical benefit. Local code, test results and documented limitations are the sources for implementation claims. No Turnitin check or empirical clinical study has been performed.
