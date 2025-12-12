#!/bin/bash
set -e

# AWS Deployment Script for Flowise
# This script deploys Flowise to AWS App Runner with ECR

REGION="us-east-1"
ACCOUNT_ID="566006853584"
REPOSITORY_NAME="flowise"
IMAGE_TAG="latest"
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPOSITORY_NAME}"

echo "🚀 Deploying Flowise to AWS..."

# Step 1: Create ECR repository (if it doesn't exist)
echo "📦 Creating ECR repository..."
aws ecr create-repository \
    --repository-name ${REPOSITORY_NAME} \
    --region ${REGION} 2>/dev/null || echo "Repository already exists"

# Step 2: Login to ECR
echo "🔐 Logging in to ECR..."
aws ecr get-login-password --region ${REGION} | podman login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Step 3: Build Docker image
echo "🏗️  Building Docker image for AMD64 (x86_64) platform..."
# Build for linux/amd64 platform (AWS App Runner requirement)
podman build --platform linux/amd64 --memory=8g -t ${REPOSITORY_NAME}:${IMAGE_TAG} .

# Step 4: Tag image for ECR
echo "🏷️  Tagging image..."
podman tag ${REPOSITORY_NAME}:${IMAGE_TAG} ${ECR_URI}:${IMAGE_TAG}

# Step 5: Push to ECR
echo "☁️  Pushing to ECR..."
podman push ${ECR_URI}:${IMAGE_TAG}

echo "✅ Image pushed successfully to ${ECR_URI}:${IMAGE_TAG}"
echo ""
echo "📋 Next steps:"
echo "1. Create Cognito App Client (see cognito-setup.md)"
echo "2. Create App Runner service (see apprunner-setup.md)"
echo "3. Configure environment variables in App Runner"
