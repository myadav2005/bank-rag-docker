# Bank RAG System (Dockerized)

A Retrieval-Augmented Generation (RAG) system for banking data.

## Features
- Laravel backend (PHP)
- Python Flask embedding service
- Local LLaMA model (via Ollama / llama.cpp)
- Direct connection to live bank database
- Optional caching of embeddings using pgvector

## Requirements
- Docker & Docker Compose
- PostgreSQL with pgvector
- Bank database credentials
- Local LLaMA model files

## Setup

1. Copy `.env.example` → `.env` and set DB credentials
2. (Optional) Run `database/pgvector_setup.sql` if you want caching
3. Start stack:

```bash
docker-compose up --build
