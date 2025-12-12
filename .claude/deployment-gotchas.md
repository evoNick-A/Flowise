# Deployment Gotchas & Checklist

## ✅ Issues Found & Fixed

### 1. **Health Check Endpoint** ⚠️ CRITICAL
- **Wrong**: `/health`
- **Correct**: `/api/v1/ping`
- Flowise doesn't have a `/health` endpoint, it uses `/api/v1/ping`
- Already updated in `apprunner-setup.md`

### 2. **Docker Platform Architecture** ✅ FIXED
- Mac M1/M2 (ARM64) builds wrong architecture by default
- AWS App Runner needs `linux/amd64` (x86_64)
- Fixed in `deploy-to-aws.sh` with `--platform linux/amd64`

### 3. **Memory During Build** ✅ FIXED
- Initial builds failed with exit code 137 (OOM)
- Podman VM had only 2GB RAM
- Increased to 12GB via `.claude/increase-podman-memory.sh`
- Dockerfile uses `NODE_OPTIONS="--max-old-space-size=6144"`

### 4. **File Permissions** ✅ FIXED
- App Runner runs as `node` user (non-root)
- `/var/data/flowise` directories must exist with correct ownership
- Dockerfile creates directories and sets ownership before switching to node user

### 5. **Database & Storage Paths** ✅ HANDLED
- Default paths won't work without proper setup
- Container pre-creates `/var/data/flowise` with permissions
- Uses SQLite by default (good for single instance)

## 🔍 Potential Issues to Watch

### 6. **Data Persistence** ⚠️ IMPORTANT
- **Problem**: App Runner is ephemeral - data lost on redeploy
- **Impact**: All chatflows, credentials, chat history will be lost
- **Solutions**:
  - Option A: Use RDS PostgreSQL instead of SQLite
  - Option B: Mount EFS volume (App Runner doesn't support this directly)
  - Option C: Use external storage (S3) for uploads + RDS for data
- **Recommendation**: **Switch to RDS PostgreSQL** before production use

### 7. **API Keys & Secrets** ⚠️ SECURITY
- JWT secrets in env vars are visible in console
- **Better approach**: Use AWS Secrets Manager
- Environment variables to protect:
  - `JWT_AUTH_TOKEN_SECRET`
  - `JWT_REFRESH_TOKEN_SECRET`
  - Any API keys for AI services

### 8. **CORS & Trusted Origins** 
- Default CORS is `*` (wide open)
- Set `CORS_ORIGINS` env var to your domain
- Set `IFRAME_ORIGINS` if embedding

### 9. **Cognito Integration Details**
- App Runner's built-in Cognito auth bypasses Flowise's auth entirely
- Flowise won't know about user identities from Cognito
- All users will share the same workspace/data
- **If you need multi-tenancy**: Implement Option 2 (Cognito SSO provider in Flowise)

### 10. **Scaling Considerations**
- SQLite = single instance only (no horizontal scaling)
- If you scale to >1 instance, you MUST use PostgreSQL
- Redis needed for session sharing across instances
- Consider setting Max instances to 1 if using SQLite

## 📋 Pre-Production Checklist

### Required:
- [ ] Switch to RDS PostgreSQL for data persistence
- [ ] Move secrets to AWS Secrets Manager
- [ ] Set `CORS_ORIGINS` and `IFRAME_ORIGINS` to your domain
- [ ] Create Cognito App Client (see `cognito-setup.md`)
- [ ] Update Cognito callback URLs after App Runner deployment
- [ ] Test authentication flow end-to-end
- [ ] Verify health check at `/api/v1/ping`

### Recommended:
- [ ] Set up CloudWatch logging
- [ ] Configure Auto Scaling (Min: 1, Max: 1 for SQLite OR Min: 2, Max: 5 for PostgreSQL)
- [ ] Set up RDS backup policy
- [ ] Configure S3 for file uploads (`STORAGE_TYPE=s3`)
- [ ] Set `LOG_LEVEL=info` (default is too verbose)
- [ ] Enable telemetry or metrics if needed
- [ ] Set up alerts for health check failures

### Security:
- [ ] Use HTTPS only (`SECURE_COOKIES=true`)
- [ ] Set `TRUST_PROXY=true` for App Runner
- [ ] Review and set `DISABLED_NODES` if needed (security sensitive nodes)
- [ ] Consider API rate limiting (`NUMBER_OF_PROXIES=1`)
- [ ] Rotate JWT secrets regularly

## 🗄️ Switching to RDS PostgreSQL

If you need data persistence, add these env vars:

```bash
DATABASE_TYPE=postgres
DATABASE_HOST=<your-rds-endpoint>
DATABASE_PORT=5432
DATABASE_NAME=flowise
DATABASE_USER=<username>
DATABASE_PASSWORD=<from-secrets-manager>
DATABASE_SSL=true
```

Remove or comment out:
- `DATABASE_PATH` (not used with PostgreSQL)

## 🔐 Using AWS Secrets Manager

Store secrets in Secrets Manager, then reference in App Runner:

```bash
# In Secrets Manager, create secret: flowise/jwt-secrets
{
  "JWT_AUTH_TOKEN_SECRET": "...",
  "JWT_REFRESH_TOKEN_SECRET": "..."
}

# In App Runner env vars, use AWS Secrets Manager ARN format
# App Runner will automatically fetch and inject
```

## 🎯 Current Status

**Working**:
- ✅ Docker image builds for correct architecture
- ✅ Image pushes to ECR
- ✅ Container runs with correct permissions
- ✅ Health check endpoint configured correctly

**Still Needed**:
- ⚠️ Data persistence solution (currently ephemeral)
- ⚠️ Cognito App Client creation
- ⚠️ App Runner service creation and auth configuration

**Next Steps**:
1. Decide on database strategy (SQLite ephemeral vs RDS persistent)
2. Follow `cognito-setup.md` to create app client
3. Follow `apprunner-setup.md` to deploy service
4. Test authentication flow
