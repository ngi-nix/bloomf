{
  description = "Efficient Bloom filters for OCaml";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.05";
    flake-utils.url = "github:numtide/flake-utils";
    ocaml-flake-utils.url = "git+https://git.sr.ht/~ilkecan/ocaml-flake-utils";
    source-utils.url = "git+https://git.sr.ht/~ilkecan/source-utils";
    version-utils.url = "git+https://git.sr.ht/~ilkecan/version-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ocaml-flake-utils, source-utils, version-utils }:
    let
      inherit (builtins)
        attrNames
        attrValues
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
      inherit (source-utils.lib { inherit (nixpkgs) lib; })
        filterSource
      ;
      inherit (version-utils.lib)
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
      overlays = createOverlays derivations { inherit (nixpkgs) lib; inherit filterSource; };
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
