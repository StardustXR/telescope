{
  description = "A simple default stardust setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; 
    
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
        
        packages.default = pkgs.writeShellApplication {
          name = "telescope";
          runtimeInputs = [ inputs'.server.packages.default ];
          text = ''stardust-xr-server -e "${self'.packages.startup_script}/bin/startup_script"'';
        };
        apps.default = {
          type = "app";
          program = "${self'.packages.default}/bin/telescope";
        };
      };
      flake = {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.

      };
    };
}
