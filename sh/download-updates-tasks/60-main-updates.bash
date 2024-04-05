# This file will be sourced by the shell bash.
#
# Filename: 60-main-updates.bash
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
#     The task downloads updates for Microsoft Windows and Office.
#
#     Global variables from other files
#     - The indexed arrays updates_list, architectures_list and
#       languages_list are defined in the file 10-parse-command-line.bash

# ========== Configuration ================================================

w100_versions_file="windows-10-versions.ini"

w100_x86_all_versions=( 10240 14393 17763 18362 19041 )
w100_x64_all_versions=( 10240 14393 17763 18362 19041 20348 )

w100_x86_enabled_versions=()
w100_x64_enabled_versions=()

w100_x86_disabled_versions=()
w100_x64_disabled_versions=()

# Exclude lists for service packs
#
# In the Linux download scripts, the option -includesp is applied to
# all downloads, although only two files for w63 are installed. Users
# may create the custom file ../exclude/custom/ExcludeList-SPs.txt,
# to define additional service packs for all Windows and Office versions.
service_packs=(
    "../exclude/custom/ExcludeList-SPs.txt"
    "../client/static/StaticUpdateIds-w63-upd1.txt"
    "../client/static/StaticUpdateIds-w63-upd2.txt"
)

# ========== Global variables =============================================

if [[ "${prefer_seconly}" == enabled ]]
then
    used_superseded_updates_list="../exclude/ExcludeList-Linux-superseded-seconly.txt"
else
    used_superseded_updates_list="../exclude/ExcludeList-Linux-superseded.txt"
fi

# ========== Functions ====================================================

function prepare_w100_downloads ()
{
    local version=""
    local arch=""
    local state=""
    local skip_rest=""

    # Parse the Windows 10 versions file
    if [[ -f "${w100_versions_file}" ]]
    then
        log_info_message "Parsing Windows 10 versions file..."

        while IFS=$'_= \r\n' read -r version arch state skip_rest
        do
            if [[ "${state}" == "on" ]]
            then
                case "${arch}" in
                    x86)
                        w100_x86_enabled_versions+=( "${version}" )
                    ;;
                    x64)
                        w100_x64_enabled_versions+=( "${version}" )
                    ;;
                esac
            fi
        done < "${w100_versions_file}"

        # Workarounds for an old bash bug, which treated empty arrays as
        # "unset". This was fixed in bash 4.4, though.
        if (( "${#w100_x86_enabled_versions[@]}" > 0 ))
        then
            for version in "${w100_x86_all_versions[@]}"
            do
                if ! in_array "${version}" "${w100_x86_enabled_versions[@]}"
                then
                    w100_x86_disabled_versions+=( "${version}" )
                fi
            done
        else
            w100_x86_disabled_versions=( "${w100_x86_all_versions[@]}" )
        fi

        if (( "${#w100_x64_enabled_versions[@]}" > 0 ))
        then
            for version in "${w100_x64_all_versions[@]}"
            do
                if ! in_array "${version}" "${w100_x64_enabled_versions[@]}"
                then
                    w100_x64_disabled_versions+=( "${version}" )
                fi
            done
        else
            w100_x64_disabled_versions=( "${w100_x64_all_versions[@]}" )
        fi

    else
        log_warning_message "The Windows 10 versions file was not found. Please run the script update-generator.bash to create it"
        w100_x86_enabled_versions=( "${w100_x86_all_versions[@]}" )
        w100_x64_enabled_versions=( "${w100_x64_all_versions[@]}" )
    fi

    #echo ""
    #declare -p w100_x86_enabled_versions w100_x64_enabled_versions w100_x86_disabled_versions w100_x64_disabled_versions
    #echo ""

    return 0
}

# Move versioned Windows 10 downloads into the new directories
#
# The static download files:
#
# - wsusoffline/static/StaticDownloadLinks-w100-10240-x86-glb.txt
# - wsusoffline/static/StaticDownloadLinks-w100-10240-x64-glb.txt
# - wsusoffline/static/StaticDownloadLinks-w100-14393-x86-glb.txt
# - ...
#
# contain the full URLs for version-specific downloads. The filenames
# are extracted to pattern file.
#
# The exclude list files:
#
# - wsusoffline/exclude/ExcludeList-w100-10240.txt
# - wsusoffline/exclude/ExcludeList-w100-14393.txt
# - wsusoffline/exclude/ExcludeList-w100-17763.txt
# - ...
#
# contain search patterns to identify version-specific downloads. These
# patterns are added to the filenames from the static download files.
#
# The resulting filter files are used to identify existing downloads in
# the directories:
#
# - wsusoffline/client/w100/glb
# - wsusoffline/client/w100-x64/glb
#
# These downloads are then separated into the versioned subdirectories.

function sort_w100_downloads ()
{
    local name="$1"
    local arch="$2"

    local base_directory=""
    local target_directory=""
    local version=""
    local -a enabled_versions=()
    local -a disabled_versions=()
    local pattern=""
    local pathname=""

    [[ "${name}" == "w100" ]] || return 0

    case "${arch}" in
        x86)
            base_directory="../client/w100/glb"
            if (( "${#w100_x86_enabled_versions[@]}" > 0 ))
            then
                enabled_versions=( "${w100_x86_enabled_versions[@]}" )
            fi
            if (( "${#w100_x86_disabled_versions[@]}" > 0 ))
            then
                disabled_versions=( "${w100_x86_disabled_versions[@]}" )
            fi
        ;;
        x64)
            base_directory="../client/w100-x64/glb"
            if (( "${#w100_x64_enabled_versions[@]}" > 0 ))
            then
                enabled_versions=( "${w100_x64_enabled_versions[@]}" )
            fi
            if (( "${#w100_x64_disabled_versions[@]}" > 0 ))
            then
                disabled_versions=( "${w100_x64_disabled_versions[@]}" )
            fi
        ;;
        *)
            log_warning_message "Unknown arch ${arch}"
        ;;
    esac

    #echo ""
    #echo "Enabled and disabled versions for w100 ${arch}"
    #declare -p enabled_versions disabled_versions
    #echo ""

    log_info_message "Removing unused directories..."
    if (( "${#disabled_versions[@]}" > 0 ))
    then
        for version in "${disabled_versions[@]}"
        do
            target_directory="${base_directory}/${version}"
            if [[ -d "${target_directory}" ]]
            then
                log_info_message "Deleting unused directory ${target_directory}"
                rmdir "${target_directory}" || true
            fi
        done
    fi

    log_info_message "Separating Windows 10 downloads into versioned subdirectories..."
    if (( "${#enabled_versions[@]}" > 0 ))
    then
        for version in "${enabled_versions[@]}"
        do
            log_info_message "Searching for w100-${version}-${arch} downloads..."

            target_directory="${base_directory}/${version}"
            mkdir -p "${target_directory}"

            cat_existing_files                                                          \
                "../static/StaticDownloadLinks-w100-${version}-${arch}-glb.txt"         \
                "../static/custom/StaticDownloadLinks-w100-${version}-${arch}-glb.txt"  \
              > "${temp_dir}/StaticDownloadLinks-w100-${version}-${arch}-glb.txt"

            extract_filenames                                                      \
                "${temp_dir}/StaticDownloadLinks-w100-${version}-${arch}-glb.txt"  \
                "${temp_dir}/filter-file-w100-${version}-${arch}.txt"

            cat_existing_files                                       \
                "../exclude/ExcludeList-w100-${version}.txt"         \
                "../exclude/custom/ExcludeList-w100-${version}.txt"  \
             >> "${temp_dir}/filter-file-w100-${version}-${arch}.txt"

            if [[ -s "${temp_dir}/filter-file-w100-${version}-${arch}.txt" ]]
            then
                while read -r pattern
                do
                    # safety check for empty lines
                    if [[ -n "${pattern}" ]]
                    then
                        # find matching files
                        shopt -s nullglob
                        for pathname in "${base_directory}"/*"${pattern}"*
                        do
                            # safety check for file type
                            if [[ -f "${pathname}" ]]
                            then
                                #log_debug_message "Found file ${pathname}"
                                mv -n "${pathname}" "${target_directory}" || true
                            fi
                        done
                        shopt -u nullglob
                    fi
                done < "${temp_dir}/filter-file-w100-${version}-${arch}.txt"
            fi
        done
    else
        log_warning_message "There are no Windows 10 versions selected for ${arch}"
    fi

    return 0
}


function unsort_win_100_downloads ()
{
    local name="$1"
    local arch="$2"

    local base_directory=""
    local pathname=""

    [[ "${name}" == "w100" ]] || return 0

    log_info_message "Moving Windows 10 downloads back into base directory..."

    case "${arch}" in
        x86)
            base_directory="../client/w100/glb"
        ;;
        x64)
            base_directory="../client/w100-x64/glb"
        ;;
        *)
            log_warning_message "Unknown arch ${arch}"
        ;;
    esac

    shopt -s nullglob
    for pathname in "${base_directory}"/*/*.*
    do
        #log_debug_message "Found file ${pathname}"
        mv -n "${pathname}" "${base_directory}" || true
    done
    shopt -u nullglob

    return 0
}


function get_main_updates ()
{
    local current_update=""
    local current_lang=""

    if (( "${#updates_list[@]}" > 0 ))
    then
        # This in-string comparison matches both w100 and w100-x64
        if [[ "${updates_list[*]}" == *w100* ]]
        then
            prepare_w100_downloads
        fi

        for current_update in "${updates_list[@]}"
        do
            case "${current_update}" in
                # Common Windows updates
                win)
                    process_main_update "win" "x86" "glb"
                ;;
                # Global Windows and Office updates, 32-bit
                w63 | o2k16)
                    process_main_update "${current_update}" "x86" "glb"
                ;;
                # Global Windows updates, 64-bit,
                # Office 2016, 32-bit and 64-bit
                w62-x64 | w63-x64 | o2k16-x64)
                    process_main_update "${current_update/-x64/}" "x64" "glb"
                ;;
                w100)
                    if (( "${#w100_x86_enabled_versions[@]}" > 0 ))
                    then
                        process_main_update "w100" "x86" "glb"
                    else
                        log_error_message "There are no Windows 10 versions selected for x86. Skipping calculation of w100 x86 glb..."
                    fi
                ;;
                w100-x64)
                    if (( "${#w100_x64_enabled_versions[@]}" > 0 ))
                    then
                        process_main_update "w100" "x64" "glb"
                    else
                        log_error_message "There are no Windows 10 versions selected for x64. Skipping calculation of w100 x64 glb..."
                    fi
                ;;
                # Localized Office updates, 32-bit
                o2k13)
                    for current_lang in "glb" "${languages_list[@]}"
                    do
                        process_main_update "${current_update}" "x86" "${current_lang}"
                    done
                ;;
                # Localized Office updates, 32-bit and 64-bit
                o2k13-x64)
                    for current_lang in "glb" "${languages_list[@]}"
                    do
                        process_main_update "${current_update/-x64/}" "x64" "${current_lang}"
                    done
                ;;
                *)
                    fail "${FUNCNAME[0]} - Unknown or unsupported update: ${current_update}"
                ;;
            esac
        done
    fi
    return 0
}


function process_main_update ()
{
    local name="$1"
    local arch="$2"
    local lang="$3"
    local -i initial_errors="0"
    initial_errors="$(get_error_count)"

    # Create naming scheme.
    #
    # The variable ${timestamp_pattern} is used to create temporary files
    # like the timestamp files and the static and dynamic download
    # lists. It is also used in messages to identify the download task.
    #
    # The timestamp pattern is usually composed of the first three
    # positional parameters of this function:
    #
    # ${name}-${arch}-${lang}
    #
    # The timestamp pattern for Windows Server 2012 (w62-x64) uses the
    # original language list as set on the command-line of the download
    # script, to keep track of localized downloads for Internet Explorer.
    #
    # 64-bit Office updates always include 32-bit updates, and they are
    # downloaded to the same directories. Therefore, if 64-bit updates
    # have been downloaded, it is not necessary to download 32-bit updates
    # again. The timestamp files should still be different, to make sure,
    # that the additional 64-bit downloads are always included.
    #
    # The names for the hashes_file, hashed_dir and download_dir must
    # be synchronized with the Windows script DownloadUpdates.cmd. All
    # temporary files may vary.
    #
    # All paths are relative to the home directory of the download script.
    local timestamp_pattern="not-available"
    local hashes_file="not-available"
    local hashed_dir="not-available"
    local download_dir="not-available"
    local timestamp_file="not-available"
    local valid_static_links="not-available"
    local valid_dynamic_links="not-available"
    local valid_links="not-available"
    local -i interval_length="${interval_length_dependent_files}"
    local interval_description="${interval_description_dependent_files}"

    case "${name}" in
        win | w63 | w100)
            timestamp_pattern="${name}-${arch}-${lang}"
            if [[ "${arch}" == "x86" ]]
            then
                hashes_file="../client/md/hashes-${name}-${lang}.txt"
                hashed_dir="../client/${name}/${lang}"
                download_dir="../client/${name}/${lang}"
            else
                hashes_file="../client/md/hashes-${name}-${arch}-${lang}.txt"
                hashed_dir="../client/${name}-${arch}/${lang}"
                download_dir="../client/${name}-${arch}/${lang}"
            fi
        ;;
        w62)
            # The timestamp pattern includes the language list, as passed
            # on the command-line, because the downloads include localized
            # installers for Internet Explorer.
            timestamp_pattern="${name}-${arch}-${language_parameter}"
            if [[ "${arch}" == "x86" ]]
            then
                hashes_file="../client/md/hashes-${name}-${lang}.txt"
                hashed_dir="../client/${name}/${lang}"
                download_dir="../client/${name}/${lang}"
            else
                hashes_file="../client/md/hashes-${name}-${arch}-${lang}.txt"
                hashed_dir="../client/${name}-${arch}/${lang}"
                download_dir="../client/${name}-${arch}/${lang}"
            fi
        ;;
        o2k13 | o2k16)
            timestamp_pattern="${name}-${arch}-${lang}"
            hashes_file="../client/md/hashes-${name}-${lang}.txt"
            hashed_dir="../client/${name}/${lang}"
            download_dir="../client/${name}/${lang}"
        ;;
        *)
            fail "${FUNCNAME[0]} - Unknown update name: ${name}"
        ;;
    esac

    # The download results are influenced by the options to
    # include Service Packs and to prefer security-only updates. If
    # these options change, then the affected downloads should be
    # re-evaluated. Including the values of these two options in the
    # name of the timestamp file is a simple way to achieve that much.
    #
    # - Only w62 and w63 are affected by the option prefer_seconly
    # - In the Linux download scripts, version 2.4, the option -includesp
    #   is applied to all downloads
    case "${name}" in
        w62 | w63)
            timestamp_file="${timestamp_dir}/timestamp-${timestamp_pattern}-${include_service_packs}-${prefer_seconly}.txt"
        ;;
        *)
            timestamp_file="${timestamp_dir}/timestamp-${timestamp_pattern}-${include_service_packs}.txt"
        ;;
    esac

    # The names of the output files for static and dynamic links
    # are defined here, because they are passed as parameters to
    # the functions download_static_files, download_multiple_files
    # and cleanup_client_directory. They use the generic pattern
    # "${name}-${arch}-${lang}".
    valid_static_links="${temp_dir}/ValidStaticLinks-${name}-${arch}-${lang}.txt"
    valid_dynamic_links="${temp_dir}/ValidDynamicLinks-${name}-${arch}-${lang}.txt"
    valid_links="${temp_dir}/ValidLinks-${name}-${arch}-${lang}.txt"

    if same_day "${timestamp_file}" "${interval_length}"
    then
        log_info_message "Skipped processing of \"${timestamp_pattern//-/ }\", because it has already been done less than ${interval_description} ago"
    else
        log_info_message "Start processing of \"${timestamp_pattern//-/ }\" ..."

        seconly_safety_guard "${name}"
        unsort_win_100_downloads "${name}" "${arch}"
        verify_integrity_database "${hashed_dir}" "${hashes_file}"
        calculate_static_updates "${name}" "${arch}" "${lang}" "${valid_static_links}"
        calculate_dynamic_updates "${name}" "${arch}" "${lang}" "${valid_dynamic_links}"
        download_static_files "${download_dir}" "${valid_static_links}"
        download_multiple_files "${download_dir}" "${valid_dynamic_links}"
        cleanup_client_directory "${download_dir}" "${valid_links}" "${valid_static_links}" "${valid_dynamic_links}"
        verify_digital_file_signatures "${download_dir}"
        create_integrity_database "${hashed_dir}" "${hashes_file}"
        verify_embedded_hashes "${hashed_dir}" "${hashes_file}"
        sort_w100_downloads "${name}" "${arch}"

        if same_error_count "${initial_errors}"
        then
            update_timestamp "${timestamp_file}"
            log_info_message "Done processing of \"${timestamp_pattern//-/ }\""
        else
            log_warning_message "There were $(get_error_difference "${initial_errors}") runtime errors for \"${timestamp_pattern//-/ }\". See the download log for details."
        fi
    fi

    echo ""
    return 0
}


# To calculate static download links, there should be a non-empty file
# with one of the names:
#
# - StaticDownloadLinks-${name}-${lang}.txt
# - StaticDownloadLinks-${name}-${arch}-${lang}.txt
#
# These files can be found in the ../static and ../static/custom
# directories.
#
# In some cases, there are no statically defined downloads:
#
# - The provided files for o2k16 are all empty.
# - Static downloads are often large files like service packs. If service
#   packs are excluded from download, then the resulting file with valid
#   static download links will be empty.
#
# Note: The usage of the "win" static download files for common Windows
# downloads changed in different versions of WSUS Offline update:
#
# - In the ESR version 9.2.x, there were still localized versions with
#   the name StaticDownloadLinks-win-x86-${lang}.txt, but the localized
#   files were all empty.
# - The name StaticDownloadLinks-win-x86-glb.txt implied, that the
#   directory win/glb is for 32-bit downloads only, but actually,
#   it always included a mixture of 32-bit and 64-bit downloads,
#   e.g. Silverlight.exe and Silverlight_x64.exe.
# - In WSUS Offline Update 10.4, the localized files were removed,
#   and the architecture was removed from the filename of the global
#   file. So there is only one file StaticDownloadLinks-win-glb.txt left.

function calculate_static_updates ()
{
    local name="$1"
    local arch="$2"
    local lang="$3"
    local valid_static_links="$4"

    local current_dir=""
    local current_lang=""
    local version=""
    local -a enabled_versions=()
    local -a exclude_lists_static=()

    # Preconditions
    case "${name}" in
        # Accepted update names
        win | w62 | w63 | w100 | o2k13 | o2k16)
            :
        ;;
        *)
            # ofc is not used anymore
            return 0
        ;;
    esac

    log_info_message "Determining static update links for ${name} ${arch} ${lang} ..."

    # Remove existing files
    rm -f "${valid_static_links}"

    for current_dir in ../static ../static/custom
    do
        # Global "win" updates (since version 10.4), 32-bit Office updates
        if [[ -s "${current_dir}/StaticDownloadLinks-${name}-${lang}.txt" ]]
        then
            cat_dos "${current_dir}/StaticDownloadLinks-${name}-${lang}.txt" \
                >> "${temp_dir}/StaticDownloadLinks-${name}-${arch}-${lang}.txt"
        fi
        # Updates for Windows and 64-bit Office updates
        #
        # Localized installers for the default languages are removed
        # from the "global" download files at this point.
        #
        # In the master development branch, this removes German language
        # packs for:
        # - Internet Explorer 11 on Windows Server 2012
        if [[ -s "${current_dir}/StaticDownloadLinks-${name}-${arch}-${lang}.txt" ]]
        then
            filter_default_languages                                              \
                "${current_dir}/StaticDownloadLinks-${name}-${arch}-${lang}.txt"  \
                >> "${temp_dir}/StaticDownloadLinks-${name}-${arch}-${lang}.txt"
        fi
    done

    # Localized installers for all selected languages on the command-line
    # are added back from the localized download files.
    #
    # The search patterns are the same as in the Windows script
    # AddCustomLanguageSupport.cmd.
    case "${name}" in
        w62)
            # Language packs for Internet Explorer 11 on Windows Server
            # 2012
            for current_lang in "${languages_list[@]}"
            do
                if [[ -s "../static/StaticDownloadLinks-ie11-w62-${arch}-${current_lang}.txt" ]]
                then
                    cat_dos "../static/StaticDownloadLinks-ie11-w62-${arch}-${current_lang}.txt" \
                         >> "${temp_dir}/StaticDownloadLinks-${name}-${arch}-${lang}.txt"
                fi
            done
        ;;
    esac

    # *** Windows 10 version-specific static download links ***
    if [[ "${name}" == "w100" ]]
    then
        case "${arch}" in
            x86)
                # Workarounds for an old bash bug, which treated empty
                # arrays as "unset". This was fixed in bash 4.4, though.
                (( "${#w100_x86_enabled_versions[@]}" > 0 )) \
                && enabled_versions=( "${w100_x86_enabled_versions[@]}" )
            ;;
            x64)
                (( "${#w100_x64_enabled_versions[@]}" > 0 )) \
                && enabled_versions=( "${w100_x64_enabled_versions[@]}" )
            ;;
            *)
                log_warning_message "Unknown arch ${arch}"
            ;;
        esac

        if (( "${#enabled_versions[@]}" > 0 ))
        then
            for version in "${enabled_versions[@]}"
            do
                cat_existing_files                                                          \
                    "../static/StaticDownloadLinks-w100-${version}-${arch}-glb.txt"         \
                    "../static/custom/StaticDownloadLinks-w100-${version}-${arch}-glb.txt"  \
                 >> "${temp_dir}/StaticDownloadLinks-w100-${arch}-glb.txt"
            done
        fi
    fi

    # At this point, a non-empty file
    # ${temp_dir}/StaticDownloadLinks-${name}-${arch}-${lang}.txt should
    # be found.
    if [[ -s  "${temp_dir}/StaticDownloadLinks-${name}-${arch}-${lang}.txt" ]]
    then
        sort_in_place "${temp_dir}/StaticDownloadLinks-${name}-${arch}-${lang}.txt"

        # The ExcludeListForce-all.txt is meant to work with both static
        # and dynamic updates. The provided file in the ../exclude
        # directory is empty and does not need to be tested. Users must
        # create copies of the file in the ../exclude/custom directory.
        exclude_lists_static+=( "../exclude/custom/ExcludeListForce-all.txt" )

        # Service Packs are already included in the static download
        # links file created above. If the command line option
        # -includesp is NOT used, then Service Packs must be removed
        # again. This includes the files StaticUpdateIds-w63-upd1.txt
        # and StaticUpdateIds-w63-upd2.txt.
        if [[ "${include_service_packs}" == "disabled" ]]
        then
            exclude_lists_static+=( "${service_packs[@]}" )
        fi

        # Debug output: print all added ExcludeLists
        #echo ""
        #declare -p exclude_lists_static
        #echo ""

        # The filename for the combined exclude list includes the
        # update name, architecture and language, to distinguish
        # between different Windows and Office versions. This is only
        # for debugging purposes.
        apply_exclude_lists                                               \
            "${temp_dir}/StaticDownloadLinks-${name}-${arch}-${lang}.txt" \
            "${valid_static_links}"                                       \
            "${temp_dir}/ExcludeListStatic-${name}-${arch}-${lang}.txt"   \
            "${exclude_lists_static[@]}"
    fi

    if ensure_non_empty_file "${valid_static_links}"
    then
        log_info_message "Created file ${valid_static_links##*/}"
    else
        # Static downloads are mostly installers and service packs. If
        # these files are excluded from download, then the download list
        # may be empty. This is not an error.
        log_warning_message "No static updates found for ${name} ${arch} ${lang}. This is normal for Office 2016 and some localized Office updates, if service packs are excluded."
    fi
    return 0
}


function calculate_dynamic_updates ()
{
    local name="$1"
    local arch="$2"
    local lang="$3"
    local valid_dynamic_links="$4"

    local locale=""
    local version=""
    local -a disabled_versions=()
    local -a exclude_lists_dynamic=()

    # Preconditions
    case "${name}" in
        # Accepted update names (TMP_PLATFORM in DownloadUpdates.cmd)
        w62 | w63 | w100 | o2k13 | o2k16)
            :
        ;;
        *)
            # Dynamic updates are not calculated for "win", and ofc is
            # not used anymore
            return 0
        ;;
    esac

    log_info_message "Determining dynamic update urls for ${name} ${arch} ${lang}"

    # Remove existing files
    rm -f "${valid_dynamic_links}"

    # Note: The output filename must include the update name, because
    # the function xml_transform was designed to skip the calculation,
    # if the output file already exists. This simply means, that different
    # output files must have different names.
    log_info_message "Extracting file 1, revision-and-update-ids-${name}.txt ..."
    xml_transform "extract-revision-and-update-ids-${name}.xsl" \
                          "revision-and-update-ids-${name}.txt"

    log_info_message "Extracting file 2, BundledUpdateRevisionAndFileIds.txt ..."
    xml_transform "extract-update-revision-and-file-ids.xsl" \
                  "BundledUpdateRevisionAndFileIds.txt"

    log_info_message "Extracting file 3, UpdateCabExeIdsAndLocations.txt ..."
    xml_transform "extract-update-cab-exe-ids-and-locations.xsl" \
                  "UpdateCabExeIdsAndLocations.txt"

    log_info_message "Creating file 4, file-and-update-ids-${name}.txt ..."
    join -t "," -e "unavailable" -o "2.3,1.2"                \
          "${temp_dir}/revision-and-update-ids-${name}.txt"  \
          "${temp_dir}/BundledUpdateRevisionAndFileIds.txt"  \
        > "${temp_dir}/file-and-update-ids-${name}.txt"
    sort_in_place "${temp_dir}/file-and-update-ids-${name}.txt"

    log_info_message "Creating file 5, update-ids-and-locations-${name}.txt ..."
    join -t "," -e "unavailable" -o "1.2,2.2"            \
          "${temp_dir}/file-and-update-ids-${name}.txt"  \
          "${temp_dir}/UpdateCabExeIdsAndLocations.txt"  \
        > "${temp_dir}/update-ids-and-locations-${name}.txt"
    sort_in_place "${temp_dir}/update-ids-and-locations-${name}.txt"

    # Filtering by language differs between Windows and Office
    log_info_message "Creating file 6, update-ids-and-locations-${name}-${lang}.txt ..."
    case "${name}" in
        # Windows updates (PLATFORM_WINDOWS in DownloadUpdates.cmd)
        w62 | w63 | w100)
            # Simply rename the file, because ${lang} will always be
            # "glb" for Windows updates
            mv "${temp_dir}/update-ids-and-locations-${name}.txt" \
               "${temp_dir}/update-ids-and-locations-${name}-${lang}.txt"
        ;;
        # Office updates (PLATFORM_OFFICE in DownloadUpdates.cmd)
        o2k13 | o2k16)
            # To filter Office updates, language codes like deu and enu
            # are translated to locales.
            #
            # All global Office updates, which are extracted from the
            # WSUS Offline scan file wsusscn2.cab, can be identified with
            # a pseudo locale "x-none". This locale is not used, though.
            #
            # Locales with language and territory code are used as in the
            # Windows script DetermineSystemProperties.vbs
            #
            # For details see the configuration files in
            # /usr/share/i18n/locales (Debian 10 Buster)
            #
            # TODO: This should be an associative array (map in Python),
            # but it was implemented like that for compatibility with
            # the ancient bash 3.x in Mac OS X.
            case "${lang}" in
                deu) locale="de-de";;
                enu) locale="en-us";;
                ara) locale="ar-sa";;
                chs) locale="zh-cn";;
                cht) locale="zh-tw";;
                csy) locale="cs-cz";;
                dan) locale="da-dk";;
                nld) locale="nl-nl";;
                fin) locale="fi-fi";;
                fra) locale="fr-fr";;
                ell) locale="el-gr";;
                heb) locale="he-il";;
                hun) locale="hu-hu";;
                ita) locale="it-it";;
                jpn) locale="ja-jp";;
                kor) locale="ko-kr";;
                nor) locale="nb-no";;
                plk) locale="pl-pl";;
                ptg) locale="pt-pt";;
                ptb) locale="pt-br";;
                rus) locale="ru-ru";;
                esn) locale="es-es";;
                sve) locale="sv-se";;
                trk) locale="tr-tr";;
                glb) locale="x-none";;
                *) fail "Unsupported or unknown language ${lang}";;
            esac
            if [[ "${lang}" == "glb" ]]
            then
                # Remove all localized files using the
                # ExcludeList-locales.txt, which contains all known
                # locales.
                apply_exclude_lists                                            \
                    "${temp_dir}/update-ids-and-locations-${name}.txt"         \
                    "${temp_dir}/update-ids-and-locations-${name}-${lang}.txt" \
                    "${temp_dir}/ExcludeList-locales.txt"                      \
                    "../exclude/ExcludeList-locales.txt"                       \
                    "../exclude/custom/ExcludeList-locales.txt"
            else
                # Extract localized files using search strings like
                # "-de-de_" and "-en-us_"
                grep -F -i -e "-${locale}_"                                    \
                    "${temp_dir}/update-ids-and-locations-${name}.txt"         \
                  > "${temp_dir}/update-ids-and-locations-${name}-${lang}.txt" \
                    || true
            fi
        ;;
    esac

    # Label :DetermineShared in DownloadUpdates.cmd
    #
    # Create the files ../client/UpdateTable/UpdateTable-*-*.csv,
    # which are needed for the installation of the updates. They link
    # the UpdateIds (in form of UUIDs) to the file names.
    log_info_message "Creating file 7, UpdateTable-${name}-${lang}.csv ..."
    mkdir -p "../client/UpdateTable"
    extract_ids_and_filenames                                      \
        "${temp_dir}/update-ids-and-locations-${name}-${lang}.txt" \
        "../client/UpdateTable/UpdateTable-${name}-${lang}.csv"

    # At this point, the UpdateIds are no longer needed. Only the
    # locations (URLs) are needed to create the initial list of dynamic
    # download links.
    #
    # Note: The Windows script creates slightly different names by using
    # the original positional parameters %1 and %2 again, which may or
    # may not include the architecture. The files themselves may still
    # contain a mixture of all platforms supported by Windows (x86, x64,
    # ia64, arm64).
    log_info_message "Creating file 8, DynamicDownloadLinks-${name}-${lang}.txt ..."
    cut -d ',' -f 2                                                  \
          "${temp_dir}/update-ids-and-locations-${name}-${lang}.txt" \
        > "${temp_dir}/DynamicDownloadLinks-${name}-${lang}.txt"
    sort_in_place "${temp_dir}/DynamicDownloadLinks-${name}-${lang}.txt"

    # Remove the superseded updates to get a list of current dynamic
    # download links
    log_info_message "Creating file 9, CurrentDynamicLinks-${name}-${lang}.txt ..."
    if [[ -s "${used_superseded_updates_list}" ]]
    then
        join -v1 "${temp_dir}/DynamicDownloadLinks-${name}-${lang}.txt" \
                 "${used_superseded_updates_list}"                      \
               > "${temp_dir}/CurrentDynamicLinks-${name}-${lang}.txt"
    else
        mv "${temp_dir}/DynamicDownloadLinks-${name}-${lang}.txt" \
           "${temp_dir}/CurrentDynamicLinks-${name}-${lang}.txt"
    fi

    # Apply the remaining exclude lists, which typically contain kb
    # numbers only, to get the final list of valid dynamic download links
    log_info_message "Creating file 10, ValidDynamicLinks-${name}-${arch}-${lang}.txt ..."
    exclude_lists_dynamic+=(
        "../exclude/ExcludeList-${name}.txt"
        "../exclude/ExcludeList-${name}-${arch}.txt"
        "../exclude/ExcludeList-${name}-${lang}.txt"
        "../exclude/ExcludeList-${name}-${arch}-${lang}.txt"
        "../exclude/custom/ExcludeList-${name}.txt"
        "../exclude/custom/ExcludeList-${name}-${arch}.txt"
        "../exclude/custom/ExcludeList-${name}-${lang}.txt"
        "../exclude/custom/ExcludeList-${name}-${arch}-${lang}.txt"
    )

    # The next filters refer to the single file ExcludeList-o2k13-lng.txt
    # in Community Editions 11.9.8-ESR and 12.5
    if [[ "${lang}" != "glb" ]]
    then
        exclude_lists_dynamic+=(
            "../exclude/ExcludeList-${name}-lng.txt"
            "../exclude/ExcludeList-${name}-${arch}-lng.txt"
            "../exclude/custom/ExcludeList-${name}-lng.txt"
            "../exclude/custom/ExcludeList-${name}-${arch}-lng.txt"
        )
    fi

    # In the Linux downloads scripts, version 2.4, the option -includesp
    # is applied to all Windows and Office versions. This includes the
    # files StaticUpdateIds-w63-upd1.txt and StaticUpdateIds-w63-upd2.txt.
    if [[ "${include_service_packs}" == "disabled" ]]
    then
        exclude_lists_dynamic+=( "${service_packs[@]}" )
    fi

    # Add Windows 10 version-specific exclude lists
    if [[ "${name}" == "w100" ]]
    then
        case "${arch}" in
            x86)
                (( "${#w100_x86_disabled_versions[@]}" > 0 )) \
                && disabled_versions=( "${w100_x86_disabled_versions[@]}" )
            ;;
            x64)
                (( "${#w100_x64_disabled_versions[@]}" > 0 )) \
                && disabled_versions=( "${w100_x64_disabled_versions[@]}" )
            ;;
            *)
                log_warning_message "Unknown arch ${arch}"
            ;;
        esac

        if (( "${#disabled_versions[@]}" > 0 ))
        then
            for version in "${disabled_versions[@]}"
            do
                exclude_lists_dynamic+=(
                    "../exclude/ExcludeList-w100-${version}.txt"
                    "../exclude/custom/ExcludeList-w100-${version}.txt"
                )
            done
        fi
    fi

    # Another branch between Windows and Office updates
    case "${name}" in
        # All supported Windows versions
        # Label :DetermineWindowsSpecificExclude in DownloadUpdates.cmd
        w62 | w63 | w100)
            # Prevent the download of cumulative monthly update rollups,
            # if security-only updates are selected
            if [[ "${prefer_seconly}" == "enabled" ]]
            then
                exclude_lists_dynamic+=(
                    "../client/exclude/HideList-seconly.txt"
                    "../client/exclude/custom/HideList-seconly.txt"
                )
            fi
            # Exclude other architectures, for example x64, ia64 and
            # arm64, if x86 is selected
            exclude_lists_dynamic+=(
                "../exclude/ExcludeList-${arch}.txt"
            )
        ;;
        # All supported Office versions
        # Label :DetermineOfficeSpecificExclude in DownloadUpdates.cmd
        o2k13 | o2k16)
            # These filters are similar to those above, but they are
            # explicitly named ExcludeList-ofc-*.txt
            exclude_lists_dynamic+=(
                "../exclude/ExcludeList-ofc.txt"
                "../exclude/ExcludeList-ofc-${lang}.txt"
                "../exclude/custom/ExcludeList-ofc.txt"
                "../exclude/custom/ExcludeList-ofc-${lang}.txt"
            )
            if [[ "${lang}" != "glb" ]]
            then
                exclude_lists_dynamic+=(
                    "../exclude/ExcludeList-ofc-lng.txt"
                    "../exclude/custom/ExcludeList-ofc-lng.txt"
                )
            fi
        ;;
    esac

    # Finally, add the ExcludeListForce-all.txt, but only from the
    # custom directory
    exclude_lists_dynamic+=(
        "../exclude/custom/ExcludeListForce-all.txt"
    )

    # Debug output: print all added ExcludeLists
    #echo ""
    #declare -p exclude_lists_dynamic
    #echo ""

    apply_exclude_lists                                              \
        "${temp_dir}/CurrentDynamicLinks-${name}-${lang}.txt"        \
        "${valid_dynamic_links}"                                     \
        "${temp_dir}/ExcludeListDynamic-${name}-${arch}-${lang}.txt" \
        "${exclude_lists_dynamic[@]}"

    # Dynamic updates should always be found, so an empty output file
    # is unexpected.
    if ensure_non_empty_file "${valid_dynamic_links}"
    then
        log_info_message "Created file ${valid_dynamic_links##*/}"
    else
        log_warning_message "No dynamic updates found for ${name} ${arch} ${lang}"
    fi
    return 0
}


# Safety guard for security-only updates for Windows 8, 8.1 and the
# corresponding server versions
#
# The download and installation of security-only updates depends on the
# correct configuration of the files:
#
# - wsusoffline/client/exclude/HideList-seconly.txt
# - wsusoffline/client/static/StaticUpdateIds-w62-seconly.txt
# - wsusoffline/client/static/StaticUpdateIds-w63-seconly.txt
#
# Usually, these files must be updated after each official patch day,
# which is the second Tuesday each month. This is done by the maintainer
# of WSUS Offline Update, and new configuration files are downloaded
# automatically.
#
# The function seconly_safety_guard tries to make sure, that the
# configuration files have been updated after the last official patch
# day. Otherwise, the download will be stopped, to prevent unwanted side
# effects. The possible side effect would be the download and installation
# of the most recent quality and security update rollup. Since these
# update rollups are cumulative, they will install everything, which
# was meant to be prevented by specifying security-only updates in the
# first place.

function seconly_safety_guard ()
{
    local update_name="$1"

    # Preconditions
    if [[ "${prefer_seconly}" != "enabled" ]]
    then
        log_debug_message "Option prefer_seconly is not enabled"
        return 0
    fi
    case "${update_name}" in
        w62 | w63)
            log_debug_message "Recognized Windows 8 or 8.1"
        ;;
        *)
            log_debug_message "Not an affected Windows version"
            return 0
        ;;
    esac

    log_info_message "Running Security-only Safety Guard..."

    # Get the official patch day of this month
    #
    # The ISO-8601 format can be turned into an integer number by just
    # stripping the hyphens, e.g. 2017-08-08 -> 20170808. This should be
    # sufficient to compare the dates. The previous approach to calculate
    # the date in seconds was not really necessary.

    local this_month=""
    this_month="$(date -u '+%Y-%m')"          # for example 2017-08
    local day_of_month=""                     # as padded strings 08..14
    local current_date=""                     # ISO-8601 format: 2017-08-08
    local -i day_of_week="0"                  # as integer 1..7, with Monday=1
    local patchday_this_month=""              # ISO-8601 format: 2017-08-08
    local -i patchday_this_month_integer="0"  # without hyphens: 20170808
    local input_format="%Y-%m-%d %H:%M:%S"    # used for FreeBSD date

    # GNU/Linux date has different options than FreeBSD date. In
    # particular, the option -d or --date must be replaced with the
    # option -v or a combination of -j and -f. The option -v allows time
    # calculations similar to GNU/Linux date. The option -f is suggested
    # for date format conversions.

    case "${kernel_name}" in
        Linux | CYGWIN*)
            # The variable "${day_of_month}" should get the values as zero
            # padded strings, to construct the full date in ISO format.
            #
            # for day_of_month in {08..14}
            #
            # should work, but I don't exactly know, when padding with
            # zeros was introduced.
            for day_of_month in {08..14}
            do
                current_date="${this_month}-${day_of_month}"
                day_of_week="$(date -u -d "${current_date}" '+%u')"
                if (( day_of_week == 2 ))
                then
                    patchday_this_month="${current_date}"
                    patchday_this_month_integer="${current_date//-/}"
                fi
            done
        ;;
        # TODO: So far, only FreeBSD 12.1 was tested
        Darwin | FreeBSD | NetBSD | OpenBSD)
            for day_of_month in {08..14}
            do
                # The hours, minutes and seconds must be specified for
                # FreeBSD date; otherwise the current time will be used.
                current_date="${this_month}-${day_of_month}"
                day_of_week="$(date -j -u -f "${input_format}" "${current_date} 00:00:00" '+%u')"
                if (( day_of_week == 2 ))
                then
                    patchday_this_month="${current_date}"
                    patchday_this_month_integer="${current_date//-/}"
                fi
            done
        ;;
        *)
            log_error_message "Unknown operating system ${kernel_name}, ${OSTYPE}"
            exit 1
        ;;
    esac
    log_info_message "Official patch day of this month: ${patchday_this_month}"

    # Get the official patch day of the last month
    #
    # The patch day of the last month is not used for numeric comparisons,
    # and therefore does not need to be converted to an integer number.
    local last_month=""
    local patchday_last_month=""

    case "${kernel_name}" in
        Linux | CYGWIN*)
            # GNU date understands relative date specifications in plain
            # English like "yesterday", "last week" or "last month". To
            # get the last month, we use the 15th of this month and go
            # back to "last month":
            last_month="$(date -u -d "${this_month}-15 last month" '+%Y-%m')"
            for day_of_month in {08..14}
            do
                current_date="${last_month}-${day_of_month}"
                day_of_week="$(date -u -d "${current_date}" '+%u')"
                if (( day_of_week == 2 ))
                then
                    patchday_last_month="${current_date}"
                fi
            done
        ;;
        Darwin | FreeBSD | NetBSD | OpenBSD)
            # Go to the 15th of this month and then back for one month.
            last_month="$(date -u -v 15d -v 0H -v 0M -v 0S -v -1m '+%Y-%m')"
            for day_of_month in {08..14}
            do
                current_date="${last_month}-${day_of_month}"
                day_of_week="$(date -j -u -f "${input_format}" "${current_date} 00:00:00" '+%u')"
                if (( day_of_week == 2 ))
                then
                    patchday_last_month="${current_date}"
                fi
            done
        ;;
        *)
            log_error_message "Unknown operating system ${kernel_name}, ${OSTYPE}"
            exit 1
        ;;
    esac
    log_info_message "Official patch day of last month: ${patchday_last_month}"

    # The last official patch day is the patch day of this month,
    # if today is on the patch day of this month or later. Otherwise,
    # the last patch day is the patch day of the last month.
    local today=""
    local -i today_integer="0"
    today="$(date -u '+%F')"
    today_integer="${today//-/}"
    log_info_message "Today: ${today}"

    local last_patchday=""
    if (( today_integer >= patchday_this_month_integer ))
    then
        last_patchday="${patchday_this_month}"
    else
        last_patchday="${patchday_last_month}"
    fi
    log_info_message "Last official patchday: ${last_patchday}"

    # Create a list of configuration files for the correct handling of
    # security-only update rollups. Custom files are included, so that
    # users can easily provide the needed information, if necessary.
    #
    # Appending an asterisk removes all files from the list, which cannot
    # be found.

    local -a configuration_files=()
    shopt -s nullglob
    configuration_files+=(
        ../client/exclude/HideList-seconly.txt*
        ../client/static/StaticUpdateIds-w62-seconly.txt*
        ../client/static/StaticUpdateIds-w63-seconly.txt*
        ../client/exclude/custom/HideList-seconly.txt*
        ../client/static/custom/StaticUpdateIds-w62-seconly.txt*
        ../client/static/custom/StaticUpdateIds-w63-seconly.txt*
    )
    shopt -u nullglob

    # Comparing the modification date of the configuration files to the
    # last patch day does not work anymore, because GitLab does not set
    # the Last-Modified header for files, which are extracted from the
    # version control system. The download scripts use the ETag instead,
    # to query the server for modified files.
    #
    # The contents of the configuration files may be searched instead
    # for the expected month, e.g. "January 2021".
    #
    # The environment variable LC_ALL=C should be set, to get English
    # month names. This is done in the main script download-updates.bash.

    local expected_month=""
    case "${kernel_name}" in
        Linux | CYGWIN*)
            expected_month="$(date -u -d "${last_patchday}" '+%B %Y')"
        ;;
        Darwin | FreeBSD | NetBSD | OpenBSD)
            expected_month="$(date -j -u -f "${input_format}" "${last_patchday} 00:00:00" '+%B %Y')"
        ;;
        *)
            log_error_message "Unknown operating system ${kernel_name}, ${OSTYPE}"
            exit 1
        ;;
    esac

    # The configurations files are not searched individually, because
    # custom files, if present, may provide the needed information.

    log_info_message "Searching for the month \"${expected_month}\" in the wsusoffline configuration files..."
    local -i misconfiguration="0"
    if (( "${#configuration_files[@]}" > 0 ))
    then
        if grep -F -q -e "${expected_month}" "${configuration_files[@]}"
        then
            log_info_message "The expected month \"${expected_month}\" was found"
        else
            log_warning_message "The expected month \"${expected_month}\" was NOT found"
            misconfiguration="1"
        fi
    else
        log_warning_message "The list of configuration files is empty. This is probably an error."
    fi

    if (( misconfiguration == 1 ))
    then
        log_message "\
The correct handling of security-only update rollups for both download
and installation depends on the configuration files:

- wsusoffline/client/exclude/HideList-seconly.txt
- wsusoffline/client/static/StaticUpdateIds-w62-seconly.txt
- wsusoffline/client/static/StaticUpdateIds-w63-seconly.txt

These files should be updated after the official patch day, which is the
second Tuesday each month. This is done by the maintainer of WSUS Offline
Update, but it may take some days. New versions of the configuration
files are downloaded automatically.

If these files have not been updated yet, then the download and
installation of security-only updates should be postponed, to prevent
unwanted side effects.

If necessary, you could also update the configuration files yourself. See
the discussion in the forum for details:

- https://forums.wsusoffline.net/viewtopic.php?f=4&t=6897&start=10#p23708

If you have manually updated and verified the configuration files, you
can set the variable exit_on_configuration_problems to \"disabled\" in the
preferences file, to let the script continue at this point.
"
        if [[ "${exit_on_configuration_problems}" == "enabled" ]]
        then
            log_error_message "The script will exit now, to prevent unwanted side effects with the download and installation of security-only updates for Windows 8, 8.1 and their Server versions."
            exit 1
        else
            log_warning_message "There are configuration problems with the download of security-only updates for Windows 8, 8.1 and their Server versions. Proceed with caution to prevent unwanted side effects."
        fi
    else
        log_info_message "Security-only Safety Guard: No problems found"
    fi

    return 0
}

# ========== Commands =====================================================

get_main_updates
return 0
