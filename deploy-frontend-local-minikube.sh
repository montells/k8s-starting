#!/bin/bash

# Deployment pipeline script for sinatra-app
# This script reads the version from frontend/version.rb and deploys to Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Sinara App Deployment Pipeline ===${NC}"

# Step 1: Extract version from frontend/version.rb
echo -e "${YELLOW}[1/3] Extracting version from frontend/version.rb...${NC}"
VERSION=$(grep "STRING = " frontend/version.rb | sed "s/.*STRING = '\(.*\)'/\1/")

if [ -z "$VERSION" ]; then
    echo -e "${RED}ERROR: Could not extract version from frontend/version.rb${NC}"
    exit 1
fi

echo -e "${GREEN}  Version: $VERSION${NC}"

# Step 2: Build Docker image
echo -e "${YELLOW}[2/3] Building Docker image sinatra-app:$VERSION...${NC}"
cd frontend && docker build -t sinatra-app:$VERSION . && cd ..


if [ $? -eq 0 ]; then
    echo -e "${GREEN}  Docker image built successfully${NC}"
else
    echo -e "${RED}ERROR: Docker build failed${NC}"
    exit 1
fi

#Step 3: Load image into minikube cluster
echo -e "${YELLOW}[3/3] Loading Docker image into minikube cluster...${NC}"
minikube image load sinatra-app:$VERSION
if [ $? -eq 0 ]; then
    echo -e "${GREEN}  Docker image loaded into minikube successfully${NC}"
else
    echo -e "${RED}ERROR: Failed to load Docker image into minikube${NC}"
    exit 1
fi

# Step 4: Deploy to Kubernetes using sed pipe (no modification to original file)
echo -e "${YELLOW}[4/4] Deploying to Kubernetes...${NC}"
sed "s/\${VERSION}/$VERSION/" k8s/frontend/deployment.yaml | kubectl apply -f -

if [ $? -eq 0 ]; then
    echo -e "${GREEN}=== Deployment completed successfully! ===${NC}"
    echo -e "${GREEN}  Image: sinatra-app:$VERSION${NC}"
else
    echo -e "${RED}ERROR: Kubernetes deployment failed${NC}"
    exit 1
fi
