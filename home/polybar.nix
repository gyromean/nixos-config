{ config, pkgs, lib, machine, opts, ... }:
{
  services.polybar = {
    enable = true;
    package = pkgs.polybarFull;
    script = ''
PATH=$PATH:/run/current-system/sw/bin
rm /tmp/polybar_*.sock

for m in $(polybar --list-monitors | cut -d":" -f1); do
MONITOR=$m polybar --reload example &
polybar_pid="$!"
${machine.polybarBrightness}
${machine.polybarI3Workspaces}
done

python ~/.config/custom/polybar-scripts/eyetimer.py &
python ~/.config/custom/polybar-scripts/audio.py &

python ~/.config/custom/scripts/i3-workspace-groups.py refresh-polybar
'';
  };
}
