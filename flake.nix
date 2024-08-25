{
  description = "A simple default stardust setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    server = {
      url = "github:StardustXR/server/dev";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flatland = {
      url = "github:StardustXR/flatland/dev";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    protostar = {
      url = "github:StardustXR/protostar/dev";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    gravity = {
      url = "github:StardustXR/gravity/dev";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    black_hole = {
      url = "github:StardustXR/black-hole";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [];
      systems = [ "aarch64-linux" "x86_64-linux" "riscv64-linux" ];
      perSystem = { config, self', inputs', pkgs, system, ... }: let
        inherit (pkgs) lib writeShellApplication buildFHSEnv;
      in
      {
        # edit these to add/remove clients
        packages.startup_script = writeShellApplication {
          name = "startup_script";
          runtimeInputs = [
            inputs'.flatland.packages.default
            inputs'.protostar.packages.default
            inputs'.gravity.packages.default
            inputs'.black_hole.packages.default
            pkgs.xwayland-satellite
          ];
          ## and this is the startup script
          text = ''
          	xwayland-satellite :10 &
          	export DISPLAY=:10 &
           	sleep 0.1;

            flatland &
            gravity -- 0 0.0 -0.5 hexagon_launcher &
            black_hole &
          '';
        };
        packages.flatscreen = writeShellApplication {
          name = "flatscreen";
          runtimeInputs = [ self'.packages.telescope ];
          text = ''telescope -f'';
        };
        packages.telescope-unwrapped = writeShellApplication {
          name = "telescope-unwrapped";
          runtimeInputs = [
            inputs'.server.packages.default
          ];
          text = ''stardust-xr-server -o 1 -e "${lib.getExe self'.packages.startup_script}" "$@"'';
        };
        packages.telescope = buildFHSEnv {
          name = "telescope";

          strictDeps = true;

          targetPkgs = pkgs: [ self'.packages.telescope-unwrapped ] ++ (with pkgs; [ libGL vulkan-loader ]);

          runScript = "${lib.getExe self'.packages.telescope-unwrapped}";
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
          program = "${self'.packages.telescope}/bin/telescope";
        };
        apps.default = self'.apps.telescope;
      };
      flake = {};
    };
}
