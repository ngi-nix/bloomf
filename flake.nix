{
  description = "Efficient Bloom filters for OCaml";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      inherit (builtins) substring attrNames mapAttrs attrValues;
      inherit (nixpkgs.lib) listToAttrs getAttrs optionalAttrs;
      inherit (flake-utils.lib) defaultSystems eachSystem;

      supportedSystems = defaultSystems;
      year = substring 0 4 self.lastModifiedDate;
      month = substring 4 2 self.lastModifiedDate;
      day = substring 6 2 self.lastModifiedDate;
      commonArgs = {
        version = "unstable-${year}-${month}-${day}";
        homepage = "https://p2pcollab.net/";
        downloadPage = "https://github.com/p2pcollab/bloomf/releases";
        changelog = "https://raw.githubusercontent.com/p2pcollab/bloomf/master/CHANGES.md";
        maintainers = [
          {
            name = "ilkecan bozdogan";
            email = "ilkecan@protonmail.com";
            github = "ilkecan";
            githubId = "40234257";
          }
        ];
        platforms = supportedSystems;
      };

      derivations = {
        p2pcollab-bloomf = import ./nix/p2pcollab-bloomf.nix commonArgs;
      };

      packageNames = attrNames derivations;
    in
    {
      overlays = mapAttrs
        (name: drv:
          (final: prev:
            listToAttrs [
              { name = name; value = drv final; }
            ]
          )
        )
        derivations;

      overlay = self.overlays.p2pcollab-bloomf;
    } // eachSystem supportedSystems (system:
      let
        inherit (pkgs.stdenv) isLinux;

        pkgs = import nixpkgs {
          inherit system;
          overlays = attrValues self.overlays;
        };
      in
      rec {
        checks = packages;

        packages = getAttrs packageNames pkgs;
        defaultPackage = pkgs.p2pcollab-bloomf;

        hydraJobs = {
          build = packages;
        };

        devShell =
          let
            packages' = attrValues packages;
          in
          pkgs.mkShell {
            packages = packages';
            inputsFrom = packages';
          };
      });
}
