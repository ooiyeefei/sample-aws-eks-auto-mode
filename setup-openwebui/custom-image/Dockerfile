FROM ghcr.io/open-webui/open-webui:main

# Copy customized index.html with GAR GPT branding
COPY index.html /app/build/index.html

# Copy custom static assets (logos, icons, etc.)
COPY static/* /app/build/static/

# Maintain the same user and permissions as the base image
USER root
RUN chown -R 1000:1000 /app/build/
USER 1000

# Expose the same port as the base image
EXPOSE 8080

# Use the same entrypoint as the base image
