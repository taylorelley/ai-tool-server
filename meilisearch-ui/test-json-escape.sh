#!/bin/sh
# Test script for JSON escaping function
# Validates POSIX-compatibility in Alpine/BusyBox environment

set -e

echo "=========================================="
echo "JSON Escape Function Test Suite"
echo "=========================================="
echo ""

# Source the json_escape function from entrypoint.sh
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

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test function
test_escape() {
    local test_name="$1"
    local input="$2"
    local expected="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    result=$(json_escape "$input")

    if [ "$result" = "$expected" ]; then
        echo "✅ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "❌ FAIL: $test_name"
        echo "   Input:    '$input'"
        echo "   Expected: '$expected'"
        echo "   Got:      '$result'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run tests
echo "Running JSON escape tests..."
echo ""

# Test 1: Simple string (no escaping needed)
test_escape "Simple string" \
    "hello world" \
    "hello world"

# Test 2: String with double quotes
test_escape "Double quotes" \
    'He said "Hello"' \
    'He said \"Hello\"'

# Test 3: String with backslashes
test_escape "Backslashes" \
    'C:\Windows\System32' \
    'C:\\Windows\\System32'

# Test 4: String with tabs
test_escape "Tabs" \
    "hello	world" \
    'hello\tworld'

# Test 5: String with newlines
test_escape "Newlines" \
    "line1
line2" \
    'line1\nline2'

# Test 6: Complex string with multiple special chars
test_escape "Complex string" \
    'Path: "C:\temp\file.txt"	Size: 1KB' \
    'Path: \"C:\\temp\\file.txt\"\tSize: 1KB'

# Test 7: Empty string
test_escape "Empty string" \
    "" \
    ""

# Test 8: String with only special characters
test_escape "Only special chars" \
    '"\	' \
    '\"\\\t'

# Test 9: URL (no escaping needed)
test_escape "URL" \
    "http://localhost:7700" \
    "http://localhost:7700"

# Test 10: API key format
test_escape "API key" \
    "abc123def456" \
    "abc123def456"

echo ""
echo "=========================================="
echo "Test Results"
echo "=========================================="
echo "Total tests:  $TESTS_RUN"
echo "Passed:       $TESTS_PASSED"
echo "Failed:       $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed!"
    exit 1
fi
