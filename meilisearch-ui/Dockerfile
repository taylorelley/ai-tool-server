# Dockerfile for Meilisearch UI with Runtime Environment Variable Injection
#
# This Dockerfile extends the base meilisearch-simple-hybrid-search-frontend image
# and adds a custom entrypoint script that injects environment variables at runtime.
#
# Problem being solved:
# - Vite environment variables (VITE_*) are build-time only
# - Setting them in docker-compose.yaml doesn't work for pre-built images
# - This causes 403 API key errors when the frontend tries to connect to Meilisearch
#
# Solution:
# - Custom entrypoint script generates a runtime config file
# - The config file is loaded by the frontend when it starts
# - Environment variables are now injected at container startup, not build time

FROM ghcr.io/taylorelley/meilisearch-simple-hybrid-search-frontend:latest

# Install sed if not present (needed for HTML modification)
RUN if ! command -v sed > /dev/null; then apk add --no-cache sed; fi

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /entrypoint.sh

# Set the entrypoint to our custom script
# The CMD from the base image (nginx) will be passed as arguments to our entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Default command (nginx) - this will be passed to the entrypoint script
CMD ["nginx", "-g", "daemon off;"]
