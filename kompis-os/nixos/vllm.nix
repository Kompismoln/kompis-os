# kompis-os/nixos/vllm.nix
{
  config,
  lib,
  lib',
  pkgs,
  ...
}:

let
  cfg = config.kompis-os.vllm;
  enabledServers = lib.filterAttrs (_: serverCfg: serverCfg.enable) cfg.servers;

  vllmOpts =
    { name, ... }:
    {
      options = {
        enable = lib.mkEnableOption "vLLM inference server" // {
          default = true;
        };
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "The name for this vllm server.";
        };
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.vllm;
          description = "The vllm package to use.";
        };
        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "The host address to bind the server to.";
        };
        model = lib.mkOption {
          type = lib.types.str;
          description = "Path to the model weights or HuggingFace model ID.";
          example = "lmsys/vicuna-7b-v1.5";
        };
        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Extra arguments to pass to the vllm server (e.g. ['--kv-cache-dtype', 'fp8']).";
        };
        environment = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Extra arguments to pass to the vllm server (e.g. VLLM_ATTENTION_BACKEND=FLASHINFER).";
        };
        allowedGPUs = lib.mkOption {
          type = lib.types.listOf lib.types.int;
          default = [ 0 ];
          description = "List of NVIDIA GPU indices this server is allowed to access.";
        };
      };
    };
in
{
  options.kompis-os.vllm = {
    enable = lib.mkEnableOption "vLLM inference server environment";
    user = lib.mkOption {
      type = lib.types.str;
      default = "vllm";
    };
    servers = lib.mkOption {
      type = with lib.types; attrsOf (submodule vllmOpts);
      default = { };
      description = "Definition of per-domain vLLM inference servers.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.kompis-os.huggingface.enable;
        message = "kompis-os.vllm requires kompis-os.huggingface to be enabled";
      }
    ];

    kompis-os.users.${cfg.user} = {
      class = "service";
      home = true;
      groups = [
        "video"
        "render"
      ];
    };

    kompis-os.users.huggingface.members = [ cfg.user ];

    systemd.services = lib.mapAttrs' (
      server: serverCfg:
      lib.nameValuePair "vllm-${server}" {
        description = "vLLM-${server} Inference Server";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        environment = {
          HF_HOME = config.kompis-os.huggingface.home;
          HF_HUB_CACHE = config.kompis-os.huggingface.repo;
          HF_HUB_OFFLINE = "1";
          CUDA_VISIBLE_DEVICES = lib.concatMapStringsSep "," toString serverCfg.allowedGPUs;
        }
        // serverCfg.environment;

        serviceConfig = {
          User = cfg.user;
          Group = cfg.user;
          ExecStart =
            let
              inherit (serverCfg) host model extraArgs;
              port = lib'.ports "vllm-${server}";
              args = lib.escapeShellArgs extraArgs;
              cmd = lib.getExe' serverCfg.package "vllm";
            in
            "${cmd} serve ${model} --host=${host} --port=${toString port} ${args}";

          DeviceAllow = [
            "/dev/nvidiactl rw"
            "/dev/nvidia-uvm rw"
            "/dev/nvidia-uvm-tools rw"
            "/dev/nvidia-modeset rw"
          ]
          ++ map (i: "/dev/nvidia${toString i} rw") serverCfg.allowedGPUs;
        };
      }
    ) enabledServers;
  };
}
