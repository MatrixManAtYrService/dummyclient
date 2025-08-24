{
  description = "C client application for dummyserver generated from OpenAPI spec";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    openapi-generator.url = "path:/Users/matt/src/openapi-generator";
  };

  outputs = { self, nixpkgs, flake-utils, openapi-generator }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        openapi-generator-cli-pkg = openapi-generator.packages.${system}.openapi-generator-cli;
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "dummyclient";
          version = "1.0.0";

          src = ./.;

          nativeBuildInputs = with pkgs; [
            cmake
            pkg-config
          ] ++ [
            openapi-generator-cli-pkg
          ];

          buildInputs = with pkgs; [
            curl
            openssl
          ];

          # Override phases since we don't have a CMakeLists.txt in the root
          configurePhase = "true";
          
          buildPhase = ''
            echo "🔧 Generating C client from OpenAPI specification..."
            
            # Generate C client using local openapi-generator-cli
            ${openapi-generator-cli-pkg}/bin/openapi-generator-cli generate \
              -i dummy.openapi.json \
              -g c \
              -o generated \
              --package-name DummyServerClient \
              --additional-properties=packageCompany="Demo",packageAuthors="Demo",packageVersion="1.0.0"
            
            echo "✅ C client generated"
            
            # Force static library in the generated CMakeLists.txt
            echo "🔧 Patching generated CMakeLists.txt for static linking..."
            cd generated
            sed -i 's/BUILD_SHARED_LIBS ON/BUILD_SHARED_LIBS OFF/' CMakeLists.txt
            sed -i '1a set(BUILD_SHARED_LIBS OFF)' CMakeLists.txt
            
            # ============================================================================
            # PATCH 1: Fix enum serialization in action_type_convertToJSON()
            # ============================================================================
            # 
            # PROBLEM: OpenAPI-Generator C client incorrectly serializes enum values as 
            # nested objects instead of direct string values.
            #
            # OpenAPI Spec shows:
            #   "ActionType": {
            #     "type": "string",
            #     "enum": ["add", "subtract"]
            #   }
            #
            # Generated code incorrectly produces:
            #   {"action": {"action_type": "add"}, "value": 25}
            #
            # Server expects (and spec implies):
            #   {"action": "add", "value": 25}
            #
            # Server response to incorrect JSON:
            #   HTTP 422 Unprocessable Entity - validation error
            #
            # ROOT CAUSE: The generated action_type_convertToJSON() creates a cJSON object
            # with a "action_type" property containing the enum string, rather than 
            # returning the enum string directly as a cJSON string value.
            #
            # This appears to be a bug in openapi-generator-cli for C client generation
            # when handling enum types. The generator should recognize that when an enum
            # is used as a property value, it should serialize to the string directly,
            # not wrap it in an additional object layer.
            #
            # WORKAROUND: Replace the entire function to return cJSON_CreateString()
            # directly instead of creating a nested object structure.
            #
            echo "🔧 Patching action_type.c JSON serialization bug..."
            # Replace the entire action_type_convertToJSON function
            cat > temp_fix.c << 'PATCH_EOF'
cJSON *action_type_convertToJSON(dummy_server_action_type__e action_type) {
    // Fixed: return string directly instead of nested object
    return cJSON_CreateString(action_type_action_type_ToString(action_type));
}
PATCH_EOF
            
            # Replace the function in the file
            sed -i '/^cJSON \*action_type_convertToJSON/,/^}$/c\
cJSON *action_type_convertToJSON(dummy_server_action_type__e action_type) {\
    \/\/ Fixed: return string directly instead of nested object\
    return cJSON_CreateString(action_type_action_type_ToString(action_type));\
}' model/action_type.c
            
            rm -f temp_fix.c
            
            # ============================================================================
            # PATCH 2: Fix array response parsing in DefaultAPI_getLogLogGet()
            # ============================================================================
            #
            # PROBLEM: OpenAPI-Generator C client incorrectly parses JSON arrays as 
            # key-value pairs, causing segmentation faults when array elements don't 
            # have string keys.
            #
            # OpenAPI Spec shows:
            #   "/log": {
            #     "get": {
            #       "responses": {
            #         "200": {
            #           "content": {
            #             "application/json": {
            #               "schema": {
            #                 "items": {
            #                   "additionalProperties": true,
            #                   "type": "object"
            #                 },
            #                 "type": "array"
            #               }
            #             }
            #           }
            #         }
            #       }
            #     }
            #   }
            #
            # Server actually returns:
            #   [
            #     {"action": "initialize", "value": 70},
            #     {"action": "add", "value": 25},
            #     {"action": "subtract", "value": 10}
            #   ]
            #
            # Generated code incorrectly assumes:
            #   {
            #     "key1": {"action": "add", "value": 25},
            #     "key2": {"action": "subtract", "value": 10}
            #   }
            #
            # ROOT CAUSE: The generated parsing code calls:
            #   keyValuePair_create(strdup(VarJSON->string), cJSON_Print(VarJSON))
            # 
            # But for array elements, VarJSON->string is NULL (arrays don't have keys),
            # so strdup(NULL) causes a segmentation fault.
            #
            # The generator appears to incorrectly assume that any JSON response 
            # returning a list_t should be parsed as key-value pairs rather than 
            # as a simple array of objects.
            #
            # WORKAROUND: Replace the parsing logic to store cJSON objects directly
            # in the list using cJSON_Duplicate(), which properly handles array elements.
            # The client code can then iterate through the list and access each 
            # cJSON object safely.
            #
            echo "🔧 Patching DefaultAPI.c log endpoint bug..."
            # Replace the buggy log parsing logic
            sed -i '/cJSON_ArrayForEach(VarJSON, localVarJSON){/,/}/c\
        cJSON_ArrayForEach(VarJSON, localVarJSON){\
            \/\/ Fixed: store cJSON objects directly instead of keyValuePairs\
            list_addElement(elementToReturn, cJSON_Duplicate(VarJSON, 1));\
        }' api/DefaultAPI.c
            
            # Build the generated client library as static
            echo "🔨 Building client library..."
            mkdir -p build
            cd build
            cmake -DBUILD_SHARED_LIBS=OFF ..
            make
            cd ../..
            
            echo "🔨 Building client application..."
            # Use the client application from src/main.c
            mkdir -p app
            cp src/main.c app/main.c
            
            # Build the example application
            mkdir -p app/build
            cd app/build
            
            # Create CMakeLists.txt for the example app that includes all source files directly
            cat > ../CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(dummyclient_demo C)

# Find required packages
find_package(PkgConfig REQUIRED)
find_package(OpenSSL REQUIRED)
pkg_check_modules(CURL REQUIRED libcurl)

# Collect all the generated source files
file(GLOB CLIENT_SOURCES
    ../generated/src/*.c
    ../generated/model/*.c
    ../generated/api/*.c
    ../generated/external/cJSON.c
)

# Create the demo executable with all sources compiled directly
add_executable(dummyclient_demo 
    main.c
    ''${CLIENT_SOURCES}
)

# Link libraries
target_link_libraries(dummyclient_demo 
    ''${CURL_LIBRARIES}
    OpenSSL::SSL 
    OpenSSL::Crypto
)

# Include directories
target_include_directories(dummyclient_demo PRIVATE
    ../generated/include
    ../generated/model
    ../generated/api
    ../generated/external
    ''${CURL_INCLUDE_DIRS}
)
EOF
            
            cmake ..
            make
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp ./dummyclient_demo $out/bin/dummyclient
            
            # Also install the generated client library for others to use
            mkdir -p $out/lib
            cp generated/build/libdummy_server.* $out/lib/ 2>/dev/null || true
            
            # Install headers
            mkdir -p $out/include
            cp -r generated/include/* $out/include/ 2>/dev/null || true
            cp -r generated/model/*.h $out/include/ 2>/dev/null || true
            cp -r generated/api/*.h $out/include/ 2>/dev/null || true
          '';

          meta = with pkgs.lib; {
            description = "C client for dummyserver generated from OpenAPI specification";
            homepage = "https://github.com/user/dummyclient";
            license = licenses.mit;
            platforms = platforms.unix;
            maintainers = [ ];
          };
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/dummyclient";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Tools for development/debugging
            cmake
            pkg-config
            curl
            openssl
            gdb
            
            # JSON tools for debugging
            jq
          ] ++ [
            # Local openapi-generator-cli
            openapi-generator-cli-pkg
          ];
          
          shellHook = ''
            echo "🚀 Dummy Client Development Environment"
            echo "======================================"
            echo ""
            echo "📋 Available commands:"
            echo "  - openapi-generator-cli: Generate clients from OpenAPI specs"
            echo "  - cmake: Build system"
            echo "  - curl: HTTP client for testing"
            echo "  - jq: JSON processor for API responses"
            echo ""
            echo "💡 To run the client demo:"
            echo "  nix run"
            echo ""
            echo "🔧 To rebuild after changes:"
            echo "  nix build"
            echo ""
            echo "🌐 Make sure the server is running:"
            echo "  cd ../dummyserver && nix run"
          '';
        };
      }
    );
}
