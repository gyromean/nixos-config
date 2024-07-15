{ config, pkgs, lib, machine, opts, ... }@inputs:
{
  home.file.".local/share/wireplumber/scripts/wireplumber-hijack.lua".source = inputs.linkFunc "${opts.configPath}/home/nolink/wireplumber-hijack.lua" ./nolink/wireplumber-hijack.lua;
}
