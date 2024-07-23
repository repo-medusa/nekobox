{
  lib,
  clangStdenv,
  fetchFromGitHub,
  libsForQt5,
  cmake,
  ninja,
  protobuf,
  yaml-cpp,
  zxing-cpp,
  callPackage,
  makeDesktopItem,
  copyDesktopItems,

  v2ray-geoip,
  v2ray-domain-list-community,
  sing-geoip,
  sing-geosite,
}:

let
  fetchSource = args:
    fetchFromGitHub (
      args
      // {
        owner = "MatsuriDayo";
        repo = args.name;
      }
    );

  extraSources = {
    # revs found in https://github.com/MatsuriDayo/nekoray/blob/<version>/libs/get_source_env.sh
    sing-box = fetchSource {
      name = "sing-box";
      rev = "cf36758f11b7c144e1211801753cc91f06ff2906";
      hash = "sha256-4WDT4X6vErTr3Byk5YYqGu1FeEBzSYqnMIsNrX1TVXM=";
    };
    libneko = fetchSource {
      name = "libneko";
      rev = "1c47a3af71990a7b2192e03292b4d246c308ef0b";
      hash = "sha256-9ftRh8K4z7m265dbEwWSBeNiwznnNl/FolVv4rZ4C8E=";
    };
  };

  geodata = {
    "geoip.dat" = "${v2ray-geoip}/share/v2ray/geoip.dat";
    "geosite.dat" = "${v2ray-domain-list-community}/share/v2ray/geosite.dat";
    "geoip.db" = "${sing-geoip}/share/sing-box/geoip.db";
    "geosite.db" = "${sing-geosite}/share/sing-box/geosite.db";
  };

  installGeodata = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (filename: file: ''
      install -Dm644 ${file} "$out/share/nekobox/${filename}"
    '') geodata
  );
in
clangStdenv.mkDerivation (finalAttrs: {
  pname = "nekobox";
  version = "4.0-beta3";

  src = fetchSource {
    name = "nekoray";
    rev = finalAttrs.version;
    hash = "sha256-YqdEM5L9NCRHFC5moaveZX/zNKnQoOVMr+d/NrYADrU=";
    fetchSubmodules = true;
  };

  strictDeps = true;

  nativeBuildInputs = [
    libsForQt5.wrapQtAppsHook
    cmake
    ninja
    copyDesktopItems
  ];

  buildInputs = [
    libsForQt5.qtbase
    libsForQt5.qttools
    libsForQt5.qtwayland
    libsForQt5.qtx11extras
    protobuf
    yaml-cpp
    zxing-cpp
  ];

  # NKR_PACKAGE makes sure the app uses the user's config directory to store it's non-static content
  # it's essentially the same as always setting the -appdata flag when running the program
  cmakeFlags = [ (lib.cmakeBool "NKR_PACKAGE" true) ];

  installPhase = ''
    runHook preInstall

    install -Dm755 nekobox "$out/share/nekobox/nekobox"
    mkdir -p "$out/bin"
    ln -s "$out/share/nekobox/nekobox" "$out/bin"

    # nekobox looks for other files and cores in the same directory it's located at
    ln -s ${finalAttrs.passthru.nekobox-core}/bin/nekobox_core "$out/share/nekobox/nekobox_core"

    ${installGeodata}

    install -Dm644 "$src/res/public/nekobox.png" "$out/share/icons/hicolor/256x256/apps/nekobox.png"

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "nekobox";
      desktopName = "nekobox";
      exec = "nekobox";
      icon = "nekobox";
      comment = finalAttrs.meta.description;
      terminal = false;
      categories = [
        "Network"
        "Application"
      ];
    })
  ];

  passthru = {
    nekobox-core = callPackage ./nekobox-core.nix {
      inherit (finalAttrs) src;
      inherit extraSources;
    };
  };

  meta = {
    description = "Qt based cross-platform GUI proxy configuration manager";
    homepage = "https://github.com/MatsuriDayo/nekoray";
    license = lib.licenses.gpl3Plus;
    mainProgram = "nekobox";
    maintainers = with lib.maintainers; [ fakelog ];
    platforms = lib.platforms.linux;
  };
})
