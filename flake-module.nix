localFlake: {
  perSystem = {
    lib,
    config,
    system,
    pkgs,
    ...
  }: let
    inherit (pkgs.llvmPackages_latest) clang bintools stdenv;
    inherit (localFlake.withSystem system ({inputs', ...}: inputs'.fenix.packages.minimal)) toolchain;

    rustPlatform = let
    in
      pkgs.makeRustPlatform {
        cargo = toolchain;
        rustc = toolchain;
      };

    python3 = pkgs.python313;
    nodejs = pkgs.nodejs_23;

    common = {
      nativeBuildInputs = with pkgs;
        [
          sqlcipher
          yarn
        ]
        ++ [
          nodejs
          python3
          clang
          bintools
          toolchain
        ];

      RUSTFLAGS =
        lib.concatMapStringsSep " " (x: "-C ${x}") [
          "target-cpu=apple-m1"
          "codegen-units=1"
          "embed-bitcode=yes"
          "linker=${clang}/bin/cc"
          "link-args=-fuse-ld=lld"
          "lto=thin"
          "opt-level=3"
          "strip=symbols"
        ]
        + " -Zdylib-lto";
      env = {
        NIX_ENFORCE_NO_NATIVE = 0;
        NIX_ENFORCE_PURITY = 0;
      };

      enableParallelBuilding = true;
      hardeningDisable = ["all"];
    };
  in {
    devShells.default = pkgs.mkShell.override {inherit stdenv;} common;

    packages.seshat = rustPlatform.buildRustPackage rec {
      pname = "seshat-node";
      version = "4.0.1";

      src = ./seshat-node;

      cargoLock = {
        lockFile = src + "/Cargo.lock";
      };

      useFetchCargoVendor = true;
      doCheck = false;

      nativeBuildInputs =
        common.nativeBuildInputs
        ++ [
          pkgs.fixup-yarn-lock
        ];

      inherit (common) RUSTFLAGS env enableParallelBuilding hardeningDisable;

      buildInputs = [pkgs.sqlcipher];

      yarnOfflineCache = pkgs.fetchYarnDeps {
        yarnLock = src + "/yarn.lock";
        sha256 = "sha256-hh9n8By/dNdKS55rcZkzCxmJWwQa6Ovt+4M3YP3/hDs=";
      };

      buildPhase = ''
        runHook preBuild

        chmod u+w . ./yarn.lock
        export HOME=$PWD/tmp
        mkdir -p $HOME
        yarn config --offline set yarn-offline-mirror $yarnOfflineCache
        fixup-yarn-lock yarn.lock
        yarn --offline --frozen-lockfile --ignore-platform --ignore-scripts --no-progress --non-interactive
        yarn run build-bundled

        runHook postBuild
      '';
    };
  };
}
