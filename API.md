# API Documentation

## Bank RAG API Reference

Base URL: `http://localhost:8000/api`

### Authentication

The API provides both authenticated and non-authenticated endpoints:
- **Test endpoints**: No authentication required (for development/testing)
- **Production endpoints**: Require Laravel Sanctum token authentication

## Endpoints

### Health & System Status

#### GET `/health`
Get overall system health status.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2025-09-24T07:19:55.588501Z",
  "services": {
    "laravel": "running",
    "database": "configured",
    "python_embedding": "available",
    "ollama_llm": "available"
  }
}
```

#### GET `/test/ping`
Simple ping test for Laravel API.

**Response:**
```json
{
  "message": "pong"
}
```

#### GET `/test/python`
Test connectivity to Python embedding service.

**Response:**
```json
{
  "python_service": "ok",
  "response": {
    "embedding": [0.011573463678359985, 0.025136182084679604, ...]
  }
}
```

#### GET `/test/ollama`
Test connectivity to Ollama LLM service.

**Response:**
```json
{
  "ollama_service": "ok",
  "response": {
    "version": "0.12.1"
  }
}
```

### RAG (Retrieval-Augmented Generation)

#### POST `/test/ask` (No Auth Required)
Submit a banking query to the RAG system for testing.

**Request:**
```json
{
  "query": "What was my largest transaction?"
}
```

**Response:**
```json
{
  "answer": "Based on your transaction history, your largest transaction was a freelance payment of $500.00..."
}
```

**Query Examples:**
- "What was my largest transaction?"
- "How much did I spend on groceries?" 
- "Show me all my deposits"
- "What's my account balance based on recent transactions?"

#### POST `/ask` (Auth Required)
Protected RAG endpoint requiring authentication.

**Headers:**
```
Authorization: Bearer {sanctum_token}
Content-Type: application/json
```

**Request:**
```json
{
  "query": "What are my recent spending patterns?"
}
```

**Response:**
```json
{
  "answer": "Based on your recent transactions, you've been spending primarily on essential items..."
}
```

### Error Responses

#### 400 Bad Request
```json
{
  "error": "Query is required"
}
```

#### 401 Unauthorized
```json
{
  "message": "Unauthenticated."
}
```

#### 500 Internal Server Error
```json
{
  "error": "Embedding service failed"
}
```

#### Service Errors
```json
{
  "python_service": "error",
  "message": "Connection refused"
}
```

## Usage Examples

### cURL Examples

#### Health Check
```bash
curl -X GET http://localhost:8000/api/health
```

#### Test RAG Query
```bash
curl -X POST http://localhost:8000/api/test/ask \
  -H "Content-Type: application/json" \
  -d '{"query": "What was my largest transaction?"}'
```

#### Protected RAG Query
```bash
curl -X POST http://localhost:8000/api/ask \
  -H "Authorization: Bearer your-token-here" \
  -H "Content-Type: application/json" \
  -d '{"query": "Show me my spending patterns"}'
```

### JavaScript/Fetch Examples

#### Basic RAG Query
```javascript
const response = await fetch('http://localhost:8000/api/test/ask', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    query: 'What was my largest transaction?'
  })
});

const data = await response.json();
console.log(data.answer);
```

#### With Authentication
```javascript
const response = await fetch('http://localhost:8000/api/ask', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer ' + token,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    query: 'How much did I spend this month?'
  })
});
```

### Python Examples

#### Using requests library
```python
import requests
import json

# Test endpoint
url = 'http://localhost:8000/api/test/ask'
data = {'query': 'What was my largest transaction?'}

response = requests.post(url, json=data)
result = response.json()
print(result['answer'])

# Protected endpoint
url = 'http://localhost:8000/api/ask'
headers = {'Authorization': 'Bearer your-token-here'}

response = requests.post(url, json=data, headers=headers)
result = response.json()
print(result['answer'])
```

## RAG System Architecture

The RAG (Retrieval-Augmented Generation) system works as follows:

1. **Query Processing**: User submits natural language query
2. **Embedding Generation**: Python service converts query to vector embedding
3. **Database Search**: PostgreSQL searches for relevant transactions using vector similarity
4. **Context Preparation**: Retrieved transactions are formatted as context
5. **LLM Generation**: Ollama generates response using query + context
6. **Response**: Final answer returned to user

### Sample Database Schema

**transactions table:**
```sql
CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    amount DECIMAL(10,2),
    description TEXT,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Sample Data:**
```sql
INSERT INTO transactions (amount, description) VALUES 
(100.50, 'Salary deposit'), 
(-25.00, 'Coffee shop'), 
(-150.00, 'Grocery shopping'), 
(500.00, 'Freelance payment'), 
(-50.00, 'Gas station');
```

## Rate Limiting

Currently no rate limiting is implemented. For production use, consider:
- Laravel's built-in rate limiting
- API throttling middleware
- Request quotas per user

## CORS

CORS is configured to allow all origins in development. For production:
- Configure specific allowed origins
- Set appropriate CORS headers
- Validate request origins

## Development vs Production

### Development Mode
- Test endpoints available without authentication
- Detailed error messages
- CORS allows all origins
- Debug information included

### Production Mode
- Authentication required for all sensitive endpoints
- Generic error messages
- Strict CORS policy
- No debug information leaked

## Extending the API

### Adding New Endpoints

1. **Create Controller Method:**
```php
// app/Http/Controllers/Api/RagController.php
public function customQuery(Request $request) {
    // Your logic here
}
```

2. **Add Route:**
```php
// routes/api.php
Route::post('/custom-ask', [RagController::class, 'customQuery']);
```

3. **Rebuild Container:**
```bash
docker compose up --build -d laravel
```

### Custom Embedding Models

To use different embedding models, update:
```python
# python-embedding-service/embedding_service.py
model = SentenceTransformer('your-model-name')
```

### Different LLM Models

To use different Ollama models:
```bash
# Install new model
docker exec llama ollama pull mistral:7b

# Update controller
# Change 'model' => 'llama3.2:1b' to 'model' => 'mistral:7b'
```

## Security Considerations

- **Authentication**: Implement proper user authentication for production
- **Input Validation**: Validate and sanitize all user inputs
- **Rate Limiting**: Implement rate limiting to prevent abuse
- **SQL Injection**: Use parameterized queries (already implemented)
- **CORS**: Configure appropriate CORS policies
- **HTTPS**: Use HTTPS in production environments
- **Secrets**: Store API keys and passwords securely