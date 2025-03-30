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

    # TODO: package
    # rustPlatform = let

    # in
    #   pkgs.makeRustPlatform {
    #     cargo = toolchain;
    #     rustc = toolchain;
    #   };

    python3 = pkgs.python313;
    nodejs = pkgs.nodejs_23;
  in {
    devShells.default = pkgs.mkShell.override {inherit stdenv;} {
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
  };
}
