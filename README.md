# Dummy Server C++ Client

A C++ client application that communicates with the dummyserver API using an auto-generated client from the OpenAPI specification.

## Features

- Auto-generated C++ client from OpenAPI 3.1.0 specification
- HTTP REST client using cpp-restsdk (Microsoft's C++ REST SDK)
- Example application demonstrating number operations
- CMake-based build system

## Getting Started

### Prerequisites

Enter the Nix development shell:
```bash
nix develop
```

This provides:
- `openapi-generator-cli` - Generates C++ client from OpenAPI spec
- `cmake`, `gcc` - C++ build tools
- `cpprest`, `boost`, `openssl` - HTTP client dependencies
- `nlohmann_json` - JSON parsing

### Generate the C++ Client

Generate the client code from the OpenAPI specification:
```bash
./generate-client.sh
```

This will:
1. Read `dummy.openapi.json` (the OpenAPI spec)
2. Generate C++ client code in `./generated/`
3. Create headers, source files, and CMake configuration

**Generated Structure:**
```
generated/
├── CMakeLists.txt           # Build configuration
├── include/                 # Header files
│   └── DummyServerClient/   # Client classes
└── src/                     # Implementation files
    └── DummyServerClient/   # Client implementation
```

### Build and Run

After generating the client:
```bash
mkdir build
cd build
cmake ..
make
./dummy_client
```

## API Operations

The generated client provides methods for:

- **GET /** - Root welcome message
- **GET /number** - Get current number
- **POST /number** - Add or subtract from number
  - `{"action": "add", "value": 10}`
  - `{"action": "subtract", "value": 5}`
- **GET /log** - Get operation history

## Example Usage

The application in `src/main.cpp` demonstrates:
1. Getting the initial number
2. Performing add/subtract operations
3. Retrieving the operation log
4. Proper error handling

This shows your friend how to:
- Use auto-generated clients instead of writing HTTP code
- Focus on business logic rather than API implementation details
- Leverage OpenAPI specifications for type-safe API communication

## Development Workflow

1. **Server changes** → Update OpenAPI spec
2. **Regenerate client** → `./generate-client.sh`  
3. **Rebuild app** → `make` in build directory
4. **Client code stays in sync** with server automatically

This approach ensures the C++ client always matches the server's API contract!