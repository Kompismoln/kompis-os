pkgs: with pkgs; rec {
  all =
    core-cli
    ++ terminal-env
    ++ system-tools
    ++ networking
    ++ data-processing
    ++ archive-utils
    ++ secrets-management
    ++ nix-tools;

  core-cli = [
    bat
    eza
    fd
    fzf
    git
    jq
    restic
    ripgrep
    tree
  ];

  terminal-env = [
    tmux
    ranger
    osc
    xdg-utils
  ];

  system-tools = [
    btrfs-progs
    lsof
    openssl
    pciutils
    psmisc
    strace
    usbutils
  ];

  networking = [
    dig
    iproute2
    nethogs
    nmap
    tcpdump
    traceroute
    wireguard-tools
  ];

  data-processing = [
    envsubst
    libxml2
    rdfind
    w3m
  ];

  media-processing = [
    ffmpeg
    imagemagick
  ];

  archive-utils = [
    unzip
    zip
  ];

  secrets-management = [
    age
    bitwarden-cli
    sops
    ssh-to-age
    km-tools
  ];

  nix-tools = [
    nixos-facter
    nix-serve-ng
  ];
}
