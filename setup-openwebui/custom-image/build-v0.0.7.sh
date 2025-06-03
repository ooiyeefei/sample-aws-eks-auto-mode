#!/bin/bash
set -e

# Version 0.0.7 Configuration (minimal approach with proper index.html extraction)
VERSION="v0.0.9"
IMAGE_NAME="openwebui/custom-build"
REGISTRY="public.ecr.aws/v2f5y6u4"
FULL_IMAGE_NAME="$REGISTRY/$IMAGE_NAME:$VERSION"

echo "🏗️  Building Custom OpenWebUI Image $VERSION"
echo "============================================="
echo "Image: $FULL_IMAGE_NAME"
echo ""

# Verify required files exist
echo "📋 Checking required files..."
if [ ! -f "index.html" ]; then
    echo "❌ Error: index.html not found"
    echo "Please run ./extract-and-modify-index.sh first to create the modified index.html"
    exit 1
fi

if [ ! -f "static/gar-logo.png" ]; then
    echo "❌ Error: static/gar-logo.png not found"
    echo "Please ensure the GAR logo is present in the static/ directory"
    exit 1
fi

if [ ! -f "static/splash.png" ]; then
    echo "❌ Error: static/splash.png not found"
    echo "Please ensure splash.png is present in the static/ directory"
    exit 1
fi

if [ ! -f "static/splash-dark.png" ]; then
    echo "❌ Error: static/splash-dark.png not found"
    echo "Please ensure splash-dark.png is present in the static/ directory"
    exit 1
fi

echo "✅ All required files found"
echo ""

# Build the image
echo "📦 Building $FULL_IMAGE_NAME..."
docker build -t $FULL_IMAGE_NAME .

# Also tag as latest
echo "🏷️  Tagging as latest..."
docker tag $FULL_IMAGE_NAME $REGISTRY/$IMAGE_NAME:latest

echo ""
echo "✅ Image $VERSION built successfully!"
echo ""
echo "📊 Image Details:"
docker images $REGISTRY/$IMAGE_NAME:$VERSION --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
echo ""
echo "🧪 Test locally:"
echo "   docker run -d -p 3000:8080 --name test-openwebui-v004 $FULL_IMAGE_NAME"
echo "   # Access at http://localhost:3000"
echo "   # Stop with: docker stop test-openwebui-v004 && docker rm test-openwebui-v004"
echo ""
echo "🚀 Push to registry:"
echo "   # Login to ECR:"
echo "   aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin $REGISTRY"
echo "   # Push images:"
echo "   docker push $FULL_IMAGE_NAME"
echo "   docker push $REGISTRY/$IMAGE_NAME:latest"
echo ""
echo "📝 Update values.yaml.tpl to use:"
echo "   image:"
echo "     repository: $REGISTRY/$IMAGE_NAME"
echo "     tag: $VERSION"
echo ""
echo "🔄 Version 0.0.4 Changes:"
echo "   - Minimal Dockerfile approach (no permission/user changes)"
echo "   - Proper index.html extraction from current OpenWebUI image"
echo "   - GAR GPT branding with favicon pointing to local static assets"
echo "   - Database connection compatibility maintained"
echo "   - Clean separation of branding from infrastructure"
