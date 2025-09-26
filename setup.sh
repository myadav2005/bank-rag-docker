#!/bin/bash

# Bank RAG Docker Setup Script
# This script automates the complete setup of the Bank RAG system

set -e  # Exit on any error

echo "🚀 Starting Bank RAG Docker Setup..."
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker and Docker Compose first."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_info "Docker and Docker Compose are available ✓"

# Stop any existing containers
print_info "Stopping any existing containers..."
docker compose down -v 2>/dev/null || true

# Check for port conflicts
print_info "Checking for port conflicts..."
PORTS=(8000 5432 5001 11434)
for port in "${PORTS[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "Port $port is in use. You may need to stop the service using it."
        if [ "$port" -eq 5432 ]; then
            print_info "Attempting to stop local PostgreSQL..."
            sudo systemctl stop postgresql 2>/dev/null || true
        fi
    fi
done

# Build and start containers
print_info "Building and starting Docker containers (this may take 5-10 minutes)..."
docker compose up --build -d

# Wait for PostgreSQL to be ready
print_info "Waiting for PostgreSQL to be ready..."
timeout=60
counter=0
while ! docker exec postgres pg_isready -U postgres -d bankrag >/dev/null 2>&1; do
    if [ $counter -ge $timeout ]; then
        print_error "PostgreSQL failed to start within $timeout seconds"
        exit 1
    fi
    sleep 2
    counter=$((counter + 2))
    echo -n "."
done
print_status "PostgreSQL is ready"

# Run database migrations
print_info "Running Laravel database migrations..."
docker exec laravel php artisan migrate --force

# Insert sample data
print_info "Inserting sample banking data..."
docker exec postgres psql -U postgres -d bankrag -c "
INSERT INTO transactions (amount, description) VALUES 
(100.50, 'Salary deposit'), 
(-25.00, 'Coffee shop'), 
(-150.00, 'Grocery shopping'), 
(500.00, 'Freelance payment'), 
(-50.00, 'Gas station');" >/dev/null

print_status "Sample data inserted"

# Install Ollama model
print_info "Installing Ollama LLM model (this may take 2-5 minutes)..."
docker exec llama ollama pull llama3.2:1b

print_status "Ollama model installed"

# Wait for all services to be ready
print_info "Waiting for all services to be ready..."
sleep 10

# Test services
print_info "Testing service connectivity..."

# Test Laravel API
if curl -s http://localhost:8000/api/health >/dev/null; then
    print_status "Laravel API is responding"
else
    print_error "Laravel API is not responding"
    exit 1
fi

# Test Python Flask
if curl -s http://localhost:5001/health >/dev/null; then
    print_status "Python Flask service is responding"
else
    print_error "Python Flask service is not responding"
    exit 1
fi

# Test Ollama
if curl -s http://localhost:11434/api/version >/dev/null; then
    print_status "Ollama LLM service is responding"
else
    print_error "Ollama LLM service is not responding"
    exit 1
fi

# Test RAG system
print_info "Testing RAG system..."
RAG_RESPONSE=$(curl -s -X POST http://localhost:8000/api/test/ask \
  -H "Content-Type: application/json" \
  -d '{"query": "What was my largest transaction?"}')

if echo "$RAG_RESPONSE" | grep -q "answer"; then
    print_status "RAG system is working correctly"
else
    print_error "RAG system test failed"
    exit 1
fi

echo ""
echo "🎉 Setup Complete! Your Bank RAG system is ready to use."
echo "================================================"
echo ""
echo "📋 Service URLs:"
echo "   • Laravel API:    http://localhost:8000"
echo "   • PostgreSQL:     localhost:5432 (user: postgres, password: postgres, db: bankrag)"
echo "   • Python Flask:   http://localhost:5001"
echo "   • Ollama LLM:     http://localhost:11434"
echo ""
echo "🧪 Test Commands:"
echo "   • Health Check:   curl http://localhost:8000/api/health"
echo "   • RAG Query:      curl -X POST http://localhost:8000/api/test/ask -H 'Content-Type: application/json' -d '{\"query\": \"What was my largest transaction?\"}'"
echo ""
echo "📊 Monitor Services:"
echo "   • Container Status: docker ps"
echo "   • Service Logs:     docker logs [laravel|postgres|python-flask|llama]"
echo "   • Stop Services:    docker compose down"
echo ""
echo "📖 For more information, check README.md or SETUP_COMPLETE.md"
echo ""
print_status "Ready for banking queries! 🏦"