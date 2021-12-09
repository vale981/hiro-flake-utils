{
  outputs = { self }: {
    lib = rec {
      currentDefaultPackage = flake: system: flake.defaultPackage.${system};
      makeDefaultPackageOverrides =
        flakes: inputs: system:
        let
          body = (builtins.listToAttrs (builtins.map
          (name: {
            name = name;
            value = (currentDefaultPackage inputs.${name} system);
          })
          flakes));
        in (self: super:
          body
        );
    };
  };
}
