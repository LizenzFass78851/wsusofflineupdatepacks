# This file will be sourced by the shell bash.
#
# Filename: msedge-downloads.bash
#
# Copyright (C) 2021 Hartmut Buhrmester
#                    <wsusoffline-scripts-xxyh@hartmut-buhrmester.de>
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
#     This file handles the download of Microsoft Edge (Chromium) files.
#
#     It requires the additional tools jq, base64 and one of hexdump,
#     od or xxd.
#
#     - jq is used to parse JSON files. It is installed with the
#       package jq.
#
#     - base64 and od are part of the GNU core utilities (coreutils). They
#       should be available in common Linux distributions. base64 and
#       od are also found in FreeBSD. hexdump is preferred over od,
#       if available.
#
#     Usually, you only need to install jq.


function request_edge_chromium_links ()
{
    # Verify number of parameters
    if (( $# < 2 ))
    then
        log_error_message "Error in request_edge_chromium_links: two parameters are required"
        return 0
    fi
    local static_download_links_edge="$1"
    local hashes_edge="$2"

    # Reset both output files
    true > "${static_download_links_edge}"
    true > "${hashes_edge}"

    # Write a header to the hashdeep file
    echo "%%%% HASHDEEP-1.0" >> "${hashes_edge}"
    echo "%%%% size,sha1,sha256,filename" >> "${hashes_edge}"

    local -a target_names=(
        "msedge-stable-win-x86"
        "msedge-stable-win-x64"
        "msedgeupdate-stable-win-x86"
    )

    local current_name=""
    for current_name in "${target_names[@]}"
    do
        get_latest_edge_download "${static_download_links_edge}" \
                                 "${hashes_edge}"                \
                                 "Default"                       \
                                 "${current_name}"
    done

    return 0
}


# Query the latest version of MS Edge download files

function get_latest_edge_download ()
{
    local static_download_links_edge="$1"
    local hashes_edge="$2"
    # Variables used to create the request
    local target_namespace="$3"
    local target_name="$4"
    local json_request=""
    local url=""
    local -i wget_result_code="0"
    # Values read from the JSON response
    local json_response=""
    local str_namespace=""
    local str_name=""
    local str_version=""

    # Validate input strings
    [[ -z "${static_download_links_edge}" ]] && return 0
    [[ -z "${hashes_edge}" ]] && return 0
    [[ -z "${target_namespace}" ]] && return 0
    [[ -z "${target_name}" ]] && return 0

    log_info_message "Request the latest version for ${target_name}"

    # Create an empty JSON collection for the request. The compact form
    # is usually preferred for automatic queries:
    json_request='{"targetingAttributes":{"":""}}'

    # Pretty-printed, this would be:
    # {
    #   "targetingAttributes": {
    #     "": ""
    #   }
    # }

    # Debug output for JSON requests and answers
    #
    # jq is often used to parse JSON data. In its most basic form,
    # it will pretty-print JSON files.
    #
    #echo "JSON request"
    #jq '.' <<< "${json_request}"
    #echo ""

    # Insert target namespace and name into the url
    url="https://msedge.api.cdp.microsoft.com/api/v1.1/contents/Browser/namespaces/${target_namespace}/names/${target_name}/versions/latest?action=select"

    # Output file for wget
    json_response="${temp_dir}/${target_name}_version.json"

    # wget usually expects form data like "key1=value1&key2=value2"
    # with the content type "application/x-www-form-urlencoded". The
    # content is not checked, though, and the type may be changed with
    # a custom header.
    #
    # The content length is set by wget.
    #
    # The server uses certificates, which are not known to Linux, and
    # which must be ignored at this point.
    if wget --verbose                                  \
            --server-response                          \
            --tries="2"                                \
            --timeout="60"                             \
            --waitretry="20"                           \
            --user-agent=""                            \
            --no-check-certificate                     \
            --post-data="${json_request}"              \
            --header="Content-Type: application/json"  \
            --append-output="${logfile}"               \
            -O "${json_response}"                      \
            "${url}"
    then
        wget_result_code="0"
    else
        wget_result_code="$?"
        log_error_message "wget returned error code ${wget_result_code}"
        increment_error_count
        return 0
    fi

    #echo "JSON response"
    #jq '.' "${json_response}"
    #echo ""

    # Extract the namespace, name and version number from the
    # response. The jq option -r will produce raw output without
    # quotation marks.
    str_namespace="$( jq -r '.ContentId.Namespace' "${json_response}" )"
    str_name="$( jq -r '.ContentId.Name' "${json_response}" )"
    str_version="$( jq -r '.ContentId.Version' "${json_response}" )"

    # Validate response fields
    [[ -z "${str_namespace}" ]] && return 0
    [[ -z "${str_name}" ]] && return 0
    [[ -z "${str_version}" ]] && return 0

    # Call the next function to get more details
    get_edge_download "${static_download_links_edge}" \
                      "${hashes_edge}"                \
                      "${str_namespace}"              \
                      "${str_name}"                   \
                      "${str_version}"

    return 0
}


# Get detailed download info for MS Edge installation files

function get_edge_download ()
{
    local static_download_links_edge="$1"
    local hashes_edge="$2"
    # Variables used to create the request
    local target_namespace="$3"
    local target_name="$4"
    local target_version="$5"
    local json_request=""
    local url=""
    local -i wget_result_code="0"
    # Values read from the response
    local json_response=""
    local real_filename=""
    local download_link=""
    local filesize=""
    local sha1_base64=""
    local sha256_base64=""
    # Converted hashes
    local sha1_hex=""
    local sha256_hex=""

    # Validate input strings
    [[ -z "${static_download_links_edge}" ]] && return 0
    [[ -z "${hashes_edge}" ]] && return 0
    [[ -z "${target_namespace}" ]] && return 0
    [[ -z "${target_name}" ]] && return 0
    [[ -z "${target_version}" ]] && return 0

    log_info_message "Request download info for ${target_name}, version ${target_version}"

    # Create an empty JSON array for the request
    json_request='[]'

    #echo "JSON request"
    #jq '.' <<< "${json_request}"
    #echo ""

    # Insert target namespace, name and version into the url
    url="https://msedge.api.cdp.microsoft.com/api/v1.1/internal/contents/Browser/namespaces/${target_namespace}/names/${target_name}/versions/${target_version}/files?action=GenerateDownloadInfo&foregroundPriority=true"

    # Output file for wget
    json_response="${temp_dir}/${target_name}_download_info.json"

    if wget --verbose                                  \
            --server-response                          \
            --tries="2"                                \
            --timeout="60"                             \
            --waitretry="20"                           \
            --user-agent=""                            \
            --no-check-certificate                     \
            --post-data="${json_request}"              \
            --header="Content-Type: application/json"  \
            --append-output="${logfile}"               \
            -O "${json_response}"                      \
            "${url}"
    then
        wget_result_code="0"
    else
        wget_result_code="$?"
        log_error_message "wget returned error code ${wget_result_code}"
        increment_error_count
        return 0
    fi

    #echo "JSON response"
    #jq '.' "${json_response}"
    #echo ""

    # The JSON response is an array. There may be one full installer
    # and several updates from previous versions.
    local expected_filename=""
    case "${target_name}" in
        "msedge-stable-win-x86")
            expected_filename="MicrosoftEdge_X86_${target_version}.exe"
        ;;
        "msedge-stable-win-x64")
            expected_filename="MicrosoftEdge_X64_${target_version}.exe"
        ;;
        "msedgeupdate-stable-win-x86")
            expected_filename="MicrosoftEdgeUpdateSetup_X86_${target_version}.exe"
        ;;
        *)
            log_error_message "Unknown target name"
            return 0
        ;;
    esac

    # Get the number of elements in the JSON response
    local -i array_length="0"
    array_length="$( jq 'length' "${json_response}" )"
    if (( array_length == 0 ))
    then
        log_warning_message "The JSON response appears to be an empty array"
        return 0
    fi

    local -i i="0"
    for (( i = 0; i < array_length; i++ ))
    do
        real_filename="$( jq -r ".[${i}].FileId" "${json_response}" )"
        if [[ "${real_filename}" == "${expected_filename}" ]]
        then
            download_link="$( jq -r ".[${i}].Url" "${json_response}" )"
            filesize="$( jq -r ".[${i}].SizeInBytes" "${json_response}" )"
            sha1_base64="$( jq -r ".[${i}].Hashes.Sha1" "${json_response}" )"
            sha256_base64="$( jq -r ".[${i}].Hashes.Sha256" "${json_response}" )"

            # Validate the results
            [[ -z "${real_filename}" ]] && return 0
            [[ -z "${download_link}" ]] && return 0
            [[ -z "${filesize}" ]] && return 0
            [[ -z "${sha1_base64}" ]] && return 0
            [[ -z "${sha256_base64}" ]] && return 0

            # Convert hashes from base64 encoded strings to hexadecimal
            # numbers
            sha1_hex="$( base64_to_hex "${sha1_base64}" )"
            sha256_hex="$( base64_to_hex "${sha256_base64}" )"

            # Append all needed data to the static download links file
            # and the hashes file
            printf '%s\n' "${download_link},${real_filename}" >> "${static_download_links_edge}"
            printf '%s\n' "${filesize},${sha1_hex},${sha256_hex},${real_filename}" >> "${hashes_edge}"

            # Don't test the remaining array elements, if the expected
            # filename has been found
            break
        fi
    done

    echo ""
    return 0
}


# Conversion from base64 encoded strings to hexadecimal numbers
#
# base64 is part of the GNU Core Utilities (coreutils) and should always
# be installed on common Linux distributions. The FreeBSD base64 should
# work, too.
#
# hexdump is a BSD utility, which is also widely available in Linux. In
# Debian systems, it is installed with the packages bsdmainutils or
# bsdextrautils. The package bsdmainutils is automatically installed in
# Debian 10 Buster.
#
# "od" is part of the GNU Core Utilities (coreutils), and there is a
# similar "od" in FreeBSD. The BSD "od" does not have the option -w. So
# this could be used as a fallback for Linux, if hexdump is not available.
#
# xxd is easier to use, but it is not available everywhere.

function base64_to_hex ()
{
    local base64_string="$1"
    local hexnumber=""

    case "${hexdump_utility}" in
        hexdump)
            hexnumber="$( echo -n "${base64_string}" | base64 --decode | hexdump -v -e '/1 "%02x"' )"
        ;;
        od)
            # The width parameter -w is used to print all output in one
            # line. Line feeds could also be removed with tr -d '\n' .
            hexnumber="$( echo -n "${base64_string}" | base64 --decode | od -An -t x1 -w40 -v )"
            hexnumber="${hexnumber// /}"
        ;;
        xxd)
            hexnumber="$( echo -n "${base64_string}" | base64 --decode | xxd -plain -cols 80 )"
        ;;
        *)
            log_error_message "No hexdump utility found"
        ;;
    esac

    echo "${hexnumber}"
    return 0
}


# Handling of filenames
#
# For some reason, the real filename from the field "FileId" in the second
# JSON response is not used for the download. Instead, the filename in
# the URL is a UUID, followed by several GET parameters. Sometimes, this
# UUID is specified as the filename with a Content-Disposition header:
#
# Content-Disposition: attachment; filename="e4f751ce-fd0a-46b7-bade-fe4291397ee7"
#
# wget can use this filename, if the option --content-disposition is used.
#
# This doesn't work reliably, though. Most of the time the
# Content-Disposition header is NOT set, and then wget uses the basename
# of the URL as filename, including all GET parameters. This isn't
# really a problem by itself, because special characters like ?&=%
# are not illegal on Linux.
#
# Characters, which are illegal in URLs, are percent-encoded. wget
# decodes SOME of these characters, while others are kept unchanged:
#
# %2b is replaced with +
# %3d is replaced with =
# %2F is not changed, as the forward slash "/" is the only incompatible
#     character for filenames in Linux
#
# However, the best approach might be to delete all GET parameters after
# the "?", and to use only the UUID as the remote filename.
#
# Timestamping does not work with wget, although the Last-Modified header
# is set. But comparing the file modification date with wget requires,
# that the local filename and the remote filename are the same. This would
# mean, that the files are renamed back and forth, like the static C++
# downloads. But this doesn't work reliably, because the GET parameters
# may change on the server, and they are further modified by wget,
# before writing the file to disk.
#
# Existing files can be compared to remote files by the filename, which
# is versioned, and by the SHA-1 and SHA-256 hashes, which are part of
# the download info.

function download_edge_chromium ()
{
    local static_download_links_edge="$1"
    local hashes_edge="$2"
    local download_dir="$3"
    local url=""
    local real_filename=""
    local skip_rest=""
    local filename_from_url=""
    local hashdeep_output=""
    local -i wget_result_code="0"

    # Validate input
    if (( $# < 3 ))
    then
        log_error_message "Error in function download_edge_chromium: 3 parameters are required"
        return 0
    fi

    # Validating input parameters
    [[ -z "${static_download_links_edge}" ]] && return 0
    [[ -z "${hashes_edge}" ]] && return 0
    [[ -z "${download_dir}" ]] && return 0

    # The input files must already exist, and they should not be empty.
    [[ -s "${static_download_links_edge}" ]] || return 0
    [[ -s "${hashes_edge}" ]] || return 0

    # Create the download directory
    mkdir -p "${download_dir}" || return 0

    # Parse the static download links file
    while IFS=$'\r\n,' read -r url real_filename skip_rest
    do
        # "basename" in bash
        filename_from_url="${url##*/}"
        # delete GET parameters from the end of the URL
        filename_from_url="${filename_from_url%%\?*}"

        [[ -z "${url}" ]] && return 0
        [[ -z "${real_filename}" ]] && return 0
        [[ -z "${filename_from_url}" ]] && return 0

        log_info_message "Downloading/validating ${real_filename} ..."

        # Check, if the file already exists
        if [[ -f "${download_dir}/${real_filename}" ]]
        then
            # Validate the hashes with hashdeep in positive matching mode
            #
            # This mode works better for single files than the audit
            # mode: hashdeep prints all matching input files to standard
            # output. If a single input file is tested, and the hashdeep
            # output matches the filename, then the file is valid.
            #
            # The hashdeep result code cannot be used, though, because
            # hashdeep only returns okay, if there are matching input
            # files for ALL records in the hashdeep file.
            hashdeep_output="$( hashdeep -k "${hashes_edge}" -m -b -vv "${download_dir}/${real_filename}" )" || true

            if [[ "${hashdeep_output}" == "${real_filename}" ]]
            then
                log_info_message "The file ${real_filename} already exists and all hashes match. No download required."
            else
                log_info_message "The file ${real_filename} exists, but the hashes did not match. The file will be deleted and downloaded again."
                rm "${download_dir}/${real_filename}"
            fi
        else
            log_info_message "The file ${real_filename} does not exist yet."
        fi

        # Check, if the file still exists
        if [[ ! -f "${download_dir}/${real_filename}" ]]
        then
            # A new download is required
            log_info_message "Downloading new file ${real_filename} ..."

            if wget --verbose                             \
                    --server-response                     \
                    --progress="dot:mega"                 \
                    --timestamping                        \
                    --trust-server-names                  \
                    --content-disposition                 \
                    --no-http-keep-alive                  \
                    --tries="10"                          \
                    --timeout="120"                       \
                    --waitretry="20"                      \
                    --directory-prefix="${download_dir}"  \
                    --append-output="${logfile}"          \
                    "${url}"
            then
                # wget downloaded some file, but it must be renamed to
                # the real filename, and the file hashes must be verified.
                wget_result_code="0"

                log_info_message "Renaming downloaded file to real filename..."
                # The shell can handle file globbing best
                shopt -s nullglob
                for pathname in "${download_dir}/${filename_from_url}"*
                do
                    mv "${pathname}" "${download_dir}/${real_filename}"
                done
                shopt -u nullglob

                if [[ -f "${download_dir}/${real_filename}" ]]
                then
                    log_info_message "Verifying the new download with hashdeep..."
                    hashdeep_output="$( hashdeep -k "${hashes_edge}" -m -b -vv "${download_dir}/${real_filename}" )" || true

                    if [[ "${hashdeep_output}" == "${real_filename}" ]]
                    then
                        log_info_message "The download of ${real_filename} succeeded."
                    else
                        log_warning_message "The download of ${real_filename} did not succeed. The file will be deleted."
                        rm "${download_dir}/${real_filename}"
                    fi
                else
                    log_warning_message "The downloaded file was not found for unknown reasons."
                fi
            else
                wget_result_code="$?"
                log_error_message "The download failed with wget error code ${wget_result_code}."
                increment_error_count
            fi
        fi
        echo ""

    done < "${static_download_links_edge}"

    return 0
}

return 0  # for sourced files
