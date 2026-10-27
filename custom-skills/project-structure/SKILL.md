---
name: project-structure
description: Dedicated Project Structure & Clean Architecture skill and subagent workflow for designing, scaffolding, and reorganizing folder structures by language/framework (Next.js, React, NestJS, Node.js, Go, Python, Rust, Monorepo). Use for /project-structure, setting up new projects, cleaning up messy directories, or deciding where files belong.
---

# Project Structure & Clean Architecture (`project-structure`)

Act as a **Principal Software Architect** specializing in repository organization, modular boundaries, and language-idiomatic folder structures.

---

## 1. Core Folder Organization Principles

1. **Feature/Domain Colocation over Technical Sprawl (`principle-model-the-domain`):**
   - Group closely related files by **domain/feature** (`features/auth/`, `modules/billing/`) rather than dumping hundreds of unrelated files into global `controllers/`, `helpers/`, or `utils/` folders.
   - Reserve top-level `shared/` or `lib/` strictly for genuinely cross-cutting, domain-agnostic code.
2. **Strict Layer & Dependency Direction (`principle-boundary-discipline`):**
   - Dependencies flow **inward**: `UI / Controllers / CLI` -> `Application / Use-Cases / Services` -> `Domain Models / Pure Logic` <- `Infrastructure / DB / External APIs`.
   - Domain logic must never import UI components, HTTP request objects, or raw database drivers directly.
3. **No Junk-Drawer Directories (`principle-minimize-reader-load`):**
   - Avoid vague folder/file names like `misc/`, `common2/`, ` helpers.ts`, or `new-utils.ts`. Name every module after the exact domain or capability it owns.

---

## 2. Idiomatic Blueprints by Language & Framework

When scaffolding or reorganizing a project, follow the idiomatic standard of its language:

### TypeScript / Next.js (App Router + Feature-Based)
```text
src/
├── app/                  # Routing, layouts, and page entry points only (thin layer)
├── features/             # Domain modules (e.g., auth/, documents/,transfers/)
│   └── <feature>/
│       ├── components/   # Feature-specific UI components
│       ├── hooks/        # Feature-specific client hooks
│       ├── actions.ts    # Server actions / API callers
│       ├── service.ts    # Pure business logic & validation
│       └── types.ts      # Domain types & schemas
├── components/ui/        # Reusable design-system primitives (buttons, modals)
├── lib/                  # Infrastructure clients (db, auth client, logger)
└── types/                # Global shared type definitions
```

### TypeScript / NestJS (Modular Clean Architecture)
```text
src/
├── common/               # Guards, interceptors, filters, decorators, pipes
├── config/               # Typed environment & configuration schemas
├── database/             # Prisma / TypeORM setup & migrations
└── modules/
    └── <domain>/
        ├── dto/          # Input/Output validation DTOs (boundary guards)
        ├── entities/     # Domain models & types
        ├── <domain>.controller.ts
        ├── <domain>.service.ts
        └── <domain>.module.ts
```

### Go (Standard Go Project Layout)
```text
├── cmd/
│   └── <app-name>/main.go  # Entry point & dependency wiring only
├── internal/               # Private application packages (enforced by Go compiler)
│   ├── domain/             # Core entities & interfaces
│   ├── service/            # Business use-cases
│   ├── handler/            # HTTP / gRPC transport handlers
│   └── repository/         # Database implementations
├── pkg/                    # Public libraries safe for external import (if any)
└── go.mod
```

### Python (FastAPI / Modern `src` Layout)
```text
src/
└── <package_name>/
    ├── main.py             # FastAPI app initialization & routers
    ├── core/               # Config, security, logging, dependencies
    ├── modules/
    │   └── <domain>/
    │       ├── router.py   # Endpoints
    │       ├── schemas.py  # Pydantic models
    │       ├── service.py  # Business logic
    │       └── models.py   # ORM models
    └── db/                 # Session management & migrations
tests/                      # Mirrors src/ structure
```

---

## 3. Safe Folder Restructuring Workflow

When reorganizing an existing codebase:
1. **Map Current Layout (`/how`):** Spawn a `flash` research subagent to map existing imports and entry points.
2. **Check Impact (`/blast-radius`):** Identify path aliases (`tsconfig.json`, `package.json`, `go.mod`, Dockerfiles, CI scripts) affected by moving files.
3. **Move & Update Imports Atomically:** Move files, update all import paths and barrel exports, and delete empty directories (`principle-subtract-before-you-add`).
4. **Verify Build & Tests (`principle-prove-it-works`):** Run the compiler/typechecker and test suite to prove zero broken imports remain.

