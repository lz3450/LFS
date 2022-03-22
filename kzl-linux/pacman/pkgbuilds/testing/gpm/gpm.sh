case $( /usr/bin/tty ) in
    /dev/tty[0-9]*)
        if [ -n "$(pidof -s gpm)" ]; then /usr/bin/disable-paste fi
        ;;
esac