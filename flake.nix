{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            gleam
            erlang_28
            rebar3
            bun

            # Mise is for now still default task runner and will likely use it's own deps...
            mise
          ];

          shellHook = ''
            eval "$(mise activate bash)"
            echo "❄️ Welcome to Cynthia Mini's development shell!"
            mise tasks
            echo "use mise run to run these."
          '';
        };
      });
}

