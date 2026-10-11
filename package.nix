{
  callPackage,
  lib,
  symlinkJoin,
  launchEnv ? { },
  launchArg ? [ ],
  ...
}:
let
  enwrap = callPackage ./enwrap.nix { inherit launchEnv launchArg; };
  desktop = callPackage ./desktop.nix { };
in
symlinkJoin {
  name = "x-minecraft-launcher";
  paths = [
    enwrap
    desktop
  ];
  meta = {
    description = "X Minecraft Launcher";
    homepage = "https://xmcl.app";
    license = lib.licenses.mit;
    # What `nix run` executes.
    mainProgram = "xmcl";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
