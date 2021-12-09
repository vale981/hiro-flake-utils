{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix.url = "github:nix-community/poetry2nix";
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }: {
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

      poetry2nixWrapper = pythonInputs: {name, poetryArgs, buildInputs}:
        (flake-utils.lib.eachDefaultSystem (system:
          let
            overlay = nixpkgs.lib.composeManyExtensions [
              poetry2nix.overlay

              (final: prev:
            let overrides = prev.poetry2nix.overrides.withDefaults
              (makeDefaultPackageOverrides pythonInputs system);
            in
            {
              ${name} = (prev.poetry2nix.mkPoetryApplication {
                projectDir = ./.;
                preferWheels = true;
                overrides = overrides;
              });

              "${name}Shell" = (prev.poetry2nix.mkPoetryEnv {
                projectDir = ./.;
                overrides = overrides;
                preferWheels = true;
                editablePackageSources = {
                  ${name} = ./${name};
                };
              });
            })

        ];
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
          config.allowUnfree = true;
        };
      in
      rec {
        packages = {
          ${name} = pkgs.${name};
        };

        defaultPackage = packages.${name};
        devShell = pkgs."${name}Shell".env.overrideAttrs (oldAttrs: {
          buildInputs = (buildInputs.pkgs);
        });
      }));
    };
  };
}
