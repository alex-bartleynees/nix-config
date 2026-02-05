# Helper functions to extract nixosConfig and homeConfig from combined modules
{
  # Extract nixosConfig from a combined desktop module
  # Falls back to the module itself if it's not a combined module
  extractSystemConfig = desktop:
    let module = import (../desktops + "/${desktop}.nix");
    in if builtins.isAttrs module && module ? nixosConfig then
      module.nixosConfig
    else
      module;

  # Extract homeConfig from a combined desktop module
  # Returns an empty module if no homeConfig exists to prevent NixOS options leaking into Home Manager
  extractHomeConfig = desktop:
    let module = import (../desktops + "/${desktop}.nix");
    in if builtins.isAttrs module && module ? homeConfig then
      module.homeConfig
    else
    # Return empty module instead of the whole module
    # This prevents NixOS-only modules from leaking into Home Manager
      { ... }: { };
}
