{
  self,
  nixpkgs,
  set-and-setting,
  ...
}:
{
  packages =
    nixpkgs.lib.genAttrs
      [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ]
      (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.writeShellApplication {
            name = "lefthook-skill-registered";
            runtimeInputs = with pkgs; [ git ];
            text = builtins.readFile ./lefthook-skill-registered.sh;
          };
          setting = (set-and-setting.lib.mkSetting { inherit pkgs; }).materialized;
        }
      );

  devShells =
    nixpkgs.lib.genAttrs
      [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ]
      (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          fragments = [
            "base"
            "actions"
            "nix"
            "shell"
            "ascii"
            "markdown"
            "yaml"
          ];
          mat = set-and-setting.lib.materializationFor { inherit pkgs fragments; };
        in
        set-and-setting.lib.mkDevShells {
          inherit pkgs;
          basePackages = mat.packages;
          settingHook = ''
            ${self.packages.${system}.setting}/bin/sync-setting .
            _assemble_out="$(mktemp -d)"
            FRAGMENTS="${builtins.concatStringsSep " " fragments}" \
              out="$_assemble_out" \
              FRAGMENTS_DIR="${set-and-setting}/setting/integrations/lefthook" \
              bash "${set-and-setting}/setting/lib/assemble-lefthook.sh"
            cp -f "$_assemble_out/lefthook.yml" lefthook.yml
            rm -rf "$_assemble_out"
          '';
        }
      );

  checks =
    nixpkgs.lib.genAttrs
      [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ]
      (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          actionlintWrapper = pkgs.writeShellApplication {
            name = "lefthook-actionlint";
            runtimeInputs = [ pkgs.actionlint ];
            text = ''
              [ "$1" = "--check" ] && shift
              actionlint "$@"
            '';
          };
          workflowSrc = pkgs.lib.sources.sourceByRegex [ "^\\.github/workflows/.*" ] ./.;
        in
        (
          (set-and-setting.lib.checksFor {
            inherit pkgs;
            fragments = [
              "base"
              "nix"
              "shell"
              "ascii"
              "markdown"
              "yaml"
            ];
            src = ./.;
          })
          // {
            actionlint = set-and-setting.lib.mkLefthookCheck {
              inherit pkgs;
              wrapper = actionlintWrapper;
              src = workflowSrc;
              name = "actionlint";
              suffices = [
                ".yml"
                ".yaml"
              ];
            };
          }
        )
        // {
          dep-graph = set-and-setting.lib.mkDepGraphCheck {
            inherit pkgs;
            projectRoot = ./.;
          };
          default = pkgs.runCommand "checks" { } "touch $out";
        }
      );

  apps =
    nixpkgs.lib.genAttrs
      [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ]
      (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          fragments = [
            "base"
            "actions"
            "nix"
            "shell"
            "ascii"
            "markdown"
            "yaml"
          ];
          mat = set-and-setting.lib.materializationFor { inherit pkgs fragments; };
        in
        {
          confirm = {
            type = "app";
            program = "${
              pkgs.writeShellApplication {
                name = "confirm";
                runtimeInputs = [
                  pkgs.coreutils
                  pkgs.diffutils
                  pkgs.findutils
                  pkgs.gawk
                  pkgs.git
                  pkgs.gnugrep
                ]
                ++ mat.packages;
                text = ''
                  export FRAGMENTS_DIR="${set-and-setting}/setting/integrations/lefthook"
                  export ASSEMBLE_SCRIPT="${set-and-setting}/setting/lib/assemble-lefthook.sh"
                  export DETECT_SCRIPT="${set-and-setting}/setting/lib/detect-fragments.sh"
                  export SETTING_SRC="${self.packages.${pkgs.stdenv.hostPlatform.system}.setting}"
                  export CONFIRM_SCRIPT="${set-and-setting}/lib/confirm.sh"
                  export CONFIRM_REV="${set-and-setting.rev or "unknown"}"
                  bash "$CONFIRM_SCRIPT"
                '';
              }
            }/bin/confirm";
          };
        }
      );
}
