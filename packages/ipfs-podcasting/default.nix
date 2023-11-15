{
  stdenv,
  ipfs,
  fetchFromGitHub,
  fetchgit,
}:
stdenv.mkDerivation {
  name = "ipfspodcastnode";
  src = fetchFromGitHub {
    owner = "Cameron-IPFSPodcasting";
    repo = "podcastnode-Python";
    rev = "e538e090fdcf1d9db783e2862be00e6e3f484cd6";
    hash = "sha256-NP7Ilj3Jl9uHBfGi4bdMfhaSS8bQ9G0hoZwwUJGiV1E=";
  };
  #src = fetchgit{
  #url = /home/eric/git/podcastnode-Python;
  #hash = "sha256-GDakBrjtaiu8DhkA7DqrP0IjUfvuFvs+giEM6RQV0Ko=";
  ##hash = "";
  #};
  buildPhase = ''
    mkdir $out;
    cp ipfspodcastnode.py $out;
    # patch the ipfspodcastnode.py script to point to the ipfs binary
    sed -i 's@/usr/local/bin:/usr/bin:/bin:@${ipfs}/bin:/usr/local/bin:/usr/bin:/bin:@' "$out/ipfspodcastnode.py"
    # replace the python identifier with the nix identifier
    # see https://github.com/Cameron-IPFSPodcasting/podcastnode-Python/issues/12
    sed -i -E 's/"version": "([0-9]+\.[0-9]+)p/"version": "\1z/' $out/ipfspodcastnode.py
  '';
}
