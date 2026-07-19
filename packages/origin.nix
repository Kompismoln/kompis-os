{
  lib,
  stdenv,
  fetchFromGitHub,
  clang,
  which,
  python3,
  fakechroot,
  util-linux,
}:

stdenv.mkDerivation {
  pname = "origin";
  version = "unstable-ddf14a6";

  src = fetchFromGitHub {
    owner = "atorstling";
    repo = "origin";
    rev = "release-ddf14a6d40de6c78ef9c1e3064d60bf71d697c9f";
    sha256 = "sha256-j4rw+sgkd9Sf8JvCtC7sqdOlVPlIXG3osYzAfGYYOho=";
  };

  buildInputs = [ clang ];

  checkInputs = [
    which
    python3
    fakechroot
    util-linux
  ];

  makeFlags = [
    "DEBUG=0"
    "CFLAGS+=-Wno-implicit-void-ptr-cast"
    "CFLAGS+=-Wno-used-but-marked-unused"
  ];

  doCheck = true;

  preCheck = ''
    patchShebangs ./run_tests.sh ./testsetup.sh
  '';

  installPhase = ''
    runHook preInstall
    install -Dm 755 target/origin $out/bin/origin
    runHook postInstall
  '';

  meta = {
    description = "Track down the origin of a command";
    homepage = "https://github.com/atorstling/origin";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    maintainers = [ lib.maintainers.ahbk ];
  };
}
