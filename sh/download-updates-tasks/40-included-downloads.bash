# This file will be sourced by the shell bash.
#
# Filename: 40-included-downloads.bash
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
#     This task downloads the WSUS catalog file and optional static
#     downloads like the installation files for .NET Frameworks. It
#     must be evaluated before calculating superseded updates and
#     dynamic updates.
#
#     Global variables from other files
#     - The indexed arrays architectures_list, languages_list and
#       downloads_list are defined in the file 10-parse-command-line.bash

# ========== Functions ====================================================

function get_included_downloads ()
{
    local current_download=""
    local current_arch=""

    if (( "${#downloads_list[@]}" > 0 ))
    then
        for current_download in "${downloads_list[@]}"
        do
            case "${current_download}" in
                # Architecture-independent downloads
                wsus | cpp | dotnet)
                    process_included_download "${current_download}" "all"
                ;;
                # Architecture dependent downloads; these downloads must
                # be processed twice for both x86 and x64, if present
                # in the architectures list.
                msse | wddefs | wddefs8)
                    if (( "${#architectures_list[@]}" > 0 ))
                    then
                        for current_arch in "${architectures_list[@]}"
                        do
                            process_included_download "${current_download}" "${current_arch}"
                        done
                    else
                        log_warning_message "Skipped processing of ${current_download}, because there are no architectures defined for included downloads. These are derived from Windows updates only."
                    fi
                ;;
                *)
                    fail "${FUNCNAME[0]} - Unknown download name: ${current_download}"
                ;;
            esac
        done
    fi
    return 0
}


function process_included_download ()
{
    local name="$1"
    local arch="$2"
    local -i initial_errors="0"
    initial_errors="$(get_error_count)"

    # All paths are relative to the home directory of the download script.
    local timestamp_pattern="not-available"
    local hashes_file="not-available"
    local hashed_dir="not-available"
    local download_dir="not-available"
    local timestamp_file="not-available"
    local -i interval_length=0
    local interval_description=""
    local static_download_links="not-available"

    # The name of the timestamp files is
    # timestamp-${name}-${arch}-${lang}.txt
    #
    # - ${arch} is "all" for architecture-independent downloads
    # - ${lang} is "glb" for global/multilingual downloads

    case "${name}" in
        wsus)
            timestamp_pattern="wsus-all-glb"
            hashes_file="../client/md/hashes-wsus.txt"
            hashed_dir="../client/wsus"
            download_dir="../client/wsus"
            interval_length="${interval_length_configuration_files}"
            interval_description="${interval_description_configuration_files}"
        ;;
        cpp)
            timestamp_pattern="cpp-all-glb"
            hashes_file="../client/md/hashes-cpp.txt"
            hashed_dir="../client/cpp"
            download_dir="../client/cpp"
            interval_length="${interval_length_dependent_files}"
            interval_description="${interval_description_dependent_files}"
        ;;
        dotnet)
            timestamp_pattern="dotnet-all-${language_parameter}"
            hashes_file="../client/md/hashes-dotnet.txt"
            hashed_dir="../client/dotnet"
            download_dir="../client/dotnet"
            interval_length="${interval_length_dependent_files}"
            interval_description="${interval_description_dependent_files}"
        ;;
        msse)
            timestamp_pattern="msse-${arch}-${language_parameter}"
            hashes_file="../client/md/hashes-msse-${arch}-glb.txt"
            hashed_dir="../client/msse/${arch}-glb"
            download_dir="../client/msse/${arch}-glb"
            interval_length="${interval_length_virus_definitions}"
            interval_description="${interval_description_virus_definitions}"
        ;;
        wddefs)
            timestamp_pattern="wddefs-${arch}-glb"
            hashes_file="../client/md/hashes-wddefs-${arch}-glb.txt"
            hashed_dir="../client/wddefs/${arch}-glb"
            download_dir="../client/wddefs/${arch}-glb"
            interval_length="${interval_length_virus_definitions}"
            interval_description="${interval_description_virus_definitions}"
        ;;
        wddefs8)
            timestamp_pattern="wddefs8-${arch}-glb"
            hashes_file="../client/md/hashes-msse-${arch}-glb.txt"
            hashed_dir="../client/msse/${arch}-glb"
            download_dir="../client/msse/${arch}-glb"
            interval_length="${interval_length_virus_definitions}"
            interval_description="${interval_description_virus_definitions}"
        ;;
        *)
            fail "${FUNCNAME[0]} - Unknown download name: ${name}"
        ;;
    esac
    # The ${timestamp_pattern} is used to create different timestamp and
    # download files for each combination of download_name, architecture
    # and language.
    timestamp_file="${timestamp_dir}/timestamp-${timestamp_pattern}.txt"
    static_download_links="${temp_dir}/StaticDownloadLinks-${timestamp_pattern}.txt"

    if same_day "${timestamp_file}" "${interval_length}"
    then
        log_info_message "Skipped processing of \"${timestamp_pattern//-/ }\", because it has already been done less than ${interval_description} ago"
    else
        log_info_message "Start processing of \"${timestamp_pattern//-/ }\" ..."

        verify_integrity_database "${hashed_dir}" "${hashes_file}"
        calculate_static_downloads "${name}" "${arch}" "${static_download_links}"
        download_static_files "${download_dir}" "${static_download_links}"
        cleanup_client_directory "${download_dir}" "${static_download_links}" "${static_download_links}"
        verify_digital_file_signatures "${download_dir}"
        create_integrity_database "${hashed_dir}" "${hashes_file}"

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


function calculate_static_downloads ()
{
    local name="$1"
    local arch="$2"
    local static_download_links="$3"

    log_info_message "Determining static download links ..."
    # Remove existing file
    rm -f "${static_download_links}"

    case "${name}" in
        wsus | cpp | dotnet | msse | wddefs | wddefs8)
            "calculate_static_downloads_${name}" "${arch}" "${static_download_links}"
        ;;
        *)
            log_error_message "Unknown download name ${name}"
        ;;
    esac
    sort_in_place "${static_download_links}"

    # Since included updates are only statically defined, and there are
    # no service packs, which could be subtracted, it is an unexpected
    # error, if the static downloads list is empty.
    if ensure_non_empty_file "${static_download_links}"
    then
        log_info_message "Created file ${static_download_links##*/}"
    else
        log_warning_message "No downloads found for ${name}"
    fi
    return 0
}


function calculate_static_downloads_wsus ()
{
    local arch="$1"  # unused for wsus
    local static_download_links="$2"
    local current_dir=""

    for current_dir in ../static ../static/custom
    do
        if [[ -s "${current_dir}/StaticDownloadLinks-wsus.txt" ]]
        then
            cat_dos "${current_dir}/StaticDownloadLinks-wsus.txt" \
                >> "${static_download_links}"
        fi
    done
    return 0
}


function calculate_static_downloads_cpp ()
{
    local arch="$1"  # unused for cpp, but both architectures are
                     # downloaded anyway
    local static_download_links="$2"
    local current_dir=""
    local current_arch=""

    for current_dir in ../static ../static/custom
    do
        # Visual C++ runtime libraries always include both 32-bit and
        # 64-bit versions, which are downloaded to the same directory.
        for current_arch in x86 x64
        do
            if [[ -s "${current_dir}/StaticDownloadLinks-cpp-${current_arch}-glb.txt" ]]
            then
                cat_dos "${current_dir}/StaticDownloadLinks-cpp-${current_arch}-glb.txt" \
                    >> "${static_download_links}"
            fi
        done
    done
    return 0
}


# Calculation of static download links for .NET Frameworks
#
# The English installers for .NET Frameworks are the only full
# installers. They are always needed, and they are supplemented with
# language packs for other languages. The filenames may be similar,
# but the English installers are much larger.

function calculate_static_downloads_dotnet ()
{
    local arch="$1"  # unused for dotnet
    local static_download_links="$2"
    # The file ${dotnet_installers} is a preliminary file for the static
    # download links, before applying the ExcludeListForce-all.txt.
    local dotnet_installers="${temp_dir}/dotnet-installers-${language_parameter}.txt"
    local current_dir=""
    local current_lang=""

    # German language packs are first removed from the "global" download
    # files.
    for current_dir in ../static ../static/custom
    do
        if [[ -s "${current_dir}/StaticDownloadLinks-dotnet.txt" ]]
        then
            filter_default_languages "${current_dir}/StaticDownloadLinks-dotnet.txt" \
                >> "${dotnet_installers}"
        fi
    done

    # Language packs for all selected languages on the command-line are
    # then added back from the localized download files.
    #
    # The search patterns are the same as in the Windows script
    # AddCustomLanguageSupport.cmd.
    for current_lang in "${languages_list[@]}"
    do
        if [[ -s "../static/StaticDownloadLinks-dotnet-${current_lang}.txt" ]]
        then
            grep_dos -F -i                 \
                -e "dotnetfx35langpack_"   \
                -e "dotNetFx40LP_Full_"    \
                -e "NDP452-KB2901907-"     \
                -e "NDP46-KB3045557-"      \
                -e "NDP461-KB3102436-"     \
                -e "NDP462-KB3151800-"     \
                -e "NDP47-KB3186497-"      \
                -e "NDP471-KB4033342-"     \
                -e "NDP472-KB4054530-"     \
                -e "ndp48-x86-x64-allos-"  \
                "../static/StaticDownloadLinks-dotnet-${current_lang}.txt" \
                >> "${dotnet_installers}" || true
        fi
    done

    # Apply ExcludeListForce-all.txt as in
    # https://trac.wsusoffline.net/trac.fcgi/changeset/1015/trunk/cmd/DownloadUpdates.cmd
    apply_exclude_lists \
        "${dotnet_installers}" \
        "${static_download_links}" \
        "${temp_dir}/ExcludeListForce-all.txt" \
        "../exclude/custom/ExcludeListForce-all.txt"
    return 0
}

function calculate_static_downloads_msse ()
{
    local arch="$1"
    local static_download_links="$2"
    local current_dir=""
    local current_lang=""

    for current_dir in ../static ../static/custom
    do
        # The default languages are removed from the global download
        # files, but selected languages are added back from the localized
        # download files
        for current_lang in glb "${languages_list[@]}"
        do
            if [[ -s "${current_dir}/StaticDownloadLinks-msse-${arch}-${current_lang}.txt" ]]
            then
                filter_default_languages "${current_dir}/StaticDownloadLinks-msse-${arch}-${current_lang}.txt" \
                    >> "${static_download_links}"
            fi
        done
    done
    return 0
}

function calculate_static_downloads_wddefs ()
{
    local arch="$1"
    local static_download_links="$2"
    local current_dir=""

    for current_dir in ../static ../static/custom
    do
        if [[ -s "${current_dir}/StaticDownloadLink-wddefs-${arch}-glb.txt" ]]
        then
            cat_dos "${current_dir}/StaticDownloadLink-wddefs-${arch}-glb.txt" \
                >> "${static_download_links}"
        fi
    done
    return 0
}

# wddefs8 is msse without the localized installers, which are not needed
# for Windows 8, 8.1 and 10

function calculate_static_downloads_wddefs8 ()
{
    local arch="$1"
    local static_download_links="$2"
    local current_dir=""

    for current_dir in ../static ../static/custom
    do
        if [[ -s "${current_dir}/StaticDownloadLinks-msse-${arch}-glb.txt" ]]
        then
            grep_dos -F -i -v -e "MSEInstall.exe"                         \
                "${current_dir}/StaticDownloadLinks-msse-${arch}-glb.txt" \
                >> "${static_download_links}" || true
        fi
    done
    return 0
}

# ========== Commands =====================================================

get_included_downloads
return 0
