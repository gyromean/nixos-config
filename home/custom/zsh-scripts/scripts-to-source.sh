# interactive cd by calling fzf, parameter can be used to specify root directory of the search, otherwise home directory is used, only directories are shown
cf()
{
  if [ $# -gt 0 ]; then
    fzf_dir="$1"
  else
    fzf_dir="~"
  fi
  find_cmd="find $fzf_dir -type d 2>/dev/null"
  fzf_path="$(FZF_DEFAULT_COMMAND="$find_cmd" fzf)"
  [[ -z $fzf_path ]] && return # return if fzf was exited
  cd "$fzf_path"
}

# interactive vim by calling fzf, parameter can be used to specify root directory of the search, otherwise home directory is used, only files are shown (not directories)
vf()
{
  if [ $# -gt 0 ]; then
    fzf_dir="$1"
  else
    fzf_dir="~"
  fi
  find_cmd="find $fzf_dir -type f,l 2>/dev/null"
  fzf_path="$(FZF_DEFAULT_COMMAND="$find_cmd" fzf)"
  [[ -z $fzf_path ]] && return # return if fzf was exited
  vim "$fzf_path"
}

# interactively select starting folder for ranger by calling fzf, parameter can be used to specify root directory of the search, otherwise home directory is used, only directories are shown
rf()
{
  if [ $# -gt 0 ]; then
    fzf_dir="$1"
  else
    fzf_dir="~"
  fi
  find_cmd="find $fzf_dir -type d 2>/dev/null"
  fzf_path="$(FZF_DEFAULT_COMMAND="$find_cmd" fzf)"
  [[ -z $fzf_path ]] && return # return if fzf was exited
  ranger "$fzf_path"
}

# interactive xdg-open by calling fzf, parameter can be used to specify root directory of the search, otherwise home directory is used, all file types are shown
xf()
{
  if [ $# -gt 0 ]; then
    fzf_dir="$1"
  else
    fzf_dir="~"
  fi
  find_cmd="find $fzf_dir 2>/dev/null"
  fzf_path="$(FZF_DEFAULT_COMMAND="$find_cmd" fzf)"
  [[ -z $fzf_path ]] && return # return if fzf was exited
  xdg-open "$fzf_path" &>/dev/null
}

# interactively select starting folder for nemo by calling fzf, parameter can be used to specify root directory of the search, otherwise home directory is used, only directories are shown
nf()
{
  if [ $# -gt 0 ]; then
    fzf_dir="$1"
  else
    fzf_dir="~"
  fi
  find_cmd="find $fzf_dir -type d 2>/dev/null"
  fzf_path="$(FZF_DEFAULT_COMMAND="$find_cmd" fzf)"
  [[ -z $fzf_path ]] && return # return if fzf was exited
  (nemo "$fzf_path" &>/dev/null &)
}

# interactively search files via fzf, parameter can be used to specify root directory of the search, otherwise home directory is used, both directories and files are shown
f()
{
  if [ $# -gt 0 ]; then
    fzf_dir="$1"
  else
    fzf_dir="~"
  fi
  find_cmd="find $fzf_dir 2>/dev/null"
  FZF_DEFAULT_COMMAND="$find_cmd" fzf
}

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
