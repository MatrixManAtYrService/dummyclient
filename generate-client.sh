#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Generating C++ client from OpenAPI specification..."

# Clean previous generation
rm -rf generated/

# Generate C++ client using cpp-restsdk generator
openapi-generator-cli generate \
  -i dummy.openapi.json \
  -g cpp-restsdk \
  -o generated \
  --package-name DummyServerClient \
  --additional-properties=packageCompany="Demo",packageAuthors="Demo",packageVersion="1.0.0"

echo "✅ C++ client generated in ./generated/"
echo ""
echo "📋 Generated files:"
echo "  - generated/include/: Header files"
echo "  - generated/src/: Implementation files" 
echo "  - generated/CMakeLists.txt: Build configuration"
echo ""
echo "💡 Next steps:"
echo "  1. Review the generated client in ./generated/"
echo "  2. Build your application in ./src/ that uses the client"
echo "  3. Use CMake to build: mkdir build && cd build && cmake .. && make"