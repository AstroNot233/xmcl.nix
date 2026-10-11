{ makeDesktopItem, ... }:
makeDesktopItem {
  categories = [ "Game" ];
  # desktopName is the entry's Name, name is the file it lands in.
  desktopName = "X Minecraft Launcher";
  exec = "xmcl";
  icon = ./logo.png;
  name = "X Minecraft Launcher";
  startupWMClass = "X Minecraft Launcher";
  terminal = false;
  type = "Application";
}
