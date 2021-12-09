{
  outputs = { self }: {
    lib = {
      currentDefaultPackage = flake: system: flake.defaultPackage.${system};
    };
  };
}
