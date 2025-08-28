{
  description = "Solana Transaction Signer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems =
        f:
        builtins.listToAttrs (
          map (system: {
            name = system;
            value = f system;
          }) systems
        );

      mkPkgs = system: import nixpkgs { inherit system; };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;

          inherit (pkgs) lib;
        in
        {
          default = pkgs.rustPlatform.buildRustPackage (
            finalAttrs:
            let
              toml = with builtins; (fromTOML (readFile "${finalAttrs.src}/Cargo.toml"));
            in
            {
              pname = "solana-tx-signer";
              version = toml.package.version;
              src = self;

              cargoLock = {
                lockFile = "${finalAttrs.src}/Cargo.lock";
              };

              nativeBuildInputs = with pkgs; [
                pkg-config
              ];

              buildInputs = with pkgs; [
                openssl
                udev
              ];

              env = {
                OPENSSL_NO_VENDOR = 1;
              };

              meta = {
                description = "Bare-bones tool to sign raw Solana transaction messages with a keyfile.";
                homepage = toml.package.repository;
                sourceProvenance = [ lib.sourceTypes.fromSource ];

                license = with lib.licenses; [
                  asl20
                  mit
                ];

                maintainers = [
                  {
                    name = "Thomas Lambertz";
                    email = "thomas.lambertz@neodyme.io";
                    github = "tlambertz";
                    githubId = 58152939;
                  }
                ];
              };
            }
          );
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.default ];

            env = {
              OPENSSL_NO_VENDOR = 1;
            };
          };
        }
      );
    };
}
