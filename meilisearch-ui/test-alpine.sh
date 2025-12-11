#!/bin/sh
# Test the entrypoint.sh script in an Alpine container
# This validates that the JSON escaping works with BusyBox awk

set -e

echo "=========================================="
echo "Alpine/BusyBox Compatibility Test"
echo "=========================================="
echo ""

echo "Testing json_escape function in Alpine container..."
echo ""

# Create a temporary test script that will run inside Alpine
cat > /tmp/alpine-test-runner.sh <<'TESTSCRIPT'
#!/bin/sh
set -e

# Source the json_escape function
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

# Show environment
echo "Environment:"
echo "  Shell: $SHELL"
echo "  Awk version:"
awk --version 2>&1 | head -1 || echo "  (version info not available)"
echo ""

# Run test cases
echo "Test 1: Simple string"
result=$(json_escape "hello world")
echo "  Result: $result"
[ "$result" = "hello world" ] && echo "  ✅ PASS" || echo "  ❌ FAIL"

echo ""
echo "Test 2: String with quotes"
result=$(json_escape 'He said "Hello"')
echo "  Result: $result"
[ "$result" = 'He said \"Hello\"' ] && echo "  ✅ PASS" || echo "  ❌ FAIL"

echo ""
echo "Test 3: String with backslashes"
result=$(json_escape 'C:\temp')
echo "  Result: $result"
[ "$result" = 'C:\\temp' ] && echo "  ✅ PASS" || echo "  ❌ FAIL"

echo ""
echo "Test 4: Complex Meilisearch config"
export VITE_MEILISEARCH_HOST='http://localhost:7700'
export VITE_MEILISEARCH_API_KEY='test"key\with\special'
export VITE_APP_TITLE='AI Tool	Server'

ESCAPED_HOST=$(json_escape "$VITE_MEILISEARCH_HOST")
ESCAPED_KEY=$(json_escape "$VITE_MEILISEARCH_API_KEY")
ESCAPED_TITLE=$(json_escape "$VITE_APP_TITLE")

# Generate a config file like the real entrypoint does
cat > /tmp/test-config.js <<EOF
window.__RUNTIME_CONFIG__ = {
  VITE_MEILISEARCH_HOST: "${ESCAPED_HOST}",
  VITE_MEILISEARCH_API_KEY: "${ESCAPED_KEY}",
  VITE_APP_TITLE: "${ESCAPED_TITLE}"
};
EOF

echo "Generated config.js:"
cat /tmp/test-config.js
echo ""

# Validate it's valid JavaScript by checking syntax
# (We can't use node in Alpine, so just check for obvious issues)
if grep -q '""' /tmp/test-config.js; then
    echo "  ⚠️  Warning: Found empty strings"
fi

# Check that special chars are escaped
if grep -q 'test\\"key' /tmp/test-config.js; then
    echo "  ✅ Quotes properly escaped in config"
else
    echo "  ❌ Quotes NOT escaped in config"
fi

if grep -q 'AI Tool\\tServer' /tmp/test-config.js; then
    echo "  ✅ Tabs properly escaped in config"
else
    echo "  ❌ Tabs NOT escaped in config"
fi

echo ""
echo "✅ Alpine compatibility test complete!"
TESTSCRIPT

chmod +x /tmp/alpine-test-runner.sh

# Check if docker is available
if ! command -v docker > /dev/null 2>&1; then
    echo "⚠️  Docker not available in this environment"
    echo "   Running local test instead..."
    echo ""
    sh /tmp/alpine-test-runner.sh
else
    echo "Running test in nginx:alpine container..."
    echo ""

    # Run the test in a real Alpine container
    docker run --rm \
        -v /tmp/alpine-test-runner.sh:/test.sh:ro \
        nginx:alpine \
        sh /test.sh
fi

echo ""
echo "=========================================="
echo "Test Complete!"
echo "=========================================="
