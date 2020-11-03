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
while [ $# -gt 0 ]; do
  case $1 in
    --update | -u | --force ) FORCE_INSTALL=1; shift;;
    --backlight ) FORCE_BACKLIGHT=1; shift;;
    --dwm ) FORCE_DWM=1; shift;;
    --polybar ) FORCE_POLYBAR=1; shift;;
    --config ) FORCE_CONFIG=1; shift;;
    --fonts ) FORCE_FONTS=1; shift;;
    --wallpapers ) FORCE_WALLPAPERS=1; shift;;
    *) shift;;
  esac
done

git submodule update --init

if [ ${FORCE_BACKLIGHT} -eq 1 ] || [ ${FORCE_INSTALL} -eq 1 ] || [ ! -e "/etc/udev/rules.d/backlight.rules" ]; then
  echo "Installing udev rule for backlight control"
  sudo install -m 644 ./backlight.rules /etc/udev/rules.d/
  sudo udevadm control --reload
  sudo udevadm trigger
fi

if [ ${FORCE_DWM} -eq 1 ] || [ ${FORCE_INSTALL} -eq 1 ] || [ ! -e "/opt/local/dwm/bin/dwm" ]; then
  echo "Installing dwm WM" 
  cd "./dwm"
  make clean
  make -j${PROC_CNT} all
  sudo make DESTDIR="/opt/local/dwm" PREFIX="" install
  sudo install -m755 ./dwm-wrapper /usr/bin/dwm-wrapper
  sudo install -m644 ./dwm.desktop /usr/share/xsessions/dwm.desktop
  cd -
fi

if [ ${FORCE_POLYBAR} -eq 1 ] || [ ${FORCE_INSTALL} -eq 1 ] || [ ! -e "/opt/local/polybar-dwm-module/bin/polybar" ]; then
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
  sudo ln -f -s /opt/local/polybar-dwm-module/bin/polybar /usr/bin/polybar
  sudo ln -f -s /opt/local/polybar-dwm-module/bin/polybar-msg /usr/bin/polybar-msg
  cd ${SCRIPT_PATH}
fi

[ ${FORCE_INSTALL} -eq 1 ] || unset FORCE_INSTALL;
[ ${FORCE_FONTS} -eq 1 ] || unset FORCE_FONTS;
[ ${FORCE_CONFIG} -eq 1 ] || unset FORCE_CONFIG;
[ ${FORCE_WALLPAPERS} -eq 1 ] || unset FORCE_WALLPAPERS;

./user-fonts-install/update-fonts.sh ${FORCE_INSTALL:+--update} ${FORCE_FONTS:+--update}
./dwm-config/install.sh ${FORCE_INSTALL:+--update} ${FORCE_CONFIG:+--update}
./polybar-config/install.sh ${FORCE_INSTALL:+--update} ${FORCE_CONFIG:+--update}
./wallpapers/install.sh ${FORCE_INSTALL:+--update} ${FORCE_WALLPAPERS:+--update}
./dotfiles/install.sh ${FORCE_INSTALL:+--update} ${FORCE_CONFIG:+--update}

