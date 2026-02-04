# Deployment Guide

This guide provides instructions for deploying the Restaurant Order Management API to production environments.

## 🏗️ Recommended Production Stack

- **Cloud Platform**: AWS, GCP, Azure, or Render/Heroku
- **Container Orchestration**: Kubernetes (AWS EKS, GCP GKE), AWS ECS, or Docker Swarm
- **Database**: Managed PostgreSQL (AWS RDS, GCP Cloud SQL)
- **Cache/Queue**: Managed Redis (AWS ElastiCache, GCP Cloud Memorystore)
- **Reverse Proxy**: NGINX or Cloud-native Ingress
- **SSL/TLS**: Let's Encrypt or Cloud Certificate Manager

## 🔧 Environment Configuration

The following environment variables should be configured in your production environment:

| Variable | Description | Example |
|----------|-------------|---------|
| `RAILS_ENV` | Production environment | `production` |
| `RAILS_MASTER_KEY` | Key for decryption | (Secret) |
| `DATABASE_URL` | PostgreSQL connection string | `postgres://user:pass@host:5432/db` |
| `REDIS_URL` | Redis connection string | `redis://host:6379/1` |
| `RAILS_LOG_TO_STDOUT` | Enable logging to stdout | `true` |
| `RAILS_SERVE_STATIC_FILES` | Serve static files (if any) | `true` |
| `ALLOWED_HOSTS` | Domain names allowed | `api.example.com` |

## 🚀 Deployment Steps

### 1. Build Production Image

The provided `Dockerfile` is optimized for development. For production, consider using a multi-stage build to reduce image size and security surface.

```bash
docker build -t your-registry/restaurant-api:latest .
```

### 2. Database Migrations

Always backup your database before running migrations in production.

```bash
docker run --rm your-registry/restaurant-api:latest rails db:migrate
```

### 3. Running Services

#### Web Server (Puma)
Ensure Puma is configured for production in `config/puma.rb`.

```bash
rails server -e production
```

#### Background Worker (Sidekiq)
Sidekiq handles daily sales aggregation.

```bash
bundle exec sidekiq -e production
```

## 🛡️ Security Considerations

1. **Authentication Gateway**:
   This API does not include its own user authentication layer. It is designed to be seated behind an API Gateway or Reverse Proxy that handles:
   - JWT/OAuth2 Verification
   - API Key Management
   - IP Whitelisting

2. **Database Hardening**:
   - Use VPC/Private Subnets for Database and Redis.
   - Do not expose DB ports to the public internet.

3. **Rate Limiting**:
   Modify `config/initializers/rack_attack.rb` to set production-specific limits based on your traffic expectations.

4. **Secrets Management**:
   Use AWS Secrets Manager, GCP Secret Manager, or Environment Variables. **Never commit `.env` or `config/master.key` to source control.**

## 📊 Monitoring

- **Health Checks**:
  - `/api-docs` (Swagger UI) - simple check
  - Custom health check endpoint (recommended to add)
- **Sidekiq Dashboard**: Use basic auth if exposing in production.
- **Logging**: Use a log aggregator (CloudWatch, ELK Stack, Datadog).

---

**For Cloud-Specific Guides, please refer to their respective documentation.**
