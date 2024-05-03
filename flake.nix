{
  description = "A simple default stardust setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; 

    nixgl = {
      url = "github:nix-community/nixgl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    server = {
      url = "github:StardustXR/server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flatland = {
      url = "github:StardustXR/flatland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    protostar = {
      url = "github:StardustXR/protostar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gravity = {
      url = "github:StardustXR/gravity";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import a flake module
        # 1. Add foo to inputs
        # 2. Add foo as a parameter to the outputs function
        # 3. Add here: foo.flakeModule
        
      ];
      systems = [ "aarch64-linux" "x86_64-linux" "riscv64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
      {
        # edit these to add/remove clients
        packages.startup_script = pkgs.writeShellApplication {
          name = "startup_script";
          runtimeInputs = [
            inputs'.flatland.packages.default
            inputs'.protostar.packages.default
            inputs'.gravity.packages.default
          ];
          ## and this is the startup script
          text = ''
            flatland &
            gravity -- 0 0.0 -0.5 hexagon_launcher &
          '';
        };
        packages.flatscreen = pkgs.writeShellApplication {
          name = "flatscreen";
          runtimeInputs = [ self'.packages.telescope ];
          text = ''telescope -f'';
        };
        packages.flatscreenNvidia = pkgs.writeShellApplication {
          name = "flatscreen";
          runtimeInputs = [ self'.packages.telescopeNvidia ];
          text = ''telescope -f'';
        };
        packages.telescope = pkgs.writeShellApplication {
          name = "telescope";
          runtimeInputs = [
            inputs'.server.packages.default
            # Note: intel is actually a misnomer. It's for all mesa drivers, not just intel
            # This does mean that NVIDIA proprietary drivers are not supported
            # NVK, being part of mesa, is supported
            inputs'.nixgl.packages.nixGLIntel
            inputs'.nixgl.packages.nixVulkanIntel
          ];
          text = ''
            export LD_LIBRARY_PATH=${
              pkgs.lib.makeLibraryPath [
                pkgs.vulkan-loader
              ]
            }"''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            nixGLIntel nixVulkanIntel stardust-xr-server -o 1 -e "${self'.packages.startup_script}/bin/startup_script" "$@"
          '';
        };
        packages.telescopeNvidia = pkgs.writeShellApplication {
          name = "telescope";
          runtimeInputs = [
            inputs'.server.packages.default
            inputs'.nixgl.packages.nixGLNvidia
            inputs'.nixgl.packages.nixVulkanNvidia
            pkgs.vulkan-loader
          ];
          text = ''
            export LD_LIBRARY_PATH=${
              pkgs.lib.makeLibraryPath [
                pkgs.vulkan-loader
              ]
            }"''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            nixGLNvidia nixVulkanNvidia stardust-xr-server -o 1 -e "${self'.packages.startup_script}/bin/startup_script" "$@"
          '';
        };
        packages.default = self'.packages.telescope;
        apps.flatscreen = {
          type = "app";
          program = "${self'.packages.flatscreen}/bin/flatscreen";
        };
        apps.flatscreenNvidia = {
          type = "app";
          program = "${self'.packages.flatscreenNvidia}/bin/flatscreen";
        };
        apps.telescope = {
          type = "app";
          program = "${self'.packages.default}/bin/telescope";
        };
        apps.default = self'.apps.telescope;
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

      };
    };
}
