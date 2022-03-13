#!/bin/sh

# Extract original gresource files
# if [ ! -f /usr/share/gnome-shell/gnome-shell-theme.gresource.old ]; then
#   sudo mv /usr/share/gnome-shell/gnome-shell-theme.gresource /usr/share/gnome-shell/gnome-shell-theme.gresource.old
# fi

# cp -f /usr/share/gnome-shell/gnome-shell-theme.gresource.old gnome-shell-theme.gresource

rm -rf ./theme
mkdir -p ./theme/icons

for r in `gresource list gnome-shell-theme.gresource`;
do
  gresource extract gnome-shell-theme.gresource $r > ./${r#\/org\/gnome\/shell/}
done

cp theme/gnome-shell.css .
