## Purpose

Generate the OpenAPI contract from the server code, keep the committed contract in sync with the code, reject breaking changes to /api/v1, and guarantee that client generators can consume it.

## Requirements

### Requirement: Contract generated from route definitions
Every `/api/v1/` endpoint SHALL be defined with request and response schemas in the server code, and `contract/openapi.json` SHALL be generated from those definitions. The contract SHALL describe every `/api/v1/` endpoint, including its request parameters, request body, responses, and the shared error format.

#### Scenario: Health endpoint in the contract
- **WHEN** the contract is generated
- **THEN** `contract/openapi.json` contains `GET /api/v1/health` with its 200 response schema

#### Scenario: Endpoint without a schema
- **WHEN** a developer adds an `/api/v1/` endpoint without request and response schemas
- **THEN** verification fails

### Requirement: Committed contract stays in sync with code
`contract/openapi.json` SHALL be committed to the repository. Generation SHALL be deterministic, and verification SHALL fail when the committed file differs from freshly generated output. The failure message SHALL name the command that regenerates the file.

#### Scenario: Route changed without regenerating
- **WHEN** a developer changes an endpoint's schema without regenerating the contract
- **THEN** the contract check fails and prints the regeneration command

#### Scenario: Contract up to date
- **WHEN** the committed contract matches freshly generated output
- **THEN** the contract check passes

#### Scenario: Native builds do not need the web toolchain
- **WHEN** an Apple or Android build consumes the contract
- **THEN** it reads the committed `contract/openapi.json` without running Node.js tooling

### Requirement: Breaking changes to v1 are rejected
CI SHALL compare the contract in a change against the contract on the main branch and SHALL fail when the change is backward-incompatible for existing clients. Backward-incompatible changes include removing an endpoint or response field, changing a field's type, adding a required request field, and making an optional request field required. Additive changes SHALL pass.

#### Scenario: Removing a response field
- **WHEN** a change removes a field from an `/api/v1/` response
- **THEN** the breaking-change check fails and identifies the field

#### Scenario: Adding an optional field
- **WHEN** a change adds an optional request field or a new response field
- **THEN** the breaking-change check passes

#### Scenario: Adding an endpoint
- **WHEN** a change adds a new `/api/v1/` endpoint
- **THEN** the breaking-change check passes

### Requirement: Contract is consumable by client generators
`contract/openapi.json` SHALL use an OpenAPI version and constructs that `swift-openapi-generator` and the Kotlin `openapi-generator` accept without errors.

#### Scenario: Generate clients from the contract
- **WHEN** the committed contract is passed to `swift-openapi-generator` and to the Kotlin `openapi-generator`
- **THEN** both generate code without errors
