# API (FastAPI)

Planned layout:

```
api/
├── app/
│   ├── core/          config, database client, security, middleware, exceptions
│   ├── features/      one folder per domain (router → service → repository)
│   │   ├── auth/
│   │   ├── users/
│   │   ├── chat/
│   │   ├── documents/
│   │   ├── public/
│   │   ├── analytics/
│   │   └── billing/
│   ├── services/      shared building blocks
│   │   ├── rag/
│   │   └── document_processing/
│   ├── static/        embeddable chat widget
│   └── templates/
├── migrations/        SQL migrations
└── tests/
```
