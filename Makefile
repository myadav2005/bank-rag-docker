# Bank RAG Docker Makefile
# Provides convenient commands for managing the Bank RAG system

.PHONY: help build start stop restart logs health test clean setup

# Default target
help: ## Show this help message
	@echo "Bank RAG Docker Management"
	@echo "=========================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Quick Start: make setup"

setup: ## Complete setup - build, start, and initialize the system
	@echo "🚀 Setting up Bank RAG system..."
	./setup.sh

build: ## Build all Docker containers
	@echo "🔨 Building containers..."
	docker compose build

start: ## Start all services
	@echo "🚀 Starting services..."
	docker compose up -d

stop: ## Stop all services
	@echo "🛑 Stopping services..."
	docker compose down

restart: ## Restart all services
	@echo "🔄 Restarting services..."
	docker compose down && docker compose up -d

logs: ## Show logs for all services
	@echo "📋 Showing logs..."
	docker compose logs -f

logs-laravel: ## Show Laravel logs only
	docker logs -f laravel

logs-postgres: ## Show PostgreSQL logs only
	docker logs -f postgres

logs-python: ## Show Python Flask logs only
	docker logs -f python-flask

logs-ollama: ## Show Ollama logs only
	docker logs -f llama

health: ## Check health of all services
	@echo "🏥 Checking service health..."
	@echo "Laravel API:"
	@curl -s http://localhost:8000/api/health | python3 -m json.tool || echo "❌ Laravel not responding"
	@echo ""
	@echo "Python Flask:"
	@curl -s http://localhost:5001/health | python3 -m json.tool || echo "❌ Python Flask not responding"
	@echo ""
	@echo "Ollama:"
	@curl -s http://localhost:11434/api/version | python3 -m json.tool || echo "❌ Ollama not responding"
	@echo ""
	@echo "Container Status:"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

test: ## Run a test RAG query
	@echo "🧪 Testing RAG system..."
	@curl -X POST http://localhost:8000/api/test/ask \
		-H "Content-Type: application/json" \
		-d '{"query": "What was my largest transaction?"}' \
		| python3 -c "import sys, json; data=json.loads(sys.stdin.read()); print('✅ RAG Test Success!\\nResponse:', data.get('answer', 'No answer')[:200] + '...')" \
		|| echo "❌ RAG test failed"

shell-laravel: ## Access Laravel container shell
	docker exec -it laravel bash

shell-postgres: ## Access PostgreSQL container shell
	docker exec -it postgres psql -U postgres -d bankrag

shell-python: ## Access Python Flask container shell
	docker exec -it python-flask bash

shell-ollama: ## Access Ollama container shell
	docker exec -it llama bash

migrate: ## Run Laravel database migrations
	docker exec laravel php artisan migrate --force

migrate-fresh: ## Fresh migration with sample data
	docker exec laravel php artisan migrate:fresh --force
	@$(MAKE) seed

seed: ## Insert sample banking data
	@echo "🌱 Seeding database..."
	docker exec postgres psql -U postgres -d bankrag -c "\
		INSERT INTO transactions (amount, description) VALUES \
		(100.50, 'Salary deposit'), \
		(-25.00, 'Coffee shop'), \
		(-150.00, 'Grocery shopping'), \
		(500.00, 'Freelance payment'), \
		(-50.00, 'Gas station') \
		ON CONFLICT DO NOTHING;"

model-install: ## Install default Ollama model
	@echo "🧠 Installing Ollama model..."
	docker exec llama ollama pull llama3.2:1b

model-install-large: ## Install larger Ollama model (requires more RAM)
	@echo "🧠 Installing larger Ollama model..."
	docker exec llama ollama pull llama3.2:3b

model-list: ## List installed Ollama models
	@echo "📋 Installed models:"
	docker exec llama ollama list

clean: ## Remove all containers, networks, and volumes
	@echo "🧹 Cleaning up..."
	docker compose down -v --remove-orphans
	docker system prune -f

clean-all: ## Remove everything including images
	@echo "🧹 Deep cleaning..."
	docker compose down -v --remove-orphans --rmi all
	docker system prune -af --volumes

dev: ## Start in development mode with hot reloading
	@echo "🔧 Starting development environment..."
	docker compose -f docker-compose.yml -f docker-compose.override.yml up -d

prod: ## Start in production mode
	@echo "🚀 Starting production environment..."
	docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

backup-db: ## Backup PostgreSQL database
	@echo "💾 Creating database backup..."
	docker exec postgres pg_dump -U postgres bankrag > backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "Backup created: backup_$(shell date +%Y%m%d_%H%M%S).sql"

stats: ## Show Docker container statistics
	docker stats --no-stream

ps: ## Show running containers
	docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Size}}"

update: ## Update and rebuild containers
	@echo "🔄 Updating containers..."
	git pull
	docker compose build --pull
	docker compose up -d

# Development shortcuts
dev-logs: ## Show development logs
	docker compose -f docker-compose.yml -f docker-compose.override.yml logs -f

dev-shell: ## Quick Laravel development shell
	docker exec -it laravel bash