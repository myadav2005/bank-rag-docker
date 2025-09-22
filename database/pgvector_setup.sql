CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS transaction_embeddings (
    txn_id BIGINT PRIMARY KEY REFERENCES transactions(id) ON DELETE CASCADE,
    embedding vector(384) NOT NULL
);
