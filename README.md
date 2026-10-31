<p align="center">
  <img alt="Logo" width="100" src="./logo.png">
</p>

# xmcl.nix

自动跟随上游发布的 [X Minecraft Launcher](https://xmcl.app) Nix flake：始终打包上游最新的版本；\
版本与各平台 source hash 由 [update 工作流](./.github/workflows/update.yml) 刷新，每次更新以与上游同名的 `v<version>` 添加 tag。\
启动器本身见[官网](https://xmcl.app)与[上游仓库](https://github.com/Voxelum/x-minecraft-launcher)。

A Nix flake for [X Minecraft Launcher](https://xmcl.app) that packages the newest upstream version, prereleases included;\
the [update workflow](./.github/workflows/update.yml) refreshes its version and per-platform source hashes, tagging every bump as `v<version>`.\
See the [website](https://xmcl.app) and the [upstream repository](https://github.com/Voxelum/x-minecraft-launcher) for the launcher itself.

[![update](https://github.com/AstroNot233/xmcl.nix/actions/workflows/update.yml/badge.svg)](https://github.com/AstroNot233/xmcl.nix/actions/workflows/update.yml)

<!-- BEGIN PACKAGED -->

| Ref | `x86_64-linux` | `aarch64-linux` | Updated |
| --- | :---: | :---: | --- |
| [`v0.73.0`](https://github.com/Voxelum/x-minecraft-launcher/releases/tag/v0.73.0) | ✅ [`URJe5hhh…`](https://github.com/Voxelum/x-minecraft-launcher/releases/download/v0.73.0/app-0.73.0-linux.asar.gz) | ✅ [`K1hiDMLA…`](https://github.com/Voxelum/x-minecraft-launcher/releases/download/v0.73.0/app-0.73.0-linux-arm64.asar.gz) | 2026-10-31 |

<!-- END PACKAGED -->

| 图例 Legend | 描述 Description |
|:---:|:---|
| `✅` | hash 由 update 工作流从上游产物直接取得 · hash taken from the upstream artifact by the update workflow |
| `—` | 上游当前没有可用的版本 · upstream has no usable release right now |

## 用法 | Usage

```sh
# 试用 | Trial
nix run github:AstroNot233/xmcl.nix

# 安装到 profile | Install to user profile
nix profile add github:AstroNot233/xmcl.nix
nix profile remove xmcl.nix
```

### home-manager

```nix
# flake.nix
inputs = {
  # ...
  xmcl = {
    url = "github:AstroNot233/xmcl.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

```nix
# home.nix
imports = [ inputs.xmcl.homeModules ];
programs.xmcl = {
  enable = true;
  root = "/opt/MinecraftX";
  settings = {
    locale = "zh-CN";
    globalMaxMemory = 8192;
    disableTelemetry = true;
  };
  jres = [ pkgs.jdk21 ];
};
```

可选属性：

| 键 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `enable` | `bool` | `false` | 设为 `true` 以启用 X Minecraft Launcher。 |
| `jres` | `list of package` | `[ ]` | 写入启动器 Java 列表的 JRE/JDK。 |
| `root` | `str` | `null` | 游戏数据目录，写进配置目录的 `root`；不设时由启动器首次启动引导选择。 |
| `settings` | `attrs` | `{ }` | 启动器设置，写入 `setting.json`，例如 `locale`、`globalMaxMemory`、`globalVmOptions`、`httpProxy`、`disableTelemetry`。 |
| `theme` | `attrs` | `{ }` | 主题，写入 `theme.json`。 |
| `launchEnv` | `attrs` | `{ }` | 启动时额外的环境变量，例如 `{ WEBKIT_DISABLE_DMABUF_RENDERER = 1; }`。 |
| `launchArg` | `list of string` | `[ ]` | 传给启动器的启动参数。 |

### 锁定版本 | Pin a version

Tag 与上游同名（`v<version>`），可直接锁定到某一版本。

```nix
inputs.xmcl.url = "github:AstroNot233/xmcl.nix?ref=v0.71.0";
```
