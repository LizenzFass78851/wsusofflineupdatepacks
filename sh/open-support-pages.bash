#!/usr/bin/env bash

# Filename: open-support-pages.bash
#
# Copyright (C) 2019-2021 Hartmut Buhrmester
#                    <wsusoffline-scripts-xxyh@hartmut-buhrmester.de>
#
# License
#
#     This file is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published
#     by the Free Software Foundation, either version 3 of the License,
#     or (at your option) any later version.
#
#     This file is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#     General Public License for more details.
#
#     You should have received a copy of the GNU General
#     Public License along with this program.  If not, see
#     <http://www.gnu.org/licenses/>.
#
# Description
#
#     This script opens the Microsoft support pages for a series of
#     kb numbers.
#
#     It tries a series of Linux "open handlers", to open the URLs with
#     the preferred browser of the current desktop environment. Suitable
#     open handlers are:
#
#     handler     package name    desktop environment
#     ----------  --------------  -----------------------
#     gio open    libglib2.0-bin  GNOME 3.30 in Debian 10
#     gvfs-open   gvfs-bin        GNOME 3.22 in Debian 9
#     gnome-open  libgnome2-bin   GNOME 2
#     kde-open5   kde-cli-tools   KDE 5 (untested)
#     kde-open    kde-runtime     KDE 4 (untested)
#     exo-open    exo-utils       Xfce
#     xdg-open    xdg-utils       others
#
#     Note: The package names are for Debian and related distributions.
#
#     These open handlers use the file mimeapps.list to find the preferred
#     applications for known file types and URL schemes. The location
#     of the file mimeapps.list is either:
#
#     ~/.config/mimeapps.list
#     ~/.local/share/applications/mimeapps.list
#
#     In addition to these open handlers, sensible-browser, firefox-esr
#     and firefox are also tried, because this script only needs
#     to handle http or https URLs. sensible-browser is part of the
#     update-alternatives system in Debian. It uses gnome-www-browser,
#     x-www-browser or www-browser, depending on the context.
#
#     If none of the above can be found, then the script recommends the
#     installation of xdg-open as a general open handler, which is not
#     tied to a particular desktop environment.
#
#     Mac OS X users could simply use "open", but this is a completely
#     different utility in Linux.
#
#     Note: Neither gvfs-open nor Firefox can handle multiple URLs on
#     the command line. Calling xdg-open multiple times means that the
#     application should be launched multiple times, but this will fail
#     with Firefox. To have Firefox open the URLs in multiple tabs,
#     it should be launched first, before running this script.
#
# Usage
#
#     ./open-support-pages.bash kb-number [kb-number...]


# Set shell options
set -o nounset
set -o errexit
set -o errtrace
set -o pipefail

# The script expects at least one kb-number as a command-line parameter
if (( $# == 0 ))
then
    printf '%s\n' "This script opens the Microsoft support pages for a series of kb numbers."
    printf '%s\n' ""
    printf '%s\n' "Usage: open-support-pages.bash kb-number [kb-number...]"
    exit 1
fi

# Find a suitable Linux open handler
binary_name=""
linux_open_handler=""
for binary_name in gio gvfs-open gnome-open kde-open5 kde-open exo-open xdg-open sensible-browser firefox-esr firefox
do
    if type -P "${binary_name}" >/dev/null; then
        linux_open_handler="${binary_name}"
        break
    fi
done

if [[ "${linux_open_handler}" == "gio" ]]
then
    # gio uses different commands, which must be added at this point.
    linux_open_handler="gio open"
fi

if [[ -n "${linux_open_handler}" ]]
then
    printf '%s\n' "Found Linux open handler: ${linux_open_handler}"
else
    printf '%s\n' "Please install the command xdg-open, from package xdg-utils, to open files and URLs with the preferred application of your desktop environment."
    exit 1
fi

# Parse command line parameters
number=""
for number in "$@"
do
    # Remove "kb" or "KB" from the beginning of the string
    number="${number/#kb/}"
    number="${number/#KB/}"
    # xdg-open can only open one URL at the same time. The variable
    # linux_open_handler must not be quoted, because it may resolve to
    # gio open.
    ${linux_open_handler} "https://support.microsoft.com/en-us/help/${number}" &
    sleep 1s
done

exit 0
