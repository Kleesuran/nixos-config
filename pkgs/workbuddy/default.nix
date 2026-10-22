{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libappindicator-gtk3,
  libdrm,
  libgbm,
  libnotify,
  libsecret,
  libuuid,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  nodejs_22,
  pango,
  systemd,
  vulkan-loader,
  xdg-utils,
  xorg,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "workbuddy";
  version = "5.6.2.40046327_c7b525f3";

  # 上游版本化 deb 地址；版本号在 URL 里用 '-' 而不是 '_'。
  src = fetchurl {
    name = "WorkBuddy-linux-x64-deb-${finalAttrs.version}.deb";
    url = "https://download.codebuddy.cn/workbuddy/saas/linux-x64-deb/WorkBuddy-linux-x64-deb-${lib.replaceStrings [ "_" ] [ "-" ] finalAttrs.version}.deb";
    hash = "sha256-EhSa2MDNdI/VBi2PYseCfWiNgJVCetqZsa6ecBmJdSM=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libappindicator-gtk3
    libdrm
    libgbm
    libnotify
    libsecret
    libuuid
    libxkbcommon
    mesa
    nspr
    nss
    nodejs_22
    pango
    systemd
    vulkan-loader
    xdg-utils
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libXScrnSaver
    xorg.libXtst
    xorg.libxcb
    xorg.libxshmfence
    zlib
    stdenv.cc.cc.lib
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libffmpeg.so"
    "libEGL.so"
    "libGLESv2.so"
    "libvulkan.so.1"
    "libvk_swiftshader.so"
  ];

  dontUnpack = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p unpack
    dpkg-deb -x "$src" unpack

    mkdir -p "$out/opt" "$out/share/applications" "$out/share/icons"
    cp -a "unpack/opt/WorkBuddy" "$out/opt/"
    cp -a "unpack/usr/share/icons/hicolor" "$out/share/icons/"

    install -Dm644 ${./WorkBuddy.desktop} "$out/share/applications/workbuddy.desktop"
    substituteInPlace "$out/share/applications/workbuddy.desktop" \
      --replace-fail 'Exec=/usr/bin/workbuddy' "Exec=$out/bin/workbuddy"

    runHook postInstall
  '';

  postInstall = ''
    # 清掉非 Linux-x64 / musl 的可选原生模块，避免 autoPatchelf 去解析
    # OpenBSD/macOS/Windows/arm64 的二进制。
    find "$out/opt/WorkBuddy/resources/app.asar.unpacked/node_modules" \
      -depth -type d -name '*musl*' -exec rm -rf {} +

    if [ -d "$out/opt/WorkBuddy/resources/app.asar.unpacked/node_modules/koffi/build/koffi" ]; then
      find "$out/opt/WorkBuddy/resources/app.asar.unpacked/node_modules/koffi/build/koffi" \
        -mindepth 1 -maxdepth 1 -type d ! -name linux_x64 -exec rm -rf {} +
    fi

    if [ -d "$out/opt/WorkBuddy/resources/app.asar.unpacked/node_modules/@lydell" ]; then
      find "$out/opt/WorkBuddy/resources/app.asar.unpacked/node_modules/@lydell" \
        -mindepth 1 -maxdepth 1 -type d -name 'node-pty-*' ! -name 'node-pty-linux-x64' -exec rm -rf {} +
    fi

    rm -rf "$out/opt/WorkBuddy/resources/app.asar.unpacked/node_modules/fsevents"

    # 上游 bundled Node 被 patchelf 后会段错误；它只是给 skills 用的 Node 22，
    # 直接用 NixOS 的 nodejs_22 代替，避免运行时崩溃。
    node_bin="$out/opt/WorkBuddy/resources/runtime/node/bin/node"
    if [ -f "$node_bin" ]; then
      rm -f "$node_bin"
      cat > "$node_bin" <<EOF
#!/bin/sh
exec ${nodejs_22}/bin/node "\$@"
EOF
      chmod +x "$node_bin"
    fi

    makeWrapper "$out/opt/WorkBuddy/workbuddy" "$out/bin/workbuddy" \
      --prefix LD_LIBRARY_PATH : "$out/opt/WorkBuddy:${lib.makeLibraryPath finalAttrs.buildInputs}" \
      --prefix PATH : "${lib.makeBinPath [ xdg-utils ]}"
  '';

  meta = {
    description = "WorkBuddy - Tencent Cloud AI Agent desktop application";
    homepage = "https://www.workbuddy.cn/app";
    license = lib.licenses.unfree;
    mainProgram = "workbuddy";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
