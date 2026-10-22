# OpenUUYC Linux 客户端（djkcyl/farwing PR #1）
#
# 固定到 PR head / v1.0.2-beta.5-linux.4 的同一个 commit。上游没有 Nix
# 表达式，这里用 rustPlatform 从源码构建；字体路径在 postPatch 里改指
# Nix store，否则程序会去找 /usr/share/fonts 下的固定文件。
{ lib
, fetchFromGitHub
, rustPlatform
, pkg-config
, cmake
, nasm
, makeWrapper
, alsa-lib
, dbus
, libva
, libxkbcommon
, wayland
, libX11
, libxcb
, libXrandr
, libXi
, libXcursor
, libXfixes
, libXtst
, libglvnd
, vulkan-loader
, openssl
, udev
, pipewire
, libpulseaudio
, mesa
, noto-fonts-cjk-sans
, fuse3
, glib
, librsvg
, xdg-utils
, ethtool
}:

rustPlatform.buildRustPackage rec {
  pname = "openuuyc";
  version = "1.0.2-beta.5";

  src = fetchFromGitHub {
    owner = "DoyoDia";
    repo = "openuuyc-linux";
    rev = "e79abd9c00b8e9f15d467aea3ebd62d9e12720cd";
    hash = "sha256-anKykFjV9u8geWmyXRnoACAQti2LkQ/0fACmm9nlY1Q=";
  };

  cargoHash = "sha256-PnyeqXx+1B+Rra1v96EiAqjk5KHv0aFisxoOS6QRoVw=";

  # KDE/KWin 的 ScreenCast 门户用 SPA_DATA_MemFd 送帧；上游只读了
  # data.data（MemPtr），没有 mmap fd，导致所有缓冲都“读不出画面”。
  patches = [ ./memfd.patch ];

  nativeBuildInputs = [
    pkg-config
    cmake
    nasm
    makeWrapper
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    alsa-lib
    dbus
    libva
    libxkbcommon
    wayland
    libX11
    libxcb
    libXrandr
    libXi
    libXcursor
    libXfixes
    libXtst
    libglvnd
    vulkan-loader
    openssl
    fuse3
    udev
    pipewire
    libpulseaudio
    mesa
  ];

  # 程序不走 fontconfig，直接读这个固定路径；把首选候选替换成 Nix store 里的
  # Noto CJK。其余候选保持原样，换机器时仍能回退。
  postPatch = ''
    substituteInPlace src/ui/fonts.rs \
      --replace-fail '"/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"' \
                     '"${noto-fonts-cjk-sans}/share/fonts/opentype/noto-cjk/NotoSansCJK-VF.otf.ttc"'
  '';

  # 程序会 re-exec current_exe（显示恢复守护、插件、关机），所以 RPATH 必须
  # 落在真正的二进制上，不能只靠 wrapper 的 LD_LIBRARY_PATH。
  env.RUSTFLAGS = "-C link-arg=-Wl,-rpath,${lib.makeLibraryPath [
    libglvnd
    mesa
    vulkan-loader
    wayland
    libxkbcommon
    libX11
    libxcb
    libXrandr
    libXi
    libXcursor
    libXfixes
    libXtst
    pipewire
    libpulseaudio
    alsa-lib
    libva
    dbus
    udev
    fuse3
  ]}:/run/opengl-driver/lib";

  doCheck = false;

  # fixup 的 patchelf hook 默认会把 RUNPATH 缩到只剩 NEEDED 里的库，把我们为
  # dlopen（libcuda / libnvidia-encode / libpipewire / libpulse / Vulkan）加的
  # 目录删掉。程序会 re-exec 自己，所以这些目录必须留在真正的二进制上。
  # stdenv 没有 dontShrinkRpath，只有关掉整个 patchelf hook 才保得住。
  dontPatchELF = true;

  postInstall = ''
    mkdir -p $out/libexec/openuuyc
    mv $out/bin/OpenUUYC $out/libexec/openuuyc/OpenUUYC

    makeWrapper $out/libexec/openuuyc/OpenUUYC $out/bin/OpenUUYC \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        libglvnd
        mesa
        vulkan-loader
        wayland
        libxkbcommon
        libX11
        libxcb
        libXrandr
        libXi
        libXcursor
        libXfixes
        libXtst
        pipewire
        libpulseaudio
        alsa-lib
        libva
        dbus
        udev
        fuse3
      ]}:/run/opengl-driver/lib" \
      --suffix PATH : "${lib.makeBinPath [
        fuse3
        glib
        librsvg
        xdg-utils
        ethtool
      ]}" \
      --set-default NVD_BACKEND direct

    install -Dm644 assets/icon-256.png \
      $out/share/icons/hicolor/256x256/apps/openuuyc.png
    install -Dm644 packaging/linux/openuuyc.desktop \
      $out/share/applications/openuuyc.desktop
    install -Dm644 LICENSE THIRD_PARTY_NOTICES -t $out/share/doc/openuuyc
  '';

  meta = {
    description = "Third-party UU Remote client (Linux port)";
    homepage = "https://github.com/djkcyl/farwing/pull/1";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    mainProgram = "OpenUUYC";
  };
}
