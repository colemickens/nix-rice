{
  description = "nix-rice";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    iterm-color-schemes = {
      url = "github:mbadolato/iTerm2-Color-Schemes";
      flake = false;
    };
  };

  outputs = inputs:
    let
      nameValuePair = name: value: { inherit name value; };
      genAttrs = names: f: builtins.listToAttrs (map (n: nameValuePair n (f n)) names);
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = genAttrs supportedSystems;
      pkgsFor = pkgs: system: overlays:
        import pkgs {
          inherit system overlays;
          config.allowUnfree = true;
          config.allowAliases = false;
        };
    in
    {
      lib = forAllSystems (sys: let pkgs = pkgsFor inputs.nixpkgs sys []; in {
        op = pkgs.callPackage ./lib/operators.nix { };
        float = pkgs.callPackage ./lib/float.nix { };
        hex = pkgs.callPackage ./lib/hex.nix { };
        color = pkgs.callPackage ./lib/color.nix { };
        palette = pkgs.callPackage ./lib/palette.nix { };
      });
    };
}
