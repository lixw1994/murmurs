## ADDED Requirements

### Requirement: Versioned public API prefix
Every HTTP endpoint intended for clients other than the bundled web UI SHALL be served under `/api/v1/`. Native clients SHALL use only `/api/v1/` endpoints. TanStack Start server functions SHALL NOT be part of the public API.

#### Scenario: API and web UI share one Worker
- **WHEN** a browser requests `/`
- **THEN** the Worker returns the web UI landing page as HTML
- **AND** a request to `/api/v1/health` on the same host returns JSON

### Requirement: Health endpoint
`GET /api/v1/health` SHALL return HTTP 200 with a JSON body containing `status` set to `"ok"`, the deployed `version`, and the `environment` name (`development`, `staging`, or `production`). It SHALL NOT require authentication.

#### Scenario: Healthy Worker
- **WHEN** a client sends `GET /api/v1/health`
- **THEN** the response status is 200
- **AND** the body is JSON with `status` equal to `"ok"`

#### Scenario: Environment is reported
- **WHEN** a client calls the health endpoint on the staging deployment
- **THEN** the `environment` field equals `"staging"`

### Requirement: JSON error format
Errors from `/api/v1/` SHALL use HTTP status codes and a JSON body of the form `{ "error": { "code": string, "message": string, "details"?: object } }`. Unknown `/api/v1/` paths SHALL return 404 in this format, not the web UI's HTML not-found page. Requests that fail schema validation SHALL return 400 with code `invalid_request` and the validation issues in `details`.

#### Scenario: Unknown API path
- **WHEN** a client requests `GET /api/v1/does-not-exist`
- **THEN** the response status is 404
- **AND** the body is JSON with `error.code` equal to `"not_found"`

#### Scenario: Invalid request
- **WHEN** a client sends a request that violates an endpoint's request schema
- **THEN** the response status is 400
- **AND** `error.code` equals `"invalid_request"` and `error.details` describes the violations

#### Scenario: Unexpected server error
- **WHEN** an endpoint throws an unhandled error
- **THEN** the response status is 500 with `error.code` equal to `"internal_error"`
- **AND** the response does not include stack traces or internal messages

### Requirement: Isolated environments
The Worker SHALL be deployable as separate development (local), staging, and production environments. Each environment SHALL use its own D1 database, and deploying one environment SHALL NOT change another environment's code or data. No resource, secret, or domain from the `react-tanstarter` template deployment SHALL be reused.

#### Scenario: Deploy to staging
- **WHEN** a developer deploys to staging
- **THEN** the production Worker version and the production D1 data are unchanged

#### Scenario: Local development
- **WHEN** a developer starts the local development server
- **THEN** the API and web UI run against a local D1 database without network access to staging or production resources

### Requirement: D1 schema changes through migrations
Changes to the D1 schema SHALL be applied through generated, committed migration files. Pushing a schema directly to a database without a migration SHALL NOT be part of the documented workflow.

#### Scenario: Apply migrations to an environment
- **WHEN** a developer applies migrations to staging
- **THEN** staging D1 reaches the schema defined in code
- **AND** the applied migrations are recorded so that applying them again changes nothing

### Requirement: Sign-in is disabled
Until a sign-in change is adopted, the Worker SHALL NOT allow creating accounts or signing in. The web UI SHALL NOT show sign-in or sign-up pages.

#### Scenario: Sign-up attempt
- **WHEN** a client sends a sign-up or sign-in request to `/api/auth/`
- **THEN** the request is rejected and no user or session is created

#### Scenario: No sign-in UI
- **WHEN** a visitor opens the web UI
- **THEN** no sign-in or sign-up page or link is available
