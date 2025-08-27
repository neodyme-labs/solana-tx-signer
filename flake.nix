{
  description = "Solana Transaction Signer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];

    forAllSystems = f:
      builtins.listToAttrs (map (system: {
        name = system;
        value = f system;
      }) systems);

    mkPkgs = system: import nixpkgs { inherit system; };
  in {
    packages = forAllSystems (system:
      let pkgs = mkPkgs system;
      in {
        default = pkgs.rustPlatform.buildRustPackage {
          pname = "solana-tx-signer";
          version = "0.1.0";
          src = ./.;
          cargoLock = { lockFile = ./Cargo.lock; };

          nativeBuildInputs = [
            pkgs.pkg-config
          ];

          buildInputs = [
            pkgs.openssl
            pkgs.udev
          ];

          OPENSSL_NO_VENDOR = 1;
        };
      });

    apps = forAllSystems (system: {
      default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/solana-tx-signer";
      };
    });

    devShells = forAllSystems (system:
      let pkgs = mkPkgs system;
      in {
        default = pkgs.mkShell {
          buildInputs = [
            pkgs.rustc
            pkgs.cargo
            pkgs.pkg-config
            pkgs.openssl
            pkgs.udev
          ];
          OPENSSL_NO_VENDOR = 1;
        };
      });
  };
}
