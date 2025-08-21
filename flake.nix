{
  description = "C++ client application for dummyserver";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        
        # Custom cpprestsdk package
        cpprestsdk = pkgs.callPackage ./nix/cpprestsdk.nix { };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # OpenAPI client generation
            openapi-generator-cli
            
            # C++ development tools
            cmake
            gcc
            pkg-config
            
            # HTTP client libraries (for cpp-restsdk generator)
            cpprestsdk
            boost
            openssl
            
            # JSON library
            nlohmann_json
            
            # Build utilities
            gnumake
            ninja
          ];
          
          shellHook = ''
            echo "🚀 C++ dummyserver client development environment"
            echo "📋 Available commands:"
            echo "  - openapi-generator-cli: Generate C++ client from OpenAPI spec"
            echo "  - cmake: Build system"
            echo "  - gcc: C++ compiler"
            echo ""
            echo "💡 To generate the C++ client:"
            echo "  ./generate-client.sh"
            echo ""
            echo "📁 Project structure:"
            echo "  - dummy.openapi.json: OpenAPI specification"
            echo "  - generated/: Generated C++ client code (after running generate-client.sh)"
            echo "  - src/: Your C++ application code"
          '';
        };
      }
    );
}