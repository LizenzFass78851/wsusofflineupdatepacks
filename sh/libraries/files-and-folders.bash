# This file will be sourced by the shell bash.
#
# Filename: files-and-folders.bash
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
#     This library provides functions to work with files and folders.
#
#     The functions sort_in_place and remove_duplicates are simple
#     wrappers for "sort" and "uniq".
#
#     The functions require_directory, require_file,
#     require_non_empty_file and ensure_non_empty_file test the
#     pre-conditions and post-conditions of other functions. They could
#     be replaced with simple tests, but they produce useful diagnostic
#     output when needed, and they also recognize the placeholder
#     "not-available", which is often used to initialize variables for
#     files and directories.


# The function sort_in_place sorts a file with "sort --unique".
#
# Generally, files should be sorted by the first field only, if they
# are matched with join later. But in WSUS Offline Update, most files
# can also be sorted by the whole line:
#
# The FileId is actually the SHA-1 hash of the file in Base64
# text encoding. It has a fixed length, and then the file
# UpdateCabExeIdsAndLocations.txt can be sorted by the whole line.
#
# Similarly, appending a number sign "#" to the end of a number field
# stabilizes the search, if the numbers have different lengths, because
# the number sign comes before all alphanumerical characters in a
# traditional C sort by the byte order (LC_ALL=C).

function sort_in_place ()
{
    if [[ -f "$1" ]]
    then
        sort -u "$1" > "$1.tmp" &&
        mv "$1.tmp" "$1"
    else
        log_debug_message "${FUNCNAME[0]}: File $1 was not found."
    fi
    return 0
}


function remove_duplicates ()
{
    if [[ -f "$1" ]]
    then
        uniq "$1" > "$1.tmp" &&
        mv "$1.tmp" "$1"
    else
        log_debug_message "${FUNCNAME[0]}: File $1 was not found."
    fi
    return 0
}


# Require an existing directory
#
# Result codes:
#   0 if the directory was found
#   1 otherwise
function require_directory ()
{
    local pathname="$1"
    local result_code=0

    if [[ -z "${pathname}" ]]
    then
        log_debug_message "${FUNCNAME[1]}: The pathname is empty"
        result_code=1
    elif [[ "${pathname}" == "not-available" ]]
    then
        log_debug_message "${FUNCNAME[1]}: The pathname is set to \"not-available\""
        result_code=1
    elif [[ -d "${pathname}" ]]
    then
        log_debug_message "${FUNCNAME[1]}: Found directory \"${pathname}\""
        result_code=0
    else
        log_debug_message "${FUNCNAME[1]}: Directory \"${pathname}\" was not found"
        result_code=1
    fi
    return ${result_code}
}

# Require an input file, which can possibly be empty
#
# Result codes:
#   0 if the file was found
#   1 otherwise
function require_file ()
{
    local pathname="$1"
    local result_code=0

    if [[ -z "${pathname}" ]]
    then
        log_debug_message "${FUNCNAME[1]}: The pathname is empty"
        result_code=1
    elif [[ "${pathname}" == "not-available" ]]
    then
        log_debug_message "${FUNCNAME[1]}: The pathname is set to \"not-available\""
        result_code=1
    elif [[ -f "${pathname}" ]]
    then
        log_debug_message "${FUNCNAME[1]}: Found file \"${pathname}\""
        result_code=0
    else
        log_debug_message "${FUNCNAME[1]}: File \"${pathname}\" was not found"
        result_code=1
    fi
    return ${result_code}
}

# Require an input file, which is not empty. Empty files are reported to
# debug output but not deleted.
#
# Result codes:
#   0 if the file was found and is not empty
#   1 otherwise
function require_non_empty_file ()
{
    local pathname="$1"
    local result_code=0

    if [[ -z "${pathname}" ]]
    then
        log_debug_message "${FUNCNAME[1]}: The pathname is empty"
        result_code=1
    elif [[ "${pathname}" == "not-available" ]]
    then
        log_debug_message "${FUNCNAME[1]}: The pathname is set to \"not-available\""
        result_code=1
    elif [[ -s "${pathname}" ]]
    then
        log_debug_message "${FUNCNAME[1]}: Found non-empty file \"${pathname}\""
        result_code=0
    elif [[ -f "${pathname}" ]]
    then
        log_debug_message "${FUNCNAME[1]}: Found empty file \"${pathname}\""
        result_code=1
    else
        log_debug_message "${FUNCNAME[1]}: File \"${pathname}\" was not found"
        result_code=1
    fi
    return ${result_code}
}

# The function ensure_non_empty_file is called at the end of a function,
# to make sure, that an output file larger than 0 was created. Empty
# files will be deleted. In this case, the function prints a warning.
#
# Result codes:
#   0 if the file was created and is not empty
#   1 otherwise
function ensure_non_empty_file ()
{
    local pathname="$1"
    local result_code=0

    if [[ -z "${pathname}" ]]
    then
        log_debug_message "${FUNCNAME[1]}: The pathname is empty"
        result_code=1
    elif [[ "${pathname}" == "not-available" ]]
    then
        log_debug_message "${FUNCNAME[1]}: The pathname is set to \"not-available\""
        result_code=1
    elif [[ -s "${pathname}" ]]
    then
        log_debug_message "${FUNCNAME[1]}: Found non-empty file \"${pathname}\""
        result_code=0
    elif [[ -f "${pathname}" ]]
    then
        log_debug_message "${FUNCNAME[1]}: Deleted file \"${pathname##*/}\", because it was empty"
        log_warning_message "Deleted file \"${pathname##*/}\", because it was empty"
        rm "${pathname}"
        result_code=1
    else
        log_debug_message "${FUNCNAME[1]}: File \"${pathname}\" was not found"
        result_code=1
    fi
    return ${result_code}
}

# The function apply_exclude_lists applies one or more exclude lists to
# an input file with static or dynamic links to create the output file
# with valid static or dynamic links.
#
# The exclude lists usually contain the KB numbers only. Therefore, a
# grep --inverted-match must be used to remove lines with these numbers
# from the input file.
#
# The exclude list for superseded updates is handled more efficiently with
# the utility "join". This utility should also be used in other cases,
# where the input file and the exclude list share the same format. Then a
# "left join" will be more efficient than an inverted grep.
#
# Positional parameters
#
# 1. The input file, for example "current_dynamic_links"
# 2. The output file, for example "valid_dynamic_links", after applying
#    the exclude lists
# 3. The name of the temporary file combining all exclude lists. This
#    is often the name of the first exclude list, which is copied to
#    the temporary directory as a first step.
# 4. The remaining parameters are the single exclude lists. These files
#    must be specified with their relative paths, e.g. ../exclude and
#    ../exclude/custom must both be specified. This is different from
#    the version in beta-1.
#
# Additional requirements
#
# - All configuration files in WSUS Offline Update use DOS line
#   endings. The carriage return must be removed during read.
# - Some input files, like StaticUpdateIds-w61-seconly.txt and
#   HideList-seconly.txt, combine the kb number and a description,
#   separated by a comma. Only the first field should be extracted
#   from these files. If there is no comma, then the whole line should
#   be copied.
# - In Community Editions 11.9.8-ESR and 12.5, a semicolon may be used
#   as an alternate or additional field delimiter.
#
# These conditions can be met by setting IFS (Internal Field Separator)
# to a comma, semicolon, carriage return and line feed. Then the bash
# reads each line into two variables:
#
# - The first variable gets the first field, if field delimiters are used,
#   or the complete line, if no delimiters are found.
# - The variable ship_rest gets the rest of the line, if field delimiters
#   are used. This will be the optional description (which itself may
#   contain more commas).
# - Carriage returns are treated as field separators and will be removed
#   from input.
#
# This also handles some unusual conditions:
#
# - If the file does not end with a cr/lf pair, then the end-of-file
#   will still close the read.
# - Additional empty lines and files, which only consist of one cr/lf
#   pair, can be detected by testing the length of variable first_field:
#   Only non-empty fields are written to the output file.

function apply_exclude_lists ()
{
    local input_file="$1"
    local output_file="$2"
    local combined_exclude_list="$3"
    local current_file=""
    local first_field=""
    local skip_rest=""

    rm -f "${output_file}"
    rm -f "${combined_exclude_list}"
    require_non_empty_file "${input_file}" || return 0
    log_debug_message "apply_exclude_lists:"  \
        " - input file     ${input_file}"     \
        " - output file    ${output_file}"    \
        " - combined list  ${combined_exclude_list}"

    shift 3
    if (( $# > 0 ))
    then
        # Scan the different exclude lists and add their contents to a
        # combined exclude list.
        log_debug_message "Searching $# exclude lists..."
        for current_file in "$@"
        do
            # Report all files for better debugging, even if they
            # are empty
            if [[ -f "${current_file}" ]]
            then
                log_debug_message "Found      ${current_file}"
            else
                log_debug_message "Not found  ${current_file}"
            fi
            # Check for non-empty files
            if [[ -s "${current_file}" ]]
            then
                # Tell shellcheck to ignore the "unused" variable
                # skip_rest
                # shellcheck disable=SC2034
                while IFS=$',;\r\n' read -r first_field skip_rest
                do
                    if [[ -n "${first_field}" ]]
                    then
                        printf '%s\n' "${first_field}"
                    fi
                done < "${current_file}" >> "${combined_exclude_list}"
            fi
        done
        log_debug_message "Done searching exclude lists"
    fi

    if [[ -s "${combined_exclude_list}" ]]
    then
        # Remove the combined exclude list from the input file using a
        # grep --inverted-match (grep -v). The result code of grep is
        # "1", if the output is empty. This must be masked, if the shell
        # option errexit or a trap on ERR is used.
        log_debug_message "Removing the combined exclude list from input file..."
        grep -F -i -v -f "${combined_exclude_list}" \
            "${input_file}" > "${output_file}" || true
    else
        # Rename the input file to the output file
        log_debug_message "Renaming input file to output file..."
        mv "${input_file}" "${output_file}"
    fi

    # In some cases, the output file may be empty. For example, static
    # download links are typically used for service packs. If service
    # packs are excluded from download, then the list of valid static
    # links may be empty. This may happen with the download directories
    # for Office 2013 and 2016.
    ensure_non_empty_file "${output_file}" || true

    return 0
}


# The function verify_cabinet_file uses cabextract -t, to ensure that all
# archive contents can be extracted. If some files could not extracted,
# cabextract will report checksum errors and set the result code to 1.

function verify_cabinet_file ()
{
    local pathname="$1"
    local filename="${pathname##*/}"
    local -i result_code="0"

    log_info_message "Testing the integrity of the cabinet file ${filename} (ignore any warnings about extra bytes at end of file)..."
    if [[ -f "${pathname}" ]]
    then
        echo ""
        if cabextract -t "${pathname}"
        then
            log_info_message "The integrity test of cabinet file ${filename} succeeded."
        else
            log_error_message "Trashing/deleting cabinet file ${filename}, because the integrity test failed."
            trash_file "${pathname}"
            result_code="1"
        fi
    else
        log_warning_message "The cabinet file ${pathname} was not found."
        result_code="1"
    fi
    return "${result_code}"
}


# The function create_backup_copy makes a backup copy of an existing file,
# preserving the file modification date and other meta-data.
#
# TODO: For recent versions of Wget, this copy could actually be a hard
# link. Wget can delete existing files first with the option --unlink,
# which is explicitly meant for directories with hard links. But this
# option is missing in older version of Wget. Aria 2 also has different
# options for the allocation of files.

function create_backup_copy ()
{
    local pathname="$1"

    if [[ -f "${pathname}" ]]
    then
        log_info_message "Creating a backup copy of ${pathname##*/} ..."
        cp -a "${pathname}" "${pathname}.bak"
    else
        # This function is used for the WSUS offline scan file
        # wsusscn2.cab and the four virus definition files.
        #
        # These files may not exist yet, if the download script is
        # running for the first time. This is not an error.
        log_debug_message "create_backup_copy: The file ${pathname} was not found."
    fi
    return 0
}


# The function restore_backup_copy restores the backup copy, if the
# original file does not exist.
#
# If both files exist, then the modification date will be compared and
# the newer file will be kept.
#
# Otherwise, the backup copy (if any) will be deleted.
#
# Usually, the newly downloaded file is expected to be the newer file,
# but this is not necessarily true for the virus definition files, if
# they are downloaded with old versions of GNU Wget: These files change
# every two hours, and there may be up to three different versions in
# the Microsoft delivery network.
#
# This is not handled well by GNU Wget up to version 1.16:
#
# - GNU Wget 1.16 always use two server requests, HEAD and GET, for
#   timestamping. The first request is used to get the file headers
#   and to compare the file length and modification dates. The second
#   request is used to download the file. But in a content delivery
#   network, different servers may give different answers. The first
#   server may offer a newer file, but when Wget tries to download it,
#   it may get a different version: sometimes an older file, or it may
#   just download the existing file again.
# - GNU Wget 1.16 will always download a file, whenever the file size
#   changes, regardless of the file modification date. This may replace
#   a newer file with an older version of the same file.
#
# This is only a problem with the specific combination of the virus
# definition files and old versions of GNU Wget, if these downloads are
# retried within a few hours.
#
# GNU Wget 1.18 and late use a single server request for timestamping,
# a GET query with the conditional header If-Modified-Since. Then the
# server can decide, if the file needs to be downloaded. (I never tried
# GNU Wget 1.17, since this version was never used by Debian Linux).

function restore_backup_copy ()
{
    local pathname="$1"

    if [[ -f "${pathname}.bak" ]]
    then
        # According to the bash manual, the operator -nt is true, if file1
        # is newer than file2, or if file1 exists and file2 does not.
        if [[ "${pathname}.bak" -nt "${pathname}" ]]
        then
            log_info_message "Restoring backup copy of ${pathname##*/}"
            mv "${pathname}.bak" "${pathname}"
        else
            rm "${pathname}.bak"
        fi
    fi
    return 0
}


function get_catalog_creationdate ()
{
    local creation_date=""

    if [[ -f "../client/catalog-creationdate.txt" ]]
    then
        IFS=$'\r\n' read -r creation_date < "../client/catalog-creationdate.txt"
        log_info_message "CreationDate of the update catalog file: ${creation_date}"
    else
        log_warning_message "The file catalog-creationdate.txt was not found."
    fi

    return 0
}


# The function xml_transform was designed with simplicity in mind. It
# uses three parameters:
#
# $1 is the filename of the XSLT transformation file
# $2 is the filename of the output file
# $3 is the target directory for the output file. This parameter is
#    optional, and the default is the temporary directory of the script.
#
# The script then does some common steps, which are needed for most
# XSLT transformations:
#
# - It searches the XSLT transformation file in ./xslt and ../xslt; this
#   means, a private directory of the Linux scripts and the directory
#   wsusoffline/xslt.
# - It checks the file package.xml
# - It creates the output file by applying the XSLT transformation file
#   to package.xml
# - It sorts the output file by the whole line, removing any duplicates

function xml_transform ()
{
    local xslt_filename="$1"         # only the filename without path
    local output_filename="$2"       # only the filename without path
    local output_directory="${3:-}"  # optional, default is ${temp_dir}
    local output_pathname=""
    local current_dir=""
    local xslt_directory=""
    local xslt_pathname=""

    # Check requirements
    if ! require_file "${cache_dir}/package.xml"
    then
        log_error_message "The file package.xml was not found."
        exit 1
    fi

    # If the output directory was not specified, set it to the temporary
    # directory of the script
    if [[ -z "${output_directory}" ]]
    then
        output_directory="${temp_dir}"
    fi

    mkdir -p "${output_directory}"
    output_pathname="${output_directory}/${output_filename}"

    # Search the private and the wsusoffline xslt directories for the
    # xslt file
    for current_dir in ./xslt ../xslt
    do
        if [[ -f "${current_dir}/${xslt_filename}" ]]
        then
            xslt_directory="${current_dir}"
            break
        fi
    done

    if [[ -z "${xslt_directory}" ]]
    then
        log_error_message "The file ${xslt_filename} was not found in either ./xslt or ../xslt"
        exit 1
    fi
    xslt_pathname="${xslt_directory}/${xslt_filename}"

    # The output file should only be extracted, if it does not already
    # exist. Often, these files can be reused in another context.
    if [[ -f "${output_pathname}" ]]
    then
        log_info_message "Skipped the extraction of ${output_filename}, because it already exists"
    else
        log_debug_message "Extracting ${output_filename} ..."

        "${xmlstarlet}" transform       \
            "${xslt_pathname}"          \
            "${cache_dir}/package.xml"  \
          > "${output_pathname}.unsorted"

        log_debug_message "Sorting ${output_filename} ..."
        sort -u "${output_pathname}.unsorted" > "${output_pathname}"

        if ensure_non_empty_file "${output_pathname}"
        then
            log_info_message "Created file ${output_filename}"
        fi
    fi
    return 0
}

# The function extract_ids_and_filenames expects a file
# update-ids-and-locations-*.txt as input and extracts the update ids
# and filenames. The resulting file UpdateTable-*.csv is written with
# DOS or Linux line-endings, depending on the output path:
# - files in the directory ../client/UpdateTable use DOS line-endings,
#   for compatibility with the installation scripts
# - temporary files use Linux line-endings
function extract_ids_and_filenames ()
{
    local inputfile="$1"
    local outputfile="$2"
    local update_id=""
    local url=""
    local skip_rest=""

    require_file "${inputfile}" || fail "File ${inputfile} was not found"

    case "${outputfile}" in
        ../client/UpdateTable/*)
            while IFS=',' read -r update_id url skip_rest
            do
                printf '%s\r\n' "${update_id},${url##*/}"
            done < "${inputfile}" \
                 > "${outputfile}"
        ;;
        *)
            while IFS=',' read -r update_id url skip_rest
            do
                printf '%s\n' "${update_id},${url##*/}"
            done < "${inputfile}" \
                 > "${outputfile}"
        ;;
    esac
    return 0
}


function extract_filenames ()
{
    local inputfile="$1"
    local outputfile="$2"
    local url=""
    local skip_rest=""

    if [[ -s "${inputfile}" ]]
    then
        while read -r url skip_rest
        do
            printf '%s\n' "${url##*/}"
        done < "${inputfile}" \
             > "${outputfile}"
    else
        :
        #debug=enabled log_debug_message "The file ${inputfile##*/} was not found or is empty."
    fi
    return 0
}


# The functions in_array tests, if a search-term is a member of the
# specified array
#
# Usage: in_array "${search_term}" "${array[@]}"

function in_array ()
{
    if (( $# < 2 ))
    then
        fail "function in_array: at least two parameters are expected."
    fi

    local -i result_code="1" # assume false
    local search_term="$1"
    shift 1

    local array_element=""
    for array_element in "$@"
    do
        if [[ "${array_element}" == "${search_term}" ]]
        then
            result_code="0"
        fi
    done
    return "${result_code}"
}


return 0
