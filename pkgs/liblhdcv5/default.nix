# LHDC v5 编码库（AOSP android-17 的 system/audio/codecs/lhdcv5）
#
# 上游是 Android 的 Rust 编码器 + AOSP 风格的 C ABI 包装，仓库里另有一个
# Linux 用的 Makefile，把两者链接成 liblhdcv5.so 并装出头文件与 pkg-config。
# pipewire 的 bluez5 LHDC 支持通过 dependency('lhdcv5') 找它。
{
  lib,
  stdenv,
  fetchFromGitHub,
  cargo,
  rustc,
  rustPlatform,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "liblhdcv5";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "DBeidachazi";
    repo = "liblhdcv5";
    rev = "0df76b08196dc26e460404189279b17a7101af74";
    hash = "sha256-j9cKgWrjn0QE3H5oNyXO074Mam2SDH7o9NeQ9hSm48U=";
  };

  # Makefile 里的 cargo build 在沙箱里不能联网，预先把锁文件里的 crate 全部拉好。
  cargoDeps = rustPlatform.importCargoLock {
    lockFile = "${finalAttrs.src}/aosp/Cargo.lock";
  };

  nativeBuildInputs = [
    cargo
    rustc
    rustPlatform.cargoSetupHook
  ];

  # Makefile 负责 rustc -vV、RUSTFLAGS 与最终链接，不套 buildRustPackage。
  buildPhase = ''
    runHook preBuild
    make VERSION=${finalAttrs.version}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    make install VERSION=${finalAttrs.version} PREFIX=$out
    runHook postInstall
  '';

  meta = {
    description = "AOSP LHDC v5 Bluetooth encoder library";
    homepage = "https://github.com/DBeidachazi/liblhdcv5";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
})
