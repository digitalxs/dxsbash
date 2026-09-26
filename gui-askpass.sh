#!/bin/sh
# DXSBash graphical sudo password prompt (SUDO_ASKPASS helper).
# Used by dxsbash-gui when the updater or login-shell change needs
# administrator rights and there is no terminal to type into.
# sudo passes its prompt text as $1; the password goes to stdout.
exec zenity --password --title="DXSBash — administrator password" 2>/dev/null
