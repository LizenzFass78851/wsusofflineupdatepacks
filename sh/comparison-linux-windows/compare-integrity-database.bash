#!/usr/bin/env bash
#
# Filename: compare-integrity-database.bash
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
#     This script is used for development. It compares two directories
#     with hashdeep checksum files. Since each hashdeep file corresponds
#     to one download directory and contains a fingerprint of each
#     downloaded file, this is a simple but in-depth comparison of the
#     downloads on both platforms.
#
#     For cross-platform compatibility, trailing carriage returns are
#     deleted and the files are sorted in a generic order. The first
#     four lines of the hashdeep files are comments, which can be
#     safely omitted.
#
#     The file example-results-md.txt shows a typical result. Most
#     directories should be the same, but the virus definition files
#     for Windows Defender and Microsoft Security Essentials are updated
#     every two hours. Therefore, the files mpas-fe.exe, mpas-feX64.exe,
#     mpam-fe.exe and mpam-fex64.exe are often different.
#
#     Note: To really get the same results, language settings and the
#     settings for 64-bit Office downloads must be the same.
#
#     The Windows script DownloadUpdates.cmd downloads a default set
#     of German and English installers for Internet Explorer, Microsoft
#     Security Essentials and .NET Frameworks. With the Linux scripts,
#     these downloads must be repeated for both languages, deu and enu.
#
#     On the other hand, you can directly select 64-bit Office
#     downloads in the script update-generator.bash. For the Windows
#     version, these downloads must be enabled by running the script
#     AddOffice2010x64Support.cmd twice, for deu and enu.
#
# Usage
#
#     ./compare-integrity-database.bash <windows-path> <linux-path>
#
#     The paths are the complete pathnames of the directories
#     wsusoffline/client/md on both Windows and Linux, for example:
#
#     /media/${USER}/Windows/wsusoffline/client/md
#     /home/${USER}/wsusoffline/client/md
#
#     The Windows partition is usually mounted in one of the directories
#     /mnt, /media or "/media/${USER}".

# ========== Shell options ================================================

set -o nounset
set -o errexit
set -o errtrace
set -o pipefail

# ========== Environment variables ========================================

# Use English messages and a generic sort order
export LC_ALL=C

# ========== Configuration ================================================

# Paths to the temporary directories
temp_md_windows="/tmp/md-windows"
temp_md_linux="/tmp/md-linux"

# ========== Functions ====================================================

function create_diff_files ()
{
    local source_directory="$1"
    local temp_directory="$2"
    local filename=""

    if [[ -d "${source_directory}" ]]
    then
        printf '%s\n' "Processing source directory: ${source_directory} ..."
    else
        printf '%s\n' "Error: The directory ${source_directory} was not found."
        exit 1
    fi

    mkdir -p "${temp_directory}"
    rm -f "${temp_directory}"/*.txt

    pushd "${source_directory}" > /dev/null
    for filename in ./*.txt
    do
        printf '%s\n' "Processing: ${filename}"
        # Skip the first five lines with hashdeep comments
        tail -n +6 "${filename}" | tr -d '\r' | sort > "${temp_directory}/${filename}"
        # Remove empty files
        if [[ ! -s "${temp_directory}/${filename}" ]]
        then
            rm -f "${temp_directory}/${filename}"
        fi
    done
    popd > /dev/null
}

# ========== Commands =====================================================

# Resolving the installation path with GNU readlink is very reliable,
# but it may only work in Linux and FreeBSD. Remove the option -f for
# BSD readlink on Mac OS X. If there are problems with resolving the
# installation path, change directly into the installation directory of
# this script and run it script from there.

cd "$(dirname "$(readlink -f "$0")")" || exit 1

# Parse command-line arguments
#
# Print the usage, if not enough arguments are provided
if (( $# < 2 ))
then
    printf '%s\n' "Usage: ./compare-integrity-database.bash <windows-path> <linux-path>

<windows-path> and <linux-path> are the complete pathnames of the
directories wsusoffline/client/md on Windows and Linux, for example:

/media/${USER}/Windows/wsusoffline/client/md
/home/${USER}/wsusoffline/client/md"
    exit 1
fi

# Set the pathnames of the directories wsusoffline/client/md on Windows
# and Linux
source_md_windows="$1"
source_md_linux="$2"

echo "Creating diff files..."
create_diff_files "${source_md_windows}" "${temp_md_windows}"
create_diff_files "${source_md_linux}" "${temp_md_linux}"

echo "Comparing diff files..."
diff --unified --color=auto --report-identical-files "${temp_md_windows}" "${temp_md_linux}"
# The script will exit at this point, if there are any differences,
# because the shell option errexit is set.

echo "Cleaning up temporary directories..."
rm -rf "${temp_md_windows}"
rm -rf "${temp_md_linux}"

echo "All done, normal exit..."
exit 0
