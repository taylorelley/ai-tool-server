# Langflow + Supabase Integration Guide

## 🎯 Overview

This stack is designed so that Langflow can use Supabase as its backend for:
- **PostgreSQL Database** - Store and retrieve data in flows
- **Vector Database** - Embeddings and similarity search (pgvector)
- **Storage** - File uploads and downloads
- **Authentication** - User management
- **Realtime** - WebSocket subscriptions
- **Edge Functions** - Serverless function calls

Both Langflow and Open WebUI have direct access to all Supabase services through the shared network.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     AI Tools Layer                          │
│  ┌──────────┐  ┌────────────┐  ┌────────────┐             │
│  │ Langflow │  │ Open WebUI │  │ Playwright │             │
│  └────┬─────┘  └─────┬──────┘  └────────────┘             │
│       │              │                                      │
└───────┼──────────────┼──────────────────────────────────────┘
        │              │
        └──────┬───────┘
               │ (Shared Network Access)
               ▼
┌─────────────────────────────────────────────────────────────┐
│                   Supabase Backend                          │
│  ┌──────┐  ┌──────┐  ┌─────────┐  ┌────────┐  ┌─────────┐ │
│  │ Kong │  │ Auth │  │ Storage │  │  REST  │  │ Realtime│ │
│  │ (API)│  │      │  │         │  │        │  │         │ │
│  └──┬───┘  └──┬───┘  └────┬────┘  └───┬────┘  └────┬────┘ │
│     └─────────┴───────────┴───────────┴────────────┘      │
│                           │                                 │
│                    ┌──────▼───────┐                        │
│                    │  PostgreSQL   │                        │
│                    │  (+ pgvector) │                        │
│                    └──────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

## 🔑 Connection Details Available in Langflow

All these environment variables are automatically configured:

```python
# Supabase API Access (REST, Auth, Storage, Realtime)
SUPABASE_URL = "http://kong:8000"
SUPABASE_ANON_KEY = "your-anon-key"
SUPABASE_SERVICE_KEY = "your-service-role-key"

# Direct PostgreSQL Access
SUPABASE_DB_HOST = "db"
SUPABASE_DB_PORT = "5432"
SUPABASE_DB_NAME = "postgres"
SUPABASE_DB_USER = "postgres"
SUPABASE_DB_PASSWORD = "your-postgres-password"
```

## 📚 Usage Examples in Langflow

### 1. PostgreSQL Database Component

**Connection Settings:**
- Host: `db`
- Port: `5432`
- Database: `postgres`
- User: `postgres`
- Password: (from `.env`)

**Example:**
```sql
-- Store chat history
INSERT INTO chat_history (session_id, message) 
VALUES ('session-123', 'Hello world');

-- Query history
SELECT * FROM chat_history WHERE session_id = 'session-123';
```

### 2. Supabase REST API

Use the **API Request** component:

- URL: `http://kong:8000/rest/v1/your_table`
- Headers:
  ```json
  {
    "apikey": "${SUPABASE_ANON_KEY}",
    "Authorization": "Bearer ${SUPABASE_ANON_KEY}"
  }
  ```

### 3. Vector Search (pgvector)

```sql
-- Enable extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create table
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    content TEXT,
    embedding vector(1536)
);

-- Similarity search
SELECT content 
FROM documents
ORDER BY embedding <=> '[0.1, 0.2, ...]'::vector
LIMIT 5;
```

### 4. File Storage

```python
# Upload
url = f"http://kong:8000/storage/v1/object/bucket/file.pdf"
requests.post(url, files={'file': f}, headers=headers)

# Download
url = f"http://kong:8000/storage/v1/object/bucket/file.pdf"
requests.get(url, headers=headers)
```

## 🔐 Security

Use **Service Role Key** for admin operations:
```python
headers = {"apikey": os.getenv("SUPABASE_SERVICE_KEY")}
```

Use **Anon Key** for user-facing operations with RLS:
```python
headers = {"apikey": os.getenv("SUPABASE_ANON_KEY")}
```

## 🧪 Testing

```bash
# Test PostgreSQL
docker compose exec db psql -U postgres -c "SELECT version();"

# Test API
ANON_KEY=$(grep ANON_KEY .env | cut -d= -f2)
curl "http://localhost:8000/rest/v1/" -H "apikey: $ANON_KEY"
```

## 🎓 Complete Example: Chatbot with Memory

**Flow:**
1. Chat Input → Get message
2. PostgreSQL Query → Fetch history
3. Prompt Template → Format context
4. OpenAI LLM → Generate response
5. PostgreSQL Insert → Store conversation

**Supabase Setup:**
```sql
CREATE TABLE chat_history (
    id BIGSERIAL PRIMARY KEY,
    session_id TEXT NOT NULL,
    role TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
```

See full documentation in the main README!