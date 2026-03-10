# kompis-os/roles/inference-server.nix
{
  flake.nixosModules.inference-server =
    {
      config,
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

      kompis-os.huggingface = {
        enable = true;
        repo = "/srv/models/huggingface";
      };

      kompis-os.vllm.enable = true;
      kompis-os.vllm.servers.qwen3-8b = {
        model = "Qwen/Qwen3-8B-AWQ";
        host = "0.0.0.0";
        extraArgs = [
          "--gpu-memory-utilization=0.95"
          "--max-model-len=8192"
          "--max-num-seqs=1"
          "--tool-call-parser=hermes"
          "--enable-prefix-caching"
          "--enable-auto-tool-choice"
        ];
      };

      services.ollama = {
        enable = false;
        models = "/srv/models/ollama";
        host = "0.0.0.0";
        package = pkgs.ollama-cuda;
        home = "/var/lib/private/ollama";
        user = "ollama";
        loadModels = [
          "llama3.1:8b"
          "medllama2:7b"
          "gemma3:4b"
          "gemma3:12b"
          "mistral:7b"
          "qwen3:8b-q8_0"
          "qwen3:14b-q4_K_M"
          "deepseek-r1:8b-llama-distill-q8_0"
          "deepseek-r1:14b-qwen-distill-q4_K_M"
        ];
      };

      kompis-os.paths."/srv/models/ollama" = lib.mkIf config.services.ollama.enable {
        user = "ollama";
      };

    };
}
