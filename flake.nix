{
  description = "Description for the project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      imports = [ inputs.treefmt-nix.flakeModule ];
      perSystem =
        { pkgs, ... }:
        {
          checks = {
            max-inputs =
              pkgs.runCommandWith
                {
                  name = "check-not-too-much-inputs";
                  runLocal = true;
                  derivationArgs.nativeBuildInputs = with pkgs; [
                    jq
                    yaml2json
                  ];
                }
                ''
                  set -euo pipefail

                  n="$(yaml2json < ${./.github/workflows/review.yml} \
                    | jq '.on.workflow_dispatch.inputs | keys | length' \
                    | tee $out)"

                  if [ "$n" -gt 10 ]; then
                    echo "ERROR: You have $n inputs. Max is 10."
                    exit 1
                  fi
                '';
          };

          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            programs.yamlfmt.enable = true;
          };
        };
    };
}
