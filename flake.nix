{
  description = "Efficient Bloom filters for OCaml";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.05";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
    nix-utils = {
      url = "sourcehut:~ilkecan/nix-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, nix-utils, ... }@inputs:
    let
      inherit (builtins)
        attrNames
        attrValues
      ;
      inherit (flake-utils.lib)
        defaultSystems
        eachSystem
      ;
      nix-filter = inputs.nix-filter.lib;
      inherit (nix-utils.lib)
        createOcamlOverlays
        getOcamlPackages
        getOcamlPackagesFrom
        getUnstableVersion
      ;

      supportedSystems = defaultSystems;
      commonArgs = {
        version = getUnstableVersion self.lastModifiedDate;
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
    in
    {
      overlays = createOcamlOverlays derivations { inherit nix-filter; };
      overlay = self.overlays.ocamlPackages-p2pcollab-bloomf;
    } // eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = attrValues self.overlays;
        };

        packageNames = attrNames derivations;
        defaultOcamlPackages = getOcamlPackagesFrom pkgs packageNames "ocamlPackages";
      in
      rec {
        checks = packages;

        packages = getOcamlPackages pkgs packageNames;
        defaultPackage = packages.ocamlPackages-p2pcollab-bloomf;

        hydraJobs = {
          build = defaultOcamlPackages;
        };

        devShell =
          let
            packages = attrValues defaultOcamlPackages;
          in
          pkgs.mkShell {
            inherit packages;
            inputsFrom = packages;
          };
      });
}
