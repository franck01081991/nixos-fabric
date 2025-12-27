{ lib, ... }:

{
  # Common utility functions for the fabric
  fabricUtils = {
    # Create a standard module structure
    mkFabricModule = name: options: {
      options.network-fabric.${name} = lib.mkOption {
        type = lib.types.submodule {
          options = options;
        };
      };
    };
    
    # Safe config access with defaults
    getConfig = path: default: config:
      let
        pathParts = lib.splitString "." path;
        firstAttr = lib.head pathParts;
        restPath = lib.tail pathParts;
      in
      if config != null && lib.hasAttr firstAttr config
      then
        if lib.isAttrs (config.${firstAttr}) && restPath != []
        then lib.getAttrFromPath restPath config.${firstAttr}
        else config.${firstAttr}
      else default;
    
    # Create standard activation scripts
    mkActivationScript = name: content:
      lib.mkBefore ''
        echo "Running ${name} activation script..."
        ${content}
        echo "${name} activation script completed."
      '';
  };
}