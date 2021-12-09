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
          in
          (self: super:
            body
          ));

      poetry2nixWrapper = nixpkgs:
        { name
        , poetryArgs ? { }
        , shellPackages ? (_: [ ])
        , nixpkgsConfig ? { }
        , addCythonTo ? [ ]
        , noPackage ? false
        , shellOverride ? (_: { })
        }:
        (flake-utils.lib.eachDefaultSystem (system:
          let
            overlay = nixpkgs.lib.composeManyExtensions [
              poetry2nix.overlay

              (final: prev:
                let overrides = # custom overrides for packages that require cython
                  (self: super: {
                    fcspline = super.fcspline.overridePythonAttrs (
                      old: {
                        buildInputs = (old.buildInputs or [ ]) ++ [
                          self.cython
                        ];
                      }
                    );

                    stocproc = super.stocproc.overridePythonAttrs (
                      old: {
                        buildInputs = (old.buildInputs or [ ]) ++ [
                          self.cython
                        ];
                      }
                    );
                  });
                in
                {
                  "${name}Shell" = (prev.poetry2nix.mkPoetryEnv ({
                    overrides = overrides;
                    preferWheels = true;
                    editablePackageSources = {
                      ${name} = poetryArgs.projectDir + "/${name}";
                    };
                  } // poetryArgs));
                } // (if noPackage then { } else {
                  ${name} = (prev.poetry2nix.mkPoetryApplication ({
                    preferWheels = true;
                    overrides = overrides;
                  } // poetryArgs));
                }))
            ];
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ overlay ];
              config = nixpkgsConfig;
            };
          in
          rec {
            devShell = (pkgs."${name}Shell".env.overrideAttrs (oldAttrs: {
              buildInputs = (shellPackages pkgs) ++ [ pkgs.poetry ];
            })).overrideAttrs shellOverride;
          } // (if noPackage then { } else rec {
            packages = {
              ${name} = pkgs.${name};
            };

            defaultPackage = packages.${name};
          })
        ));
    };
  };
}
