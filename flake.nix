{
  description = "client for dummy-server, depends on a client generated from OpenAPI spec";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # I was using this input before I discovered a bug
    # openapi-generator.url = "github:OpenAPITools/openapi-generator";

    # I used this while I tested that bug's fix
    #openapi-generator.path = "path:/Users/matt/src/openapi-generator";

    # This is my fork with the fix, once it's merged, we can go back to using the official fork
    openapi-generator.url = "github:MatrixManAtYrService/openapi-generator";
  };

  outputs = { self, nixpkgs, flake-utils, openapi-generator }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        openapi-generator-cli-pkg = openapi-generator.packages.${system}.openapi-generator-cli;

        # Generated C client source code from OpenAPI spec
        generated-source = pkgs.stdenv.mkDerivation {
          pname = "dummy-client-generated";
          version = "1.0.0";

          src = ./.;

          nativeBuildInputs = [ openapi-generator-cli-pkg ];

          buildPhase = ''
            echo "🔧 Generating C client from OpenAPI specification..."
            
            ${openapi-generator-cli-pkg}/bin/openapi-generator-cli generate \
              -i dummy.openapi.json \
              -g c \
              -o generated \
              --package-name DummyServerClient \
              --additional-properties=packageCompany="Demo",packageAuthors="Demo",packageVersion="1.0.0"
            
            echo "✅ C client generated"
          '';

          installPhase = ''
            cp -r generated $out
          '';

          meta = with pkgs.lib; {
            description = "Generated C client source code from OpenAPI specification";
            license = licenses.mit;
            platforms = platforms.unix;
          };
        };

        # CMakeLists.txt content for the client app
        clientCMakeFile = builtins.readFile ./CMakeLists.txt;

        # Built C client binary that consumes the generated source
        client = pkgs.stdenv.mkDerivation {
          pname = "dummy-client";
          version = "1.0.0";

          src = ./.;

          nativeBuildInputs = with pkgs; [
            cmake
            pkg-config
          ];

          buildInputs = with pkgs; [
            curl
            openssl
          ];

          # Override phases since we don't have a CMakeLists.txt in the root
          configurePhase = "true";
          
          buildPhase = ''
            echo "🔧 Using pre-generated C client source..."
            
            # Copy the generated source from the generated-source package
            cp -r ${generated-source}/* ./
            
            echo "🔨 Building client application..."
            # Use the client application from src/main.c
            mkdir -p app
            cp src/main.c app/main.c
            
            # Build the example application
            mkdir -p app/build
            cd app/build
            
            # Create CMakeLists.txt for the example app from our local file
            cat > ../CMakeLists.txt << 'EOF'
${clientCMakeFile}EOF
            
            cmake ..
            make
            cd ../..
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp app/build/dummyclient_demo $out/bin/dummyclient
          '';

          meta = with pkgs.lib; {
            description = "C client for dummyserver built from generated OpenAPI code";
            homepage = "https://github.com/user/dummyclient";
            license = licenses.mit;
            platforms = platforms.unix;
            maintainers = [ ];
          };
        };
      in
      {
        packages = {
          inherit generated-source;
          default = client;
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
            echo "💡 Available packages:"
            echo "  nix build .#generated-source  # View generated C code"
            echo "  nix build .#default          # Build client binary"
            echo "  nix run                      # Run client demo"
            echo ""
            echo "🔍 To examine generated code:"
            echo "  ls \$(nix build .#generated-source --no-link --print-out-paths)/"
            echo ""
            echo "🌐 Make sure the server is running:"
            echo "  cd ../dummyserver && nix run"
          '';
        };
      }
    );
}
