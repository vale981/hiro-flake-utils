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

      overrides = (self: super: {
                    future = super.future.overridePythonAttrs (
                      old: {
                        buildInputs = (old.buildInputs or [ ]) ++ [
                          self.setuptools
                        ];
                      }
                    );

                    sqlitedict = super.sqlitedict.overridePythonAttrs (
                      old: {
                        buildInputs = (old.buildInputs or [ ]) ++ [
                          self.setuptools
                        ];
                      }
                    );

                    fcspline = super.fcspline.overridePythonAttrs (
                      old: {
                        buildInputs = (old.buildInputs or [ ]) ++ [
                          self.cython
                          self.poetry
                        ];
                      }
                    );

                    progression = super.progression.overridePythonAttrs (
                      old: {
                        buildInputs = (old.buildInputs or [ ]) ++ [
                          self.poetry
                        ];
                      }
                    );

                    binfootprint = super.binfootprint.overridePythonAttrs (
                      old: {
                        buildInputs = (old.buildInputs or [ ]) ++ [
                          self.poetry
                        ];
                      }
                    );

                    qutip = super.qutip.overridePythonAttrs (
                      old: {
                        buildInputs = (old.buildInputs or [ ]) ++ [
                          self.cython
                        ];
                      }
                    );

                    stocproc = super.stocproc.overridePythonAttrs (
                      old: {
                        buildInputs = (old.buildInputs or [ ]) ++ [
                          self.poetry
                          self.cython
                        ];
                      }
                    );

                    two-qubit-model = super.two-qubit-model.overridePythonAttrs (
                      old: {
                        buildInputs = (old.buildInputs or [ ]) ++ [
                          self.poetry
                        ];
                      }
                    );

                    hiro-models = super.hiro-models.overridePythonAttrs (
                      old: {
                        buildInputs = (old.buildInputs or [ ]) ++ [
                          self.poetry
                        ];
                      }
                    );

                    hopsflow = super.hopsflow.overridePythonAttrs (
                      old :{
                        buildInputs = old.buildInputs or [ ] ++ [
                          self.poetry
                        ];
                      }
                    );

                    hops = super.hops.overridePythonAttrs (
                      old :{
                        buildInputs = old.buildInputs or [ ] ++ [
                          self.poetry
                        ];
                      }
                    );

                    jupyter = super.jupyter-core.overridePythonAttrs (
                      old: {
                        postInstall = ''
                          rm $out/lib/python*/site-packages/__pycache__/jupyter.cpython-39.pyc
                          rm $out/lib/python*/site-packages/jupyter.py
                        '';
                      }
                    );

                    matplotlib = super.matplotlib.override (
                      {
                        enableGtk3 = true;
                        enableTk = true;
                        #                        preferWheel = false;
                      }
                    );

                    numba = super.numba.override (
                      {
                        preferWheel = false;
                      });

                    numpy = super.numpy.override (
                      {
                        blas = super.mkl;
                      }
                    );
                  });

      poetry2nixWrapper = nixpkgs:
        { name
        , poetryArgs ? { }
        , shellPackages ? (_: [ ])
        , nixpkgsConfig ? { }
        , addCythonTo ? [ ]
        , noPackage ? false
        , shellOverride ? (_: _: { })
        , python ? (pkgs: pkgs.python310)
        , extraOverrides ? (_:_:{})
        , extraOverlay ? (_:_:{})
        }:
        (flake-utils.lib.eachDefaultSystem (system:
          let
            finalOverrides = nixpkgs.lib.composeManyExtensions [overrides extraOverrides];
            overlay = nixpkgs.lib.composeManyExtensions [
              poetry2nix.overlay
              extraOverlay
              (final: prev:
                {
                  "${name}Shell" = (prev.poetry2nix.mkPoetryEnv ({
                    overrides = finalOverrides;
                    preferWheels = true;
                    python = (python prev.pkgs);
                    editablePackageSources = {
                      ${name} = poetryArgs.projectDir + "/${name}";
                    };
                  } // poetryArgs));
                } // (if noPackage then { } else {
                  ${name} = (prev.poetry2nix.mkPoetryApplication ({
                    python = (python prev.pkgs);
                    preferWheels = true;
                    overrides = finalOverrides;
                  } // poetryArgs));
                }))
            ];
            pkgs = import nixpkgs {
              inherit system;
              overlays = [
                overlay
              ];
              config = nixpkgsConfig;
            };
          in
          rec {
            devShell = (pkgs."${name}Shell".env.overrideAttrs (oldAttrs: {
              buildInputs = (shellPackages pkgs) ++ [ pkgs.poetry ];
            })).overrideAttrs (shellOverride pkgs);
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
