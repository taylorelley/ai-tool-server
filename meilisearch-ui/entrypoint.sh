#!/bin/sh
set -e

# Runtime environment variable injection for Vite apps
# This script replaces environment variable placeholders in the built static files
# with actual runtime values, solving the Vite build-time vs runtime issue.

# POSIX-compatible JSON string escaping function
# Works with Alpine/BusyBox awk (no GNU extensions required)
# Escapes: backslash (\), double-quote ("), newline (\n), carriage return (\r), tab (\t)
json_escape() {
    printf '%s' "$1" | awk '
    BEGIN {
        # No BEGIN initialization needed for POSIX awk
    }
    {
        # Process each line
        line = $0
        result = ""

        # Process character by character
        len = length(line)
        for (i = 1; i <= len; i++) {
            char = substr(line, i, 1)

            # Escape special characters
            if (char == "\\") {
                result = result "\\\\"
            } else if (char == "\"") {
                result = result "\\\""
            } else if (char == "\t") {
                result = result "\\t"
            } else if (char == "\r") {
                result = result "\\r"
            } else {
                result = result char
            }
        }

        # Print the result
        if (NR > 1) {
            # For lines after the first, prepend \n for the previous newline
            printf "\\n%s", result
        } else {
            printf "%s", result
        }
    }
    '
}

echo "🔧 Injecting runtime environment variables into Meilisearch UI..."

# Path to the built static files (typical nginx serving path)
STATIC_PATH="/usr/share/nginx/html"

# Escape all environment variables for JSON
ESCAPED_HOST=$(json_escape "${VITE_MEILISEARCH_HOST:-http://localhost:7700}")
ESCAPED_API_KEY=$(json_escape "${VITE_MEILISEARCH_API_KEY}")
ESCAPED_INDEX=$(json_escape "${VITE_MEILISEARCH_INDEX:-web_docs}")
ESCAPED_TITLE=$(json_escape "${VITE_APP_TITLE:-AI Tool Server Search}")
ESCAPED_RATIO=$(json_escape "${VITE_MEILISEARCH_SEMANTIC_RATIO:-0.5}")
ESCAPED_EMBEDDER=$(json_escape "${VITE_MEILISEARCH_EMBEDDER:-default}")

# Create a runtime config JavaScript file that will be loaded by the app
cat > "${STATIC_PATH}/config.js" <<EOF
// Runtime configuration injected by entrypoint.sh
// This file is generated when the container starts, not at build time
window.__RUNTIME_CONFIG__ = {
  VITE_MEILISEARCH_HOST: "${ESCAPED_HOST}",
  VITE_MEILISEARCH_API_KEY: "${ESCAPED_API_KEY}",
  VITE_MEILISEARCH_INDEX: "${ESCAPED_INDEX}",
  VITE_APP_TITLE: "${ESCAPED_TITLE}",
  VITE_MEILISEARCH_SEMANTIC_RATIO: "${ESCAPED_RATIO}",
  VITE_MEILISEARCH_EMBEDDER: "${ESCAPED_EMBEDDER}"
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
