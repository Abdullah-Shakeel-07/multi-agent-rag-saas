-- Multi-Agent RAG SaaS — initial schema for a FRESH database (Supabase / Postgres).
--
-- Chat-only: companies, company_users, guest_sessions, chats, messages,
-- knowledge_bases, documents, webhook_events. No voice/appointment tables.
--
-- NOTE: the original project never captured its base tables in migrations, so
-- this file was reconstructed from what the repository code reads/writes plus
-- the old ALTER migrations (001/002/003/007) folded in. Before relying on it,
-- diff it against the existing database (e.g. `pg_dump --schema-only` of the
-- chat tables) and adjust types/constraints if they differ.
--
-- Also create a PUBLIC Storage bucket named "documents" (the API tries to
-- auto-create it on first upload).

-- ── companies ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS companies (
    company_id             TEXT PRIMARY KEY,
    name                   TEXT NOT NULL,
    slug                   TEXT NOT NULL UNIQUE,
    email                  TEXT UNIQUE,
    password_hash          TEXT,
    api_keys               TEXT,
    chatbot_title          TEXT,
    chatbot_description    TEXT,
    is_published           BOOLEAN NOT NULL DEFAULT FALSE,
    published_at           TIMESTAMPTZ,
    settings               JSONB NOT NULL DEFAULT '{}'::jsonb,   -- embed config + enable_user_portal
    -- AI settings
    default_model          TEXT DEFAULT 'Llama-instant',
    system_prompt          TEXT,
    tone                   TEXT DEFAULT 'professional',
    -- UI
    theme_preference       TEXT NOT NULL DEFAULT 'system'
                             CHECK (theme_preference IN ('light', 'dark', 'system')),
    -- Billing (LemonSqueezy)
    plan                   TEXT NOT NULL DEFAULT 'free',
    ls_customer_id         TEXT,
    ls_subscription_id     TEXT,
    ls_subscription_status TEXT DEFAULT 'none',
    subscription_ends_at   TIMESTAMPTZ,
    subscription_renews_at TIMESTAMPTZ,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_companies_ls_subscription ON companies (ls_subscription_id);
CREATE INDEX IF NOT EXISTS idx_companies_api_keys ON companies (api_keys);

-- ── company_users (end users of a company's chatbot) ────────────────────
CREATE TABLE IF NOT EXISTS company_users (
    user_id       TEXT PRIMARY KEY,
    company_id    TEXT NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    email         TEXT NOT NULL,
    name          TEXT,
    password_hash TEXT,
    is_anonymous  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (company_id, email)
);

-- ── guest_sessions ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS guest_sessions (
    session_id TEXT PRIMARY KEY,
    company_id TEXT NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    ip_address TEXT,
    user_agent TEXT,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_guest_sessions_company ON guest_sessions (company_id);

-- ── chats ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chats (
    chat_id    TEXT PRIMARY KEY,
    company_id TEXT NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    user_id    TEXT,
    session_id TEXT,
    title      TEXT DEFAULT 'New Chat',
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    is_guest   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_chats_company ON chats (company_id, is_deleted, created_at DESC);

-- ── messages ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS messages (
    message_id TEXT PRIMARY KEY,
    company_id TEXT NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    chat_id    TEXT NOT NULL,
    role       TEXT NOT NULL,                 -- 'human' | 'ai'
    content    TEXT NOT NULL,
    timestamp  BIGINT,                        -- epoch milliseconds
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_messages_chat ON messages (company_id, chat_id, created_at);

-- ── knowledge_bases / documents ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS knowledge_bases (
    kb_id      TEXT PRIMARY KEY,
    company_id TEXT NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    name       TEXT NOT NULL DEFAULT 'Default KB',
    file_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_knowledge_bases_company ON knowledge_bases (company_id);

CREATE TABLE IF NOT EXISTS documents (
    doc_id            TEXT PRIMARY KEY,
    kb_id             TEXT NOT NULL REFERENCES knowledge_bases(kb_id) ON DELETE CASCADE,
    filename          TEXT NOT NULL,
    content           TEXT,
    content_type      TEXT DEFAULT 'text/plain',
    file_size         INTEGER,
    embeddings_status TEXT NOT NULL DEFAULT 'pending',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_documents_kb ON documents (kb_id, created_at DESC);

-- ── webhook_events (LemonSqueezy idempotency + audit) ───────────────────
CREATE TABLE IF NOT EXISTS webhook_events (
    id                 TEXT PRIMARY KEY,
    event_id           TEXT UNIQUE NOT NULL,
    event_name         TEXT NOT NULL,
    company_id         TEXT,
    ls_subscription_id TEXT,
    processed          BOOLEAN DEFAULT TRUE,
    error              TEXT,
    created_at         TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_webhook_events_company_id ON webhook_events (company_id);
