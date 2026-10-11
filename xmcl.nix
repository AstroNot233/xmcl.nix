{
  stdenv,
  fetchurl,
  gzip,
  ...
}:
let
  # config.json names the upstream repository and the asset suffix per system;
  # sources.json is the newest upstream version — prereleases included — and the
  # hash the update workflow pinned for it.
  config = builtins.fromJSON (builtins.readFile ./config.json);
  pinned = builtins.fromJSON (builtins.readFile ./sources.json);

  system = stdenv.hostPlatform.system;
  assets = builtins.listToAttrs (
    map (s: {
      name = s.name;
      value = s.asset;
    }) config.systems
  );
  suffix = assets.${system} or (throw "Unsupported system: ${system}");
  version = pinned.version;
in
stdenv.mkDerivation {
  pname = "xmcl-asar";
  version = version;
  src =
    let
      base = "${config.upstream_repo}/releases/download/v${version}";
    in
    fetchurl {
      url = "${base}/app-${version}-${suffix}.asar.gz";
      hash = pinned.hash.${system} or (throw "No hash for ${system} in sources.json");
    };
  nativeBuildInputs = [
    gzip
  ];
  unpackPhase = ''
    runHook preUnpack
    mkdir -p "$out"
    gzip -dc "$src" > "$out/xmcl.asar"
    runHook postUnpack
  '';
}
