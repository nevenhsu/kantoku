# Code Maps Overview

Last Updated: 2026-01-25

Overview: This codemap documents the current software architecture and how the four n8n workflows collaborate with the application layers.

## Areas
- Frontend (UI) and API boundaries
- Backend/API (n8n Workflows)
- Database & data models
- Integrations & external services
- Background workers & queues

## Current Workflows Mocalization
- Workflow 1: Generate Tasks
- Workflow 2: Review Submissions
- Workflow 3: Generate Tests
- Workflow 4: Grade Tests

## Entry Points
- n8n Workflows directory: n8n-workflows/
- API endpoints and API routes (where applicable)

## Data Flow Summary
- Data flows through the API layer to the database, with AI-assisted processing via the n8n workflows, and results emitted back to the client or stored for audit.

## Exports & Dependencies
- n8n-workflows packages and internal script integrations
- External services: OpenAI/AI models, database connections, etc.

## Related Areas
- See docs/CODEMAPS/WORKFLOW_DESIGN.md for a detailed design discussion (if available).
