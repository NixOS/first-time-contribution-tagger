# first-time-contribution-tagger
Tags PRs of first time contributors in a GitHub repo with a pre specified label and has builtin caching.

## Usage
This repository also contains a Nix flake. It can be used in a NixOS configuration like this:
1. Add flake to inputs:
```nix
first-time-contribution-tagger = {
    url = "github:NixOS/first-time-contribution-tagger";
    inputs.nixpkgs.follows = "nixpkgs"; #optional
}
```
2. Adding output: 
```nix
  outputs = inputs@{ self, nixpkgs, first-time-contribution-tagger, ... }:
```
3. Import NixOS module
```nix
imports = [ first-time-contribution-tagger.nixosModule ];
```
4. Configure the module:
```nix
{ ... }: {
  services.first-time-contribution-tagger = {
    enable = true;
    interval = "*:0/10";
    environment = {
      FIRST_TIME_CONTRIBUTION_LABEL="12. first-time contribution";
      FIRST_TIME_CONTRIBUTION_CACHE="/var/lib/first-time-contribution-tagger/cache";
      FIRST_TIME_CONTRIBUTION_REPO="nixpkgs";
      FIRST_TIME_CONTRIBUTION_ORG="NixOS";
    };
    environmentFile = "/root/first-time-contribution-tagger.env";
  };
}
```

5. Adding the cache
If you go to the [releases page](https://github.com/NixOS/first-time-contribution-tagger/releases) you will find two .pickle files, copy both of them to your specified cache directory. If the directory doesn't exist just create it. Then set the permissions, f.e. `chmod -R 666 $FIRST_TIME_CONTRIBUTION_CACHE`

6. Rebuild your system config
```sh
sudo nixos-rebuild switch --flake .#
```
