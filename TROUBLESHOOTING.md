# Troubleshooting Guide

## Common Issues and Solutions

### 1. Port Conflicts

**Problem**: Error messages like "port 5432 is already in use"

**Solutions**:
```bash
# Check which service is using the port
sudo lsof -i :5432
sudo lsof -i :8000

# Stop local PostgreSQL if running
sudo systemctl stop postgresql

# Or change ports in docker-compose.yml
# postgres:
#   ports:
#     - "5433:5432"  # Use port 5433 instead
```

### 2. Containers Won't Start

**Problem**: Containers exit immediately or fail to start

**Diagnosis**:
```bash
# Check container logs
docker logs laravel
docker logs postgres
docker logs python-flask
docker logs llama

# Check container status
docker ps -a
```

**Solutions**:
- **Laravel**: Check database connection, ensure migrations ran
- **PostgreSQL**: Verify volume permissions, check initialization scripts
- **Python**: Check requirements.txt, verify model downloads
- **Ollama**: Ensure sufficient memory (4GB+ recommended)

### 3. Out of Memory Issues

**Problem**: Ollama container crashes or system becomes unresponsive

**Solutions**:
```bash
# Use smaller model
docker exec llama ollama pull llama3.2:1b  # ~1.3GB
# Instead of llama3.2:3b  # ~2GB

# Check system memory
free -h
docker stats

# Limit container memory in docker-compose.yml
# llama:
#   deploy:
#     resources:
#       limits:
#         memory: 4G
```

### 4. Database Connection Errors

**Problem**: Laravel can't connect to PostgreSQL

**Diagnosis**:
```bash
# Test PostgreSQL connectivity
docker exec postgres pg_isready -U postgres

# Check Laravel database config
docker exec laravel php artisan config:show database

# Verify network connectivity
docker exec laravel ping postgres
```

**Solutions**:
- Ensure PostgreSQL is healthy before starting Laravel
- Check `.env` file database settings
- Verify Docker network configuration

### 5. Model Download Issues

**Problem**: Ollama models fail to download or take too long

**Solutions**:
```bash
# Manual model installation
docker exec llama ollama pull llama3.2:1b

# Check available models
docker exec llama ollama list

# Clear and retry
docker exec llama ollama rm llama3.2:1b
docker exec llama ollama pull llama3.2:1b

# Check disk space
df -h
docker system df
```

### 6. API Endpoints Return 404

**Problem**: Laravel API routes not found

**Diagnosis**:
```bash
# Check Laravel routes
docker exec laravel php artisan route:list

# Verify API installation
docker exec laravel php artisan about
```

**Solutions**:
- Ensure `php artisan install:api` was run
- Check `bootstrap/app.php` includes API routes
- Verify route files are copied correctly

### 7. RAG System Returns Errors

**Problem**: `/api/test/ask` returns error responses

**Diagnosis**:
```bash
# Test individual services
curl http://localhost:8000/api/health
curl http://localhost:5001/health
curl http://localhost:11434/api/version

# Check service connectivity from Laravel
curl http://localhost:8000/api/test/python
curl http://localhost:8000/api/test/ollama
```

**Solutions**:
- Verify all services are running and healthy
- Check Docker network connectivity between containers
- Ensure models are installed in Ollama
- Verify database has sample data

### 8. Slow Performance

**Problem**: RAG queries take too long or timeout

**Solutions**:
- Use smaller, faster models for development
- Increase timeout values in Laravel HTTP client
- Optimize database queries
- Consider caching embedding results

### 9. Development File Changes Not Reflected

**Problem**: Code changes don't appear in running containers

**Solutions**:
```bash
# Rebuild containers after code changes
docker compose up --build -d

# Or use development mode with volume mounts
make dev

# For Laravel only
docker compose up --build -d laravel
```

### 10. Permission Issues

**Problem**: File permission errors in containers

**Solutions**:
```bash
# Fix Laravel storage permissions
docker exec laravel chown -R www-data:www-data storage/
docker exec laravel chmod -R 755 storage/

# Fix volume permissions
sudo chown -R $USER:$USER ./laravel-backend/
```

## Emergency Recovery

### Complete Reset
```bash
# Stop everything
docker compose down -v

# Remove all containers, networks, volumes
docker system prune -af --volumes

# Start fresh
./setup.sh
```

### Partial Reset
```bash
# Reset database only
docker compose down postgres
docker volume rm bank-rag-docker_postgres_data
docker compose up -d postgres
make migrate-fresh

# Reset models only
docker volume rm bank-rag-docker_ollama_data
docker compose up -d llama
make model-install
```

## Performance Optimization

### For Low-Memory Systems
1. Use `llama3.2:1b` model (1.3GB vs 2GB+)
2. Limit container memory in docker-compose.yml
3. Close unnecessary applications
4. Consider using cloud-based LLM APIs instead

### For Better Performance
1. Use SSD storage for Docker volumes
2. Allocate more RAM to Docker Desktop
3. Use newer CPU with better single-thread performance
4. Consider GPU acceleration for larger models

## Getting Help

1. **Check Logs**: Always start with `docker logs <container_name>`
2. **Verify Health**: Use `make health` to check all services
3. **Test Connectivity**: Use individual test endpoints
4. **Resource Monitoring**: Use `docker stats` to check resource usage
5. **Complete Reset**: When in doubt, use `make clean && make setup`

## Useful Commands Reference

```bash
# System Information
docker --version
docker compose version
free -h
df -h

# Container Management
docker ps -a
docker logs --tail 50 <container_name>
docker exec -it <container_name> bash
docker stats --no-stream

# Service Testing
curl http://localhost:8000/api/health
curl http://localhost:5001/health
curl http://localhost:11434/api/version

# Database Access
docker exec -it postgres psql -U postgres -d bankrag
# SQL: SELECT * FROM transactions;

# Laravel Commands
docker exec laravel php artisan migrate:status
docker exec laravel php artisan route:list
docker exec laravel php artisan config:show database

# Cleanup Commands
docker compose down -v
docker system prune -f
docker volume prune -f
```