# Cognito App Client Setup for Flowise

## Create New App Client in Existing User Pool

Your existing User Pool: `us-east-1_EOjdFWrGR`

### Via AWS Console:

1. Go to AWS Cognito Console
2. Select User Pool `us-east-1_EOjdFWrGR`
3. Click "App integration" tab
4. Click "Create app client"
5. Configure:
   - **App client name**: `flowise`
   - **App type**: Public client
   - **Authentication flows**: 
     - ✅ ALLOW_USER_PASSWORD_AUTH
     - ✅ ALLOW_REFRESH_TOKEN_AUTH
   - **OAuth 2.0 grant types**:
     - ✅ Authorization code grant
   - **OpenID Connect scopes**:
     - ✅ openid
     - ✅ email
     - ✅ profile
   - **Callback URLs**: 
     - `http://localhost:3000/api/v1/oauth2/callback` (for testing)
     - `https://YOUR-APP-RUNNER-URL/api/v1/oauth2/callback` (add after App Runner is created)
   - **Sign out URLs**:
     - `http://localhost:3000`
     - `https://YOUR-APP-RUNNER-URL` (add after App Runner is created)

6. Click "Create app client"
7. **Save these values**:
   - App client ID
   - App client secret (click "Show secret")
   - User Pool ID: `us-east-1_EOjdFWrGR`

### Via AWS CLI:

```bash
aws cognito-idp create-user-pool-client \
  --user-pool-id us-east-1_EOjdFWrGR \
  --client-name flowise \
  --generate-secret \
  --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
  --allowed-o-auth-flows code \
  --allowed-o-auth-scopes openid email profile \
  --callback-urls http://localhost:3000/api/v1/oauth2/callback \
  --logout-urls http://localhost:3000 \
  --region us-east-1
```

## Save These Values

After creating the app client, save these to use in your `.env` file:

```
COGNITO_USER_POOL_ID=us-east-1_EOjdFWrGR
COGNITO_APP_CLIENT_ID=<from console or CLI output>
COGNITO_APP_CLIENT_SECRET=<from console or CLI output>
COGNITO_REGION=us-east-1
COGNITO_ISSUER=https://cognito-idp.us-east-1.amazonaws.com/us-east-1_EOjdFWrGR
```
