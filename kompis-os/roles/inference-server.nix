# kompis-os/roles/inference-server.nix
{
  flake.nixosModules.inference-server =
    {
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        ../nixos/huggingface.nix
        ../nixos/vllm.nix
      ];

      environment.systemPackages = with pkgs; [ vllm ];

      nixpkgs.config = {
        allowUnfreePredicate =
          pkg:
          (pkgs._cuda.lib.allowUnfreeCudaPredicate pkg)
          || (builtins.elem (lib.getName pkg) [
            "nvidia-kernel-modules"
            "nvidia-x11"
            "nvidia-settings"
          ]);
        cudaCapabilities = [ "8.6" ];
        cudaForwardCompat = true;
        cudaSupport = true;
      };

      nix.settings = {
        substituters = [
          "https://cache.nixos-cuda.org"
        ];
        trusted-public-keys = [
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        ];
      };

      hardware.nvidia.open = false;
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.graphics.enable = true;

      kompis-os = {
        huggingface = {
          enable = true;
          repo = "/srv/models/huggingface";
        };

        vllm.enable = true;
        vllm.servers.qwen3-8b = {
          model = "Qwen/Qwen3-8B-AWQ";
          host = "0.0.0.0";
          extraArgs = [
            "--gpu-memory-utilization=0.95"
            "--max-model-len=8192"
            "--max-num-seqs=1"
            "--enable-prefix-caching"
            "--tool-call-parser=hermes"
            "--enable-auto-tool-choice"
          ];
        };
      };
    };
}
