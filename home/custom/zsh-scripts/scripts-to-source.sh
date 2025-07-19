# change directory to one of the predefined locations
j()
{
  if [ $# -eq 0 ]; then
    echo 'Usage: j DIR_NAME'
    return
  fi
  cmd="$1"
  case "$cmd" in
    'nx') dest=$HOME'/.config/nixos-config/';;
    'mo') dest=$HOME'/.config/nixos-config/modules/';;
    'ho') dest=$HOME'/.config/nixos-config/home/';;
    'hs') dest=$HOME'/.config/nixos-config/hosts/';;
    'vim') dest=$HOME'/.config/nixos-config/home/nvim/';;
    'ps') dest=$HOME'/.config/nixos-config/home/custom/polybar-scripts/';;
    'sy') dest=$HOME'/sync/';;
    'ag') dest=$HOME'/.config/nixos-config/home/ags/';;
    'hy') dest=$HOME'/.config/nixos-config/home/hypr/';;
    'hys') dest=$HOME'/.config/nixos-config/home/custom/scripts/hypr/';;
    *) echo Unknown destination "$cmd"...; return;;
  esac
  cd "$dest"
}

# open zathura asynchronously
z()
{
  (zathura "$@" &>/dev/null &)
}

# create and move to directory
mkcd()
{
  mkdir -p "$1"
  cd "$1"
}
