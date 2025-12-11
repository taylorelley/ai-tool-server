#!/bin/sh
set -e

# Runtime environment variable injection for Vite apps
# This script replaces environment variable placeholders in the built static files
# with actual runtime values, solving the Vite build-time vs runtime issue.

echo "🔧 Injecting runtime environment variables into Meilisearch UI..."

# Path to the built static files (typical nginx serving path)
STATIC_PATH="/usr/share/nginx/html"

# Create a runtime config JavaScript file that will be loaded by the app
cat > "${STATIC_PATH}/config.js" <<EOF
// Runtime configuration injected by entrypoint.sh
// This file is generated when the container starts, not at build time
window.__RUNTIME_CONFIG__ = {
  VITE_MEILISEARCH_HOST: "${VITE_MEILISEARCH_HOST:-http://localhost:7700}",
  VITE_MEILISEARCH_API_KEY: "${VITE_MEILISEARCH_API_KEY}",
  VITE_MEILISEARCH_INDEX: "${VITE_MEILISEARCH_INDEX:-web_docs}",
  VITE_APP_TITLE: "${VITE_APP_TITLE:-AI Tool Server Search}",
  VITE_MEILISEARCH_SEMANTIC_RATIO: "${VITE_MEILISEARCH_SEMANTIC_RATIO:-0.5}",
  VITE_MEILISEARCH_EMBEDDER: "${VITE_MEILISEARCH_EMBEDDER:-default}"
};
EOF

echo "✅ Runtime config created at ${STATIC_PATH}/config.js"
echo "📝 Configuration:"
echo "   Host: ${VITE_MEILISEARCH_HOST:-http://localhost:7700}"
echo "   Index: ${VITE_MEILISEARCH_INDEX:-web_docs}"
echo "   API Key: ${VITE_MEILISEARCH_API_KEY:+***configured***}"

# Find and modify index.html to include the runtime config script
if [ -f "${STATIC_PATH}/index.html" ]; then
  # Check if config.js is already included
  if ! grep -q "config.js" "${STATIC_PATH}/index.html"; then
    echo "🔧 Injecting config.js into index.html..."

    # Insert the config.js script tag before the closing </head> tag
    sed -i 's|</head>|  <script src="/config.js"></script>\n  </head>|' "${STATIC_PATH}/index.html"

    echo "✅ Runtime config script injected into index.html"
  else
    echo "ℹ️  config.js already referenced in index.html"
  fi
else
  echo "⚠️  Warning: index.html not found at ${STATIC_PATH}/index.html"
  echo "   The app may not load the runtime configuration correctly."
fi

echo "🚀 Starting nginx..."

# Execute the original command (nginx)
exec "$@"
