{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "grok-build";
  version = "1.0.62";

  src = fetchurl {
    url = "https://x.ai/cli/grok-${finalAttrs.version}-linux-x86_64";
    hash = "sha256-KkbZ5Nfr16nP9/lXFnFLGdrV8h3SpJeCJACx+xKJaao=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/grok
    runHook postInstall
  '';

  meta = {
    description = "xAI Grok CLI";
    homepage = "https://x.ai/cli";
    license = lib.licenses.unfree;
    mainProgram = "grok";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
