{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-review.url = "github:Mic92/nixpkgs-review";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-review,
    }:

    let
      inherit (nixpkgs) lib;

      eachSystem = f: lib.genAttrs systems (system: f (import nixpkgs { inherit system overlays; }));
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      overlays = [ self.overlays.nixpkgs-review ];
    in

    {
      overlays.nixpkgs-review = final: prev: {
        inherit (nixpkgs-review.packages.${final.stdenv.hostPlatform.system}) nixpkgs-review;
      };

      legacyPackages = eachSystem lib.id;

      formatter = eachSystem (
        pkgs:
        pkgs.treefmt.withConfig {
          settings = lib.mkMerge [
            ./treefmt.nix
            { _module.args = { inherit pkgs; }; }
          ];
        }
      );

      checks = eachSystem (pkgs: {
        inherit (pkgs) nixpkgs-review;
        fmt = pkgs.runCommand "fmt-check" { } ''
          cp -r --no-preserve=mode ${self} repo
          ${lib.getExe self.formatter.${pkgs.stdenv.hostPlatform.system}} -C repo --ci
          touch $out
        '';
      });
    };

  nixConfig = {
    abort-on-warn = true;
    commit-lock-file-summary = "chore: update flake.lock";
  };
}
