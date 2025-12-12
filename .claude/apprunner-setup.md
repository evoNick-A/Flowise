# AWS App Runner Setup for Flowise

## Prerequisites

1. ✅ ECR image pushed (run `./deploy-to-aws.sh`)
2. ✅ Cognito App Client created (see `cognito-setup.md`)

## Create App Runner Service

### Via AWS Console:

1. Go to AWS App Runner Console
2. Click "Create service"
3. **Source**:
   - Repository type: Container registry
   - Provider: Amazon ECR
   - Container image URI: `566006853584.dkr.ecr.us-east-1.amazonaws.com/flowise:latest`
   - Deployment trigger: Manual (or Automatic)
   - ECR access role: Create new or use existing
4. **Service settings**:
   - Service name: `flowise`
   - Port: `3000`
   - CPU: `2 vCPU`
   - Memory: `4 GB`
5. **Environment variables** (click "Add environment variable"):
   ```
   PORT=3000
   
   # JWT Configuration (required for enterprise features, optional for basic use)
   JWT_AUTH_TOKEN_SECRET=<generate-random-32-char-string>
   JWT_REFRESH_TOKEN_SECRET=<generate-random-32-char-string>
   JWT_ISSUER=https://cognito-idp.us-east-1.amazonaws.com/us-east-1_EOjdFWrGR
   JWT_AUDIENCE=<your-cognito-app-client-id>
   JWT_TOKEN_EXPIRY_IN_MINUTES=360
   JWT_REFRESH_TOKEN_EXPIRY_IN_MINUTES=43200
   
   # App URL (add after service is created)
   APP_URL=https://YOUR-APP-RUNNER-URL
   ```
   
   **Note**: Removed DATABASE_PATH, SECRETKEY_PATH, and LOG_PATH as these are now set to `/var/data/flowise` in the container with proper permissions.
6. **Health check**:
   - Path: `/api/v1/ping`
   - Interval: 10 seconds
   - Timeout: 5 seconds
   - Healthy threshold: 1
   - Unhealthy threshold: 5
7. **Security**:
   - Instance role: Create new or use existing (needs permissions for any AWS services you'll use)
8. **Auto scaling**:
   - Min: 1
   - Max: 5
   - Concurrency: 100
9. Click "Create & deploy"

## After Service is Created

1. **Get the App Runner URL** (e.g., `https://abc123.us-east-1.awsapprunner.com`)

2. **Enable App Runner Cognito Authentication** (REQUIRED - Option 1 approach):
   - Go to App Runner Console → Your service → Configuration → Security
   - Click "Edit" in Authentication section
   - **Enable Authentication**
   - Select: **Amazon Cognito**
   - Configuration:
     - **User Pool**: `us-east-1_EOjdFWrGR`
     - **App Client**: (the one you created in cognito-setup.md)
     - **Scopes**: `openid email profile`
   - Click "Save changes"
   - **This makes App Runner handle ALL authentication** - users must login via Cognito before accessing Flowise

3. **Update Cognito App Client Callback URLs**:
   - Go to Cognito Console → User Pool → App clients → Your flowise app client
   - Add callback URL: `https://YOUR-APP-RUNNER-URL/oauth2/idpresponse`
   - Add logout URL: `https://YOUR-APP-RUNNER-URL`
   - Save changes

4. **Optional - Update App Runner environment variable**:
   - Set `APP_URL=https://YOUR-APP-RUNNER-URL`
   - Redeploy if needed

## Via AWS CLI:

```bash
# Create service (replace placeholders)
aws apprunner create-service \
  --service-name flowise \
  --source-configuration '{
    "ImageRepository": {
      "ImageIdentifier": "566006853584.dkr.ecr.us-east-1.amazonaws.com/flowise:latest",
      "ImageRepositoryType": "ECR",
      "ImageConfiguration": {
        "Port": "3000",
        "RuntimeEnvironmentVariables": {
          "PORT": "3000",
          "DATABASE_TYPE": "sqlite",
          "JWT_ISSUER": "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_EOjdFWrGR",
          "JWT_AUDIENCE": "<your-cognito-app-client-id>"
        }
      }
    },
    "AutoDeploymentsEnabled": false
  }' \
  --instance-configuration '{
    "Cpu": "2 vCPU",
    "Memory": "4 GB"
  }' \
  --health-check-configuration '{
    "Protocol": "HTTP",
    "Path": "/api/v1/ping",
    "Interval": 10,
    "Timeout": 5,
    "HealthyThreshold": 1,
    "UnhealthyThreshold": 5
  }' \
  --region us-east-1
```

## Generate Random Secrets

```bash
# Generate JWT secrets
openssl rand -base64 32
openssl rand -base64 32
```

## Test the Deployment

1. Access: `https://YOUR-APP-RUNNER-URL`
2. Check health: `https://YOUR-APP-RUNNER-URL/api/v1/ping`
3. Test login with Cognito credentials
