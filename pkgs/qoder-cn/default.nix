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
  pango,
  systemd,
  vulkan-loader,
  xdg-utils,
  xorg,
  zlib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "qoder-cn";
  version = "0.4.8";

  # 官方下载页使用的 latest 地址；上游更新后需要同步改 hash。
  src = fetchurl {
    name = "Qoder-CN-linux-amd64-${finalAttrs.version}.deb";
    url = "https://qoder-app.oss-cn-beijing.aliyuncs.com/qoder-app/releases/latest/Qoder-CN-linux-amd64.deb";
    hash = "sha256-haHVJ0P1bxblGLEoX7jdYtvqXP2u82Im1Jbtkv7nN8Y=";
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

  # 这些是 Electron 自己放在 /opt/Qoder CN 下、通过 $ORIGIN 加载的库。
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
    cp -a "unpack/opt/Qoder CN" "$out/opt/"
    cp -a "unpack/usr/share/applications/qoder-cn.desktop" "$out/share/applications/"
    cp -a "unpack/usr/share/icons/hicolor" "$out/share/icons/"

    substituteInPlace "$out/share/applications/qoder-cn.desktop" \
      --replace-fail 'Exec="/opt/Qoder CN/qoder-cn" %U' "Exec=$out/bin/qoder-cn %U"

    runHook postInstall
  '';

  postInstall = ''
    # 上游同时打包了 glibc 和 musl 两套可选原生模块；NixOS 用 glibc，
    # 删掉 musl 变体，避免 autoPatchelf 去找 musl libc，也避免 sharp
    # 错误地把 musl 的 libvips 设成 glibc 模块的 RPATH。
    rm -rf \
      "$out/opt/Qoder CN/resources/app.asar.unpacked/node_modules/@img/sharp-linuxmusl-x64" \
      "$out/opt/Qoder CN/resources/app.asar.unpacked/node_modules/@img/sharp-libvips-linuxmusl-x64" \
      "$out/opt/Qoder CN/resources/app.asar.unpacked/node_modules/@napi-rs/canvas-linux-x64-musl"

    makeWrapper "$out/opt/Qoder CN/qoder-cn" "$out/bin/qoder-cn" \
      --prefix LD_LIBRARY_PATH : "$out/opt/Qoder CN:${lib.makeLibraryPath finalAttrs.buildInputs}" \
      --prefix PATH : "${lib.makeBinPath [ xdg-utils ]}" \
      --add-flags "--password-store=kwallet6"
  '';

  meta = {
    description = "Qoder CN - Agent workbench for human and AI software teams";
    homepage = "https://qoder.com.cn";
    license = lib.licenses.unfree;
    mainProgram = "qoder-cn";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
