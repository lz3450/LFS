# gnome
sudo pacman -S gnome
sudo pacman -S gnome-tweaks gnome-software-packagekit-plugin chromium

#gsettings set org.gnome.desktop.interface monospace-font-name 'Ubuntu Mono Regular 13'
#gsettings set org.gnome.desktop.interface document-font-name 'Ubuntu Mono Regular 13'
#gsettings set org.gnome.desktop.interface font-name 'Ubuntu Light 11'
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface clock-show-seconds true
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 5000

# gdm
#sudo -u gdm dbus-launch gsettings set org.gnome.desktop.screensaver picture-uri 'file:///usr/share/gnome-control-center/pixmaps/noise-texture-light.png'
sudo -u gdm dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
sudo -u gdm dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
sudo -u gdm dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0
sudo -u gdm dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'

# gnome
#sudo dbus-launch gsettings set org.gnome.desktop.screensaver picture-uri 'file:///usr/share/gnome-control-center/pixmaps/noise-texture-light.png'
sudo dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
sudo dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
sudo dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0
sudo dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'

#gsettings set org.gnome.desktop.screensaver picture-uri 'file:///usr/share/gnome-control-center/pixmaps/noise-texture-light.png'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
