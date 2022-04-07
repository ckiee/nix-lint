{
  description = "nix-lint";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.11";
    flake-compat = {
      url = github:edolstra/flake-compat;
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-compat }:
    let
      supportedSystems =
        [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          lib = pkgs.lib;
          nodejs = pkgs.nodejs-16_x;
          y2n = pkgs.yarn2nix-moretea.override {
            inherit nodejs;
            yarn = pkgs.yarn.override { inherit nodejs; };
          };
        in {
          nix-lint = y2n.mkYarnPackage {
            name = "nix-lint";
            src = ./.;
            packageJSON = ./package.json;
            yarnLock = ./yarn.lock;
            yarnFlags = [ "--offline" "--frozen-lockfile" "--ignore-engines" ];
            pkgConfig = {
              tree-sitter-nix = {
                #nativeBuildInputs = lib.optionals pkgs.stdenv.isDarwin (with pkgs; [ xcbuild darwin.apple_sdk.frameworks.ApplicationServices ]);
                buildInputs = lib.optionals pkgs.stdenv.isDarwin (with pkgs; [ xcbuild darwin.apple_sdk.frameworks.ApplicationServices ]);
              };
              tree-sitter = {
                #nativeBuildInputs = lib.optionals pkgs.stdenv.isDarwin (with pkgs; [ xcbuild darwin.apple_sdk.frameworks.ApplicationServices ]);
                buildInputs = lib.optionals pkgs.stdenv.isDarwin (with pkgs; [ xcbuild darwin.apple_sdk.frameworks.ApplicationServices ]);
              };
            };

            postConfigure = ''
              cd deps/nix-lint
              yarn tsc
              # Will be patchShebang'ed.
              sed -i '1i#!/usr/bin/env node' built/index.js
              chmod +x built/index.js
              cd ../..
            '';

            yarnPreBuild = ''
              export PYTHON=${pkgs.python3}/bin/python3
              mkdir -p "$HOME/.cache/node-gyp/${nodejs.version}"
              echo 9 > "$HOME/.cache/node-gyp/${nodejs.version}/installVersion"
              ln -sfv "${nodejs}/include" "$HOME/.cache/node-gyp/${nodejs.version}"
            '';
          };
        });

      defaultPackage = forAllSystems (system: self.packages.${system}.nix-lint);
    };
}
