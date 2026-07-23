# ============================================
# Healthcare Website with Python Flask Backend
# Serves static HTML + API endpoints
# ============================================

FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:5000/health || exit 1
CMD ["python", "app.py"]
