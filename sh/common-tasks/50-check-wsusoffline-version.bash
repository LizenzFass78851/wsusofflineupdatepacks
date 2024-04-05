# This file will be sourced by the shell bash.
#
# Filename: 50-check-wsusoffline-version.bash
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
#     This script checks for new versions of WSUS Offline Update and
#     installs them on demand.
#
#     By default, it doesn't install new versions without
#     confirmation. Therefore, the question to ask for confirmation
#     defaults to "no" after 30 seconds.
#
#     This behavior can be reversed by setting the variable
#     "unattended_updates" to "enabled" in the file preferences.bash. Then
#     the script will still notify the user about new versions and ask
#     for confirmation, but this time the question defaults to "yes"
#     after 30 seconds.
#
#     Sometimes, it may be preferable, to keep WSUS Offline Update at
#     a certain version, for example to support downloads which are no
#     longer supported by more recent versions. Then all updates can
#     be disabled by setting "check_for_self_updates" to "disabled"
#     in the preferences file.

# ========== Configuration ================================================

# URLs for the development branch "esr-11.9"
self_update_index="https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/SelfUpdateVersion-recent.txt"
self_update_links="https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/StaticDownloadLink-recent.txt"

# ========== Global variables =============================================

# Version strings
#
# Version "numbers" are strings like "12.0" or "12.1.1", which cannot be
# assigned to integer numbers in the bash. They are converted to integer
# numbers later for an easier comparison.
installed_version="not-available"
available_version="not-available"
# The type can be "beta" (for development versions) or "release"
installed_type=""
available_type=""

wsusoffline_timestamp="${timestamp_dir}/check-wsusoffline-version.txt"

# ========== Functions ====================================================

# The current version is in the file ../static/SelfUpdateVersion-this.txt,
# which is installed with the zip archive of WSUS Offline Update. This
# file replaces the older file StaticDownloadLink-this.txt.

function get_installed_version ()
{
    local skip_rest=""
    # Reset global variables
    installed_version="not-available"
    installed_type=""

    log_info_message "Searching for the installed version of WSUS Offline Update..."
    if require_non_empty_file "../static/SelfUpdateVersion-this.txt"
    then
        IFS=$'\r\n,' read -r installed_version  \
                             installed_type     \
                             skip_rest          \
                             < "../static/SelfUpdateVersion-this.txt"
        # Corrections for compatibility with version 11.9.1esr and 11.9.2,
        # which included the archive filename in the second field
        installed_version="${installed_version%esr}"
        installed_type="${installed_type#wsusofflineCE1191.zip}"
        installed_type="${installed_type#wsusofflineCE1192.zip}"
        #log_debug_message "Installed version=${installed_version}, installed type=${installed_type}, skipped fields=${skip_rest}"
    else
        log_warning_message "The file SelfUpdateVersion-this.txt was not found."
    fi
    return 0
}


# The most recent available version is in the file
# SelfUpdateVersion-recent.txt, which will be downloaded from GitLab to
# the directory ../static/.
#
# The download links for the archive and the hashes files are in the
# file StaticDownloadLink-recent.txt.

function get_available_version ()
{
    local skip_rest=""
    local -i initial_errors="0"
    initial_errors="$(get_error_count)"
    # Reset global variables
    available_version="not-available"
    available_type=""

    log_info_message "Searching for the most recent version of WSUS Offline Update..."
    download_from_gitlab "../static" "${self_update_index}"
    download_from_gitlab "../static" "${self_update_links}"
    if same_error_count "${initial_errors}"
    then
        if require_non_empty_file "../static/SelfUpdateVersion-recent.txt"
        then
            IFS=$'\r\n,' read -r available_version  \
                                 available_type     \
                                 skip_rest          \
                                 < "../static/SelfUpdateVersion-recent.txt"
            #log_debug_message "Available version=${available_version}, available type=${available_type}, skipped fields=${skip_rest}"
        else
            log_warning_message "The file SelfUpdateVersion-recent.txt was not found."
        fi
    else
        log_warning_message "The online check for the most recent version of WSUS Offline Update failed."
    fi
    return 0
}


# The function wsusoffline_initial_installation downloads and installs
# the most recent version of WSUS Offline Update, if there is no version
# installed yet.
#
# Since the Linux download scripts depend on the configuration files
# in the static, exclude and xslt directories, this test should always
# be done first.

function wsusoffline_initial_installation
{
    local answer=""

    if require_non_empty_file "../static/SelfUpdateVersion-this.txt"
    then
        # Silently skip this check, because WSUS Offline Update is
        # already installed
        return 0
    fi

    log_info_message "There is no version of WSUS Offline Update installed yet."

    # Search for the most recent version of WSUS Offline Update
    get_available_version
    if [[ "${available_version}" == "not-available" ]]
    then
        log_error_message "The most recent version of WSUS Offline Update could not be determined. The script will quit now."
        exit 1
    fi

    log_info_message "The most recent version of WSUS Offline Update is ${available_version}."
    if [[ "${home_directory}" == */sh ]]
    then
        log_error_message "For an initial installation of wsusoffline by the Linux scripts, you should NOT rename the script directory to \"sh\", because this directory will be overwritten during installation. This may replace the running script with a previous version."
        log_error_message "The script will exit now."
        exit 1
    fi

    log_warning_message "Note, that the wsusoffline archive will be unpacked OUTSIDE of the Linux scripts directory. At this point, you should have created an enclosing directory, which contains the Linux scripts directory, and which will also get the contents of the wsusoffline archive."
    log_warning_message "The target directory, to which the wsusoffline archive will be extracted, is \"${wsusoffline_directory}\". Do you wish to proceed and install the wsusoffline archive into this directory?"
    read -r -p "[Y|n]: " answer || true
    case "${answer:-Y}" in
        [Yy]*)
            log_info_message "Starting an initial installation of WSUS Offline Update..."
            wsusoffline_self_update
        ;;
        [Nn]*)
            log_info_message "The initial installation of WSUS Offline Update was not confirmed. The script will quit now."
            exit 0
        ;;
        *)
            log_warning_message "Unknown answer. The initial installation of WSUS Offline Update was not confirmed. The script will quit now."
            exit 0
        ;;
    esac

    return 0
}


# The function compare_wsusoffline_versions does an online check for
# new versions of WSUS Offline Update, similar to the Windows script
# CheckOUVersion.cmd.
#
# It compares the files SelfUpdateVersion-this.txt and
# SelfUpdateVersion-recent.txt to check, if a new version is available.
#
# This test is done once daily, and it can be disabled by setting the
# variable check_for_self_updates to "disabled".

function compare_wsusoffline_versions ()
{
    local -i interval_length="${interval_length_configuration_files}"
    local interval_description="${interval_description_configuration_files}"
    local -i installed_version_int="0"
    local -i available_version_int="0"

    if [[ "${check_for_self_updates}" == "disabled" ]]
    then
        log_info_message "Searching for new versions of WSUS Offline Update is disabled in preferences.bash"
        return 0
    fi

    if same_day "${wsusoffline_timestamp}" "${interval_length}"
    then
        log_info_message "Skipped searching for new versions of WSUS Offline Update, because it has already been done less than ${interval_description} ago"
        return 0
    fi

    # Get the installed version of WSUS Offline Update
    get_installed_version
    if [[ "${installed_version}" == "not-available" ]]
    then
        log_error_message "The installed version of WSUS Offline Update could not be determined. The script will quit now."
        exit 1
    fi

    # Search for the most recent version of WSUS Offline Update
    get_available_version
    if [[ "${available_version}" == "not-available" ]]
    then
        log_warning_message "The most recent version of WSUS Offline Update could not be determined."
        # The timestamp is not updated, if there was an error
        # with the online check. Then the online check will be
        # repeated on the next run.
        return 0
    fi

    # Convert the version strings to integer numbers
    installed_version_int="$( version_string_to_number "${installed_version}" )"
    available_version_int="$( version_string_to_number "${available_version}" )"
    #log_debug_message "Installed version: ${installed_version} = ${installed_version_int}"
    #log_debug_message "Available version: ${available_version} = ${available_version_int}"

    # Disregard development (beta) versions
    #
    # Technically, it may be possible, to upgrade a development version
    # to a release version of the same version number, but this is
    # not recommended:
    # - It will leave a messed up wsusoffline directory behind.
    #   Development versions install more files and directories, which
    #   are no longer used in the release versions, but these additional
    #   files will not be removed.
    # - Users, who use a beta version, may prefer to update to the next
    #   beta version. Installing a release version will be a dead end in
    #   this case, because release versions won't be upgraded to newer
    #   beta versions.
    if [[ "${installed_type}" == "beta" ]]
    then
        log_warning_message "Upgrading development (beta) versions is not supported by this script"
        # The timestamp is updated here, to do the version check only
        # once daily.
        update_timestamp "${wsusoffline_timestamp}"
        return 0
    fi

    # Compare versions
    if (( installed_version_int == available_version_int ))
    then
        # After excluding beta versions, release versions may be replaced
        # with hotfix versions.
        if [[ "${installed_type}" == "${available_type}" ]]
        then
            log_info_message "No newer version of WSUS Offline Update found"
            update_timestamp "${wsusoffline_timestamp}"
        else
            confirm_wsusoffline_self_update
        fi
    elif (( installed_version_int < available_version_int ))
    then
        confirm_wsusoffline_self_update
    else
        log_warning_message "The installed version is newer than the latest available release version. This may happen, if the development (beta) versions are installed."
        update_timestamp "${wsusoffline_timestamp}"
    fi

    return 0
}


# Convert version strings like 12.0 and 11.9.1 to decimal numbers,
# which are easier to compare. The results would be, for example:
#
# 11.9.1  ->  110901
# 11.9.2  ->  110902
# 12.0    ->  120000
# 12.1    ->  120100
# 12.1.1  ->  120101

function version_string_to_number ()
{
    local version_string="$1"
    local first="0"
    # The local variables "second" and "third" must not be integer
    # variables, or the assignment will fail, if the numbers are padded
    # with zeroes
    local second="0"
    local third="0"
    local -i version_number="0"

    # Split the version string into three numbers
    IFS="." read -r first second third <<< "${version_string}"

    # Pad the second and third number with leading zeroes to two digits
    second="$( printf '%02d\n' "${second}" )"
    third="$(  printf '%02d\n' "${third}" )"

    # Join the three parts to a decimal version number
    version_number="${first}${second}${third}"

    # Print the version number to standard output
    printf '%s\n' "${version_number}"
    return 0
}


function confirm_wsusoffline_self_update ()
{
    local answer=""

    log_info_message "A new version of WSUS Offline Update is available:"
    log_info_message "- Installed version: ${installed_version} ${installed_type}"
    log_info_message "- Available version: ${available_version} ${available_type}"

    log_info_message "Do you want to install the new version now?"
    if [[ "${unattended_updates:-disabled}" == enabled ]]
    then
        cat <<EOF
---------------------------------------------------------------------------
Note: This question automatically selects "Yes" after 30 seconds, to
install the new version and then restart the script. This is also the
default answer, if you simply hit return.
---------------------------------------------------------------------------
EOF
        read -r -p "[Y|n]: " -t 30 answer || true
        case "${answer:-Y}" in
            [Yy]*)
                log_info_message "Starting wsusoffline self update..."
                wsusoffline_self_update
            ;;
            [Nn]*)
                log_info_message "Self update not confirmed."
                # If the installation was explicitly canceled, then the
                # timestamp will be updated. The online check will be
                # repeated after one day.
                update_timestamp "${wsusoffline_timestamp}"
            ;;
            *)
                log_warning_message "Unknown answer. Self update not confirmed."
                # The timestamp will not be updated for unknown
                # answers. Then the online check will be repeated on
                # the next run.
            ;;
        esac
    else
        cat <<EOF
---------------------------------------------------------------------------
Note: This question automatically selects "No" after 30 seconds, to skip
the pending self-update and let the script continue. This is also the
default answer, if you simply hit return.
---------------------------------------------------------------------------
EOF
        read -r -p "[y|N]: " -t 30 answer || true
        case "${answer:-N}" in
            [Yy]*)
                log_info_message "Starting wsusoffline self update..."
                wsusoffline_self_update
            ;;
            [Nn]*)
                log_info_message "Self update not confirmed."
                update_timestamp "${wsusoffline_timestamp}"
            ;;
            *)
                log_warning_message "Unknown answer. Self update not confirmed."
            ;;
        esac
    fi

    return 0
}


function wsusoffline_self_update ()
{
    local -a file_list=()
    local current_item=""
    local url=""
    local filename=""
    local archive_filename="not-available"
    local hashes_filename="not-available"
    local -i initial_errors="0"
    initial_errors="$(get_error_count)"

    # Download archive and hashes file to the ../cache directory. This
    # prevents errors, when the download needs to be restarted, and
    # another temporary directory with a random name is created.
    #
    # Formerly, the download and validation of the archive was done by
    # the function download_and_verify, but it is now handled inline,
    # because GitLab does not support timestamping.
    if require_non_empty_file "../static/StaticDownloadLink-recent.txt"
    then
        log_info_message "Downloading archive and accompanying hashes file..."
        while IFS=$'\r\n' read -r url
        do
            filename="${url##*/}"
            case "${filename}" in
                *.zip)        archive_filename="${filename}";;
                *_hashes.txt) hashes_filename="${filename}";;
                *)            log_error_message "File type of ${filename} was not recognized.";;
            esac
            download_from_gitlab "${cache_dir}" "${url}"
        done < "../static/StaticDownloadLink-recent.txt"
        same_error_count "${initial_errors}" || exit 1
    else
        log_warning_message "The file StaticDownloadLink-recent.txt was not found"
        return 0
    fi

    log_info_message "Searching downloaded files..."
    if [[ -f "${cache_dir}/${archive_filename}" ]]
    then
        log_info_message "Found archive:     ${cache_dir}/${archive_filename}"
    else
        log_error_message "Archive ${archive_filename} was not found"
        exit 1
    fi

    if [[ -f "${cache_dir}/${hashes_filename}" ]]
    then
        log_info_message "Found hashes file: ${cache_dir}/${hashes_filename}"
    else
        log_error_message "Hashes file ${hashes_filename} was not found"
        exit 1
    fi

    # Validate the archive using hashdeep in audit mode (-a). The bare
    # mode (-b) removes any leading directory information. This enables
    # us to check files without changing directories with pushd/popd.
    log_info_message "Verifying the integrity of the archive ${archive_filename} ..."
    if hashdeep -a -b -v -v -k "${cache_dir}/${hashes_filename}" "${cache_dir}/${archive_filename}"
    then
        log_info_message "Validated archive ${archive_filename}"
    else
        log_error_message "Validation failed"
        exit 1
    fi

    # The zip archive should be unpacked to the temporary directory;
    # if there is already a directory "wsusoffline", it will be removed
    # first.
    if [[ -d "${temp_dir}/wsusoffline" ]]
    then
        rm -r "${temp_dir}/wsusoffline"
    fi

    log_info_message "Unpacking zip archive..."
    unzip -q "${cache_dir}/${archive_filename}" -d "${temp_dir}" || exit 1

    log_info_message "Searching unpacked directory..."
    if [[ -d "${temp_dir}/wsusoffline" ]]
    then
        log_info_message "Found directory: ${temp_dir}/wsusoffline"
    else
        log_error_message "Directory ${temp_dir}/wsusoffline was not found"
        exit 1
    fi

    # Copy new files and directories to the WSUS Offline Update
    # installation directory, which is "outside" of the Linux scripts
    # directory.
    log_info_message "Copying new files to ${wsusoffline_directory} ..."
    shopt -s nullglob
    file_list=( "${temp_dir}/wsusoffline"/* )
    shopt -u nullglob

    if (( "${#file_list[@]}" > 0 ))
    then
        for current_item in "${file_list[@]}"
        do
            log_info_message "Copying ${current_item} ..."
            cp -a "${current_item}" "${wsusoffline_directory}"
        done
    fi

    # Reevaluating the installed version
    get_installed_version
    if [[ "${installed_version}" == "not-available" ]]
    then
        log_error_message "The installed version of WSUS Offline Update could not be determined."
        exit 1
    fi

    # Recompare the installed and available versions
    log_info_message "Recomparing WSUS Offline Update versions:"
    log_info_message "- Installed version: ${installed_version} ${installed_type}"
    log_info_message "- Available version: ${available_version} ${available_type}"

    if [[ "${installed_version}" == "${available_version}" ]] \
        && [[ "${installed_type}" == "${available_type}" ]]
    then
        log_info_message "The most recent version of WSUS Offline Update was installed successfully"

        # Post-processing
        check_custom_static_links
        normalize_file_permissions
        reschedule_updates_after_wou_update
        update_timestamp "${wsusoffline_timestamp}"
        restart_script
    else
        log_error_message "The installation of the most recent version of WSUS Offline Update failed for unknown reasons."
        exit 1
    fi

    return 0
}


# function check_custom_static_links
#
# Custom static download files are usually created by the Windows scripts
# AddCustomLanguageSupport.cmd and AddOffice2010x64Support.cmd. These
# scripts copy download links from the ../static to the ../static/custom
# directory, to enable custom languages and Office 64-bit versions.
#
# Therefore, links in the ../static/custom directory can usually be
# validated by searching for the links in the parent directory ../static.

function check_custom_static_links ()
{
    local -a file_list=()
    local current_file=""
    local static_download_link=""

    log_info_message "Checking links in custom static download files..."
    shopt -s nullglob
    file_list=(../static/custom/*.txt)
    shopt -u nullglob

    if (( "${#file_list[@]}" > 0 ))
    then
        for current_file in "${file_list[@]}"
        do
            cut_dos -d ',' -f 1 "${current_file}" | while read -r static_download_link
            do
                if ! grep -F -i -q "${static_download_link}" ../static/*.txt
                then
                    log_warning_message "The following download link was not found anymore: ${static_download_link} from file ${current_file}"
                fi
            done
        done
    fi
    return 0
}


# function normalize_file_permissions
#
# Ensure, that Linux scripts are executable (excluding libraries, tasks
# and the preferences file, since these files are sourced)

function normalize_file_permissions ()
{
    log_info_message "Normalize file permissions..."
    chmod +x                                                       \
        ./copy-to-target.bash                                      \
        ./create-iso-image.bash                                    \
        ./download-updates.bash                                    \
        ./fix-file-permissions.bash                                \
        ./get-all-updates.bash                                     \
        ./open-support-pages.bash                                  \
        ./rebuild-integrity-database.bash                          \
        ./reset-wsusoffline.bash                                   \
        ./syntax-check.bash                                        \
        ./update-generator.bash                                    \
        ./comparison-linux-windows/compare-integrity-database.bash \
        ./comparison-linux-windows/compare-update-tables.bash

    return 0
}


function reschedule_updates_after_wou_update ()
{
    log_info_message "Reschedule updates..."
    # The function reevaluate_all_updates removes the timestamps for
    # all updates, so that they are reevaluated on the next run.
    reevaluate_all_updates
    rm -f "../timestamps/update-configuration-files.txt"
    # Delete index files for the update of static download definitions
    # (sdd) and other configuration files
    rm -f "../static/sdd/StaticDownloadFiles-modified.txt"
    rm -f "../static/sdd/ExcludeDownloadFiles-modified.txt"
    rm -f "../static/sdd/StaticUpdateFiles-modified.txt"
    # Delete ETag database
    rm -f "../static/SelfUpdateVersion-static.txt"
    # Lists of superseded updates, Windows version
    rm -f "../exclude/ExcludeList-superseded.txt"
    rm -f "../exclude/ExcludeList-superseded-seconly.txt"
    # Lists of superseded updates, Linux version
    rm -f "../exclude/ExcludeList-Linux-superseded.txt"
    rm -f "../exclude/ExcludeList-Linux-superseded-seconly.txt"
    rm -f "../exclude/ExcludeList-Linux-superseded-seconly-revised.txt"

    return 0
}


function restart_script ()
{
    # The scripts update-generator.bash and download-updates.bash create
    # new temporary directories with random names on each run. The
    # existing temporary directory must be removed at this point.
    if [[ -d "${temp_dir}" ]]
    then
        echo "Cleaning up temporary files ..."
        rm -r "${temp_dir}"
    fi

    log_info_message "Restarting script ${script_name} ..."
    echo ""
    echo "--------------------------------------------------------------------------------"
    echo ""
    if (( "${#command_line_parameters[@]}" > 0 ))
    then
        exec "./${script_name}" "${command_line_parameters[@]}"
    else
        exec "./${script_name}"
    fi
    return 0
}

# ========== Commands =====================================================

wsusoffline_initial_installation
compare_wsusoffline_versions
echo ""
return 0
