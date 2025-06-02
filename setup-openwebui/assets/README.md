# OpenWebUI Custom Assets

This directory contains the default assets used by OpenWebUI. Departments can replace these files with their own branding assets.

## Current Assets

- `favicon.png` - Browser favicon (16x16 or 32x32 pixels recommended)
- `splash.png` - Main splash/logo image for light theme
- `splash-dark.png` - Main splash/logo image for dark theme

All assets currently use the GAR logo as the default.

## Customizing Assets for Your Department

### Method 1: Replace Files and Rebuild ConfigMaps

1. **Replace the asset files** with your department's branding:
   ```bash
   # Navigate to assets directory
   cd sample-aws-eks-auto-mode/setup-openwebui/assets/
   
   # Replace with your department's assets
   cp /path/to/your/favicon.png ./favicon.png
   cp /path/to/your/splash.png ./splash.png
   cp /path/to/your/splash-dark.png ./splash-dark.png
   ```

2. **Update the ConfigMaps** with your new assets:
   ```bash
   # Create/update the asset ConfigMaps
   kubectl create configmap openwebui-favicon \
     --from-file=favicon.png=./favicon.png \
     -n vllm-inference \
     --dry-run=client -o yaml | kubectl apply -f -
   
   kubectl create configmap openwebui-splash \
     --from-file=splash.png=./splash.png \
     --from-file=splash-dark.png=./splash-dark.png \
     -n vllm-inference \
     --dry-run=client -o yaml | kubectl apply -f -
   ```

3. **Restart the OpenWebUI deployment** to pick up the new assets:
   ```bash
   kubectl rollout restart deployment/open-webui -n vllm-inference
   ```

### Method 2: Direct ConfigMap Update (Advanced)

You can also update ConfigMaps directly without replacing files:

```bash
# Update favicon
kubectl create configmap openwebui-favicon \
  --from-file=favicon.png=/path/to/your/favicon.png \
  -n vllm-inference \
  --dry-run=client -o yaml | kubectl apply -f -

# Update splash images
kubectl create configmap openwebui-splash \
  --from-file=splash.png=/path/to/your/splash.png \
  --from-file=splash-dark.png=/path/to/your/splash-dark.png \
  -n vllm-inference \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart deployment
kubectl rollout restart deployment/open-webui -n vllm-inference
```