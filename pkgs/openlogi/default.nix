{
  callPackage,
  fetchFromGitHub,
}:

callPackage ./package.nix {
  src = fetchFromGitHub {
    owner = "AprilNEA";
    repo = "OpenLogi";
    tag = "v0.8.14";
    hash = "sha256-d/G9BlF66mB7M9vpMVsSmuzA1i/4Zp9xYcWlUbfj3Z8=";
  };
}
