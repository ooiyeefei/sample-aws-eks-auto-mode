# Custom OpenWebUI Image - GAR GPT Branding

This directory contains the files needed to build a custom OpenWebUI Docker image with GAR GPT branding, replacing all OpenWebUI references and logos.

## Files Overview

- `Dockerfile` - Docker build configuration
- `index.html` - Customized HTML with GAR GPT branding and JavaScript modifications
- `static/gar-logo.png` - Custom GAR logo (copied from `../image.png`)

## Customizations Applied

### Branding Changes
- **Title**: "Open WebUI" → "GAR GPT"
- **Favicon**: Custom GAR logo
- **Logo**: All images replaced with GAR logo
- **Text**: All "Open WebUI" references replaced with "GAR GPT"

### Hidden Elements
- OpenWebUI documentation links
- Contributing links
- Discord community links
- Default branding elements

### Dynamic Content Handling
- JavaScript monitors for dynamically loaded content
- Automatically replaces "Open WebUI" text as it appears
- Handles title changes and UI updates

## Building the Custom Image

### Prerequisites

1. **Docker installed** on your build machine
2. **AWS CLI configured** with access to ECR
3. **ECR repository** created (public registry)

### Step 1: Extract Original index.html (Optional)

If you need to update the base `index.html`, extract it from the original container:

```bash
# Pull the latest OpenWebUI image
docker pull ghcr.io/open-webui/open-webui:main

# Create a temporary container
docker run -d --name temp-openwebui ghcr.io/open-webui/open-webui:main

# Extract the original index.html
docker cp temp-openwebui:/app/build/index.html ./index-original.html

# Clean up
docker stop temp-openwebui
docker rm temp-openwebui

# Compare with your customized version if needed
```

### Step 2: Build the Custom Image

Navigate to this directory and build the image:

```bash
cd sample-aws-eks-auto-mode/setup-openwebui/custom-image

# Build the image with version tag
docker build -t openwebui/custom-build:v0.0.1 .

# Also tag as latest for convenience
docker tag openwebui/custom-build:v0.0.1 openwebui/custom-build:latest
```

### Step 3: Test the Image Locally (Optional)

Test your custom image before pushing:

```bash
# Run the custom image locally
docker run -d -p 3000:8080 --name test-gar-gpt openwebui/custom-build:v0.0.1

# Access at http://localhost:3000 to verify branding
# Check that:
# - Title shows "GAR GPT"
# - Favicon is the GAR logo
# - All "Open WebUI" text is replaced
# - OpenWebUI branding elements are hidden

# Clean up test container
docker stop test-gar-gpt
docker rm test-gar-gpt
```

### Step 4: Push to ECR

Login to AWS ECR and push the image:

```bash
# Login to ECR public registry
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/v2f5y6u4

# Tag for ECR
docker tag openwebui/custom-build:v0.0.1 public.ecr.aws/v2f5y6u4/openwebui/custom-build:v0.0.1
docker tag openwebui/custom-build:latest public.ecr.aws/v2f5y6u4/openwebui/custom-build:latest

# Push both tags
docker push public.ecr.aws/v2f5y6u4/openwebui/custom-build:v0.0.1
docker push public.ecr.aws/v2f5y6u4/openwebui/custom-build:latest
```

## Using the Custom Image

After building and pushing the image, update your Helm deployment to use the custom image:

1. **Update values.yaml.tpl**: The main setup will reference your custom image
2. **Deploy**: Use the standard OpenWebUI deployment process with the custom image

## Version Management

### Current Version: v0.0.1

### Updating the Image

When you need to update the branding or fix issues:

1. **Increment version**: Update to v0.0.2, v0.0.3, etc.
2. **Modify files**: Update `index.html`, add new static assets, etc.
3. **Rebuild**: Follow the build process with the new version tag
4. **Update deployment**: Modify `values.yaml.tpl` to use the new version
5. **Redeploy**: Apply the updated Helm chart

### Version History

- **v0.0.1**: Initial GAR GPT branding
  - Replaced all "Open WebUI" with "GAR GPT"
  - Added custom GAR logo as favicon and brand image
  - Hidden OpenWebUI documentation and community links
  - Added dynamic content monitoring

## Troubleshooting

### Build Issues

**Problem**: Docker build fails with permission errors
```bash
# Solution: Ensure proper file permissions
chmod 644 index.html
chmod 644 static/gar-logo.png
```

**Problem**: Static files not copied
```bash
# Solution: Verify file structure
ls -la static/
# Should show gar-logo.png
```

### Runtime Issues

**Problem**: Branding not applied
- Check browser console for JavaScript errors
- Verify static files are accessible at `/static/gar-logo.png`
- Ensure the MutationObserver scripts are running

**Problem**: Original OpenWebUI elements still visible
- Check CSS selectors in the `<style>` section
- Add additional CSS rules for new elements
- Verify JavaScript replacement logic

### ECR Issues

**Problem**: Push fails with authentication error
```bash
# Solution: Re-authenticate
aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/v2f5y6u4
```

**Problem**: Repository doesn't exist
```bash
# Solution: Create the repository in ECR console or via CLI
aws ecr-public create-repository --repository-name openwebui/custom-build --region us-east-1
```

## Security Considerations

- The custom image maintains the same security context as the base OpenWebUI image
- No additional privileges or capabilities are added
- Static files are served with the same permissions as the original application
- All customizations are client-side (HTML/CSS/JavaScript)

## Maintenance

### Regular Updates

1. **Monitor base image updates**: Check for new OpenWebUI releases
2. **Update base image**: Modify Dockerfile to use newer base image versions
3. **Test compatibility**: Ensure customizations work with new versions
4. **Rebuild and redeploy**: Follow the version update process

### Backup

Keep backups of:
- Original `index.html` files for reference
- Custom static assets
- Build scripts and documentation
- Version history and change logs
