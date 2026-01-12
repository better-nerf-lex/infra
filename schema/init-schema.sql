-- Production-Safe RDS Schema Initialization
-- This script is idempotent and safe to run multiple times

CREATE TABLE IF NOT EXISTS users
(
    id              BIGSERIAL PRIMARY KEY,
    username        VARCHAR(255) UNIQUE NOT NULL,
    email           VARCHAR(255) UNIQUE NOT NULL,
    password        VARCHAR(255),
    cognito_sub     VARCHAR(255) UNIQUE,
    email_verified  BOOLEAN   DEFAULT FALSE,
    enabled         BOOLEAN   DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by      BIGINT,
    version         INTEGER             NOT NULL
);

CREATE TABLE IF NOT EXISTS teams
(
    id         UUID PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    version    INTEGER      NOT NULL,
    deleted_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS document_examples
(
    id          UUID PRIMARY KEY,
    title       VARCHAR(255) NOT NULL,
    description TEXT,
    questions   JSONB,
    base        JSONB,
    requirements JSONB,
    template_files JSONB,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    search_vector tsvector
);

CREATE TABLE IF NOT EXISTS document_groups
(
    id          UUID PRIMARY KEY,
    name        VARCHAR(255),
    description TEXT,
    updated_at  TIMESTAMP,
    created_at  TIMESTAMP,
    created_by  BIGINT,
    version     INTEGER NOT NULL,
    team_id     UUID REFERENCES teams (id),
    owner_id    BIGINT REFERENCES users (id),
    case_id     UUID,
    deleted_at  TIMESTAMP
);

CREATE TABLE IF NOT EXISTS documents
(
    id                UUID PRIMARY KEY,
    title             VARCHAR(255),
    type              VARCHAR(100),
    status            VARCHAR(20) CHECK (status IN ('PENDING', 'COMPLETED', 'ERROR')),
    updated_at        TIMESTAMP,
    text              TEXT,
    created_at        TIMESTAMP,
    created_by        BIGINT,
    version           INTEGER NOT NULL,
    team_id           UUID REFERENCES teams (id),
    owner_id          BIGINT REFERENCES users (id),
    document_group_id UUID REFERENCES document_groups (id) ON DELETE SET NULL,
    deleted_at        TIMESTAMP
);

CREATE TABLE IF NOT EXISTS document_history
(
    id              UUID PRIMARY KEY,
    document_id     UUID    NOT NULL,
    content         TEXT,
    created_at      TIMESTAMP,
    created_by      BIGINT,
    version         INTEGER NOT NULL,
    history_version INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS storage_files
(
    id                UUID PRIMARY KEY,
    name              VARCHAR(255),
    file_type         VARCHAR(20) CHECK (file_type IN ('PDF', 'JPG', 'JPEG', 'PNG', 'GIF', 'TXT', 'DOC', 'DOCX', 'XLS', 'XLSX', 'OTHER')),
    document_group_id UUID REFERENCES document_groups (id) ON DELETE CASCADE,
    file_size         BIGINT,
    updated_at        TIMESTAMP,
    created_at        TIMESTAMP,
    created_by        BIGINT,
    version           INTEGER NOT NULL,
    team_id           UUID REFERENCES teams (id),
    owner_id          BIGINT REFERENCES users (id),
    deleted_at        TIMESTAMP
);

CREATE TABLE IF NOT EXISTS legal_entities
(
    id          UUID PRIMARY KEY,
    document_id UUID,
    details     JSONB,
    relevance   VARCHAR(255),
    created_at  TIMESTAMP,
    created_by  BIGINT,
    version     INTEGER NOT NULL,
    team_id     UUID REFERENCES teams (id),
    owner_id    BIGINT REFERENCES users (id),
    deleted_at  TIMESTAMP,
    FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS cases
(
    id               UUID PRIMARY KEY,
    title            VARCHAR(255),
    description      TEXT,
    status           VARCHAR(20) CHECK (status IN ('OPEN', 'IN_PROGRESS', 'CLOSED', 'ARCHIVED')),
    leading_court_id UUID REFERENCES legal_entities (id),
    updated_at       TIMESTAMP,
    created_at       TIMESTAMP,
    created_by       BIGINT,
    version          INTEGER NOT NULL,
    team_id          UUID REFERENCES teams (id),
    owner_id         BIGINT REFERENCES users (id),
    deleted_at       TIMESTAMP
);

ALTER TABLE document_groups DROP CONSTRAINT IF EXISTS document_groups_case_id_fkey;
ALTER TABLE document_groups ADD CONSTRAINT document_groups_case_id_fkey FOREIGN KEY (case_id) REFERENCES cases (id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS case_parties
(
    case_id         UUID         NOT NULL REFERENCES cases (id) ON DELETE CASCADE,
   legal_entity_id UUID         NOT NULL REFERENCES legal_entities (id) ON DELETE CASCADE,
    role            VARCHAR(20) NOT NULL CHECK (role IN ('DEFENDANT', 'PLAINTIFF', 'OTHER')),
    PRIMARY KEY (case_id, legal_entity_id, role)
);

CREATE TABLE IF NOT EXISTS case_documents
(
    case_id     UUID NOT NULL,
    document_id UUID NOT NULL,
    PRIMARY KEY (case_id, document_id),
    FOREIGN KEY (case_id) REFERENCES cases (id) ON DELETE CASCADE,
    FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS events
(
    id         UUID PRIMARY KEY,
    case_id    UUID        NOT NULL REFERENCES cases (id) ON DELETE CASCADE,
    type       VARCHAR(20) NOT NULL CHECK (type IN ('COURT', 'INHOUSE', 'OUTSIDE')),
    status     BOOLEAN     NOT NULL DEFAULT FALSE,
    event_date TIMESTAMP   NOT NULL,
    details    TEXT,
    created_at TIMESTAMP,
    created_by BIGINT,
    version    INTEGER     NOT NULL,
    team_id    UUID REFERENCES teams (id),
    owner_id   BIGINT REFERENCES users (id),
    deleted_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS event_participants
(
    event_id        UUID NOT NULL REFERENCES events (id) ON DELETE CASCADE,
    legal_entity_id UUID NOT NULL REFERENCES legal_entities (id) ON DELETE CASCADE,
    PRIMARY KEY (event_id, legal_entity_id)
);

CREATE TABLE IF NOT EXISTS activity
(
    id          UUID PRIMARY KEY,
    user_id     BIGINT REFERENCES users (id),
    team_id     UUID REFERENCES teams (id),
    action      VARCHAR(255) NOT NULL,
    entity_id   UUID,
    entity_type VARCHAR(255),
    details     TEXT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_roles
(
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT      NOT NULL REFERENCES users (id),
    role       VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS team_members
(
    id           UUID PRIMARY KEY,
    user_id      BIGINT      NOT NULL REFERENCES users (id),
    team_id      UUID        NOT NULL REFERENCES teams (id),
    access_level VARCHAR(50) NOT NULL,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by   BIGINT,
    version      INTEGER     NOT NULL
);

CREATE TABLE IF NOT EXISTS authorization_codes
(
    id           VARCHAR(255) PRIMARY KEY,
    code         VARCHAR(255) UNIQUE NOT NULL,
    client_id    VARCHAR(255)        NOT NULL,
    user_id      BIGINT              NOT NULL REFERENCES users (id),
    redirect_uri VARCHAR(1000)       NOT NULL,
    scopes       VARCHAR(1000),
    expires_at   TIMESTAMP           NOT NULL,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    used         BOOLEAN   DEFAULT FALSE
);

-- Indices for performance
CREATE INDEX IF NOT EXISTS idx_documents_status ON documents (status);
CREATE INDEX IF NOT EXISTS idx_documents_created_at ON documents (created_at);
CREATE INDEX IF NOT EXISTS idx_document_history_document_id ON document_history (document_id);
CREATE INDEX IF NOT EXISTS idx_document_history_version ON document_history (document_id, history_version);
CREATE INDEX IF NOT EXISTS idx_activity_date ON activity (created_at);
CREATE INDEX IF NOT EXISTS idx_documents_owner_id ON documents (owner_id);
CREATE INDEX IF NOT EXISTS idx_documents_team_id ON documents (team_id);
CREATE INDEX IF NOT EXISTS idx_legal_entities_owner_id ON legal_entities (owner_id);
CREATE INDEX IF NOT EXISTS idx_legal_entities_team_id ON legal_entities (team_id);
CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON team_members (user_id);
CREATE INDEX IF NOT EXISTS idx_team_members_team_id ON team_members (team_id);
CREATE INDEX IF NOT EXISTS idx_case_documents_case_id ON case_documents (case_id);
CREATE INDEX IF NOT EXISTS idx_case_documents_document_id ON case_documents (document_id);
CREATE INDEX IF NOT EXISTS idx_cases_owner_id ON cases (owner_id);
CREATE INDEX IF NOT EXISTS idx_cases_team_id ON cases (team_id);
CREATE INDEX IF NOT EXISTS idx_cases_created_at ON cases (created_at);
CREATE INDEX IF NOT EXISTS idx_case_parties_case_id ON case_parties (case_id);
CREATE INDEX IF NOT EXISTS idx_events_case_id ON events (case_id);
CREATE INDEX IF NOT EXISTS idx_events_event_date ON events (event_date);
CREATE INDEX IF NOT EXISTS idx_document_groups_owner_id ON document_groups (owner_id);
CREATE INDEX IF NOT EXISTS idx_document_groups_team_id ON document_groups (team_id);
CREATE INDEX IF NOT EXISTS idx_document_groups_created_at ON document_groups (created_at);
CREATE INDEX IF NOT EXISTS idx_storage_files_owner_id ON storage_files (owner_id);
CREATE INDEX IF NOT EXISTS idx_storage_files_team_id ON storage_files (team_id);
CREATE INDEX IF NOT EXISTS idx_storage_files_document_group_id ON storage_files (document_group_id);
CREATE INDEX IF NOT EXISTS idx_storage_files_created_at ON storage_files (created_at);

-- Full-text search setup
ALTER TABLE documents ADD COLUMN IF NOT EXISTS search_vector tsvector;
CREATE INDEX IF NOT EXISTS idx_documents_search ON documents USING GIN (search_vector);

CREATE OR REPLACE FUNCTION documents_search_vector_update()
    RETURNS trigger AS
'
    BEGIN
        NEW.search_vector :=
                setweight(to_tsvector(''english'', COALESCE(NEW.title, '''')), ''A'') ||
                setweight(to_tsvector(''english'', COALESCE(NEW.text, '''')), ''B'');
        RETURN NEW;
    END;
' LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS documents_search_vector_trigger ON documents;
CREATE TRIGGER documents_search_vector_trigger
    BEFORE INSERT OR UPDATE
    ON documents
    FOR EACH ROW
EXECUTE FUNCTION documents_search_vector_update();

-- Document examples full-text search
CREATE INDEX IF NOT EXISTS idx_document_examples_search ON document_examples USING GIN (search_vector);

CREATE OR REPLACE FUNCTION document_examples_search_vector_update()
    RETURNS trigger AS
'
    BEGIN
        NEW.search_vector :=
                setweight(to_tsvector(''english'', COALESCE(NEW.title, '''')), ''A'') ||
                setweight(to_tsvector(''english'', COALESCE(NEW.description, '''')), ''B'');
        RETURN NEW;
    END;
' LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS document_examples_search_vector_trigger ON document_examples;
CREATE TRIGGER document_examples_search_vector_trigger
    BEFORE INSERT OR UPDATE
    ON document_examples
    FOR EACH ROW
EXECUTE FUNCTION document_examples_search_vector_update();
