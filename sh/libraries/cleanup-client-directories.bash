# This file will be sourced by the shell bash.
#
# Filename: cleanup-client-directories.bash
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
#     The cleanup function removes old downloads, which are not available
#     anymore. If a trash-handler like gvfs-trash or trash-cli is found,
#     obsolete files will be put into the trash, rather than deleted
#     directly.
#
#     The function uses the concept of download sets, which is the sum
#     of static and dynamic updates: All files in the current download
#     set will be kept.
#
#     In addition, files, which are not in the current download set,
#     but which are still referenced from within the static directory,
#     will also be preserved. These files are considered "valid static
#     files". This was introduced to allow different languages to be
#     downloaded to the same directory in turn.
#
#     The same mechanism also prevents the deletion of some other files,
#     which are still valid, but not in the current download set:
#
#     - Service packs, if the option -includesp is missing
#
#     - 64-bit Office Updates, if only 32-bit updates are selected
#
#     - Installers for Microsoft Security Essentials, if virus definition
#       updates for Windows 8 are selected
#
#     Generally, this situation may occur, whenever different sets of
#     files are downloaded to the same directory.
#
#     If these "valid static files" are not needed anymore, they must
#     be deleted manually once, and then they won't get downloaded again.

# ========== Configuration ================================================

# The cleanup of client directories may be disabled, if there are
# unexpected problems.

use_cleanup_function="${use_cleanup_function:-enabled}"

# The method to keep "valid static files" was a workaround for the first
# versions of the Linux download scripts, which could only download one
# update and one language per run. If different languages were needed,
# then the existing files had to be kept between download runs. This
# was solved with a recursive grep for the whole static directory: if
# the downloads were still referenced from that directory, they would
# be considered "valid static files" and not deleted.
#
# The internal command "select" of the bash does not allow multiple
# selections either.
#
# With newer versions and the external command "dialog", this works much
# better, and the option to keep existing files may now be disabled. This
# should be done in the file preferences.bash.

keep_valid_static_files="${keep_valid_static_files:-enabled}"

# ========== Functions ====================================================

function cleanup_client_directory ()
{
    local download_dir="$1"
    local valid_links="$2"
    local valid_static_links="$3"
    # A default parameter is provided for the dynamic links, to make
    # this parameter optional.
    local valid_dynamic_links="${4:-not-available}"
    local -a file_list=()
    local pathname=""
    local filename=""
    local filetype=""

    # Print the positional parameters
    log_debug_message "Parameter 1: ${download_dir}"
    log_debug_message "Parameter 2: ${valid_links}"
    log_debug_message "Parameter 3: ${valid_static_links}"
    log_debug_message "Parameter 4: ${valid_dynamic_links}"

    # Preconditions
    if [[ "${use_cleanup_function}" == "disabled" ]]
    then
        log_info_message "Cleanup of client directories is disabled in preferences.bash"
        return 0
    fi
    if ! require_directory "${download_dir}"
    then
        log_warning_message "Aborted cleanup of client directory, because the directory ${download_dir} does not exist"
        return 0
    fi

    log_info_message "Cleaning up download directory ${download_dir} ..."

    # The function cleanup_client_directory is used for the included
    # downloads and for the main updates. The approach for the included
    # downloads can be simplified, because dynamic updates are never used.
    if [[ "${valid_dynamic_links}" == "not-available" \
       && "${valid_links}" == "${valid_static_links}" ]]
    then
        # For the included downloads, there are no dynamic links,
        # and ${valid_links} is the same as ${valid_static_links}.
        # Then the file ${valid_links} can be used as is, without a
        # duplication of the input file.
        log_debug_message "Cleanup only static links"
    else
        # For the main updates, ${valid_links} is the sum of
        # ${valid_static_links} and ${valid_dynamic_links}. This is also
        # called the "download set".
        #
        # Both input files may be empty or missing:
        # - Static download links are mostly service packs and other
        #   installers, which may be excluded from the download.
        # - Dynamic update links are not calculated for some download
        #   targets, e.g. win, o2k13 and o2k16.
        log_debug_message "Cleanup both static and dynamic links"
        # Delete output file
        rm -f "${valid_links}"
        if require_non_empty_file "${valid_static_links}"
        then
            cat "${valid_static_links}" >> "${valid_links}"
        fi
        if require_non_empty_file "${valid_dynamic_links}"
        then
            cat "${valid_dynamic_links}" >> "${valid_links}"
        fi
    fi
    if [[ ! -s "${valid_links}" ]]
    then
        # If the download set is empty, any existing files should be
        # removed and the empty directory should be deleted.
        #
        # This may happen in the ESR version for localized Office 2013
        # downloads, if service packs are NOT included. Then this is
        # not an error.
        #
        # However, as long as existing files are referenced from the
        # static directory, they will be treated as "valid static files"
        # and not deleted.
        log_warning_message "The current download set is empty"
    fi

    # Building file list as suggested in
    # http://mywiki.wooledge.org/BashFAQ/004
    shopt -s nullglob
    file_list=( "${download_dir}"/*.* )
    shopt -u nullglob

    if (( "${#file_list[@]}" > 0 ))
    then
        for pathname in "${file_list[@]}"
        do
            filename="${pathname##*/}"

            # Trash or delete HTML documents, which are sometimes saved
            # instead of the expected binary files
            case "${filename}" in
                *.crt | *.crl)
                    filetype="$(file "${pathname}")"
                    if [[ "${filetype}" == *HTML* ]]
                    then
                        log_warning_message "Trashing/deleting erroneous HTML document \"${filename}\""
                        trash_file "${pathname}"
                        continue
                    fi
                ;;
            esac

            # Keep files, which are in the current download set
            if [[ -s "${valid_links}" ]]
            then
                if grep -F -i -q "${filename}" "${valid_links}"
                then
                    log_debug_message "Found file \"${filename}\""
                    continue
                fi
            fi

            # The cleanup function may keep updates, which are not in
            # the current download set, but which are still referenced
            # from the ../static directory. These files are considered
            # "valid static files".
            if [[ "${keep_valid_static_files}" == "enabled" ]]
            then
                if grep -F -i -q -r "${filename}" "../static"
                then
                    log_info_message "Kept valid static file \"${filename}\""
                    continue
                fi
            fi

            # The virus definition files are referenced with "LinkIDs"
            # in the static download files, and the filenames are only
            # used after several redirections. Therefore, comparing the
            # filenames to the URLs does not work, and the files must
            # be preserved at this point.
            case "${pathname}" in
                ( "../client/wddefs/x86-glb/mpas-fe.exe" \
                | "../client/wddefs/x64-glb/mpas-fe.exe" \
                | "../client/msse/x86-glb/mpam-fe.exe"   \
                | "../client/msse/x64-glb/mpam-fe.exe"   )
                    continue
                ;;
            esac

            # Any remaining files are considered obsolete and will be
            # put into trash or deleted.
            log_info_message "Trashing/deleting obsolete file ${filename} ..."
            trash_file "${pathname}"
        done
    fi

    # Empty download directories should be removed after cleanup. A new
    # file list is created, which includes both files and directories
    # to handle the nested dotnet directories correctly.
    shopt -s nullglob
    file_list=( "${download_dir}"/* )
    shopt -u nullglob

    if (( "${#file_list[@]}" == 0 ))
    then
        rmdir "${download_dir}"
        log_warning_message "Deleted download directory ${download_dir}, because it was empty. This is normal for localized Office 2013 directories, e.g. o2k13/deu and o2k13/enu, if service packs are excluded."
    else
        log_info_message "Cleaned up download directory"
    fi
    return 0
}

return 0
