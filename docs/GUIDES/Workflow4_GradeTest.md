# Workflow 4: Grade Test - Guide

Last Updated: 2026-01-25

Overview:
- Workflow 4 Grade Test implements AI-driven grading for generated tests, integrating with the existing n8n workflows and database models.

What to expect:
- Automates grading of tests, analyzes weak areas, and stores results for reporting.
- Interacts with Submissions data and related test entities.
- Provides hooks for observers or auditors to review grading decisions.

Prerequisites:
- Local n8n environment running with access to the n8n-workflows/Grade Test workflow JSON
- Access to the required database and AI service credentials (OPENAI_API_KEY or equivalent)

How to run:
- Start the local environment per SETUP_GUIDE.md
- Import and trigger the Workflow 4_ Grade Test.json in n8n
- Observe the grading events and review outputs in the database and/or UI

Validation tips:
- Ensure the Grade Test workflow processes a sample submission and produces a grade and feedback
- Check logs for AI API usage and failure modes
- Validate that results are persisted with correct foreign key relationships

Notes:
- This guide complements the high-level codemap; for precise steps, refer to the repository's Runbooks and internal docs.
