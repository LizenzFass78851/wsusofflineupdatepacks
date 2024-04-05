#!/usr/bin/env bash
#
# Filename: get-all-updates.bash
#
# Copyright (C) 2016-2021 Hartmut Buhrmester
#                         <wsusoffline-scripts-xxyh@hartmut-buhrmester.de>
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
#     This is an example script to download all updates for the
#     languages German and English. These are the default languages
#     for the Windows script DownloadUpdates.cmd. For the Linux script
#     download-updates.bash, all needed languages must be listed on the
#     command line. Since version 1.0-beta-4, you can combine several
#     languages to a comma-separated list.
#
#     This script should give the same result as the Windows script
#     DownloadUpdates.cmd, if Office x64 support is enabled for German
#     and English by running:
#
#     AddOffice2010x64Support.cmd deu
#     AddOffice2010x64Support.cmd enu
#
#     It may also serve as a template to be customized.


# Stop this script, if one of download runs exits with an error code.
set -o errexit

# Resolving the installation path with GNU readlink is very reliable,
# but it may only work in Linux and FreeBSD. Remove the option -f for
# BSD readlink on Mac OS X. If there are any problems with resolving
# the installation path, change directly to the installation directory
# of this script and run it from there.
cd "$(dirname "$(readlink -f "$0")")" || exit 1


# Download using internal lists
#
# Using the internal list "all" is a simple way to get all updates for
# all supported Windows and Office versions:

./download-updates.bash all deu,enu -includesp -includecpp \
                                    -includedotnet -includewddefs


# The remaining examples demonstrate, which optional downloads are
# available for each update. They are all commented out, so that they
# won't be called twice.
#
# By default, the option -includesp only affects downloads for Windows
# 8.1 / Server 2012 R2 (w63, w63-x64). You can, however, create a custom
# file "../exclude/custom/ExcludeList-SPs.txt" to add service packs
# for all Windows and Office versions. This is supported by the scripts
# download-updates.bash, copy-to-target.bash and create-iso-image.bash.


# Windows Server 2012
#
# Updates for Windows Server 2012 are global, but they now use localized
# installers for Internet Explorer. Therefore, all needed languages
# should still be specified on the command-line, even if no optional
# downloads are added:

# ./download-updates.bash w62-x64 deu,enu -includesp -includecpp \
#                                         -includedotnet -includewddefs


# Windows  8.1 / Server 2012 R2
# Windows 10   / Server 2016/2019
#
# Updates for Windows 8.1 and 10 are really global. The language
# parameters deu and enu are still needed for the .NET Framework
# downloads. Without this optional download, one language (any one)
# would be sufficient.
#
# To be precise, the English installers for .NET Frameworks are always
# downloaded, and they are supplemented by language packs for other
# languages. So, you could actually remove the parameter "enu" here. On
# the other hand, if you like to include other "custom" languages,
# they need to be listed here.

# ./download-updates.bash w63,w63-x64,w100,w100-x64 deu,enu -includesp \
#                           -includecpp -includedotnet -includewddefs


# Office 2013
#
# o2k13-x64 includes both 32-bit and 64-bit downloads, just like the
# Windows script DownloadUpdates.cmd, if 64-bit Office support is enabled
# with the script AddOffice2010x64Support.cmd.

# ./download-updates.bash o2k13-x64 deu,enu -includesp


# Office 2016
#
# o2k16-x64 includes both 32-bit and 64-bit downloads. One language
# (any one) is sufficient.

# ./download-updates.bash o2k16-x64 deu -includesp

exit 0
