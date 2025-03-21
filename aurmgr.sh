#!/bin/bash
#
# Simple AUR helper script that maintains the manual installation experience.
#
# This tool will create the directory ~/.aur if its not present and will use
# it to store AUR sources.
#

dir=$PWD

# Give user option to view the PKGBUILD/script.
less_prompt() {

read -p ":: View script in less? [Y/n] " choice
  if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
    less "$script"
  elif [ "$choice" = "n" ] || [ "$choice" = "N" ]; then
    return
  fi
}

# Evaluate which method to use for installation.
method() {

  if [ $name = "aurmgr" ]; then
    echo ":: ELEVATED PRIVILEGE REQUIRED TO COPY AURMGR SCRIPT TO /USR/LOCAL/BIN..."
    chmod +x aurmgr.sh && sudo cp -p aurmgr.sh /usr/local/bin/aurmgr && exec "$0"
  else  
    makepkg -sirc && git clean -dfx
  fi
}

# Prompt user to install or reject.
install_prompt() {

  read -p ":: Proceed with installation? [Y/n] " choice
    if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
      method
    elif [ "$choice" = "n" ] || [ "$choice" = "N" ]; then
      cd "$dir"
      return
    fi
}

if [ "$1" = "update" ]; then 

  # Check for updates and install.
  check() {
  
    if git pull | grep -q "Already up to date." ; then
      echo " up to date."
    else
      if [ $name = "aurmgr" ]; then   # Since aurmgr is not an AUR package, it must be updated seperately.
        script="aurmgr.sh"
      else                            # Update AUR packages.
        script="PKGBUILD"
      fi
      echo ":: An update is available for $name..."
      less_prompt && install_prompt
    fi
  }

  # Traverse folders and call check().
  for path in ~/.aur/*/ ; do
    name=${path::-1}
    name=${name##*/}
    cd "$path" && echo "-> $name" && check
  done

# Install new packages.
elif [ "$1" = "install" ]; then

  # Check if .aur exists, create it if not.
  if [ ! -d ~/.aur ]; then
    echo "Creating ~/.aur directory..."
    mkdir ~/.aur
  fi

  # Clone the source into .aur.
  if [ -n "$2" ]; then
    url="$2"
  else
    read -p ":: Enter package git clone URL: " url
  fi  
  cd ~/.aur && git clone $url

  # cd into new folder.
  name=${url##*/}
  name=${name::-4}
  cd $name

  # Display PKGBUILD and install.
  script="PKGBUILD"
  less_prompt && install_prompt

# Delete directories of packages no longer installed
elif [ "$1" = "clean" ]; then

  # Retrieve list of installed AUR packages from pacman and store in an array
  echo ":: ELEVATED PRIVILEGE REQUIRED TO RETRIEVE INSTALLED LIST FROM PACMAN..."
  installed=( $(sudo pacman -Qm | cut -f 1 -d " ") )

  ntd=true

  # Traverse folders
  for path in ~/.aur/*/ ; do
    name=${path::-1}
    name=${name##*/}
    
    match=false

    # Ignore the aurmgr folder
    if [ "$name" = "aurmgr" ]; then
        continue
    fi

    # Find a match for folder name in the array
    for package in ${installed[@]}; do
      if [ "$name" = "$package" ]; then
          match=true
      fi
    done

    # If a match is not found, delete the folder
    if [ "$match" = false ]; then
      echo ":: Package \"$name\" not installed, removing..."
      rm -rf ~/.aur/"$name"
      ntd=false
    fi
  done
  
  if [ "$ntd" = true ]; then
      echo " Nothing to do."
    fi
fi