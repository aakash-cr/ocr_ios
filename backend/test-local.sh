#!/bin/bash

echo "Testing local backend..."
echo ""

echo "1. Testing health endpoint..."
curl -s http://localhost:8080/health
echo -e "\n"

if [ -f "test-image.jpg" ]; then
    echo "2. Testing extract endpoint with test-image.jpg..."
    curl -X POST http://localhost:8080/extract \
      -F "file=@test-image.jpg" \
      -H "Content-Type: multipart/form-data" | jq .
else
    echo "2. Skipping extract test (test-image.jpg not found)"
    echo "   Usage: curl -X POST http://localhost:8080/extract -F \"file=@your-image.jpg\""
fi

echo ""
echo "Done!"


