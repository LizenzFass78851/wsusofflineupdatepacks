# This file will be sourced by the shell bash.
#
# Filename: 20-get-sysinternals-helpers.bash
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
#     This task downloads and installs the Sysinternals utilities
#     Autologon, Sigcheck and Streams.
#
#     Autologon is used for the installation of updates, if the option
#     "Automatic reboot and recall" in the UpdateInstaller.exe is
#     checked. Note, that you should not use this option with Windows 10.
#
#     Sigcheck may be used under wine to check the digital file
#     signatures, but this doesn't really work so far. The Microsoft
#     intermediate and root certificates must be installed to check
#     complete certificate chains. But the wine library crypt32.dll
#     doesn't seem to provide the functionality to actually verify
#     digital file signatures. Therefore, Sigcheck running under wine
#     often reports files as "Signed", even if the files have been
#     slightly altered. For example, appending a space to the end of the
#     file or changing some bytes within the file change the hashes of
#     the file and should make digital file signatures invalid. Still,
#     Sigcheck under wine reports these files as "Signed".
#
#     Streams removes alternate data streams on NTFS volumes, but this
#     is not used on Linux.


# ========== Global variables =============================================

# The variable sigcheck_bin must be global, because it is used in the
# file digital-file-signatures.bash
#
# Since Sigcheck 2.5.1, both architectures i686 and x86_64 are
# supported. The hardware architecture can be determined with uname -m,
# according to the POSIX standard.
#
# https://en.wikipedia.org/wiki/Uname
#
# TODO: Actually, the architecture of the operating system should be
# used. If a 32-bit operating system is running on 64-bit hardware,
# then uname -m will return a wrong value. uname -i may work better,
# but this is not really standardized.

sigcheck_bin=""
case "${hardware_architecture}" in
    i386 | i686 | x86)
        sigcheck_bin="sigcheck.exe"
    ;;
    amd64 | x86_64)
        sigcheck_bin="sigcheck64.exe"
    ;;
    arm*)
        log_warning_message "ARM processors are not supported by Sysinternals Sigcheck."
        use_file_signature_verification="disabled"
    ;;
    *)
        log_warning_message "Unknown architecture ${hardware_architecture}."
        use_file_signature_verification="disabled"
    ;;
esac


# unzip with the option -u can upgrade existing files, but this option
# works slightly different in GNU/Linux and FreeBSD 12.1.
#
# The GNU/Linux unzip will ask for confirmation before overwriting
# files. This query will be skipped, if the additional option -o is used.
#
# The FreeBSD unzip considers the options -u and -o "contradictory". The
# option -u upgrades existing files without prompting for confirmation.

unzip_upgrade=""
case "${kernel_name}" in
    Linux | CYGWIN*)
        unzip_upgrade="unzip -u -o"
    ;;
    # TODO: So far, only FreeBSD 12.1 was tested
    Darwin | FreeBSD | NetBSD | OpenBSD)
        unzip_upgrade="unzip -u"
    ;;
    *)
        log_error_message "Unknown operating system ${kernel_name}, ${OSTYPE}"
        exit 1
    ;;
esac


# The Sysinternals utilities are checked once daily, like the
# configuration files of WSUS Offline Update.
sysinternals_timestamp_file="${timestamp_dir}/timestamp-sysinternals.txt"

# ========== Functions ====================================================

function check_sysinternals_helpers ()
{
    local binary_path=""

    # Check locations of the extracted binaries
    for binary_path in ../client/bin/Autologon.exe    \
                       ../client/bin/Autologon64.exe  \
                       ../bin/sigcheck.exe            \
                       ../bin/sigcheck64.exe          \
                       ../bin/streams.exe             \
                       ../bin/streams64.exe
    do
        if [[ -f "${binary_path}" ]]
        then
            log_debug_message "Found ${binary_path}"
        else
            rm -f "${sysinternals_timestamp_file}"
        fi
    done

    # Check timestamp
    if same_day "${sysinternals_timestamp_file}" "${interval_length_configuration_files}"
    then
        log_info_message "Skipped processing of Sysinternals utilities, because it has already been done less than ${interval_description_configuration_files} ago"
    else
        get_sysinternals_helpers
    fi

    echo ""
    return 0
}


function get_sysinternals_helpers ()
{
    # File modification dates of existing archives in the cache directory
    local -i previous_autologon="0"
    local -i previous_sigcheck="0"
    local -i previous_streams="0"
    # File modification dates after downloading/validating archives
    local -i current_autologon="0"
    local -i current_sigcheck="0"
    local -i current_streams="0"
    local -i initial_errors="0"
    initial_errors="$(get_error_count)"

    log_info_message "Start processing of Sysinternals utilities..."

    # Create a copy of the file StaticDownloadLinks-sysinternals.txt,
    # to remove carriage returns
    dos_to_unix < "../static/StaticDownloadLinks-sysinternals.txt" \
                > "${temp_dir}/StaticDownloadLinks-sysinternals.txt"

    # Remember the file modification dates of existing archives in seconds
    [[ -f "../bin/AutoLogon.zip" ]] \
        && previous_autologon="$(date -u -r "../bin/AutoLogon.zip" '+%s')"
    [[ -f "../bin/Sigcheck.zip" ]] \
        && previous_sigcheck="$(date -u -r "../bin/Sigcheck.zip" '+%s')"
    [[ -f "../bin/Streams.zip" ]] \
        && previous_streams="$(date -u -r "../bin/Streams.zip" '+%s')"

    # Download Sysinternals archives to the cache directory
    log_info_message "Downloading/validating Sysinternals utilities..."
    download_multiple_files "../bin" "${temp_dir}/StaticDownloadLinks-sysinternals.txt"
    if same_error_count "${initial_errors}"
    then
        log_info_message "Download/validation of Sysinternals utilities succeeded."
    else
        log_warning_message "Download/validation of Sysinternals utilities failed. See the download log for details. The extraction of the Sysinternals archives will be skipped."
        return 0
    fi

    # Get the file modification dates of the archives after download
    [[ -f "../bin/AutoLogon.zip" ]] \
        && current_autologon="$(date -u -r "../bin/AutoLogon.zip" '+%s')"
    [[ -f "../bin/Sigcheck.zip" ]] \
        && current_sigcheck="$(date -u -r "../bin/Sigcheck.zip" '+%s')"
    [[ -f "../bin/Streams.zip" ]] \
        && current_streams="$(date -u -r "../bin/Streams.zip" '+%s')"

    # Compare file modification dates after downloading/validating the
    # archives. Upgraded archives are unpacked. The archives are also
    # unpacked, if one of the *.exe files is missing.
    if (( current_autologon > previous_autologon )) \
        || [[ ! -f "../client/bin/Autologon.exe" ]] \
        || [[ ! -f "../client/bin/Autologon64.exe" ]]
    then
        log_info_message "Unpacking archive AutoLogon.zip ..."
        # Note: the variable unzip_upgrade must not be quoted.
        if ! ${unzip_upgrade} "../bin/AutoLogon.zip" -x "Eula.txt" -d "../client/bin"
        then
            log_error_message "Unpacking of AutoLogon.zip failed."
            increment_error_count
        fi
    fi

    if (( current_sigcheck > previous_sigcheck )) \
        || [[ ! -f "../bin/sigcheck.exe" ]]       \
        || [[ ! -f "../bin/sigcheck64.exe" ]]
    then
        log_info_message "Unpacking archive Sigcheck.zip ..."
        if ! ${unzip_upgrade} "../bin/Sigcheck.zip" -x "Eula.txt" -d "../bin"
        then
            log_error_message "Unpacking of Sigcheck.zip failed."
            increment_error_count
        fi
    fi

    if (( current_streams > previous_streams )) \
        || [[ ! -f "../bin/streams.exe" ]]      \
        || [[ ! -f "../bin/streams64.exe" ]]
    then
        log_info_message "Unpacking archive Streams.zip ..."
        if ! ${unzip_upgrade} "../bin/Streams.zip" -x "Eula.txt" -d "../bin"
        then
            log_error_message "Unpacking of Streams.zip failed."
            increment_error_count
        fi
    fi

    if same_error_count "${initial_errors}"
    then
        update_timestamp "${sysinternals_timestamp_file}"
        log_info_message "Done processing of Sysinternals utilities"
    else
        log_warning_message "There were $(get_error_difference "${initial_errors}") runtime errors for Sysinternals utilities. See the download log for details."
    fi

    return 0
}

# ========== Commands =====================================================

check_sysinternals_helpers
return 0
