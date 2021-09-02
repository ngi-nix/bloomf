{ version
, homepage
, downloadPage
, changelog
, maintainers
, platforms
, runFullTestSuite ? false
}:
{ lib
, filterSource
, ocamlPackages
, ...
}:

let
  pname = "bloomf";
  duneTestCommand = if runFullTestSuite then "build @runtest-rand" else "runtest";
in
ocamlPackages.buildDunePackage {
  inherit pname version;

  src = filterSource {
    src = ./..;
    directoriesToKeep = [
      "/src"
      "/test"
    ];
    filesToKeep = [
      "${pname}.opam"
      "dune-project"
    ];
    name = "p2pcollab-${pname}";
  };

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
  checkPhase = ''
    runHook preCheck
    dune ${duneTestCommand} -p ${pname} ''${enableParallelBuilding:+-j $NIX_BUILD_CORES}
    runHook postCheck
  '';

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
