self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption mkIf;
in
{
  options.programs.xmcl = {
    enable = mkEnableOption "X Minecraft Launcher";
    jres = mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      description = ''
        A list of packages of JREs/JDKs to be written into the Java list.
      '';
      example = [ pkgs.jre8 ];
    };
    root = mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = ''
        Directory the launcher keeps its game data in, written to the `root`
        file of its config directory. Left unset, the launcher asks for a path
        on first start instead.
      '';
      example = "/opt/MinecraftX";
    };
    settings = mkOption {
      type = with lib.types; attrsOf anything;
      default = { };
      description = ''
        Launcher settings, written to `setting.json`. Only the keys set here end
        up in the file: the launcher falls back to its own default for every key
        it does not find, so this is a patch and not a whole file. The keys are
        the ones the settings page writes — `locale`, `globalMinMemory`,
        `globalMaxMemory`, `globalVmOptions`, `globalMcOptions`, `globalEnv`,
        `httpProxy`, `disableTelemetry`, and so on.
      '';
      example = {
        locale = "zh-CN";
        globalMaxMemory = 8192;
        globalVmOptions = [ "-XX:+UseZGC" ];
        disableTelemetry = true;
      };
    };
    theme = mkOption {
      type = with lib.types; attrsOf anything;
      default = { };
      description = ''
        Theme, written to `theme.json`. A patch as well: the renderer falls back
        to its own default per key. Not to be confused with the `theme` key of
        {option}`settings`, which is the light/dark/system mode this theme is
        drawn in.
      '';
      example = {
        settings = {
          dark = true;
          fontSize = 18;
        };
      };
    };
    launchEnv = mkOption {
      type = with lib.types; attrsOf anything;
      default = { };
      description = ''
        Environment variables or flags to be passed to XMCL.
      '';
      example = {
        WEBKIT_DISABLE_DMABUF_RENDERER = 1;
      };
    };
    launchArg = mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = ''
        Launch options to be passed to XMCL.
      '';
      example = [
        "--electron_ozone_platform_hint=auto"
      ];
    };
  };

  config =
    let
      cfg = config.programs.xmcl;
    in
    mkIf cfg.enable {
      home.packages = [ (pkgs.callPackage ./package.nix { inherit (cfg) launchEnv launchArg; }) ];
      xdg.desktopEntries.xmcl = {
        categories = [ "Game" ];
        exec = "xmcl";
        icon = ./logo.png;
        name = "X Minecraft Launcher";
        terminal = false;
        type = "Application";
      };
      xdg.configFile."xmcl/java.json" = mkIf (cfg.jres != [ ]) {
        text = builtins.toJSON {
          all = builtins.map (jre: rec {
            path = "${jre}/bin/java";
            version = lib.getVersion jre;
            majorVersion =
              with lib;
              with versions;
              toInt ((if (toInt (major version) == 1) then minor else major) version);
          }) cfg.jres;
        };
      };
      xdg.configFile."xmcl/root" = mkIf (cfg.root != null) {
        text = cfg.root;
      };
      xdg.configFile."xmcl/setting.json" = mkIf (cfg.settings != { }) {
        text = builtins.toJSON cfg.settings;
      };
      xdg.configFile."xmcl/theme.json" = mkIf (cfg.theme != { }) {
        text = builtins.toJSON cfg.theme;
      };
    };
}
