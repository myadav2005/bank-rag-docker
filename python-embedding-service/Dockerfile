FROM python:3.10-slim

WORKDIR /app

# Copy requirements first for better Docker layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY embedding_service.py .

EXPOSE 5001
CMD ["python", "embedding_service.py"]
