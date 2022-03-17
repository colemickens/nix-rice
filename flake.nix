{
  description = "nix-rice";

  inputs = {
    nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; };
    iterm2-color-schemes = {
      url = "github:mbadolato/iTerm2-Color-Schemes";
      flake = false;
    };
  };

  outputs = inputs:
    with builtins;
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
      lib = forAllSystems (sys:
        let
          pkgs = pkgsFor inputs.nixpkgs sys [ ];
          callPackage = pkgs.lib.callPackageWith ( pkgs // self);
          self = rec {
            op = callPackage ./lib/operators.nix { };
            float = callPackage ./lib/float.nix { };
            hex = callPackage ./lib/hex.nix { };
            color = callPackage ./lib/color.nix { };
            palette = callPackage ./lib/palette.nix { };
          };
          in (self)
      );
      # how lazy is nix?
      colorschemes =
        let
          hasSuffix = suffix: content:
            let
              lenContent = builtins.stringLength content;
              lenSuffix = builtins.stringLength suffix;
            in
            lenContent >= lenSuffix && builtins.substring (lenContent - lenSuffix) lenContent content == suffix;
          mapAttrs' = f: set: builtins.listToAttrs (builtins.map (attr: f attr set.${attr}) (builtins.attrNames set));
          filterAttrs = pred: set: builtins.listToAttrs (builtins.concatMap (name: let v = set.${name}; in if pred name v then [{ name = name; value = v; }] else [ ]) (builtins.attrNames set));
          removeSuffix =
            # Suffix to remove if it matches
            suffix:
            # Input string
            str:
            let
              sufLen = stringLength suffix;
              sLen = stringLength str;
            in
            if sufLen <= sLen && suffix == substring (sLen - sufLen) sufLen str then
              substring 0 (sLen - sufLen) str
            else
              str;
          gen = dir: with builtins; mapAttrs' (name: _: { name = "${removeSuffix ".json" name}"; value = let f = "${dir}/${name}"; in builtins.fromJSON (readFile f); })
            (filterAttrs (name: _: hasSuffix ".json" name)
              (readDir dir));
        in
        gen "${inputs.iterm2-color-schemes}/windowsterminal";
    };
}
