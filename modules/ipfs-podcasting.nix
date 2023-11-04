{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  ipfs_podcasting_email = config.programs.ipfs-podcasting.email;
  ipfs_python = pkgs.python3.withPackages (ps: with ps; [requests]);
  cfg = config.services.kubo;
  program_cfg = config.programs.ipfs-podcasting;
  ipfs_podcasting_package = pkgs.stdenv.mkDerivation {
    name = "ipfspodcastnode";
    src = inputs.ipfs-podcasting-python;
    buildPhase = ''
      mkdir $out;
      cp ipfspodcastnode.py $out;
      # patch the ipfspodcastnode.py script to point to the ipfs binary
      sed -i 's@^ipfspath = \(.\+\)$@ipfspath = "${cfg.package}/bin/ipfs"@g' "$out/ipfspodcastnode.py"
      # replace the python identifier with the nix identifier
      # see https://github.com/Cameron-IPFSPodcasting/podcastnode-Python/issues/12
      sed -i -E  s/\'version\':\ \'\(\[0-9\]+\.\[0-9\]\)p/\'version\':\ \'\\1z/ "$out/ipfspodcastnode.py"
    '';
  };
  inherit (lib) mkDefault mkEnableOption mkOption mkIf optionalAttrs types;
in {
  options = {
    programs.ipfs-podcasting = {
      enable = mkEnableOption "ipfs-podcasting node";
      email = mkOption {
        type = types.str;
        description = "Enter your email for support & management via IPFSPodcasting.net/Manage";
        example = "email@example.com";
      };
      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = "Open firewall port for IPFS connections";
      };
    };
  };

  config = mkIf program_cfg.enable {
    services.kubo = {
      # kubo is the main ipfs implementation in Go
      enable = true;
      settings = {
        # this api address needs to be defined: see https://github.com/ipfs/kubo/issues/10056
        Addresses.API = mkDefault ["/ip4/127.0.0.1/tcp/5001"];
      };
    };

    systemd.services.ipfs-podcasting = {
      after = ["ipfs.service"];
      description = "IPFS Podcasting Worker for ${ipfs_podcasting_email}";
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        Group = cfg.group;
        LogsDirectory = "ipfs-podcasting";
      };
      path = [cfg.package pkgs.wget pkgs.coreutils];
      script = ''
        cd "/var/log/ipfs-podcasting";
        export IPFS_PATH=${cfg.dataDir};
        ${ipfs_python}/bin/python "${ipfs_podcasting_package}/ipfspodcastnode.py" '${ipfs_podcasting_email}'
      '';
    };

    systemd.timers.ipfs-podcasting = {
      description = "IPFS Podcasting Timer for ${ipfs_podcasting_email}";
      wantedBy = ["timers.target"];
      after = ["ipfs.service"];
      timerConfig = {
        OnBootSec = "10 minutes";
        OnUnitActiveSec = "10 minutes";
      };
    };

    # resolves this warning I had when starting ipfs:
    # `failed to sufficiently increase send buffer size (was: 208 kiB, wanted: 2048 kiB, got: 416 kiB)`
    # `See https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes for details.`
    boot.kernel.sysctl = {
      "net.core.rmem_max" = mkDefault (builtins.floor 2.5 * 1024 * 1024);
      "net.core.wmem_max" = mkDefault (builtins.floor 2.5 * 1024 * 1024);
    };

    # for ipfs connections
    networking.firewall = optionalAttrs program_cfg.openFirewall {
      allowedTCPPorts = [4001];
      allowedUDPPorts = [4001];
    };
  };
}
