{
  homeConfig = { config, lib, pkgs, userProfiles ? [ ], ... }: {
    options.agent-tools = {
      enable = lib.mkEnableOption
        "Agent tools for agent-based development and testing";
    };

    config = lib.mkMerge [
      (lib.mkIf (builtins.elem "agent-tools" userProfiles) {
        agent-tools.enable = true;
      })
      (lib.mkIf config.agent-tools.enable {
        home.packages = with pkgs; [ t3code ];
        home.sessionVariables = { T3CODE_TELEMETRY_ENABLED = false; };
      })
    ];
  };
}
