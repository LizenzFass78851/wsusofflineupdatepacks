# This file will be sourced by the shell bash.
#
# Filename: 90-finalization.bash
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
#     This file does final tasks after running all updates: convert text
#     files to DOS format, show the disk usage of all downloads and the
#     number of runtime errors.

# ========== Functions ====================================================

# Originally, unzip.exe was only needed for the download part of WSUS
# Offline Update, to unpack the wsusoffline archive during version
# updates.
#
# Since WSUS Offline Update version 10.9.1, unzip.exe is also needed by
# the installation part, to unpack two archives for Windows 7:
#
# ../client/w61/glb/Win7-KB3191566-x86.zip
# ../client/w61-x64/glb/Win7AndW2K8R2-KB3191566-x64.zip

function copy_unzip ()
{
    # GNU/Linux cp has the option -u, which will update existing files
    # or copy new files.
    #
    # As a workaround for FreeBSD cp, the files can be compared in the
    # shell first: The comparison operator -nt is true, if the first
    # file is newer than the second file, or if the first file exists
    # and the second file does not.
    #
    # This avoids copying the same file over on each run.
    if [[ "../bin/unzip.exe" -nt "../client/bin/unzip.exe" ]]
    then
        cp -a "../bin/unzip.exe" "../client/bin"
    fi
    return 0
}


function remind_build_date ()
{
    local build_date=""

    # The date should be in an international format like 2015-11-26, also
    # known as ISO-8601. The option -I can be used with both GNU/Linux
    # and FreeBSD date.
    #
    # Relevant xkcd: https://xkcd.com/1179/
    build_date="$(date -I)"

    # Remove existing files first, instead of overwriting, if hard links
    # are used for backups or snapshots of the client directory
    rm -f "../client/builddate.txt"
    rm -f "../client/autorun.inf"
    rm -f "../client/Autorun.inf"

    log_info_message "Reminding build date..."
    printf '%s\r\n' "${build_date}" > "../client/builddate.txt"

    log_info_message "Creating autorun.inf file..."
    {
        printf '%s\r\n' "[autorun]"
        printf '%s\r\n' "open=UpdateInstaller.exe"
        printf '%s\r\n' "icon=UpdateInstaller.exe,0"
        printf '%s\r\n' "action=Run WSUS Offline Update - Community Edition - v. ${wsusoffline_version} (${build_date})"
    } > "../client/autorun.inf"
    echo ""
    return 0
}


function adjust_update_installer_preferences ()
{
    log_info_message "Adjusting UpdateInstaller.ini file..."
    if [[ -f "../client/UpdateInstaller.ini" ]]
    then
        case "${prefer_seconly}" in
            enabled)
                write_setting "../client/UpdateInstaller.ini" "seconly" "Enabled"
            ;;
            disabled)
                write_setting "../client/UpdateInstaller.ini" "seconly" "Disabled"
            ;;
            *)
                log_error_message "Unknown value \"${prefer_seconly}\" for prefer_seconly"
                increment_error_count
            ;;
        esac
    else
        # The file UpdateInstaller.ini is included in the wsusoffline
        # archive and should never be missing. Unlike other ini files,
        # it is not created on the fly.
        log_error_message "File ../client/UpdateInstaller.ini was not found"
        increment_error_count
    fi
    log_info_message "Adjusted UpdateInstaller.ini file"
    echo ""
    return 0
}


function print_disk_usage ()
{
    log_info_message "Disk usage of the client directory:"
    find -L "../client" -maxdepth 1 -type d |
        sort |
        xargs -L1 du -L -h -s |
        tee -a "${logfile}"

    echo ""
    return 0
}


function print_summary ()
{
    log_info_message "Summary"
    if same_error_count "0"
    then
        log_info_message "Download and file verification errors: 0"
    else
        log_warning_message "Download and file verification errors: $(get_error_count)"
    fi
    return 0
}

# ========== Commands =====================================================

copy_unzip
remind_build_date
adjust_update_installer_preferences
print_disk_usage
print_summary

return 0
