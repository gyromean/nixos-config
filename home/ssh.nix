{ config, pkgs, lib, machine, opts, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*".addKeysToAgent = "yes";
  };

  services.ssh-agent.enable = true;
}
