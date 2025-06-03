# Custom OpenWebUI Image - GAR GPT Branding

This directory contains the files and scripts needed to build a custom OpenWebUI image with GAR GPT branding.

## Version 0.1.0 - Minimal Approach

Version 0.1.0 uses a **minimal approach** that maintains full database compatibility while adding GAR GPT branding. This approach was developed after discovering that complex permission fixes and environment variable modifications were causing database connection issues.

### Key Features

- ✅ **Database Compatible**: Works with PostgreSQL/RDS without connection issues
- ✅ **GAR GPT Branding**: Complete branding replacement with JavaScript
- ✅ **Minimal Dockerfile**: Only copies necessary files, no system modifications
- ✅ **Proper Asset Extraction**: Uses current OpenWebUI image as source
- ✅ **Local Static Assets**: Favicon points to local GAR logo

## Files Overview

```
custom-image/
├── Dockerfile                    # Minimal Dockerfile (v0.1.0)
├── extract-and-modify-index.sh   # Script to extract and modify index.html
├── build-image.sh              # Build script for version 0.1.0
├── README.md                     # This file
├── static/                       # Static assets directory
│   ├── gar-logo.png             # GAR logo (required)
│   ├── splash.png               # Splash screen logo
│   └── splash-dark.png          # Dark theme splash logo
├── index.html                    # Modified index.html (generated)
└── index-original.html           # Backup of original (generated)
```

## Quick Start

### Prerequisites

- Docker installed and running
- AWS CLI configured (for ECR push)
- GAR logo image file

### Step 1: Prepare Static Assets

Create the required static assets in the `static/` directory:

```bash
# Ensure you have these files:
static/gar-logo.png      # Your GAR logo (32x32 or larger PNG)
static/splash.png        # Can be same as gar-logo.png
static/splash-dark.png   # Can be same as gar-logo.png
```

### Step 2: Extract and Modify index.html

```bash
# Run the extraction script
./extract-and-modify-index.sh
```

This script will:
- Pull the latest OpenWebUI image
- Extract the current `index.html`
- Add GAR GPT branding scripts
- Create the modified `index.html`

### Step 3: Build the Custom Image

```bash
./build-image.sh
```

### Step 4: Push to Registry

```bash
# Login to ECR
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/v2f5y6u4

# Push the images
docker push public.ecr.aws/v2f5y6u4/openwebui/custom-build:v0.1.0
docker push public.ecr.aws/v2f5y6u4/openwebui/custom-build:latest
```

## Technical Details

### Minimal Dockerfile Approach

The v0.1.0 Dockerfile is intentionally minimal:

```dockerfile
FROM ghcr.io/open-webui/open-webui:main

# Copy the modified index.html with GAR GPT branding
COPY index.html /app/build/index.html

# Copy static assets (GAR logo, splash images)
COPY static/* /app/build/static/
```

**What we DON'T do (that caused issues in previous versions):**
- ❌ No user switching (`USER root` → `USER 1000`)
- ❌ No permission modifications (`chown`, `chmod`)
- ❌ No working directory changes (`WORKDIR`)
- ❌ No environment variables (`ENV PGSSLMODE`, etc.)
- ❌ No complex filesystem operations
