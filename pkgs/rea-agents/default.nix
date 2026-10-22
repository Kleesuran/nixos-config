{
  lib,
  buildNpmPackage,
  fetchurl,
  fetchNpmDeps,
}:

buildNpmPackage (finalAttrs: {
  pname = "rea-agents";
  version = "6.4.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/rea-agents/-/rea-agents-${finalAttrs.version}.tgz";
    hash = "sha256-WesWBLjbdfUi1Kl1w2zmtKKtRl5DutFl+aj3KDkdubg=";
  };

  npmDeps = fetchNpmDeps {
    src = ./.;
    hash = "sha256-4IO8qPs52AlMsz/gsGBAOHLGIfNAGpqCsLdsc5ZHVoM=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;
  npmFlags = [ "--legacy-peer-deps" ];

  meta = {
    description = "Reverse engineer anything from your terminal or agent with one CLI and MCP server";
    homepage = "https://github.com/morluto/rea";
    license = lib.licenses.mit;
    mainProgram = "rea";
    platforms = lib.platforms.linux;
  };
})
