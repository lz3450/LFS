#!/bin/sh

#set -vx
set -eu

# For backwards compatibility reasons, future versions of this script must
# support the syntax "update-ca-trust extract" trigger the generation of output
# files in $DEST.

DEST=/etc/pki/ca-trust/extracted
DEST_CERTS=/etc/pki/tls/certs

# Prevent p11-kit from reading user configuration files.
export P11_KIT_NO_USER_CONFIG=1

usage() {
	fold -s -w 76 >&2 <<-EOF
		Usage: $0 [extract] [-o DIR|--output=DIR]

		Update the system trust store in $DEST.

		COMMANDS
		(absent/empty command): Same as the extract command without arguments.

		extract: Instruct update-ca-trust to scan the source configuration in
		/usr/share/pki/ca-trust-source and /etc/pki/ca-trust/source and produce
		updated versions of the consolidated configuration files stored below
		the $DEST directory hierarchy.

		EXTRACT OPTIONS
		-o DIR, --output=DIR: Write the extracted trust store into the given
		directory instead of updating $DEST. (Note: This option will not
		populate the ../pki/tls/certs with the directory-hash symbolic links.)
	EOF
}

extract() {
	USER_DEST=

        # can't use getopt here. ca-certificates can't depend on a lot
        # of other libraries since openssl depends on ca-certificates
        # just fail when we hand parse

        while [ $# -ne 0 ]; do
	    case "$1" in
	      "-o"|"--output")
		  if [ $# -lt 2 ]; then
			  echo >&2 "Error: missing argument for '$1' option. See 'update-ca-trust --help' for usage."
			  echo >&2
			  exit 1
		  fi
	          USER_DEST=$2
		  shift 2
		  continue
		  ;;
		"--")
		  shift
		  break
		  ;;
		*)
		  echo >&2 "Error: unknown extract argument '$1'. See 'update-ca-trust --help' for usage."
		  exit 1
		  ;;
	    esac
	done

	if [ -n "$USER_DEST" ]; then
		DEST=$USER_DEST
	        # Attempt to create the directories if they do not exist
                # yet (rhbz#2241240)
	        /usr/bin/mkdir -p \
		    "$DEST"/openssl \
		    "$DEST"/pem
	fi


	# Delete all directory hash symlinks from the cert directory
	if [ -z "$USER_DEST" ]; then
		find "$DEST_CERTS" -type l -regextype posix-extended \
		     -regex '.*/[0-9a-f]{8}\.[0-9]+' -exec rm -f {} \;
	fi

	# OpenSSL PEM bundle that includes trust flags
	# (BEGIN TRUSTED CERTIFICATE)
	/usr/bin/trust extract --format=pem-bundle --filter=ca-anchors --overwrite --comment --purpose server-auth "$DEST/pem/tls-ca-bundle.pem"
	/usr/bin/trust extract --format=pem-bundle --filter=ca-anchors --overwrite --comment --purpose email "$DEST/pem/email-ca-bundle.pem"
	/usr/bin/trust extract --format=pem-bundle --filter=ca-anchors --overwrite --comment --purpose code-signing "$DEST/pem/sign-ca-bundle.pem"
	# Hashed directory of BEGIN TRUSTED-style certs (usable as OpenSSL CApath and
	# by GnuTLS)
	/usr/bin/trust extract --format=pem-directory-hash --filter=ca-anchors --overwrite --purpose server-auth "$DEST/pem/directory-hash"


	if [ -z "$USER_DEST" ]; then
		find "$DEST/pem/directory-hash" -type l -regextype posix-extended \
		     -regex '.*/[0-9a-f]{8}\.[0-9]+' | while read link; do
			target=$(readlink -f "$link")
			new_link="$DEST_CERTS/$(basename "$link")"
			ln -rs "$target" "$new_link"
		done
	fi
}
if [ $# -lt 1 ]; then
    set -- extract
fi

case "$1" in
	"extract")
		shift
		extract "$@"
	;;
	"--help")
		usage
		exit 0
	;;
	*)
		echo >&2 "Error: unknown command: '$1', see 'update-ca-trust --help' for usage."
		exit 1
	;;
esac
