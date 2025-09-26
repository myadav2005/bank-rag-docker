# Bank RAG Docker System

A complete Retrieval-Augmented Generation (RAG) system for banking queries using Docker containers. This system combines Laravel API, PostgreSQL with pgvector, Python embedding service, and Ollama LLM to provide intelligent banking assistance.

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- At least 4GB RAM available for Ollama LLM
- 8GB+ free disk space for models

### One-Command Setup
```bash
git clone <your-repo-url>
cd bank-rag-docker
docker compose up --build -d
```

Wait for all services to start (2-3 minutes), then the system will be ready!

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Laravel API   │    │  Python Flask    │    │   PostgreSQL    │
│   (Port 8000)   │◄──►│   (Port 5001)    │    │  + pgvector     │
│                 │    │  Embeddings      │    │   (Port 5432)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                                               │
         ▼                                               │
┌─────────────────┐                                     │
│  Ollama LLM     │                                     │
│  (Port 11434)   │◄────────────────────────────────────┘
│  llama3.2:1b    │
└─────────────────┘
```

## 📋 Services Overview

| Service | Port | Purpose | Technology |
|---------|------|---------|------------|
| **Laravel API** | 8000 | Main application & RAG orchestration | PHP 8.2, Laravel 12 |
| **PostgreSQL** | 5432 | Database with vector search | PostgreSQL 15 + pgvector |
| **Python Flask** | 5001 | Text embedding generation | Python 3.10, sentence-transformers |
| **Ollama LLM** | 11434 | Local language model | Ollama with llama3.2:1b |

## ✨ Features
- **Smart Banking Queries** - Ask questions about transactions in natural language
- **Vector Search** - Semantic search through banking data using embeddings
- **Local LLM** - Privacy-focused local language model (no external API calls)
- **RESTful API** - Clean API endpoints for integration
- **Docker Compose** - One-command deployment
- **Health Monitoring** - Built-in health checks for all services

## 🛠️ Setup Instructions

### Step 1: Clone Repository
```bash
git clone <your-repo-url>
cd bank-rag-docker
```

### Step 2: Start Services
```bash
# Start all services (this will take 2-3 minutes on first run)
docker compose up --build -d

# Check if all services are running
docker ps
```

### Step 3: Install LLM Model
The system will automatically download the Llama model on first startup. If you need to manually install:
```bash
# Install llama3.2:1b model (recommended for development)
docker exec llama ollama pull llama3.2:1b

# Or install larger model for better responses (requires more RAM)
docker exec llama ollama pull llama3.2:3b
```

### Step 4: Initialize Database
```bash
# Run database migrations
docker exec laravel php artisan migrate --force

# Insert sample banking data
docker exec postgres psql -U postgres -d bankrag -c "
INSERT INTO transactions (amount, description) VALUES 
(100.50, 'Salary deposit'), 
(-25.00, 'Coffee shop'), 
(-150.00, 'Grocery shopping'), 
(500.00, 'Freelance payment'), 
(-50.00, 'Gas station');"
```

### Step 5: Verify Installation
```bash
# Test health endpoints
curl http://localhost:8000/api/health
curl http://localhost:5001/health
curl http://localhost:11434/api/version

# Test RAG system
curl -X POST http://localhost:8000/api/test/ask \
  -H "Content-Type: application/json" \
  -d '{"query": "What was my largest transaction?"}'
```

## 🧪 API Usage

### Health Checks
```bash
# Overall system health
GET http://localhost:8000/api/health

# Individual service health
GET http://localhost:8000/api/test/ping
GET http://localhost:8000/api/test/python  
GET http://localhost:8000/api/test/ollama
```

### RAG Queries
```bash
# Test endpoint (no authentication)
POST http://localhost:8000/api/test/ask
Content-Type: application/json
{
  "query": "How much did I spend on groceries?"
}

# Protected endpoint (requires Sanctum auth)
POST http://localhost:8000/api/ask
Authorization: Bearer {token}
Content-Type: application/json
{
  "query": "Show me my recent transactions"
}
```

### Sample Queries to Try
- "What was my largest transaction?"
- "How much did I spend on food?"
- "Show me all my deposits"
- "What's my account balance based on these transactions?"

## 🐳 Docker Services Configuration

### Service Dependencies
- **Laravel** depends on PostgreSQL health check
- **PostgreSQL** includes pgvector extension for vector operations
- **Python Flask** runs independently 
- **Ollama** runs independently with persistent model storage

### Volumes
- `postgres_data` - PostgreSQL database persistence
- `ollama_data` - Ollama models and configuration persistence

### Networks
All services communicate via Docker's internal network using service names:
- `postgres:5432` - Database connection
- `python-flask:5001` - Embedding service
- `llama:11434` - LLM service

## 🔧 Development

### Adding New Queries
1. Update `app/Http/Controllers/Api/RagController.php` for custom logic
2. Add routes in `routes/api.php`
3. Rebuild Laravel container: `docker compose up --build -d laravel`

### Database Schema Changes
1. Create migrations: `docker exec laravel php artisan make:migration create_new_table`
2. Run migrations: `docker exec laravel php artisan migrate`

### Updating Models
```bash
# Pull different Ollama model
docker exec llama ollama pull mistral:7b

# Update RagController to use new model
# Edit app/Http/Controllers/Api/RagController.php
# Change 'model' => 'llama3.2:1b' to 'model' => 'mistral:7b'
```

## 📊 Monitoring

### Check Service Status
```bash
# Container status
docker ps

# Service logs
docker logs laravel
docker logs postgres  
docker logs python-flask
docker logs llama

# Resource usage
docker stats
```

### Database Access
```bash
# Connect to PostgreSQL
docker exec -it postgres psql -U postgres -d bankrag

# View transactions
SELECT * FROM transactions;

# Check pgvector extension
\dx
```

## 🚨 Troubleshooting

### Common Issues

**Port Conflicts**
```bash
# Stop local PostgreSQL if running
sudo systemctl stop postgresql

# Check port usage
sudo lsof -i :8000
sudo lsof -i :5432
```

**Container Won't Start**
```bash
# Check logs for specific service
docker logs <container_name>

# Restart all services
docker compose down
docker compose up --build -d
```

**Out of Memory (Ollama)**
```bash
# Use smaller model
docker exec llama ollama pull llama3.2:1b

# Check available memory
free -h
docker stats
```

**Database Connection Issues**
```bash
# Verify PostgreSQL is healthy
docker exec postgres pg_isready -U postgres

# Check Laravel database connection
docker exec laravel php artisan migrate:status
```

## 🔒 Security Notes

- **Development Only**: This setup is for development/testing
- **No Authentication**: Test endpoints don't require authentication
- **Local Network**: Services communicate over Docker network
- **Data Persistence**: Database and models persist in Docker volumes

## 🚀 Production Deployment

For production deployment:
1. Add proper authentication and authorization
2. Use environment-specific configurations
3. Set up SSL/HTTPS
4. Configure proper backup strategies
5. Implement monitoring and logging
6. Use production-grade models and scaling

## 📝 License

[Your License Here]

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

## 📁 Project Structure

```
bank-rag-docker/
├── README.md                 # Main documentation
├── setup.sh                 # Automated setup script
├── Makefile                 # Convenient management commands
├── docker-compose.yml       # Main Docker configuration
├── docker-compose.prod.yml  # Production overrides
├── .gitignore               # Git ignore rules
├── API.md                   # Complete API documentation
├── TROUBLESHOOTING.md       # Troubleshooting guide
├── SETUP_COMPLETE.md        # Setup completion guide
├── laravel-backend/         # Laravel API application
│   ├── Dockerfile          # Laravel container configuration
│   ├── .env                # Laravel environment variables
│   ├── app/Http/Controllers/Api/RagController.php
│   ├── routes/api.php      # API routes definition
│   └── bootstrap/app.php   # Laravel bootstrap with API routes
├── python-embedding-service/ # Python Flask embedding service
│   ├── Dockerfile          # Python container configuration
│   ├── embedding_service.py # Flask application
│   └── requirements.txt    # Python dependencies
├── database/               # Database initialization
│   └── pgvector_setup.sql # PostgreSQL vector extension setup
└── demo/                  # Demo and test scripts
    └── test_rag.php       # PHP demo script
```

## 🔗 Additional Resources

- **[API Documentation](API.md)** - Complete API reference and examples
- **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Solutions for common issues
- **[Setup Complete Guide](SETUP_COMPLETE.md)** - Detailed setup verification

## 📋 Management Commands (Makefile)

The project includes a comprehensive Makefile for easy management:

```bash
make help           # Show all available commands
make setup          # Complete automated setup
make health         # Check all service health
make test           # Test RAG system
make logs           # View all service logs
make restart        # Restart all services
make clean          # Clean up containers and volumes
make shell-laravel  # Access Laravel container shell
make migrate        # Run database migrations
make model-install  # Install Ollama model
```

## 🐳 Docker Configuration Files

- **`docker-compose.yml`** - Main configuration for all services
- **`docker-compose.override.yml`** - Development overrides (auto-loaded)
- **`docker-compose.prod.yml`** - Production configuration
- **`setup.sh`** - Automated setup script with health checks

## 🔧 Environment Configuration

### Laravel (.env)
```bash
# Database Configuration
DB_CONNECTION=pgsql
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=bankrag
DB_USERNAME=postgres
DB_PASSWORD=postgres

# Service URLs (Docker internal networking)
PYTHON_EMBEDDING_SERVICE_URL=http://python-flask:5001
OLLAMA_SERVICE_URL=http://llama:11434
```

### Python (requirements.txt)
```
flask==3.0.0
sentence-transformers==2.2.2
torch>=2.0.0
transformers>=4.32.0
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Test thoroughly: `make test`
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- **Documentation**: Check [API.md](API.md) for detailed API reference
- **Issues**: Review [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common problems
- **Logs**: Use `make logs` or `docker logs <service_name>` for debugging
- **Health Check**: Run `make health` to verify all services
- **Community**: Open an issue for questions or bug reports

---

**🎉 Ready to build intelligent banking applications with RAG!**
- **Direct PostgreSQL connection** - Live bank database integration
- **Optional pgvector caching** - Vector similarity search for embeddings

## 📋 Prerequisites

Before setting up, ensure you have:
- **Docker** and **Docker Compose** installed
- A **PostgreSQL database** with banking data
- **Bank database credentials**

## 🛠️ Local Setup

### 1. Clone and Navigate to Project
```bash
git clone <your-repo-url>
cd bank-rag-docker
```

### 2. Configure Environment Variables
Create and configure your `.env` file in the root directory:

```bash
# Copy the example file (if available) or create new one
cp .env.example .env
```

**Update the following variables in `.env`:**
```properties
APP_NAME=BankRAG
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

# Database Configuration
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1          # Your PostgreSQL server host
DB_PORT=5432               # Your PostgreSQL port
DB_DATABASE=bankrag        # Your bank database name
DB_USERNAME=postgres       # Your database username
DB_PASSWORD=postgres       # Your database password

# Optional: API Token for testing
API_TOKEN=your_api_token_here
```

### 3. (Optional) Set up pgvector for Embedding Cache
If you want to cache embeddings for better performance:

```sql
-- Connect to your PostgreSQL database and run:
-- Run the SQL commands from database/pgvector_setup.sql
```

### 4. Build and Start Docker Services
```bash
# Build and start all services in detached mode
docker compose up --build -d
```

### 5. Verify Services are Running
```bash
# Check container status
docker compose ps
```

You should see all three services running:
- **laravel** (port 8000)
- **python-flask** (port 5001) 
- **llama** (port 11434)

## 🎯 Service Architecture

| Service | Purpose | Port | Access URL |
|---------|---------|------|------------|
| **Laravel Backend** | API endpoints, database integration | 8000 | http://localhost:8000 |
| **Python Embedding Service** | Text embeddings generation | 5001 | http://localhost:5001 |
| **Ollama LLM Service** | Language model inference | 11434 | http://localhost:11434 |

## 🧪 Testing the Setup

### Test Laravel API:
```bash
curl http://localhost:8000/api/health
```

### Test Python Embedding Service:
```bash
curl http://localhost:5001/embed -X POST \
  -H "Content-Type: application/json" \
  -d '{"text":"test banking query"}'
```

### Test Ollama Service:
```bash
curl http://localhost:11434/api/version
```

## 🤖 Installing LLM Models

Install a language model in Ollama:

```bash
# Install a lightweight model (recommended for testing)
docker exec -it llama ollama pull llama3.2:3b

# Or install a larger model (requires more resources)
docker exec -it llama ollama pull llama3.2:7b
```

List installed models:
```bash
docker exec -it llama ollama list
```

## 📁 Project Structure

```
bank-rag-docker/
├── docker-compose.yml          # Docker services configuration
├── .env                       # Environment variables
├── README.md                  # This file
├── database/
│   └── pgvector_setup.sql     # Optional vector database setup
├── demo/
│   └── test_rag.php          # Demo RAG implementation
├── laravel-backend/
│   ├── Dockerfile            # Laravel container configuration
│   ├── app/Http/Controllers/Api/
│   │   └── RagController.php # RAG API controller
│   └── routes/api.php        # API routes
├── python-embedding-service/
│   ├── Dockerfile            # Python service container
│   └── embedding_service.py  # Embedding generation service
└── llama-model/              # Ollama model storage
```

## �� Development Workflow

1. **Start the services**: `docker compose up -d`
2. **View logs**: `docker compose logs -f [service-name]`
3. **Stop services**: `docker compose down`
4. **Rebuild after changes**: `docker compose up --build -d`

## 🐛 Troubleshooting

### Common Issues:

**Docker Permission Errors:**
```bash
sudo usermod -aG docker $USER
newgrp docker
```

**Port Already in Use:**
```bash
# Check what's using the port
sudo lsof -i :8000
# Kill the process or change ports in docker-compose.yml
```

**Database Connection Issues:**
- Verify your PostgreSQL server is running
- Check database credentials in `.env`
- Ensure PostgreSQL accepts connections from Docker containers

**Ollama Model Issues:**
```bash
# Check available models
docker exec -it llama ollama list

# Pull a specific model
docker exec -it llama ollama pull llama3.2:3b
```

## 📚 API Documentation

### Laravel RAG API Endpoints

**POST /api/rag/query**
```json
{
  "question": "What is my account balance?",
  "context": "optional additional context"
}
```

**GET /api/health**
- Returns system health status

### Python Embedding Service

**POST /embed**
```json
{
  "text": "Text to embed"
}
```

Returns vector embeddings for the input text.

## 🔒 Security Notes

- Change default database passwords in production
- Set `APP_DEBUG=false` in production
- Use environment-specific `.env` files
- Implement proper authentication for API endpoints

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.
