FROM python:3.10-slim

WORKDIR /app
COPY embedding_service.py .

RUN pip install --no-cache-dir flask sentence-transformers

EXPOSE 5001
CMD ["python", "embedding_service.py"]
