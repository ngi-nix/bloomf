{
  description = "Efficient Bloom filters for OCaml";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      inherit (builtins) substring attrNames mapAttrs attrValues filter tryEval;
      inherit (nixpkgs.lib) getAttrs optionalAttrs hasPrefix forEach nameValuePair mapAttrs' foldl filterAttrs;
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

      ocamlScopeNames = filter (hasPrefix "ocamlPackages") (attrNames nixpkgs.legacyPackages.x86_64-linux.ocaml-ng);

      mergeSets = sets: foldl (l: r: l // r) {} sets;
    in
    {
      overlays = mergeSets (forEach ocamlScopeNames (ocamlScopeName:
        mapAttrs' (name: drv:
          nameValuePair
          "${ocamlScopeName}-${name}"
          (final: prev: {
            ocaml-ng = prev.ocaml-ng // {
              ${ocamlScopeName} = prev.ocaml-ng.${ocamlScopeName}.overrideScope'
                (final': prev': {
                  ${name} = drv { inherit (nixpkgs) lib; ocamlPackages = final'; };
                });
            };
          })
        ) derivations
      ));

      overlay = self.overlays.ocamlPackages-p2pcollab-bloomf;
    } // eachSystem supportedSystems (system:
      let
        inherit (pkgs.stdenv) isLinux;

        pkgs = import nixpkgs {
          inherit system;
          overlays = attrValues self.overlays;
        };

        filterBrokenPackages = packages:
          filterAttrs (_: drv: (tryEval drv.outPath).success) packages;

        packages = mergeSets (forEach ocamlScopeNames (ocamlScopeName:
          mapAttrs' (name: drv:
            nameValuePair
            "${ocamlScopeName}-${name}"
            drv
          ) (filterBrokenPackages (getAttrs packageNames pkgs.ocaml-ng.${ocamlScopeName}))
        ));
        defaultOcamlPackages = filterAttrs (key: _: hasPrefix "ocamlPackages-" key) packages;
      in
      {
        checks = packages;

        inherit packages;
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
