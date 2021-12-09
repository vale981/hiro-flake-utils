{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    lib = rec {
      currentDefaultPackage = flake: system: flake.defaultPackage.${system};
      makeDefaultPackageOverrides =
          (flakes: system:
        let
          body = (nixpkgs.lib.attrsets.mapAttrs'
            (name: flake:
              {
              name = nixpkgs.lib.strings.toLower name;
              value = (currentDefaultPackage flake system);
              })
            flakes);
        in (self: super:
          body
        ));
    };
  };
}
