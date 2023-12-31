# Usage as a flake

[![FlakeHub](https://img.shields.io/endpoint?url=https://flakehub.com/f/EricTheMagician/ipfs-podcasting.nix/badge)](https://flakehub.com/flake/EricTheMagician/ipfs-podcasting.nix)

Add ipfs-podcasting.nix to your `flake.nix`:

```nix
{
  inputs.ipfs-podcasting.url = "https://flakehub.com/f/EricTheMagician/ipfs-podcasting.nix/*.tar.gz";

  outputs = { self, ipfs-podcasting }: {
    mini-nix = nixpkgs.lib.nixosSystem.ipfs-node {
      system="x86_64-linux";
      modules = [
          # ... other modules
          ipfs-podcasting.nixosModules.ipfs-podcasting  
          {
              programs.ipfs-podcasting = {
                enable = true;
                email = "your@email.example";
                # default false: higly recommended to enable it to allow other nodes to reach you.
                # opens the default tcp/udp port 4001 
                # useful to set it to false if you want a more advanced configuration
                openFirewall = true;  
                # set to true to enable turbo mode.
                # turbo-mode = false; # default is false
              };
              # additional ipfs configuration can be modified by modifying services.kubo module.
          }
      ];
    };
  };
}

```
