{ inputs, lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "nix-index"
  ];

  homeImports = [ inputs.nix-index-database.homeModules.default ];

  homeConfig =
    _cfg:
    { config, lib, ... }:
    {
      programs = {
        nix-index.enable = true;
        nix-index-database.comma.enable = true;

        # nix-index suggests nix-env by default, override to suggest , or nix-shell
        bash.initExtra = lib.mkAfter ''
          command_not_found_handle() {
            local cmd="$1"
            local -a attrs=()

            if [[ -n "''${MC_SID-}" || ! -t 1 ]]; then
              printf '%s: command not found\n' "$cmd" >&2
              return 127
            fi

            mapfile -t attrs < <(
              ${config.programs.nix-index.package}/bin/nix-locate \
                --minimal --no-group --type x --type s --whole-name \
                --at-root "/bin/$cmd"
            )

            case "''${#attrs[@]}" in
              0)
                printf '%s: command not found\n' "$cmd" >&2
                ;;
              1)
                printf "The program '%s' is currently not installed. You can run it once with:\n" "$cmd" >&2
                printf '  , %s ...\n' "$cmd" >&2
                printf "  nix-shell -p %s --run '%s ...'\n" "''${attrs[0]}" "$cmd" >&2
                ;;
              *)
                printf "The program '%s' is currently not installed. You can run it once with:\n" "$cmd" >&2
                printf '  , %s ...\n' "$cmd" >&2
                printf 'Or select a package explicitly with:\n' >&2
                for attr in "''${attrs[@]}"; do
                  printf "  nix-shell -p %s --run '%s ...'\n" "$attr" "$cmd" >&2
                done
                ;;
            esac

            return 127
          }
        '';
      };
    };
}
