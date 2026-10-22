{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  patchelf,
  alsa-lib,
  dbus,
  fontconfig,
  freetype,
  glib,
  http-parser,
  krb5,
  libdrm,
  libGL,
  libpulseaudio,
  libssh2,
  libxkbcommon,
  openssl,
  vulkan-loader,
  wayland,
  xorg,
  zlib,
}:

let
  runtimeLibs = lib.makeLibraryPath [
    alsa-lib
    dbus
    fontconfig
    freetype
    glib
    libdrm
    libGL
    libpulseaudio
    libxkbcommon
    openssl
    vulkan-loader
    wayland
    xorg.libX11
    xorg.libxcb
    xorg.libXcursor
    xorg.libXi
    xorg.libXtst
    xorg.libXrandr
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXfixes
    xorg.libXrender
    xorg.libSM
    xorg.libICE
    zlib
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "zedg";
  version = "1.24.3";

  src = fetchurl {
    url = "https://github.com/WenYin-Community/zed-globalization/releases/download/v${finalAttrs.version}/zedg-zh-cn-linux-x86_64-v${finalAttrs.version}.tar.gz";
    hash = "sha256-lcmG4Gwg6Yw3hZNU9Hsbcbay9arj4JzDX1F9/QwUeqM=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    patchelf
  ];

  buildInputs = [
    alsa-lib
    glib
    http-parser
    krb5.lib
    libssh2
    libxkbcommon
    openssl
    stdenv.cc.cc.lib
    xorg.libX11
    xorg.libxcb
    zlib
  ];

  # The bundled libgit2 is a leftover: no shipped binary references it, and
  # it was built against mbedtls 2.x and Debian's PCRE 3 sonames.
  autoPatchelfIgnoreMissingDeps = [
    "libmbedtls.so.14"
    "libmbedx509.so.1"
    "libmbedcrypto.so.7"
    "libpcre.so.3"
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r ./. $out/
    runHook postInstall
  '';

  postFixup = ''
    patchelf --set-rpath '$ORIGIN/../lib/zedg:'"${runtimeLibs}" $out/bin/zedg
  '';

  meta = {
    description = "Zed editor with globalization support (pre-built binary)";
    homepage = "https://github.com/WenYin-Community/zed-globalization";
    license = with lib.licenses; [
      agpl3Plus
      asl20
      gpl3Plus
    ];
    mainProgram = "zedg";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
