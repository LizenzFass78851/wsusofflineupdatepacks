# This file will be sourced by the shell bash.
#
# Filename: dos-files.bash
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
#     This file provides simple wrapper functions for cat, cut, grep
#     and tail. They remove any carriage returns from the result. With
#     these wrapper functions, the download script can use the file in
#     the static and exclude directory directly, without changing them
#     to the Linux format first.
#
#     These wrapper functions were introduced as a workaround for old
#     versions of wget: wget downloads all files again, if the file
#     size changes, regardless of the file modification date. Because
#     removing carriage returns changes the file size, timestamping does
#     not work for files in the static and exclude directories, if they
#     are replaced with the "update of static download definitions".
#
#     Wget 1.17 and later use a better method for timestamping, and then
#     all files could be changed on the first run of the script. Then
#     such workarounds are not necessary anymore. However, wget 1.17 is
#     not yet available in Debian 8 stable/Jessie.
#
#     On the other side, the Linux scripts may change the configuration
#     files in the static and exclude directories, because these are
#     not used for the installation. But the configuration files in
#     the client/static and client/exclude directories should not be
#     changed. These files are used since WSUS Offline Update version
#     10.9 to handle security-only updates. Then the wrapper functions
#     to read DOS files are still needed.


function cat_dos ()
{
    # The tool shellcheck calls this a useless cat, but it is actually
    # needed, if several files are used as input. A simple input
    # redirection will not handle this case.
    cat "$@" | tr -d '\r'
}

function cut_dos ()
{
    cut "$@" | tr -d '\r'
}

function grep_dos ()
{
    # Note: To get the result code of grep, the shell option pipefail
    # must be set.
    #
    # This does not work to filter empty lines with DOS line-endings,
    # because the lines will not be recognized as empty, if they still
    # contain carriage returns. In this case, carriage returns must be
    # removed first, before passing the results to grep.
    grep "$@" | tr -d '\r'
}

function tail_dos ()
{
    tail "$@" | tr -d '\r'
}


# cat_existing_files is similar to cat_dos, as is concatenates several
# input files and writes them to standard output. This function verifies,
# that each input file exists and the file size is larger than 0. Carriage
# returns will be removed.
function cat_existing_files ()
{
    local current_file=""

    if (( "$#" > 0 ))
    then
        for current_file in "$@"
        do
            if [[ -s "${current_file}" ]]
            then
                tr -d '\r' < "${current_file}"
            fi
        done
    fi
    return 0
}


# The Linux download scripts handle default and custom languages
# differently than the Windows scripts:
#
# The default languages German and English are removed from several global
# download files in the ../static directory. Since version 1.19.4-ESR
# and 2.3 of the Linux download scripts, this is done without changing
# the input files at all.
#
# Languages, which are set on the command-line, are then added back from
# the localized download files in the ../static directory.
#
# This way, only the needed languages are downloaded, without changing
# existing files in the ../static directory or creating new files in
# the ../static/custom directory.

function filter_default_languages ()
{
    local pathname="$1"

    if [[ -s "${pathname}" ]]
    then
        case "${pathname}" in
            ( ../static/StaticDownloadLinks-msse-x86-glb.txt \
            | ../static/StaticDownloadLinks-msse-x64-glb.txt \
            | ../static/StaticDownloadLinks-w61-x86-glb.txt  \
            | ../static/StaticDownloadLinks-w61-x64-glb.txt  )
                # Remove German and English language support
                tr -d '\r' < "${pathname}"                               \
                | grep -F -i -v -e 'deu.' -e '-deu_' -e 'de.' -e 'de-de' \
                                -e 'enu.' -e 'us.'                       \
                || true
            ;;
            ( ../static/StaticDownloadLinks-dotnet.txt         \
            | ../static/StaticDownloadLinks-w60-x86-glb.txt    \
            | ../static/StaticDownloadLinks-w60-x64-glb.txt    \
            | ../static/StaticDownloadLinks-w62-x64-glb.txt    )
                # Remove German language support
                tr -d '\r' < "${pathname}"                               \
                | grep -F -i -v -e 'deu.' -e '-deu_' -e 'de.' -e 'de-de' \
                || true
            ;;
            *)
                # Only filter carriage returns
                tr -d '\r' < "${pathname}"
            ;;
        esac
    fi
    return 0
}


# Filter functions read from standard input and write to standard
# output. They are typically used in pipes, but with input and output
# re-directions they can also work on files.
#
# The function unix_to_dos is used to convert the output of hashdeep to
# DOS line endings on the fly.

function unix_to_dos ()
{
    local line=""

    # IFS is set to an empty string, to read a complete line including
    # leading and trailing spaces.
    while IFS="" read -r line
    do
        printf '%s\r\n' "${line}"
    done

    return 0
}

function dos_to_unix ()
{
    tr -d '\r'
}

function unquote ()
{
    tr -d '"'
}

return 0
