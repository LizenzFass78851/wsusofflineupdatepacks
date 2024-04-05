#!/usr/bin/env bash

# Filename: reset-wsusoffline.bash
#
# Copyright (C) 2021 Hartmut Buhrmester
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
#     This script deletes files, which are automatically created by the
#     Linux download scripts. Manually created files like preferences.bash
#     are preserved.
#
#     This is used for development, to trigger a reevaluation of all
#     steps.


# Shell options
set -o nounset
set -o errexit
set -o pipefail
shopt -s nullglob

# Environment variables
export LC_ALL=C

# Global variables
file_list=()
pathname=""

# Change to the installation directory
cd "$(dirname "$(readlink -f "$0")")" || exit 1

printf '%s\n' "Create a list of automatically created files..."

# Setting files
#
# The Windows 10 versions file will be deleted, but a new file with
# default settings will be created on the next run by the script
# 10-remove-obsolete-scripts.bash.
file_list+=(
    ./update-generator.ini
    ./windows-10-versions.ini
)

# Cached files
file_list+=( ../cache/* )

# Hashdeep files, collectively known as the integrity database
file_list+=( ../client/md/*.txt )

# Update tables
file_list+=( ../client/UpdateTable/UpdateTable-*.csv )

# Superseded updates (Windows and Linux versions)
file_list+=(
    ../exclude/ExcludeList-superseded.txt
    ../exclude/ExcludeList-superseded-seconly.txt
    ../exclude/ExcludeList-Linux-*.txt
)

# Logfiles
file_list+=( ../log/*.log )

# Configuration files
#
# This deletes "meta" files, which reference changed files in the static,
# exclude and client/static directories.
file_list+=(
    ../static/sdd/StaticDownloadFiles-modified.txt
    ../static/sdd/ExcludeDownloadFiles-modified.txt
    ../static/sdd/StaticUpdateFiles-modified.txt
)

# Reset the ETag database
#
# This file is included as an empty file in the wsusoffline archive,
# and it is tracked by the git version control system. It should only
# be reset to its original size.
true > ../static/SelfUpdateVersion-static.txt

# Timestamps
file_list+=( ../timestamps/*.txt )

printf '%s\n' "Delete the list of files..."

if (( "${#file_list[@]}" > 0 ))
then
    for pathname in "${file_list[@]}"
    do
        if [[ -f "${pathname}" ]]
        then
            printf '%s\n' "Deleting ${pathname}"
            rm "${pathname}"
        fi
    done
fi

# The file preferences.bash may contain custom settings, which should
# be preserved
if [[ -f preferences.bash ]]
then
    printf '%s\n' "Please review the file preferences.bash for manual changes"
fi

printf '%s\n' "All done, exiting..."
exit 0
