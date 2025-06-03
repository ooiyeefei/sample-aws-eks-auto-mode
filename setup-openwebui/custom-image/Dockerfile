FROM ghcr.io/open-webui/open-webui:main as source
FROM ghcr.io/open-webui/open-webui:main

# Copy ALL static assets from the original image first
COPY --from=source /app/build/static/ /app/build/static/

# Then copy our custom assets (this will overwrite any duplicates like gar-logo.png)
COPY static/* /app/build/static/

# Copy our modified index.html with GAR GPT branding
COPY index.html /app/build/index.html
