#!/usr/bin/env bash
#
# Filename: rebuild-integrity-database.bash
#
# Copyright (C) 2018-2021 Hartmut Buhrmester
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
#     This is a standalone script to recreate the integrity database
#     of hashdeep checksum files. It may be useful, if the usage of the
#     integrity database was disabled in the preferences file.

# ========== Shell options ================================================

set -o nounset
set -o errexit
set -o errtrace
set -o pipefail
shopt -s nocasematch

# ========== Configuration ================================================

# Set fast_mode to "enabled" to only calculate SHA-1 hashes instead of
# MD5, SHA-1 and SHA-256
fast_mode="disabled"

# Create a list of download directories and the corresponding hashdeep
# files
directories_and_hashes=(
    "../client/cpp             ../client/md/hashes-cpp.txt"
    "../client/dotnet          ../client/md/hashes-dotnet.txt"
    "../client/o2k16/glb       ../client/md/hashes-o2k16-glb.txt"
    "../client/w62-x64/glb     ../client/md/hashes-w62-x64-glb.txt"
    "../client/w63/glb         ../client/md/hashes-w63-glb.txt"
    "../client/w63-x64/glb     ../client/md/hashes-w63-x64-glb.txt"
    "../client/w100/glb        ../client/md/hashes-w100-glb.txt"
    "../client/w100-x64/glb    ../client/md/hashes-w100-x64-glb.txt"
    "../client/wddefs/x86-glb  ../client/md/hashes-wddefs-x86-glb.txt"
    "../client/wddefs/x64-glb  ../client/md/hashes-wddefs-x64-glb.txt"
    "../client/win/glb         ../client/md/hashes-win-glb.txt"
    "../client/wsus            ../client/md/hashes-wsus.txt"
)

localized_updates=( o2k13 )
languages=(
    deu enu ara chs cht csy dan nld fin fra ell heb hun ita jpn kor nor
    plk ptg ptb rus esn sve trk glb
)

for name in "${localized_updates[@]}"
do
    for lang in "${languages[@]}"
    do
        directories_and_hashes+=(
            "../client/${name}/${lang}  ../client/md/hashes-${name}-${lang}.txt"
        )
    done
done

# Turn the indexed array into a table, which can be parsed with the
# internal command read of the bash
directories_and_hashes_table="$( printf '%s\n' "${directories_and_hashes[@]}" )"

#printf '%s\n' "List of known download directories and hashes:"
#printf '%s\n' "${directories_and_hashes_table}"

# ========== Environment variables ========================================

export LC_ALL=C

# ========== Global variables =============================================

# Create a temporary directory
if type -P mktemp >/dev/null
then
    temp_dir="$(mktemp -d "/tmp/rebuild-integrity-database.XXXXXX")"
else
    temp_dir="/tmp/rebuild-integrity-database.temp"
    mkdir -p "${temp_dir}"
fi

logfile="../log/rebuild-integrity-database.log"

# ========== Check requirements ===========================================

# hashdeep is required for creating the integrity database
if ! type -P hashdeep >/dev/null
then
    printf '%s\n' "Error: hashdeep is needed for the creation of the integrity database."
    exit 0
fi

# A Linux trash handler can move obsolete files to the trash
linux_trash_handler=""

for binary_name in gio gvfs-trash trash-put
do
    if type -P "${binary_name}" > /dev/null
    then
        linux_trash_handler="${binary_name}"
        break
    fi
done

if [[ "${linux_trash_handler}" == "gio" ]]
then
    # gio uses different commands, which must be added at this point
    linux_trash_handler="gio trash"
fi

if [[ -z "${linux_trash_handler}" ]]
then
    printf '%s\n' "Please install trash-put, to move files into the trash"
fi

# ========== Libraries ====================================================

# Rather than re-implementing everything, import existing libraries
source ./libraries/desktop-integration.bash
source ./libraries/dos-files.bash
source ./libraries/error-counter.bash
source ./libraries/files-and-folders.bash
source ./libraries/integrity-database.bash
source ./libraries/messages.bash

# ========== Functions ====================================================

function parse_directories ()
{
    local download_directory=""
    local hashes_file=""
    local skip_rest=""

    while read -r download_directory hashes_file skip_rest
    do
        if [[ -d "${download_directory}" ]]
        then
            log_info_message "Found directory ${download_directory}"
            create_integrity_database "${download_directory}" "${hashes_file}"
            verify_embedded_hashes "${download_directory}" "${hashes_file}"
            echo ""
        else
            log_debug_message "Directory ${download_directory} was not found"
        fi
    done <<< "${directories_and_hashes_table}"
    return 0
}

# ========== Commands =====================================================

# Setup working directory
#
# Resolving the installation path with GNU readlink is very reliable,
# but it may only work in Linux and FreeBSD. Remove the option -f for
# BSD readlink on Mac OS X. If there are any problems with resolving
# the installation path, change directly to the installation directory
# of this script and run it from there.
cd "$(dirname "$(readlink -f "$0")")"

# Rebuild integrity database
parse_directories

# Cleanup temporary directory
if [[ -d "${temp_dir}" ]]
then
    rm -r "${temp_dir}"
fi

exit 0
