#!/usr/bin/env bash

# Filename: create-iso-image.bash
#
# Copyright (C) 2019-2021 Hartmut Buhrmester
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
#     This script creates one ISO image of the client directory per
#     run. The included downloads can be restricted with a series of
#     ExcludeListISO-*.txt files.
#
#     The script requires either mkisofs or genisoimage, depending on
#     the distribution:
#
#     - mkisofs is the original tool and preferred. It is part of the
#       cdrtools, which use a Solaris-style license. This seems to
#       restrict the distribution of binary packages, but not that of
#       source packages. Therefore, (only) Linux distributions like
#       Gentoo, which use source packages, may still provide mkisofs
#       and the other cdrtools.
#
#     - genisoimage and cdrkit are forks, which were created after the
#       license change for the cdrtools. They are provided by most other
#       Linux distributions like Debian and Fedora.
#
#     - https://en.wikipedia.org/wiki/Cdrtools
#     - https://en.wikipedia.org/wiki/Cdrkit
#
# Usage
#
# ./create-iso-image.bash <update> [<option> ...]
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
# The options are:
#
#   -includesp         Include service packs
#   -includecpp        Include Visual C++ Runtime Libraries
#   -includedotnet     Include .NET Frameworks
#   -includewddefs     Include Windows Defender definition updates for
#                      the built-in Defender of Windows 8, 8.1 and 10
#   -output-path <dir> Output directory for the ISO image file - the
#                      default is ../iso
#   -create-hashes     Create a hashes file for the ISO image file
#
#
# The script create-iso-image.bash has basically three modes of operation:
#
# 1. The profile "all" creates one ISO image of the whole client
#    directory. It is left to the user, to restrict the resulting ISO
#    image to a reasonable size.
#
# 2. The profiles "all-x86" and "all-win-x64" create two ISO images,
#    one per architecture. These are the 'x86-cross-product' ISO images
#    of the Windows application UpdateGenerator.exe.
#
#    Originally, these ISO images were supposed to fit on DVD-5 optical
#    disks, and the file size should be restricted to 4.7 GB, but today
#    they may easily grow larger.
#
# 3. The profiles "w63", "w63-x64", etc create a series of ISO images
#    per product.
#
#    Originally, these ISO images were supposed to fit on CD-ROMs, and
#    the file size should be restricted to 700 MB. Again, the resulting
#    ISO images may easily get larger than that.
#
#    These size restrictions may explain, though, why large installers
#    are sometimes excluded from the created ISO images.
#
# The distinction "per selected language" is not used anymore. It was
# useful for localized Windows updates, e.g. Windows XP and Windows Server
# 2003, but all supported Windows versions in the current versions of
# WSUS Offline Update use global/multilingual updates.
#
# Most dynamic Office updates will be in the directories o2k13/glb and
# o2k16/glb, and a filter per language will not make a big difference.
#
# The service packs for Office 2013 (kb2817430) are quite large, but
# they can be excluded by:
#
# - creating the custom file "../exclude/custom/ExcludeList-SPs.txt"
# - adding the line "kb2817430" (without quotation marks)
# - omitting the option -includesp for this script
#
#
# The Linux script create-iso-images.bash uses its own filter files in
# the sh/exclude directory. These files are based on the files in the
# WSUS Offline Update directory wsusoffline/exclude, but the syntax has
# been reviewed: Many shell pattern seem to be unneeded. For example,
# the directory ofc can be excluded with just the name ofc. Adding shell
# pattern around the name only creates ambiguities. The syntax seems
# to be slightly different on Windows and Linux, although basically the
# same tools (mkisofs and genisoimage) are used.
#
# The file About_the_ExcludeListISO-files.txt in the directory sh/exclude
# explains the translation of the ExcludeListISO-*.txt files from Windows
# to Linux.
#
# Users may create local copies of the ExcludeListISO-*.txt files in the
# directory ./exclude/local. These local copies replace the supplied
# files. This is different from the handling of custom files by WSUS
# Offline Update, but it is more the Linux way, and it allows to both
# add and remove filter lines.
#
#
# The created ISO images have filenames like
# 2019-04-14_wsusoffline-11.6.2_all.iso. These are composed of:
#
# 1. The build date from the file wsusoffline/client/builddate.txt,
#    which indicates the last run of the download script
# 2. The name wsusoffline
# 3. The WSUS Offline Update version
# 4. The used profile

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
logfile="../log/create-iso-image.log"

declare -a option_keys=( cpp dotnet wddefs )
declare -A option_values=(
    [sp]="disabled"
    [cpp]="disabled"
    [dotnet]="disabled"
    [wddefs]="disabled"
    [hashes]="disabled"
)

# Exclude lists for service packs
service_packs=(
    "../exclude/custom/ExcludeList-SPs.txt"
    "../client/static/StaticUpdateIds-w63-upd1.txt"
    "../client/static/StaticUpdateIds-w63-upd2.txt"
)

# The ISO image creation tool is either mkisofs or genisoimage
iso_tool=""
# The default output path ../iso can be changed with the command-line
# option -output-path.
output_path="../iso"
iso_name=""

# Command-line parameters for mkisofs and genisoimage
#
# Both tools understand the same parameters. The manual for genisoimage
# is not quite complete, but "genisoimage -help" shows all options.
#
# The filter file, volume id and output filename are added later by the
# corresponding functions.
iso_tool_parameters=(
    -verbose
    -iso-level 4
    -joliet
    -joliet-long
    -rational-rock
    -udf
)

# ========== Functions ====================================================

function show_usage ()
{
    log_info_message "Usage:
./create-iso-image.bash <update> [<option> ...]

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

The options are:
    -includesp         Include service packs
    -includecpp        Include Visual C++ Runtime Libraries
    -includedotnet     Include .NET Frameworks
    -includewddefs     Include Windows Defender definition updates for
                       the built-in Defender of Windows 8, 8.1 and 10
    -output-path <dir> Output directory for the ISO image file - the
                       default is ../iso
    -create-hashes     Create a hashes file for the ISO image file
"
    return 0
}


function check_requirements ()
{
    local binary_name=""

    for binary_name in mkisofs genisoimage
    do
        if type -P "${binary_name}" >/dev/null
        then
            iso_tool="${binary_name}"
            break
        fi
    done

    if [[ -z "${iso_tool}" ]]
    then
        printf '%s\n' "Error: Please install either mkisofs (preferred) or genisoimage, depending on your distribution"
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
        # documented as the results of uname.
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


# After importing the library messages.bash, the functions can use
# log_info_message and log_error_message as needed.
function start_logging ()
{
    if [[ -f "${logfile}" ]]
    then
        # Print a divider line
        {
            echo ""
            echo "--------------------------------------------------------------------------------"
            echo ""
        } >> "${logfile}"
    else
        # Create a new file
        touch "${logfile}"
    fi
    log_info_message "Starting create-iso-image.bash"
    return 0
}


function parse_command_line ()
{
    local option_name=""
    local current_dir=""

    if (( $# < 1 ))
    then
        log_error_message "At least one parameter is required"
        show_usage
        exit 1
    fi
    log_info_message "Command line: $0 $*"

    log_info_message "Parsing first parameter..."
    update_name="$1"
    # Verify and set the used ExcludeListISO-*.txt
    case "${update_name}" in
        ( all | all-x86 | all-win-x64 | all-ofc     \
        | w62-x64 | w63 | w63-x64 | w100 | w100-x64 \
        | o2k13 | o2k16                             )
            log_info_message "Found update ${update_name}"
            # Verify the exclude list: There must be one exclude list
            # for each supported update name.
            #
            # The script create-iso-image.bash uses its own set of exclude
            # lists in the directory ./exclude. A user-created file in
            # the directory ./exclude/local replaces the installed file.
            for current_dir in ./exclude ./exclude/local
            do
                if [[ -f "${current_dir}/ExcludeListISO-${update_name}.txt" ]]
                then
                    selected_excludelist="${current_dir}/ExcludeListISO-${update_name}.txt"
                fi
            done
            if [[ -n "${selected_excludelist}" ]]
            then
                log_info_message "Selected exclude list: ${selected_excludelist}"
            else
                log_error_message "The file ExcludeListISO-${update_name}.txt was not found in the directories ./exclude and ./exclude/local"
                exit 1
            fi
        ;;
        *)
            log_error_message "The update ${update_name} was not recognized"
            show_usage
            exit 1
        ;;
    esac

    # Verify the download directories
    case "${update_name}" in
        # There is nothing to do for the profiles all, all-x86,
        # all-win-x64 and all-ofc. Using a simple "no-operation" prevents
        # error messages by the catch-all handler at the end.
        all | all-x86 | all-win-x64 | all-ofc)
            :
        ;;
        # For all single Windows and Office downloads, the download
        # directories should be verified, to prevent the creation of
        # empty ISO images.
        #
        # The shell follows symbolic links to the download directory;
        # therefore the test -d matches both the original directory and
        # valid symbolic links to directories.
        w62-x64 | w63 | w63-x64 | w100 | w100-x64 | o2k13 | o2k16)
            if [[ -d "../client/${update_name}" ]]
            then
                log_info_message "Found download directory ${update_name}"
            else
                log_error_message "The download directory ${update_name} was not found"
                exit 1
            fi
        ;;
        *)
            log_error_message "The update ${update_name} was not recognized"
            show_usage
            exit 1
        ;;
    esac

    log_info_message "Parsing remaining parameters..."
    shift 1
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
            # Options specific to mkisofs and genisoimage
            -output-path)
                log_info_message "Found option -output-path"
                shift 1
                if (( $# > 0 ))
                then
                    output_path="$1"
                else
                    log_error_message "The output directory was not specified"
                    exit 1
                fi
            ;;
            -create-hashes)
                log_info_message "Found option -create-hashes"
                option_values[hashes]="enabled"
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
    log_info_message "- Output directory: ${output_path}"
    #log_info_message "- Options: $(declare -p option_values)"

    echo ""
    return 0
}


function create_filter_file ()
{
    local current_file=""
    local line=""
    local option_name=""

    log_info_message "Creating temporary filter file for ${iso_tool}..."
    if type -P mktemp >/dev/null
    then
        filter_file="$(mktemp "/tmp/create-iso-image_${update_name}.XXXXXX")"
    else
        filter_file="/tmp/create-iso-image_${update_name}.temp"
        touch "${filter_file}"
    fi
    log_info_message "Created filter file: ${filter_file}"

    # Copy the selected file ExcludeListISO-*.txt
    log_info_message "Copying ${selected_excludelist} ..."
    
    # Remove empty lines and comments
    #
    # Carriage return must be removed first, because git may change all
    # text files to DOS line-endings with a hidden file .gitattributes,
    # and lines are not recognized as empty, if they still contain
    # carriage returns.
    dos_to_unix < "${selected_excludelist}" \
    | grep -v -e "^$" -e "^#"               \
    >> "${filter_file}"

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
                    # The case of the kb numbers is inconsistent
                    # and in some cases doesn't match the actual
                    # downloads. Since filters for mkisofs and genisoimage
                    # are case-sensitive, the kb numbers are first
                    # changed to lower case. Then both cases are added
                    # to the filter file.
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
            # Excluded directories are specified with just the name
            # of the directory; there is no need to construct a full
            # path. Without any shell patterns, only the directory names
            # are matched.
            printf '%s\n' "${option_name}" >> "${filter_file}"
            # Unneeded files in the directory client/md are also excluded:
            case "${option_name}" in
                wddefs)
                    printf '%s\n' "hashes-${option_name}-x86-glb.txt" \
                                  "hashes-${option_name}-x64-glb.txt" \
                                  >> "${filter_file}"
                ;;
                *)
                    printf '%s\n' "hashes-${option_name}.txt" \
                                  >> "${filter_file}"
                ;;
            esac
        fi
    done

    # Add the filter file to the command-line options
    iso_tool_parameters+=( -exclude-list "${filter_file}" )

    echo ""
    return 0
}


function create_output_filename ()
{
    # Get the version of WSUS Offline Update
    local wsusoffline_version=""
    if [[ -f "../cmd/DownloadUpdates.cmd" ]]
    then
        # Extract the WSUS Offline Update version from DownloadUpdates.cmd
        wsusoffline_version="$(grep -F -e "set WSUSOFFLINE_VERSION=" ../cmd/DownloadUpdates.cmd)"
        wsusoffline_version="$(tr -d '\r' <<< "${wsusoffline_version}")"
        wsusoffline_version="${wsusoffline_version#set WSUSOFFLINE_VERSION=}"
        # Sanitize spaces for beta versions
        wsusoffline_version="${wsusoffline_version// /_}"
        log_info_message "WSUS Offline Update version: ${wsusoffline_version}"
    else
        log_error_message "The Windows batch file ../cmd/DownloadUpdates.cmd was not found"
        exit 1
    fi

    # Get the build date
    local builddate=""
    if [[ -f "../client/builddate.txt" ]]
    then
        IFS=$'\r\n' read -r builddate < "../client/builddate.txt"
        log_info_message "Builddate: ${builddate}"
    else
        log_error_message "The file ../client/builddate.txt was not found"
        exit 1
    fi

    # Create filename of the ISO image, but without the extension .iso
    #
    # The iso_name is also used to create an accompanying hashes file.
    iso_name="${builddate}_wsusoffline-${wsusoffline_version}_${update_name}"
    log_info_message "Output filename (without extension): ${iso_name}"

    # Add output path and filename to the parameter list
    iso_tool_parameters+=( -output "${output_path}/${iso_name}.iso" )

    return 0
}


function create_volume_id ()
{
    local iso_volid
    iso_volid="WOU_${update_name}"

    # Add volume id to the parameter list
    iso_tool_parameters+=( -volid "${iso_volid}" )

    return 0
}


function run_iso_tool ()
{
    log_info_message "Running: ${iso_tool} ${iso_tool_parameters[*]} ../client"
    mkdir -p "${output_path}"
    if "${iso_tool}" "${iso_tool_parameters[@]}" "../client"
    then
        log_info_message "Created ISO image ${iso_name}.iso"
    else
        log_error_message "Error $? while creating ISO image"
    fi
    return 0
}


function create_hashes_file ()
{
    if [[ "${option_values[hashes]}" == "enabled" ]]
    then
        log_info_message "Creating a hashes file for ${iso_name}.iso (this may take some time)..."
        # WSUS Offline Update was always over-engineered by calculating
        # three different hashes for each file
        hashdeep -c sha1 -b "${output_path}/${iso_name}.iso" > "${output_path}/${iso_name}_hashes.txt"
        log_info_message "Created hashes file ${iso_name}_hashes.txt"
    else
        log_info_message "Skipped creation of hashes file"
    fi
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
function create_iso_image ()
{
    check_requirements
    setup_working_directory
    import_libraries
    start_logging
    parse_command_line "$@"
    print_summary
    create_filter_file
    create_output_filename
    create_volume_id
    run_iso_tool
    create_hashes_file
    remove_filter_file

    return 0
}

# ========== Commands =====================================================

create_iso_image "$@"
exit 0
