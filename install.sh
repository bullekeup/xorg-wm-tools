#!/bin/sh

tmp="$(dirname $0)" && [ "${tmp%%/*}" = "." ] && SCRIPT_PATH="$(pwd)/${tmp#.}" || SCRIPT_PATH="${tmp}"
RUNDIR="$(pwd)"
cd ${SCRIPT_PATH}

PROC_CNT="$(grep -c processor /proc/cpuinfo)"

FORCE_INSTALL=0;
FORCE_BACKLIGHT=0;
FORCE_DWM=0;
FORCE_POLYBAR=0;
FORCE_CONFIG=0;
FORCE_FONTS=0;
FORCE_WALLPAPERS=0;
FORCE_NOTES=0

REMOVE=0;

while [ $# -gt 0 ]; do
  case $1 in
    --update | -u | --force ) FORCE_INSTALL=1; shift;;
    --backlight ) FORCE_BACKLIGHT=1; shift;;
    --dwm ) FORCE_DWM=1; shift;;
    --polybar ) FORCE_POLYBAR=1; shift;;
    --config ) FORCE_CONFIG=1; shift;;
    --fonts ) FORCE_FONTS=1; shift;;
    --wallpapers ) FORCE_WALLPAPERS=1; shift;;
    --notes ) FORCE_NOTES=1; shift;;
    --remove | -r | --uninstall ) REMOVE=1; shift;;
    *) shift;;
  esac
done

git submodule update --init

[ ${REMOVE} -eq 0 ] && [ ! -e "/etc/udev/rules.d/backlight.rules" ] \
  && FORCE_BACKLIGHT=1

if [ ${FORCE_BACKLIGHT} -eq 1 ] || [ ${FORCE_INSTALL} -eq 1 ]; then
  if [ ${REMOVE} -eq 1 ]; then
    echo "Remove udev rule for backlight control"
    [ -e /etc/udev/rules.d/backlight.rules ] && rm /etc/udev/rules.d/backlight.rules
  else
    echo "Installing udev rule for backlight control"
    sudo install -m 644 ./backlight.rules /etc/udev/rules.d/
  fi
  sudo udevadm control --reload
  sudo udevadm trigger
fi

[ ${REMOVE} -eq 0 ] && [ ! -e "/opt/local/dwm/bin/dwm" ] && FORCE_DWM=1;

if [ ${FORCE_DWM} -eq 1 ] || [ ${FORCE_INSTALL} -eq 1 ]; then
  if [ ${REMOVE} -eq 1 ]; then
    echo "Removing dwm"
    [ -e /opt/local/dwm ] && sudo rm -Rf /opt/local/dwm
    [ -e /usr/bin/dwm-wrapper ] && sudo rm -Rf /usr/bin/dwm-wrapper
    [ -e /usr/share/xsessions/dwm.desktop ] && \
      sudo rm -Rf /usr/share/xsessions/dwm.desktop
  else
    echo "Installing dwm"
    cd "./dwm"
    make clean
    make -j${PROC_CNT} all
    sudo make DESTDIR="/opt/local/dwm" PREFIX="" install
    sudo install -m755 ./dwm-wrapper /usr/bin/dwm-wrapper
    sudo install -m644 ./dwm.desktop /usr/share/xsessions/dwm.desktop
    cd -
  fi
fi

[ ${REMOVE} -eq 0 ] && [ ! -e "/opt/local/polybar-dwm-module/bin/polybar" ] && FORCE_POLYBAR=1;

if [ ${FORCE_POLYBAR} -eq 1 ] || [ ${FORCE_INSTALL} -eq 1 ]; then
  if [ ${REMOVE} -eq 1 ]; then
    [ -e /opt/local/polybar-dwm-module ] && sudo rm -Rf /opt/local/polybar-dwm-module
    [ -e /usr/bin/polybar ] && sudo rm /usr/bin/polybar
    [ -e /usr/bin/polybar.orig ] && sudo mv /usr/bin/polybar.orig /usr/bin/polybar
    [ -e /usr/bin/polybar-msg ] && sudo rm /usr/bin/polybar-msg
    [ -e /usr/bin/polybar-msg.orig ] && \
      sudo mv /usr/bin/polybar-msg.orig /usr/bin/polybar-msg
    [ -e /usr/share/bash-completion/completions/polybar ] && \
      sudo rm /usr/share/bash-completion/completions/polybar
    [ -e /usr/share/bash-completion/completions/polybar.orig ] && \
      sudo mv /usr/share/bash-completion/completions/polybar.orig \
        /usr/share/bash-completion/completions/polybar
    [ -e /usr/share/zsh/site-functions/_polybar ] && \
      sudo rm /usr/share/zsh/site-functions/_polybar
    [ -e /usr/share/zsh/site-functions/_polybar.orig ] && \
      sudo mv /usr/share/zsh/site-functions/_polybar.orig \
        /usr/share/zsh/site-functions/_polybar

  else
    echo "Installing polybar-dwm-module"
    cd "./polybar-dwm-module"
    [ -e "./build" ] && rm -Rf ./build
    mkdir build && cd build
    export CXX="g++"
    cmake \
      -DCMAKE_CXX_COMPILER="$CXX"                             \
      -DENABLE_ALSA:BOOL="ON"                                 \
      -DENABLE_PULSEAUDIO:BOOL="ON"                           \
      -DENABLE_DWM:BOOL="ON"                                  \
      -DENABLE_MPD:BOOL="ON"                                  \
      -DENABLE_NETWORK:BOOL="ON"                              \
      -DENABLE_CURL:BOOL="ON"                                 \
      -DBUILD_IPC_MSG:BOOL="ON"                               \
      -DCMAKE_INSTALL_PREFIX="/opt/local/polybar-dwm-module"  \
      -DBUILD_TESTS:BOOL="ON"                                 \
      ..
    make -j${PROC_CNT}
    make test
    sudo make install
    [ -e /usr/bin/polybar ] && \
      [ "$(readlink /usr/bin/polybar)x" != \
         "/opt/local/polybar-dwm-module/bin/polybarx" ] && \
        sudo cp /usr/bin/polybar /usr/bin/polybar.orig
    sudo ln -f -s /opt/local/polybar-dwm-module/bin/polybar /usr/bin/polybar

    [ -e /usr/bin/polybar-msg ] && \
      [ "$(readlink /usr/bin/polybar-msg)x" != \
         "/opt/local/polybar-dwm-module/bin/polybar-msgx" ] && \
        sudo cp /usr/bin/polybar-msg /usr/bin/polybar-msg.orig
    sudo ln -f -s /opt/local/polybar-dwm-module/bin/polybar-msg /usr/bin/polybar-msg

    [ -e /usr/share/zsh/site-functions/_polybar ] && \
      [ "$(readlink /usr/share/zsh/site-functions/_polybar)x" != \
         "/opt/local/polybar-dwm-module/share/zsh/site-functions/_polybarx" ] && \
        sudo cp /usr/share/zsh/site-functions/_polybar \
          /usr/share/zsh/site-functions/_polybar.orig
    sudo ln -f -s /opt/local/polybar-dwm-module/share/zsh/site-functions/_polybar /usr/share/zsh/site-functions/_polybar

    [ -e /usr/share/bash-completion/completions/polybar ] && \
      [ "$(readlink /usr/share/bash-completion/completions/polybar)x" != \
         "/opt/local/polybar-dwm-module/share/bash-completion/completions/polybarx" ] && \
        sudo cp /usr/share/bash-completion/completions/polybar \
          /usr/share/bash-completion/completions/polybar.orig
    sudo ln -f -s /opt/local/polybar-dwm-module/share/bash-completion/completions/polybar /usr/share/bash-completion/completions/polybar

    cd ${SCRIPT_PATH}
  fi
fi

[ -e "${HOME}/.local/share/bash-completion/completions" ] || \
  install -d "${HOME}/.local/share/bash-completion/completions"

[ -e "${HOME}/.local/share/zsh-completion/completions" ] || \
  install -d "${HOME}/.local/share/zsh-completion/completions"

{ [ ${FORCE_NOTES} -eq 1 ] || [ ${FORCE_INSTALL} -eq 1 ]; } && {
  cd ./notes
  make BASH_COMPLETION_DIR="${HOME}/.local/share/bash-completion/completions" \
    PREFIX="~/.local" USERDIR="${HOME}"
  install -m644 ./_notes "${HOME}/.local/share/zsh-completion/completions/"
  cd ${SCRIPT_PATH}
}

[ ${FORCE_INSTALL} -eq 1 ] || unset FORCE_INSTALL;
[ ${FORCE_FONTS} -eq 1 ] || unset FORCE_FONTS;
[ ${FORCE_CONFIG} -eq 1 ] || unset FORCE_CONFIG;
[ ${FORCE_WALLPAPERS} -eq 1 ] || unset FORCE_WALLPAPERS;

./user-fonts-install/update-fonts.sh ${FORCE_INSTALL:+--update} ${FORCE_FONTS:+--update}
./dwm-config/install.sh ${FORCE_INSTALL:+--update} ${FORCE_CONFIG:+--update}
./polybar-config/install.sh ${FORCE_INSTALL:+--update} ${FORCE_CONFIG:+--update}
./wallpapers/install.sh ${FORCE_INSTALL:+--update} ${FORCE_WALLPAPERS:+--update}
./dotfiles/install.sh ${FORCE_INSTALL:+--update} ${FORCE_CONFIG:+--update}

exit 0;

