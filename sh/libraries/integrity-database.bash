# This file will be sourced by the shell bash.
#
# Filename: integrity-database.bash
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
#     The integrity database is a set of hashdeep files in the directory
#     wsusoffline/client/md. Each hashes file corresponds to one download
#     directory, and each line in the hashes file is a fingerprint of
#     one downloaded file. In WSUS Offline Update, each fingerprint
#     consists of the file size, the MD5, SHA-1 and SHA-256 hashes and
#     the relative path to the md directory, separated with commas.
#
#     The integrity database is verified at the beginning of each
#     download run, then new files are downloaded and obsolete file are
#     removed. Finally, the hashdeep files will be recreated, to match
#     the new directory contents.
#
#     After creating the integrity database, the hashdeep files
#     can be used to verify the integrity of the downloaded
#     files: The SHA-1 hash is embedded into the filename of
#     all security updates, which are extracted from the WSUS
#     offline scan file wsusscn2.cab. For example, if the filename is
#     "ndp35sp1-kb958484-x64_e69006433c1006c53da651914dc8162bbdd80d41.exe",
#     then "e69006433c1006c53da651914dc8162bbdd80d41" is the SHA-1 hash,
#     consisting of 40 hexadecimal digits. hashdeep calculates the SHA-1
#     hashes itself, and then the calculated hashes can be compared to
#     those embedded into the filenames. If the hashes don't match,
#     the damaged files will be deleted, and the corresponding lines
#     excised from the hashdeep file.
#
#     This test is independent of verifying digital file signatures with
#     Sigcheck. It only uses hashdeep and works well on Linux.
#
#     The main purpose of the integrity database is probably the
#     verification of the updates, right before installing them. WSUS
#     Offline Update was once designed to create custom update
#     CDs/DVDs. Then only the installation part of WSUS Offline Update
#     is used - only the files and directories in the client directory
#     are copied to the ISO image file. This way, the client directory
#     of WSUS Offline Update becomes the root directory of the ISO
#     image. The image file is then burned to CDs/DVDs, and these media
#     are used to update the client machines. But recordable CDs/DVDs
#     are not very reliable. The integrity database can then be used to
#     verify the updates again, right before they are installed.
#
#     - https://forums.wsusoffline.net/viewtopic.php?f=3&t=6086

# ========== Configuration ================================================

# In the Windows script DownloadUpdates.cmd, hashdeep always uses
# three hash functions: MD5, SHA-1 and SHA-256. This looks a bit
# over-engineered, and it makes the creation and validation of the
# integrity database rather slow on old machines. The Linux download
# scripts 1.19.4-ESR and 2.3 introduced a new optional "fast mode",
# which only calculates the SHA-1 hash.
#
# As with other permanent settings, the default value is provided here,
# but it should be changed in the file preferences.bash.

fast_mode="${fast_mode:-disabled}"

use_integrity_database="${use_integrity_database:-enabled}"

# ========== Functions ====================================================

# function verify_integrity_database
#
# The existing files in the ../client directory are usually verified
# before downloading new files.
#
# Parameter 1: The hashed directory with a relative path,
#              e.g. ../client/o2k13/glb
# Parameter 2: The hashdeep file with a relative path,
#              e.g. ../client/md/hashes-o2k13-glb.txt

function verify_integrity_database ()
{
    local hashed_dir="$1"
    local hashes_pathname="$2"
    local hashes_filename="${hashes_pathname##*/}"

    mkdir -p "../client/md"

    # Preconditions
    #
    # If the integrity database is disabled in the file preferences.bash,
    # then existing hashdeep files should be removed, because they will
    # become invalid after downloading new and deleting old files.
    if [[ "${use_integrity_database}" == "disabled" ]]
    then
        log_info_message "Verification of the integrity database is disabled in preferences.bash"
        rm -f "${hashes_pathname}"
        return 0
    fi

    log_info_message "Verifying the integrity of existing files in the directory ${hashed_dir} ..."

    # When the script is first run, neither the hashed directory nor
    # the hashes file exist yet. This is not an error; it only means,
    # that the download task must be run once to create the file.
    if ! require_directory "${hashed_dir}"
    then
        log_info_message "The download directory ${hashed_dir} does not exist yet. This is normal during the first run of the script."
        # If the download directory is missing, then the hashdeep file
        # should not exist either.
        if [[ -f "${hashes_pathname}" ]]
        then
            log_warning_message "The file ${hashes_filename} is not valid and will be deleted..."
            rm "${hashes_pathname}"
        fi
        return 0
    fi

    # The function ensure_non_empty_file will delete spurious empty files
    if ! ensure_non_empty_file "${hashes_pathname}"
    then
        log_info_message "The hashdeep file ${hashes_filename} does not exist yet. This is normal during the first run of the script."
        return 0
    fi

    # Create a copy of the hashes file with Linux line endings
    #
    # TODO: This step was necessary, to change the relative paths from
    # Windows to Linux, but it may be skipped now, since hashdeep seems
    # to handle the different line endings itself.
    dos_to_unix < "${hashes_pathname}" > "${temp_dir}/${hashes_filename}"

    if hashdeep -a -vv -k "${temp_dir}/${hashes_filename}"  \
                -b -r "${hashed_dir}" 2>&1                  \
        | tee -a "${logfile}"
    then
        log_info_message "Verified the integrity of existing files in the directory ${hashed_dir}"
    else
        log_file_integrity_verification_error "The directory ${hashed_dir} has changed since last creating the integrity database"
        increment_error_count
        log_warning_message "The file ${hashes_filename} is not valid and will be deleted..."
        rm "${hashes_pathname}"
    fi

    # Integrity database verification errors are only reported and
    # written to the logfile. The script may just go on, because the
    # hashdeep files will be deleted and rebuilt anyway.
    return 0
}


function create_integrity_database ()
{
    local hashed_dir="$1"
    local hashes_pathname="$2"
    local hashes_filename="${hashes_pathname##*/}"
    # The list of hash functions, that hashdeep uses
    local hash_functions=""
    if [[ "${fast_mode}" == "enabled" ]]
    then
        hash_functions="sha1"
    else
        hash_functions="md5,sha1,sha256"
    fi

    mkdir -p "../client/md"

    # Preconditions
    if [[ "${use_integrity_database}" == "disabled" ]]
    then
        log_info_message "Creation of the integrity database is disabled in preferences.bash"
        return 0
    fi

    log_info_message "Creating integrity database for directory ${hashed_dir} ..."
    # Delete existing hashdeep files
    rm -f "${hashes_pathname}"

    if ! require_directory "${hashed_dir}"
    then
        log_warning_message "The creation of the integrity database was aborted, because the directory ${hashed_dir} does not exist."
        return 0
    fi

    # The hashdeep standard output is written to the hashes file,
    # but error output can be duplicated with tee and written to the
    # terminal and the logfile.
    if { hashdeep -c "${hash_functions}" -b -r "${hashed_dir}"  \
            | unix_to_dos                                       \
            > "${hashes_pathname}"
       } 2>&1                                                   \
            | tee -a "${logfile}"
    then
        # Output redirections may create empty files, even if hashdeep
        # does not indicate any error
        if ensure_non_empty_file "${hashes_pathname}"
        then
            log_info_message "Created file ${hashes_filename}"
        else
            log_warning_message "File ${hashes_filename} was empty, probably because no input files were found"
        fi
    else
        log_error_message "Creation of hashdeep file ${hashes_filename} failed"
        increment_error_count
        rm -f "${hashes_pathname}"
    fi

    return 0
}


# function verify_embedded_hashes
#
# This function checks the integrity of the downloaded files by comparing
# the SHA-1 hashes, which are embedded into the filenames of most security
# updates, with the calculated values.
#
# Hashdeep files are CSV-formatted text files. The default field order
# in WSUS Offline Update is:
#
# field 1 = file size
# field 2 = MD5 hash
# field 3 = SHA-1 hash
# field 4 = SHA-256 hash
# field 5 = filename
#
# With the optional "fast mode", the field order is:
#
# field 1 = file size
# field 2 = SHA-1 hash
# field 3 = filename
#
# When reading the hashdeep file, the first five lines with comments are
# skipped. The remaining lines are split into five fields (the last two
# fields may be empty).
#
# Then the variables sha1_calculated and update_filename are used as
# references to the fields above:
#
# - sha1_calculated will point to field_3 in default mode, but to field_2
#   in fast mode
# - update_filename will point to field_5 in default mode, but to field_3
#   in fast mode
#
# Note: The file format could also be detected from the hashes files
# themselves, by examining the fields in the second line. But this doesn't
# seem to be necessary, because the functions create_integrity_database
# and verify_embedded_hashes are run in turn: First a new hashdeep file
# is created, and then the embedded hashes in that file are verified. Then
# both functions will use the same setting for the fast_mode.

function verify_embedded_hashes ()
{
    local hashed_dir="$1"
    local hashes_pathname="$2"
    local hashes_filename="${hashes_pathname##*/}"

    local field_1=""
    local field_2=""
    local field_3=""
    local field_4=""
    local field_5=""
    if [[ "${fast_mode}" == "enabled" ]]
    then
        # Create name references to the fields above
        local -n sha1_calculated="field_2"
        local -n update_filename="field_3"
    else
        local -n sha1_calculated="field_3"
        local -n update_filename="field_5"
    fi
    local sha1_embedded=""
    local -i initial_errors="0"
    initial_errors="$(get_error_count)"

    mkdir -p "../client/md"

    # Preconditions
    if [[ "${use_integrity_database}" == "disabled" ]]
    then
        log_info_message "Verification of embedded hashes is disabled in preferences.bash"
        return 0
    fi

    log_info_message "Verifying embedded SHA1 hashes for directory ${hashed_dir} ..."

    if ! require_directory "${hashed_dir}"
    then
        log_warning_message "The verification of embedded hashes was aborted, because the directory ${hashed_dir} does not exist."
        if [[ -f "${hashes_pathname}" ]]
        then
            log_warning_message "The file ${hashes_filename} is not valid and will be deleted..."
            rm "${hashes_pathname}"
        fi
        return 0
    fi

    if ! ensure_non_empty_file "${hashes_pathname}"
    then
        log_warning_message "The hashdeep file ${hashes_filename} does not exist."
        return 0
    fi

    # Extract filenames with embedded SHA-1 hashes from the hashdeep
    # file. The search pattern consists of an underscore, the SHA-1 hash
    # (40 hexadecimal digits) and the file extension.
    #
    # The first five lines of the hashdeep file are skipped, because
    # they only contain comments.
    #
    # Carriage returns are removed by the wrapper function tail_dos.
    tail_dos -n +6 "${hashes_pathname}"                    \
        | grep -E -e '_[[:xdigit:]]{40}[.][[:alpha:]]{3}'  \
        > "${temp_dir}/sha-1-${hashes_filename}"           \
        || true

    # Tell shellcheck to not complain about "unused variables"
    # shellcheck disable=SC2034
    while IFS=',' read -r field_1 field_2 field_3 field_4 field_5
    do
        # Extract the embedded SHA-1 hash from the filename. GNU grep
        # could conveniently use:
        #
        # grep -E --only-matching '[[:xdigit:]]{40}'
        #
        # but this was replaced with sed for compatibility. Extended
        # regular expressions work the same as basic regular expressions,
        # but parentheses and curly brackets don't need to be escaped.
        sha1_embedded="$( sed -E -e 's/.*_([[:xdigit:]]{40}).*/\1/' <<< "${update_filename}" || true )"
        # Compare the embedded SHA-1 hashes with those calculated
        # by hashdeep
        if [[ "${sha1_calculated}" != "${sha1_embedded}" ]]
        then
            log_error_message "Trashing/deleting file ${update_filename} due to mismatching SHA-1 message digests..."
            increment_error_count
            trash_file "${hashed_dir}/${update_filename}"

            # Rewrite the original hashes file (not the copy in the
            # temporary directory) without the deleted file.
            sed -i.bak -e "/${update_filename}/d" "${hashes_pathname}"
            rm -f "${hashes_pathname}.bak"
        fi
    done < "${temp_dir}/sha-1-${hashes_filename}"

    if same_error_count "${initial_errors}"
    then
        log_info_message "Verified embedded SHA1 hashes"
    else
        log_warning_message "Verification of embedded SHA1 hashes detected $(get_error_difference "${initial_errors}") errors"
    fi
    return 0
}

return 0
