#!/bin/sh

cp -f gtk-3.0.css ~/.themes/Yaru-neo/gtk-3.0/gtk.css
cp -f gtk-3.20.css ~/.themes/Yaru-neo/gtk-3.20/gtk.css

cd gtk-3.0
FILES=$(find "3.0" -type f -printf "%P\n" | xargs -i echo "    <file>3.0/{}</file>")

cat > gtk.gresource.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<gresources>
  <gresource prefix="/com/ubuntu/themes/Yaru">
$FILES
  </gresource>
</gresources>
EOF

if [ -f gtk.gresource ]; then
  rm gtk.gresource
fi

glib-compile-resources gtk.gresource.xml

cp -f gtk.gresource ~/.themes/Neo/gtk-3.0/gtk.gresource
