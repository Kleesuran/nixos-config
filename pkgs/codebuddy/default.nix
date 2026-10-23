{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  nodejs,
  autoPatchelfHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "codebuddy";
  version = "2.151.0";

  # npm 上的包本身 dependencies 为空，运行时只需要 node + 两个可选原生依赖。
  src = fetchurl {
    url = "https://registry.npmjs.org/@tencent-ai/codebuddy-code/-/codebuddy-code-${finalAttrs.version}.tgz";
    hash = "sha256-TTAYIhYJFuV5lHs9BHqpSwcaxvrXvkCqwojCZaOObHU=";
  };

  nodePty = fetchurl {
    url = "https://registry.npmjs.org/@lydell/node-pty/-/node-pty-1.2.0-beta.14.tgz";
    hash = "sha256-7ujiYOQ7lqpUUPTJXwXeG0irJPyz1O9WYjLsnM/y454=";
  };

  nodePtyLinuxX64 = fetchurl {
    url = "https://registry.npmjs.org/@lydell/node-pty-linux-x64/-/node-pty-linux-x64-1.2.0-beta.14.tgz";
    hash = "sha256-U77izQImWxGDkvfZmkxyM39KUAPA0PnuAWRsGa9Z+h8=";
  };

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
  ];

  # node-pty 的预编译 .node 需要 libstdc++/libgcc_s
  buildInputs = [ stdenv.cc.cc.lib ];

  # dist/vendor 里带预编译产物，不去动它们的权限位
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    local root=$out/lib/node_modules

    mkdir -p "$root/@tencent-ai/codebuddy-code" "$root/@lydell/node-pty" "$root/@lydell/node-pty-linux-x64"
    tar -xzf $src --strip-components=1 -C "$root/@tencent-ai/codebuddy-code"
    tar -xzf $nodePty --strip-components=1 -C "$root/@lydell/node-pty"
    tar -xzf $nodePtyLinuxX64 --strip-components=1 -C "$root/@lydell/node-pty-linux-x64"

    mkdir -p $out/bin
    # 入口脚本只有三个，npm 的 bin 别名多于实际文件
    wrap() {
      makeWrapper ${nodejs}/bin/node "$out/bin/$1" \
        --add-flags "$root/@tencent-ai/codebuddy-code/bin/$2"
    }
    wrap codebuddy codebuddy
    wrap codebuddy-code codebuddy
    wrap cbc codebuddy
    wrap cbc-prewarm cbc-prewarm
    wrap codebuddy-lowmem codebuddy-lowmem

    runHook postInstall
  '';

  meta = {
    description = "CodeBuddy Code - Tencent AI coding assistant CLI";
    homepage = "https://copilot.tencent.com";
    license = lib.licenses.unfree;
    mainProgram = "codebuddy";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
