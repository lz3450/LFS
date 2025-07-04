#!/bin/sh

# Generate gresource files
cp -f gnome-shell.css ./theme

FILES=$(find "theme" -type f -printf "%P\n" | xargs -i echo "    <file>theme/{}</file>")

cat > gnome-shell-theme.gresource.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<gresources>
  <gresource prefix="/org/gnome/shell">
$FILES
  </gresource>
</gresources>
EOF

if [ -f gnome-shell-theme.gresource ]; then
  rm gnome-shell-theme.gresource
fi

glib-compile-resources gnome-shell-theme.gresource.xml

sudo cp -f gnome-shell-theme.gresource /usr/share/gnome-shell/gnome-shell-theme.gresource
