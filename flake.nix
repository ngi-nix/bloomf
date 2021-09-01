{
  description = "Efficient Bloom filters for OCaml";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.05";
    flake-utils.url = "github:numtide/flake-utils";
    ocaml-flake-utils.url = "git+https://git.sr.ht/~ilkecan/ocaml-flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ocaml-flake-utils }:
    let
      inherit (builtins)
        attrNames
        attrValues
        substring
      ;
      inherit (flake-utils.lib)
        defaultSystems
        eachSystem
      ;
      inherit (ocaml-flake-utils.lib { inherit nixpkgs; })
        createOverlays
        getOcamlPackages
        getOcamlPackagesFrom
      ;

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
    in
    {
      overlays = createOverlays derivations { inherit (nixpkgs) lib; };
      overlay = self.overlays.ocamlPackages-p2pcollab-bloomf;
    } // eachSystem supportedSystems (system:
      let
        inherit (pkgs.stdenv) isLinux;

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
