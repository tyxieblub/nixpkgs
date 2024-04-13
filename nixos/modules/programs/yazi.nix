{ config, lib, pkgs, ... }:

let
  cfg = config.programs.yazi;

  settingsFormat = pkgs.formats.toml { };

  names = [ "yazi" "theme" "keymap" ];
in
{
  options.programs.yazi = {
    enable = lib.mkEnableOption "yazi terminal file manager";

    package = lib.mkPackageOption pkgs "yazi" { };

    settings = lib.mkOption {
      type = with lib.types; submodule {
        options = lib.listToAttrs (map
          (name: lib.nameValuePair name (lib.mkOption {
            inherit (settingsFormat) type;
            default = { };
            description = ''
              Configuration included in `${name}.toml`.

              See https://yazi-rs.github.io/docs/configuration/${name}/ for documentation.
            '';
          }))
          names);
      };
      default = { };
      description = ''
        Configuration included in `$YAZI_CONFIG_HOME`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [ cfg.package ];
      variables.YAZI_CONFIG_HOME = "/etc/yazi/";
      etc = lib.attrsets.mergeAttrsList (map
        (name: lib.optionalAttrs (cfg.settings.${name} != { }) {
          "yazi/${name}.toml".source = settingsFormat.generate "${name}.toml" cfg.settings.${name};
        })
        names);
    };
  };
  meta = {
    maintainers = with lib.maintainers; [ linsui ];
  };
}
