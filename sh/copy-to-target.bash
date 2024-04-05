#!/usr/bin/env bash
#
# Filename: copy-to-target.bash
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
#     This script uses rsync to copy the updates from the ../client
#     directory to a destination directory, which must be specified on
#     the command line.
#
# Usage
#
# ./copy-to-target.bash <update> <destination-directory> [<option> ...]
#
# The first parameter is the update name. In WSUS Offline Update,
# Community Edition 12.5, this can be one of:
#
#   all           All Windows and Office updates, 32-bit and 64-bit
#   all-x86       All Windows and Office updates, 32-bit
#   all-win-x64   All Windows updates, 64-bit
#   all-ofc       All Office updates, 32-bit and 64-bit
#   w62-x64       Windows Server 2012, 64-bit
#   w63           Windows 8.1, 32-bit
#   w63-x64       Windows 8.1 / Server 2012 R2, 64-bit
#   w100          Windows 10, 32-bit
#   w100-x64      Windows 10 / Server 2016/2019, 64-bit
#   o2k13         Office 2013, 32-bit and 64-bit
#   o2k16         Office 2016, 32-bit and 64-bit
#
# Compared to the Windows script CopyToTarget.cmd, some updates
# were renamed to match those of the Linux download script
# download-updates.bash:
#
# - The option "all-x64" was renamed to "all-win-x64", because it only
#   includes Windows updates
# - The option "ofc" was renamed to "all-ofc"
#
# Note: In Community Editions 11.9.8-ESR and 12.5, the download directory
# client/ofc is not used anymore, but the option all-ofc was kept to
# refer to all supported Office versions, 32-bit and 64-bit.
#
#
# The second parameter is the destination directory, to which files are
# copied or hard-linked. It should be specified without a trailing slash,
# because otherwise rsync may create an additional directory within the
# destination directory.
#
#
# The options are:
#
#   -includesp         Include service packs
#   -includecpp        Include Visual C++ Runtime Libraries
#   -includedotnet     Include .NET Frameworks
#   -includewddefs     Include Windows Defender definition updates for
#                      the built-in Defender of Windows 8, 8.1 and 10
#   -cleanup           Tell rsync to delete obsolete files from included
#                      directories. This does not delete excluded files
#                      or directories.
#   -delete-excluded   Tell rsync to delete obsolete files from included
#                      directories and also all excluded files and
#                      directories. Use this option with caution,
#                      e.g. try it with the option -dryrun first.
#   -hardlink <dir>    Create hard links instead of copying files. The
#                      link directory should be specified with an
#                      absolute path, otherwise it will be relative to
#                      the destination directory. The link directory
#                      and the destination directory must be on the same
#                      file system.
#   -dryrun            Run rsync without copying or deleting
#                      anything. This is useful for testing.
#
# The Linux script copy-to-target.bash handles some options differently
# than the Windows script CopyToTarget.cmd:
#
# - /excludesp was replaced with -includesp
#
#   This is consistent with both download scripts DownloadUpdates.cmd
#   and download-updates.bash.
#
# - /includedotnet was replaced with -includecpp -includedotnet
#
#   The option /includedotnet of the Windows script includes both .NET
#   Frameworks and Visual C++ Runtime Libraries. These downloads don't
#   necessarily depend on each other, and previous versions of WSUS
#   Offline Update handled them separately.
#
# The meaning of the download directories msse and wddefs was changed
# in WSUS Offline Update 12.0, compared to the previous version 11.9
# and the branch 11.9.x-ESR: The directory client/wddefs now includes
# virus definition updates for the built-in Defender of Windows 8,
# 8.1 and 10. The directory client/msse is not used anymore.
#
#
# The filter files for the script copy-to-target.bash are based on the
# existing files wsusoffline/exclude/ExcludeListUSB-*.txt. These files
# are used by the Windows script CopyToTarget.cmd, which internally uses
# xcopy.exe. They had to be edited to work with rsync on Linux. Therefore,
# the Linux script copy-to-target.bash now uses its own set of these
# files in the directory wsusoffline/sh/exclude.
#
# The differences are:
#
# Windows
# - Back-slashes are separators in pathnames.
# - Filters are case insensitive.
# - xcopy does not use shell pattern characters like "*", and all
#   filters are implicitly tried for filename expansion. This seems to
#   cause ambiguities: The file wsusoffline/client/bin/IfAdmin.cpp is
#   only excluded, if .NET Frameworks are excluded. This is due to the
#   interpretation of the file ExcludeListISO-dotnet.txt by xcopy.exe.
#   The line "cpp\" matches both the directory "cpp" (as expected)
#   and the source file IfAdmin.cpp.
#
# Linux
# - Forward slashes are separators in pathnames.
# - Filters are case sensitive: both ndp46 and NDP46, ndp472 and NDP472
#   are needed. kb numbers for service packs are added in both lower
#   case and upper case.
# - rsync supports shell patterns like "*", which are added as
#   needed. For example, service packs are excluded with the file
#   wsusoffline/exclude/ExcludeList-SPs.txt. This file contains
#   kb numbers and other unique identifiers, but not the complete
#   filenames. Therefore, the filters had to be enclosed in asterisks like
#   "*KB914961*".
# - File paths are constructed differently with rsync than with mkisofs
#   or xcopy.exe. To exclude the directory client/cpp, the filter should
#   be written as "/cpp", like an absolute path with the source directory
#   as the root of the filesystem.
#
# Finally, some of the private exclude lists were renamed to better
# match the command line parameters of the script copy-to-target.bash:
#
#   ExcludeListUSB-all-x64.txt   -->  ExcludeListUSB-all-win-x64.txt
#   ExcludeListUSB-ofc.txt       -->  ExcludeListUSB-all-ofc.txt
#   ExcludeListUSB-w60-x86.txt   -->  ExcludeListUSB-w60.txt
#   ExcludeListUSB-w61-x86.txt   -->  ExcludeListUSB-w61.txt
#   ExcludeListUSB-w63-x86.txt   -->  ExcludeListUSB-w63.txt
#   ExcludeListUSB-w100-x86.txt  -->  ExcludeListUSB-w100.txt
#
#
# The Windows script CopyToTarget.cmd is based on CreateISOImage.cmd,
# and it supports the same "modes":
#
# - It can copy all updates in the client directory
# - It can copy all 32-bit updates (Windows and Office), or all 64-bit
#   updates (Windows only)
# - It can copy single download directories per selected product and
#   language
#
# However, most of these modes are only useful for the script
# CreateISOImage.cmd, to restrict the size of the resulting ISO images to
# that of real optical media: The profiles "per architecture" are meant
# to create two ISO images, which would fit on DVD-5 media. The profiles
# "per selected product and language" are meant to create a series of
# ISO images, small enough to fit on CDs.
#
# The script CopyToTarget.cmd doesn't face the same size restrictions,
# and you should just use the option "all", provided there is enough
# free space on the target drive. Usually, there will be no reason to
# copy the download directories one-by-one.
#
#
# The Linux script copy-to-target.bash supports the same modes except
# "per language". The distinction per language was used for localized
# Windows updates, e.g. Windows XP and Server 2003. But all Windows
# versions since Vista use global/multilingual updates, and therefore
# this distinction is not needed anymore.
#
# In previous versions of this script, all Office updates would just
# be lumped together, because most updates were in the directory
# client/ofc/glb.
#
# Since WSUS Offline Update, Community Editions 11.9.8-ESR and 12.5, the
# download directory client/ofc is not used anymore, but most dynamic
# updates will still be in the global directories client/o2k13/glb and
# client/o2k16/glb.
#
# The service packs for Office 2013 (kb2817430) are quite large, but
# they can be excluded by:
#
# - creating the custom file "../exclude/custom/ExcludeList-SPs.txt"
# - adding the line "kb2817430" (without quotation marks)
# - omitting the option -includesp for this script
#
# The option all-ofc was kept to refer to all supported Office versions,
# and the options o2k13 and o2k16 were added to copy these updates
# individually.

# ========== Shell options ================================================

set -o errexit
set -o nounset
set -o pipefail
shopt -s nocasematch

# ========== Environment variables ========================================

export LC_ALL=C

# ========== Global variables =============================================

update_name=""
selected_excludelist=""
filter_file=""
logfile="../log/copy-to-target.log"

declare -a option_keys=( cpp dotnet wddefs )
declare -A option_values=(
    [sp]="disabled"
    [cpp]="disabled"
    [dotnet]="disabled"
    [wddefs]="disabled"
)

# Exclude lists for service packs
service_packs=(
    "../exclude/custom/ExcludeList-SPs.txt"
    "../client/static/StaticUpdateIds-w63-upd1.txt"
    "../client/static/StaticUpdateIds-w63-upd2.txt"
)

# rsync needs a source and destination directory and may also refer an
# optional link directory. A hard link directory is usually used for
# incremental backups: Files, which already exist in the link directory,
# are hard linked rather than copied. Therefore, the link directory must
# be on the same file system as the destination directory.
source_directory="../client/"
destination_directory=""
link_directory="(unused)"

# Command-line parameters for rsync
#
# rsync supports different methods to handle symbolic links. For backup
# purposes, the combination "--links --safe-links" works best, because
# it simply copies symbolic links unchanged. To create a working copy of
# the client directory, is seems to be more useful, to resolve symbolic
# links and copy the original files and folders instead ("--copy-links").
#
# Note: Long options are available in GNU/Linux and in FreeBSD.
rsync_parameters=( --recursive --copy-links --owner --group --perms
                   --times --verbose --stats --human-readable )

# ========== Functions ====================================================

function show_usage ()
{
    log_info_message "Usage:
./copy-to-target.bash <update> <destination-directory> [<option> ...]

The update can be one of:
    all           All Windows and Office updates, 32-bit and 64-bit
    all-x86       All Windows and Office updates, 32-bit
    all-win-x64   All Windows updates, 64-bit
    all-ofc       All Office updates, 32-bit and 64-bit
    w62-x64       Windows Server 2012, 64-bit
    w63           Windows 8.1, 32-bit
    w63-x64       Windows 8.1 / Server 2012 R2, 64-bit
    w100          Windows 10, 32-bit
    w100-x64      Windows 10 / Server 2016/2019, 64-bit
    o2k13         Office 2013, 32-bit and 64-bit
    o2k16         Office 2016, 32-bit and 64-bit

The destination directory is the directory, to which files are copied
or hard-linked. It should be specified without a trailing slash, because
otherwise rsync may create an additional directory within the destination
directory.

The options are:
    -includesp         Include service packs
    -includecpp        Include Visual C++ Runtime Libraries
    -includedotnet     Include .NET Frameworks
    -includewddefs     Include Windows Defender definition updates for
                       the built-in Defender of Windows 8, 8.1 and 10
    -cleanup           Tell rsync to delete obsolete files from included
                       directories. This does not delete excluded files
                       or directories.
    -delete-excluded   Tell rsync to delete obsolete files from included
                       directories and also all excluded files and
                       directories. Use this option with caution,
                       e.g. try it with the option -dryrun first.
    -hardlink <dir>    Create hard links instead of copying files. The
                       link directory should be specified with an
                       absolute path, otherwise it will be relative to
                       the destination directory. The link directory
                       and the destination directory must be on the same
                       file system.
    -dryrun            Run rsync without copying or deleting
                       anything. This is useful for testing.
"
    return 0
}


function check_requirements ()
{
    if ! type -P rsync >/dev/null
    then
        printf '%s\n' "Please install the package rsync"
        exit 1
    fi

    return 0
}


function setup_working_directory ()
{
    local kernel_name=""
    local canonical_name=""
    local home_directory=""

    if type -P uname >/dev/null
    then
        kernel_name="$(uname -s)"
    else
        # OSTYPE is an environment variable set by the bash. It is
        # sometimes used as an alternative to uname, but it is not as
        # well documented as the results of uname.
        printf '%s\n' "Unknown operation system ${OSTYPE}"
        exit 1
    fi

    # Reveal the normalized, absolute pathname of the running script
    case "${kernel_name}" in
        Linux | FreeBSD | CYGWIN*)
            canonical_name="$(readlink -f "$0")"
        ;;
        Darwin | NetBSD | OpenBSD)
            # Use greadlink = GNU readlink, if available; otherwise use
            # BSD readlink, which lacks the option -f
            if type -P greadlink >/dev/null
            then
                canonical_name="$(greadlink -f "$0")"
            else
                canonical_name="$(readlink "$0")"
            fi
        ;;
        *)
            printf '%s\n' "Unknown operating system ${kernel_name}, ${OSTYPE}"
            exit 1
        ;;
    esac

    # Change to the home directory of the script
    home_directory="$(dirname "${canonical_name}")"
    cd "${home_directory}" || exit 1

    return 0
}


function import_libraries ()
{
    source ./libraries/dos-files.bash
    source ./libraries/messages.bash

    return 0
}


function parse_command_line ()
{
    local option_name=""

    log_info_message "Starting copy-to-target.bash ..."

    if (( $# < 2 ))
    then
        log_error_message "At least two parameters are required"
        show_usage
        exit 1
    fi

    log_info_message "Command line: $0 $*"
    log_info_message "Parsing first parameter..."
    update_name="$1"
    # Verify and set the used ExcludeListUSB-*.txt
    case "${update_name}" in
        ( all | all-x86 | all-win-x64 | all-ofc     \
        | w62-x64 | w63 | w63-x64 | w100 | w100-x64 \
        | o2k13 | o2k16                             )
            log_info_message "Found update ${update_name}"
            # Verify the exclude list: There must be one exclude list
            # for each supported update name.
            if [[ -f "./exclude/ExcludeListUSB-${update_name}.txt" ]]
            then
                selected_excludelist="./exclude/ExcludeListUSB-${update_name}.txt"
                log_info_message "Found exclude list ${selected_excludelist}"
            else
                log_error_message "The file ExcludeListUSB-${update_name}.txt was not found in the directory ./exclude"
                exit 1
            fi
        ;;
        *)
            log_error_message "The update ${update_name} was not recognized"
            show_usage
            exit 1
        ;;
    esac

    log_info_message "Parsing second parameter..."
    destination_directory="$2"
    log_info_message "Found destination directory ${destination_directory}"

    log_info_message "Parsing remaining parameter..."
    shift 2
    while (( $# > 0 ))
    do
        option_name="$1"
        case "${option_name}" in
            -includesp)
                log_info_message "Found option -includesp"
                option_values[sp]="enabled"
            ;;
            -includecpp | -includedotnet | -includewddefs)
                case "${update_name}" in
                    all-ofc | o2k13 | o2k16)
                        log_warning_message "Option ${option_name} is ignored for Office updates"
                    ;;
                    *)
                        log_info_message "Found option ${option_name}"
                        # Strip the prefix "-include"
                        option_name="${option_name#-include}"
                        option_values["${option_name}"]="enabled"
                    ;;
                esac
            ;;
            # Options specific to rsync
            -cleanup)
                log_info_message "Found option -cleanup"
                # The rsync option --delete removes obsolete files
                # from the included directories. It does not remove
                # excluded files or directories. If this is needed,
                # then the option --delete-excluded must also be used.
                rsync_parameters+=( --delete )
            ;;
            -delete-excluded)
                log_info_message "Found option -delete-excluded"
                # Delete all excluded files and folder. This should
                # be used with caution: If, for example, the update
                # is "w60", then all other Windows versions will
                # be deleted.
                #
                # This option may be needed to solve one particular
                # problem: Files, which are excluded in rsync, are
                # neither copied nor deleted; they are just ignored.
                #
                # One example would be Service Packs in WSUS Offline
                # Update 11.9.1 ESR: If they were copied with the
                # option -includesp, then they won't be deleted
                # again by simply omitting this option.
                #
                # rsync needs both options --delete and
                # --delete-excluded, to actually delete excluded
                # files. The results should be tested with the dryrun
                # option first.
                rsync_parameters+=( --delete --delete-excluded )
            ;;
            -hardlink)
                log_info_message "Found option -hardlink"
                # The link directory should be specified with an
                # absolute path. If the link directory is a relative
                # path, it will be relative to the destination
                # directory.
                shift 1
                if (( $# > 0 ))
                then
                    link_directory="$1"
                else
                    log_error_message "The link directory was not specified"
                    exit 1
                fi
                rsync_parameters+=( "--link-dest=${link_directory}" )
            ;;
            -dryrun)
                log_info_message "Found option -dryrun"
                rsync_parameters+=( --dry-run )
            ;;
            *)
                log_error_message "Option ${option_name} was not recognized"
                show_usage
                exit 1
            ;;
        esac
        shift 1
    done

    echo ""
    return 0
}


function print_summary ()
{
    log_info_message "Summary after parsing command-line"
    log_info_message "- Update: ${update_name}"
    log_info_message "- Selected exclude list: ${selected_excludelist}"
    log_info_message "- Destination directory: ${destination_directory}"
    log_info_message "- Link directory: ${link_directory}"
    #log_info_message "- Options: $(declare -p option_values)"

    echo ""
    return 0
}


function create_filter_file ()
{
    local current_file=""
    local line=""
    local option_name=""

    log_info_message "Creating temporary filter file for rsync..."
    if type -P mktemp >/dev/null
    then
        filter_file="$(mktemp "/tmp/copy-to-target_${update_name}.XXXXXX")"
    else
        filter_file="/tmp/copy-to-target_${update_name}.temp"
        touch "${filter_file}"
    fi
    log_info_message "Created filter file: ${filter_file}"

    # Copy the selected ExcludeListUSB-*.txt
    log_info_message "Copying ${selected_excludelist} ..."
    cat_dos "${selected_excludelist}" >> "${filter_file}"

    # Remove service packs, if the option -includesp was not used
    if [[ "${option_values[sp]}" == "enabled" ]]
    then
        log_info_message "Service Packs are included"
    else
        log_info_message "Excluding Service Packs..."
        for current_file in "${service_packs[@]}"
        do
            if [[ -s "${current_file}" ]]
            then
                log_info_message "Appending ${current_file} ..."
                while read -r line
                do
                    # The case of the kb numbers is inconsistent and in
                    # some cases doesn't match the actual downloads. Since
                    # filters for rsync are case-sensitive, the kb numbers
                    # are first changed to lower case. Then both cases
                    # are added to the filter file.
                    line="${line//KB/kb}"
                    # Add shell pattern around the kb numbers
                    printf '%s\n' "*${line}*"
                    printf '%s\n' "*${line//kb/KB}*"
                done < <(cat_dos "${current_file}") >> "${filter_file}"
            fi
        done
    fi

    # Included downloads
    for option_name in "${option_keys[@]}"
    do
        if [[ "${option_values[${option_name}]}" == "enabled" ]]
        then
            log_info_message "Directory ${option_name} is included"
        else
            log_info_message "Excluding directory ${option_name} ..."
            # Excluded directories are specified with the source
            # directory as the root of the path, e.g. "/cpp", "/dotnet"
            # or "/wddefs". There should be no shell pattern before or
            # after the directory name.
            printf '%s\n' "/${option_name}" >> "${filter_file}"
        fi
    done

    # Add the filter file to the command-line options
    rsync_parameters+=( "--exclude-from=${filter_file}" )

    echo ""
    return 0
}


function run_rsync ()
{
    log_info_message "Running: rsync ${rsync_parameters[*]} ${source_directory} ${destination_directory}"
    mkdir -p "${destination_directory}"
    if rsync "${rsync_parameters[@]}" "${source_directory}" "${destination_directory}"
    then
        log_info_message "Copied ${source_directory} to ${destination_directory}"
    else
        log_error_message "Error $? while synchronizing directories"
    fi
    # TODO: enable log file for rsync?
    return 0
}


function remove_filter_file ()
{
    if [[ -f "${filter_file}" ]]
    then
        rm "${filter_file}"
    fi
    return 0
}


# The main function is named after the script
function copy_to_target ()
{
    check_requirements
    setup_working_directory
    import_libraries
    parse_command_line "$@"
    print_summary
    create_filter_file
    run_rsync
    remove_filter_file

    return 0
}

# ========== Commands =====================================================

copy_to_target "$@"
exit 0
