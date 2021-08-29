{ version
, homepage
, downloadPage
, changelog
, maintainers
, platforms
}:
{ lib
, ocamlPackages
, ...
}:

let
  inherit (builtins) any;
  inherit (lib) cleanSourceWith removePrefix hasPrefix;

  src = ./..;
  pname = "bloomf";
  packageName = "p2pcollab-${pname}";

  directoriesToKeep = [ "/src" "/test" ];
  filesToKeep = [
    "${pname}.opam"
    "dune-project"
  ];

  sourceFilter = name: type:
    let
      baseName = baseNameOf (toString name);
      relativePath = removePrefix (toString src) name;
    in
      any (file: baseName == file) filesToKeep ||
      any (dir: hasPrefix dir relativePath) directoriesToKeep;
in
ocamlPackages.buildDunePackage {
  pname = "bloomf";
  inherit version;

  src = cleanSourceWith { inherit src; filter = sourceFilter; name = packageName; };

  minimumOCamlVersion = "4.03";
  useDune2 = true;

  dontPatch = true;
  dontConfigure = true;

  buildInputs = with ocamlPackages; [
    bitv.out
  ];

  doCheck = true;
  checkInputs = with ocamlPackages; [
    alcotest.out
  ];

  meta = {
    description = "Efficient Bloom filters for OCaml";
    longDescription =
      "Bloom filters are memory and time efficient data structures allowing " +
      "probabilistic membership queries in a set.\n" +
      "A query negative result ensures that the element is not present in " +
      "the set, while a positive result might be a false positive, i.e. the " +
      "element might not be present and the BF membership query can return " +
      "true anyway.\n" +
      "Internal parameters of the BF allow to control its false positive " +
      "rate depending on the expected number of elements in it.";

    inherit homepage downloadPage changelog;

    license = lib.licenses.mit;
    inherit maintainers platforms;
  };
}
