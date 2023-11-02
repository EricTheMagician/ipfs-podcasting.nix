{
  description = "ipfs-podcasting node";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";

    # ipfs podcasting
    ipfs-podcasting.url = "github:Cameron-IPFSPodcasting/podcastnode-Python";
    ipfs-podcasting.flake = false;
  };

  outputs = {
    self,
    nixpkgs,
    ipfs-podcasting,
    ...
  } @ inputs: let
    inherit (self) outputs;
    # Supported systems for your flake packages, shell, etc.
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # Formatter for your nix files, available through 'nix fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    nixosModules = {
      ipfs-podcasting = import ./modules/ipfs-podcasting.nix;
      default = self.nixosModules.ipfs-podcasting;
    };
  };
}