{
  lib,
  stdenv,
  fetchurl,
  patchelf,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "qoder-cli";
  version = "1.1.77";

  # 官方静态发布站，清单见
  # https://static.qoder.com.cn/qoder-cli-cn/channels/manifest.json
  # 选 linux-x64（非 baseline）：本机 CPU 满足 sse4_2/popcnt/avx/avx2/bmi1/bmi2/fma。
  src = fetchurl {
    url = "https://static.qoder.com.cn/qoder-cli-cn/releases/${finalAttrs.version}/qoderclicn-linux-x64.tar.gz";
    hash = "sha256-15w/K0Ugt+2AQs0NT3lvj4VswlBY6j1Rqg+nPBMLRGk=";
  };

  nativeBuildInputs = [ patchelf ];

  # 压缩包里只有一个 bun 编译的可执行文件，没有顶层目录
  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 qoderclicn $out/bin/qoderclicn
    ln -s qoderclicn $out/bin/qoder
    ln -s qoderclicn $out/bin/qodercli
    runHook postInstall
  '';

  # 只改 ELF 解释器，不要加 RPATH：bun 编译的二进制在尾部追加了数据段，
  # patchelf 写 RPATH 会破坏它（实测加 RPATH 后直接 core dump，
  # 用 autoPatchelfHook 则会让 --version 变成错的 1.4.2）。
  # 只改解释器时 glibc 由解释器自带的搜索路径解析，功能正常。
  postFixup = ''
    patchelf --set-interpreter ${stdenv.cc.bintools.dynamicLinker} $out/bin/qoderclicn
  '';

  meta = {
    description = "Qoder CLI (CN)";
    homepage = "https://qoder.com.cn/cli";
    license = lib.licenses.unfree;
    mainProgram = "qoderclicn";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
