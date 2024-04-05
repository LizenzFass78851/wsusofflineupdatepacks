# This file will be sourced by the shell bash.
#
# Filename: 20-start-logging.bash
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
#     Start logging and write some information about the system and
#     environment, which may be useful for debugging.

# ========== Functions ====================================================

# The formatted string for the WSUS Offline Update version is extracted
# from the file DownloadUpdates.cmd.
#
# If a new version of WSUS Offline Update is installed, then the scripts
# update-generator.bash and download-updates.bash will be restarted,
# and the variable wsusoffline_version will be updated to the new version.
#
# TODO: The global variable wsusoffline_version itself could be
# re-implemented as a function, which returns the version string, so
# that it can be used by other scripts as well.

function extract_wsusoffline_version ()
{
    wsusoffline_version="not-available"

    if require_non_empty_file "../cmd/DownloadUpdates.cmd"
    then
        if  wsusoffline_version="$(grep_dos -F -e "set WSUSOFFLINE_VERSION=" ../cmd/DownloadUpdates.cmd)"
        then
            wsusoffline_version="${wsusoffline_version/set WSUSOFFLINE_VERSION=/}"
        fi
    fi
    return 0
}

function create_logfile ()
{
    local timestamp=""
    timestamp="$( date '+%Y-%m-%d %H:%M:%S' )"  # e.g. 2020-07-06 23:12:46

    if [[ -f "${logfile}" ]]
    then
        {
            echo ""
            echo "----------------------------| ${timestamp} |-----------------------------"
            echo ""
        } >> "${logfile}"
    else
        touch "${logfile}"
    fi
    return 0
}

function print_info_block ()
{
    local linux_details=""

    log_info_message "Starting ${script_name} ${script_version} (${release_date})"
    log_info_message "Command line: ${command_line}"
    if [[ "${wsusoffline_version}" != "not-available" ]]
    then
        log_info_message "Running on WSUS Offline Update, Community Edition ${wsusoffline_version}"
    fi

    if [[ -f ../client/catalog-creationdate.txt ]]
    then
        get_catalog_creationdate
    fi

    if [[ -f ../client/builddate.txt ]]
    then
        log_info_message "Repository last updated on $(cat_dos ../client/builddate.txt)"
    fi

    # The command lsb_release is installed on Debian with the package
    # lsb-release. Although the Linux Standard Base is not supported
    # anymore by Debian, lsb_release is still useful by itself, to get
    # information about the Linux distribution.
    if type -P lsb_release > /dev/null
    then
        linux_details="$(lsb_release --all 2> /dev/null)"
    else
        linux_details="not-available"
    fi

    # The logfile includes an info block about the Kernel, Linux
    # distribution and environment. This is only for reference and not
    # displayed in the terminal window.
    #
    # ${OSTYPE} is an environment variable, which is set by the bash
    # itself.
    {
        printf '%s\n' "Local time:     $(date -R)"  # RFC 2822 format
        printf '%s\n' "OS type:        ${OSTYPE}"
        printf '%s\n' "Kernel name:    ${kernel_name}"
        printf '%s\n' "Kernel details: ${kernel_details}"
        printf '%s\n' "Hardware:       ${hardware_architecture}"
        printf '%s\n' "Bash version:   ${BASH_VERSION}"
        printf '%s\n' "Terminal type:  ${TERM:-}"
        echo ""
        printf '%s\n' "Linux distribution" "${linux_details}"
        echo ""
        printf '%s\n' "Environment" "LC_ALL=${LC_ALL:-}" \
                      "LC_COLLATE=${LC_COLLATE:-}" "LC_CTYPE=${LC_CTYPE:-}" \
                      "LC_MESSAGES=${LC_MESSAGES:-}" "LANG=${LANG:-}"
        echo ""
        printf '%s\n' "Resolution of the installation directory"
        printf '%s\n' "Canonical name:    ${canonical_name}"
        printf '%s\n' "Script name:       ${script_name}"
        printf '%s\n' "Home directory:    ${home_directory}"
        printf '%s\n' "Working directory: $(pwd)"
        printf '%s\n' "WSUS Offline Upd.: ${wsusoffline_directory}"
        printf '%s\n' "Temp directory:    ${temp_dir}"
        echo ""
        printf '%s\n' "Configuration variables from the preferences file"
        printf '%s\n' "prefer_seconly:    ${prefer_seconly}"
    } >> "${logfile}"
    return 0
}

# ========== Commands =====================================================

extract_wsusoffline_version
create_logfile
print_info_block
echo ""
return 0
