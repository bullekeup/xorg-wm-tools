# X11 utilities

Can clone with all the submodules to build a DWM + polybar X11 setup :

git clone --recursive https://github.com/bullekeup/x11-tools

Auto install with ./install.sh

This will install 

- dwm to /opt/local/dwm, with a wrapper dwm-wrapper in /usr/bin and a dwm.desktop file in /usr/share/xsessions to allow display manager to launch dwm
- dwm-config in ~/.local/share/dwm
- polybar-config in ~/.config/polybar
- polybar-dwm-module to /opt/local/polybar-dwm-module, with symlinks in /usr/bin
- fonts in user-specific ~/.local/share/fonts
- wallpapers in ~/.local/share/wallpapers
- dotfiles
 - .zshrc, .p10k.zsh, .bashrc, .xprofile, .profile in ~/
 - alacritty.yml in ~/.config/alacritty
 - dunst config in ~/.config/dunst
 - tmux.conf in ~/


## displayset

A simple display auto-setup script using xrandr.
See https://github.com/bullekeup/displayset

Install through the AUR : yay -S displayset displayset-udev-rules displayset-doc

### Dependencies

- xrandr
- A POSIX sh shell
- awk
- udev (for udev rule)

## dwm

My own patched version of dwm.
See https://github.com/bullekeup/dwm

to install as user :

make DESTDIR=~/.local install

### Dependencies

yajl (ipc patch)

### Dependencies

## polybar-dwm-module

Polybar with DWM support.
See https://github.com/mihirlad55/polybar-dwm-module
See https://github.com/polybar/polybar/wiki/Compiling#building

Install from the AUR : yay -S polybar-dwm-module

### Build

Clone the repo with all submodules:
git clone --recursive https://github.com/mihirlad55/polybar-dwm-module

Create a build dir in polybar-dwm-module and cd to it

Build with modules you want and install dir you want :

CXX=g++ OR CXX=clang++

cmake                                           \
	-DCMAKE_CXX_COMPILER="${CXX}"           \
	-DENABLE_ALSA:BOOL="ON"                 \
	-DENABLE_PULSEAUDIO:BOOL="ON"           \
	-DENABLE_DWM:BOOL="ON"                  \
	-DENABLE_MPD:BOOL="ON"                  \
	-DENABLE_NETWORK:BOOL="ON"              \
	-DENABLE_CURL:BOOL="ON"                 \
	-DBUILD_IPC_MSG:BOOL="ON"               \
	-DBUILD_TESTS:BOOL="ON"                 \
	-DCMAKE_INSTALL_PREFIX=~/.local         \
	..

make -jX
make test
make install

### Dependencies

- jsoncpp
- alsalib (alsa-lib on Arch) (alsa support)
- libpulse (pulseaudio support)
- libnl / libiw (wireless_tools on Arch) (network support)
- libmpdclient / libmpd (mpd support)
- clang (optional if GCC installed)
- libcurl (github plugin)

## Installation as user

DWM and polybar can be installed as user, for example in ~/.local
displayset can too, but if you want to use the udev rule for hotplug display detection, installing system-wide is easier.

