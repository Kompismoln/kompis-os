{ stdenv, kernel }:

stdenv.mkDerivation rec {
  pname = "ax88179-vendor";
  version = "4.1.0";

  src = ./ASIX_USB_NIC_Linux_Driver_Source_v4.1.0.tar.bz2;

  nativeBuildInputs = kernel.moduleBuildDependencies;

  hardeningDisable = [
    "pic"
    "format"
  ];

  KDIR = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";

  makeFlags = [
    "KDIR=${KDIR}"
    "TOOL_EXTRA_CFLAGS="
  ];

  installPhase = ''
    runHook preInstall

    long_mod_dir="$out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/usb"
    mkdir -p "$long_mod_dir"
    cp ax_usb_nic.ko "$long_mod_dir/"

    mkdir -p "$out/bin"
    cp axcmd *_programmer *_ieee "$out/bin/" 2>/dev/null || true

    runHook postInstall
  '';
}
