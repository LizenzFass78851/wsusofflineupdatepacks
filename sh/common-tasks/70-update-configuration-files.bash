# This file will be sourced by the shell bash.
#
# Filename: 70-update-configuration-files.bash
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
#     This script updates the configuration files in the exclude,
#     static, client/exclude and client/static directories. This was
#     formerly known as the "update of static download definitions"
#     (SDD), but it now includes all four directories.
#
#     The update of configuration files can be disabled by setting the
#     variable check_for_self_updates to "disabled".

# ========== Configuration ================================================

# URLs for the "esr-11.9" development branch
excludelist_superseded_exclude_url="https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/ExcludeList-superseded-exclude.txt"
excludelist_superseded_exclude_seconly_url="https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/ExcludeList-superseded-exclude-seconly.txt"
excludelist_url="https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/ExcludeList.txt"
hidelist_seconly_url="https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/HideList-seconly.txt"
static_downloadfiles_modified_url="https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/StaticDownloadFiles-modified.txt"
exclude_downloadfiles_modified_url="https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/ExcludeDownloadFiles-modified.txt"
static_updatefiles_modified_url="https://gitlab.com/wsusoffline/wsusoffline-sdd/-/raw/esr-11.9/StaticUpdateFiles-modified.txt"

# ========== Functions ====================================================

function no_pending_updates ()
{
    local result_code=1

    if [[ -f "../static/SelfUpdateVersion-this.txt" \
       && -f "../static/SelfUpdateVersion-recent.txt" ]]
    then
        if diff "../static/SelfUpdateVersion-this.txt" \
                "../static/SelfUpdateVersion-recent.txt" > /dev/null
        then
            result_code="0"
        fi
    fi
    return "${result_code}"
}

# The configuration files in the directories exclude, static,
# client/exclude and client/static can be updated individually using a
# mechanism known as the update of static download definitions (SDD).
#
# These updates are always relative to the latest available version
# of WSUS Offline Update. Once a new version of WSUS Offline Update is
# available, the updated files are integrated into the zip archive for
# the new version. Then the individual files are no longer available
# for download.
#
# This seems to imply, that the configuration files should only be
# updated, if the latest available version of WSUS Offline Update
# is installed. This script doesn't need to do an online check for
# new versions, because this has already been done by the script
# 50-check-wsusoffline-version.bash; but it does compare the files
# SelfUpdateVersion-this.txt and SelfUpdateVersion-recent.txt again:
#
# - If these files are the same, then the latest version is installed.
# - If they are different, then a new version of WSUS Offline Update is
#   available, and the update of the individual configuration files will
#   be postponed.

function run_update_configuration_files ()
{
    local timestamp_file="${timestamp_dir}/update-configuration-files.txt"
    local -i interval_length="${interval_length_configuration_files}"
    local interval_description="${interval_description_configuration_files}"

    if [[ "${check_for_self_updates}" == "disabled" ]]
    then
        log_info_message "The update of configuration files for WSUS Offline Update is disabled in preferences.bash"
        echo ""
        return 0
    fi

    if same_day "${timestamp_file}" "${interval_length}"
    then
        log_info_message "Skipped update of configuration files for WSUS Offline Update, because it has already been done less than ${interval_description} ago"
        echo ""
        return 0
    fi

    if no_pending_updates
    then
        remove_obsolete_files
        update_configuration_files
    else
        log_warning_message "The update of configuration files was skipped, because the installed version of WSUS Offline Update is not the latest available release."
        # The timestamp can be updated here, to do this check once
        # daily. A successful wsusoffline self-update will delete this
        # timestamp and reschedule the update of configuration files
        # again.
        update_timestamp "${timestamp_file}"
        echo ""
    fi
    return 0
}


function remove_obsolete_files ()
{
    local -a file_list=()
    local current_file=""

    log_info_message "Removing obsolete files from previous versions of WSUS Offline Update..."
    # Only changes since WSUS Offline Update version 9.5.3 are considered.

    # Dummy files are inserted, because zip archives cannot include
    # empty directories. They can be deleted on the first run.
    #
    # These files should be kept in development versions, otherwise they
    # will be marked as missing after every run.
    if [[ -d ./.svn ]]
    then
        log_warning_message "Keeping dummy.txt files in development version..."
    else
        find .. -type f -name dummy.txt -delete
    fi

    # *** Obsolete internal stuff ***
    file_list+=(
        ../cmd/ExtractUniqueFromSorted.vbs
        ../cmd/CheckTRCerts.cmd
        ../client/static/StaticUpdateIds-w100-x86.txt
        ../client/static/StaticUpdateIds-w100-x64.txt
    )

    # Removed in WSUS Offline Update 10.9
    file_list+=( ../client/exclude/ExcludeUpdateFiles-modified.txt )

    # Removed in the Community Editions 11.9.2-ESR and 12.1
    #
    # The index files *-modified.txt for the update of static download
    # definitions (sdd) were moved to ../static/sdd
    file_list+=(
        ../static/StaticDownloadFiles-modified.txt
        ../exclude/ExcludeDownloadFiles-modified.txt
        ../client/static/StaticUpdateFiles-modified.txt
    )

    # Removed in Community Editions 11.9.8-ESR and 12.5
    file_list+=(
        ../static/StaticDownloadLinks-ie8-w60-*.txt
        ../static/StaticDownloadLinks-ie9-w61-*.txt
        ../xslt/ExtractUpdateCategoriesAndFileIds.xsl
        ../xslt/ExtractUpdateCabExeIdsAndLocations.xsl
        ../xslt/ExtractSupersededUpdateRelations.xsl
        ../xslt/ExtractSupersedingRevisionIds.xsl
        ../xslt/ExtractUpdateFileIdsAndLocations.xsl
        ../xslt/ExtractUpdateRevisionAndFileIds.xsl
        ../xslt/ExtractUpdateRevisionIds.xsl
        ../xslt/extract-office-revision-and-update-ids.xsl
        ../xslt/ExtractDownloadLinks-w60-x64-glb.xsl
        ../xslt/ExtractDownloadLinks-w60-x86-glb.xsl
        ../xslt/ExtractDownloadLinks-w61-x64-glb.xsl
        ../xslt/ExtractDownloadLinks-w61-x86-glb.xsl
        ../xslt/ExtractDownloadLinks-w62-x64-glb.xsl
        ../xslt/ExtractDownloadLinks-w63-x64-glb.xsl
        ../xslt/ExtractDownloadLinks-w63-x86-glb.xsl
        ../xslt/ExtractDownloadLinks-w100-x64-glb.xsl
        ../xslt/ExtractDownloadLinks-w100-x86-glb.xsl
    )
    # Delete the directory ../opt with the file ../opt/locales.txt
    if [[ -d ../opt ]]
    then
        rm -r ../opt
    fi

    # *** Obsolete external stuff ***
    file_list+=(
        ../static/StaticDownloadLinks-mkisofs.txt
        ../static/StaticDownloadLink-mkisofs.txt
    )

    # *** Windows Server 2003 stuff ***
    shopt -s nullglob
    file_list+=(
        ../client/static/StaticUpdateIds-w2k3-x64.txt
        ../client/static/StaticUpdateIds-w2k3-x86.txt
        ../exclude/ExcludeList-w2k3-x64.txt
        ../exclude/ExcludeList-w2k3-x86.txt
        ../exclude/ExcludeListISO-w2k3-x64.txt
        ../exclude/ExcludeListISO-w2k3-x86.txt
        ../exclude/ExcludeListUSB-w2k3-x64.txt
        ../exclude/ExcludeListUSB-w2k3-x86.txt
        ../static/StaticDownloadLinks-w2k3-x64-*.txt
        ../static/StaticDownloadLinks-w2k3-x86-*.txt
        ../xslt/ExtractDownloadLinks-w2k3-x64-*.xsl
        ../xslt/ExtractDownloadLinks-w2k3-x86-*.xsl
    )
    shopt -u nullglob

    # *** Windows language specific stuff ***
    #
    # Localized win updates are not used since Windows XP and Server
    # 2003. The only remaining file StaticDownloadLinks-win-x86-glb.txt
    # was renamed to StaticDownloadLinks-win-glb.txt.
    shopt -s nullglob
    file_list+=( ../static/StaticDownloadLinks-win-x86-*.txt )
    shopt -u nullglob

    # *** Windows 8, 32-bit stuff ***
    #
    # Windows Server 2012, 64-bit (w62-x64) is still supported
    file_list+=(
        ../client/static/StaticUpdateIds-w62-x86.txt
        ../exclude/ExcludeList-w62-x86.txt
        ../exclude/ExcludeListISO-w62-x86.txt
        ../exclude/ExcludeListUSB-w62-x86.txt
        ../static/StaticDownloadLinks-w62-x86-glb.txt
        ../xslt/ExtractDownloadLinks-w62-x86-glb.xsl
    )

    # *** Windows 10 Version 1511 stuff ***
    file_list+=(
        ../client/static/StaticUpdateIds-w100-10586-x86.txt
        ../client/static/StaticUpdateIds-w100-10586-x64.txt
    )

    # *** Windows 10 Version 1703 stuff ***
    #
    # Removed in WSUS Offline Update 12.0 and in the Community Edition
    # 11.9.2-ESR
    file_list+=(
        ../client/static/StaticUpdateIds-w100-15063-dotnet.txt
        ../client/static/StaticUpdateIds-w100-15063-dotnet4-528049.txt
        ../client/static/StaticUpdateIds-w100-15063-x64.txt
        ../client/static/StaticUpdateIds-w100-15063-x86.txt
        ../client/static/StaticUpdateIds-wupre-w100-15063.txt
    )

    # *** Windows 10 Version 1709 stuff ***
    #
    # Removed in the Community Editions 11.9.7-ESR and 12.4
    file_list+=(
        ../client/static/StaticUpdateIds-w100-16299.txt
        ../client/static/StaticUpdateIds-w100-16299-x64.txt
        ../client/static/StaticUpdateIds-w100-16299-x86.txt
        ../client/static/StaticUpdateIds-wupre-w100-16299.txt
        ../client/static/StaticUpdateIds-servicing-w100-16299.txt
        ../client/static/StaticUpdateIds-w100-16299-dotnet.txt
        ../client/static/StaticUpdateIds-w100-16299-dotnet4-528049.txt
    )

    # *** Windows 10 Version 1803 stuff ***
    #
    # Removed in the Community Editions 11.9.8-ESR and 12.5
    file_list+=(
        ../client/static/StaticUpdateIds-w100-17134.txt
        ../client/static/StaticUpdateIds-w100-17134-x64.txt
        ../client/static/StaticUpdateIds-w100-17134-x86.txt
        ../client/static/StaticUpdateIds-wupre-w100-17134.txt
        ../client/static/StaticUpdateIds-servicing-w100-17134.txt
        ../client/static/StaticUpdateIds-w100-17134-dotnet.txt
        ../client/static/StaticUpdateIds-w100-17134-dotnet4-528049.txt
    )

    # *** Office stuff ***
    #
    # Removed in Community Edition 11.9.8-ESR and 12.5
    shopt -s nullglob
    file_list+=(
        ../static/StaticDownloadLinks-ofc-*.txt
    )
    shopt -u nullglob

    # *** Office 2003 stuff ***
    shopt -s nullglob
    file_list+=(
        ../client/static/StaticUpdateIds-o2k3.txt
        ../static/StaticDownloadLinks-o2k3-*.txt
    )
    shopt -u nullglob

    # *** Office 2007 stuff ***
    #
    # Removed in WSUS Offline Update 11.1
    shopt -s nullglob
    file_list+=(
        ../client/static/StaticUpdateIds-o2k7.txt
        ../static/StaticDownloadLinks-o2k7-*.txt
    )
    shopt -u nullglob

    # *** Office 2010 stuff ***
    #
    # Removed in the Community Editions 11.9.7-ESR and 12.4
    shopt -s nullglob
    file_list+=(
        ../static/StaticDownloadLinks-o2k10-*.txt
        ../client/static/StaticUpdateIds-o2k10.txt
    )
    shopt -u nullglob

    # *** .NET restructuring stuff ***
    #
    # Removed in Community Editions 11.9.8-ESR and 12.3. The XSLT files
    # are in the section "obsolete internal stuff" in the Windows script
    # DownloadUpdates.cmd.
    shopt -s nullglob
    file_list+=(
        ../exclude/ExcludeList-dotnet-x86.txt
        ../exclude/ExcludeList-dotnet-x64.txt
        ../static/StaticDownloadLinks-dotnet-x86-*.txt
        ../static/StaticDownloadLinks-dotnet-x64-*.txt
        ../xslt/ExtractDownloadLinks-dotnet-x86-glb.xsl
        ../xslt/ExtractDownloadLinks-dotnet-x64-glb.xsl
    )
    shopt -u nullglob

    # *** IE restructuring stuff ***
    #
    # The file ../client/static/StaticUpdateIds-ie10-w61.txt was
    # renamed to StaticUpdateIds-ie11-w61.txt in the Community Edition
    # 11.9.5-ESR. The old file will be removed.
    file_list+=( ../client/static/StaticUpdateIds-ie10-w61.txt )

    # *** Microsoft Security Essentials stuff ***
    #
    # The file hashes-msse.txt was replaced with two separate files
    # for the subdirectories x86-glb and x64-glb in Community Edition
    # 11.9.8-ESR
    file_list+=( ../client/md/hashes-msse.txt )

    # *** Old Windows Defender stuff ***
    #
    # The file hashes-wddefs.txt was replaced with two separate files
    # for the subdirectories x86-glb and x64-glb in Community Editions
    # 11.9.8-ESR and 12.5
    file_list+=( ../client/md/hashes-wddefs.txt )

    # *** Windows Essentials 2012 stuff ***
    #
    # Also known as Windows Live Essentials (wle)
    shopt -s nullglob
    file_list+=(
        ../static/StaticDownloadLinks-wle-*.txt
        ../static/custom/StaticDownloadLinks-wle-*.txt
        ../exclude/ExcludeList-wle.txt
        ../client/md/hashes-wle.txt
    )
    shopt -u nullglob

    # *** Old self update stuff ***
    #
    # The file StaticDownloadLink-this.txt was replaced with
    # SelfUpdateVersion-this.txt in the Community Editions 11.9.1-ESR
    # and 12.0
    file_list+=( ../static/StaticDownloadLink-this.txt )

    # Print the resulting file list:
    #log_debug_message "Obsolete files:" "${file_list[@]}"

    # Delete all obsolete files, if existing
    if (( "${#file_list[@]}" > 0 ))
    then
        for current_file in "${file_list[@]}"
        do
            if [[ -f "${current_file}" ]]
            then
                log_debug_message "Deleting ${current_file}"
                rm "${current_file}"
            fi
        done
    fi

    # *** Warn if unsupported updates are found ***
    if [[ -d ../client/wxp || -d ../client/wxp-x64 ]]
    then
        log_warning_message "Windows XP is no longer supported."
    fi
    if [[ -d ../client/w2k3 || -d ../client/w2k3-x64 ]]
    then
        log_warning_message "Windows Server 2003 is no longer supported."
    fi
    if [[ -d ../client/w62 ]]
    then
        log_warning_message "Windows 8, 32-bit (w62) is no longer supported."
    fi
    if [[ -d ../client/o2k3 ]]
    then
        log_warning_message "Office 2003 is no longer supported."
    fi
    # Office 2007 was removed in WSUS Offline Update 11.1
    if [[ -d ../client/o2k7 ]]
    then
        log_warning_message "Office 2007 is no longer supported."
    fi
    # Office 2010 was removed in Community Editions 11.9.7-ESR and 12.4
    if [[ -d ../client/o2k10 ]]
    then
        log_warning_message "Office 2010 is no longer supported."
    fi
    # Community Editions 11.9.8-ESR and 12.5 removed the download
    # directory ../client/ofc for dynamic Office updates. Dynamic updates
    # are now downloaded to ../client/o2k13 and ../client/o2k16.
    if [[ -d ../client/ofc ]]
    then
        log_warning_message "The download directory ../client/ofc for dynamic Office updates is no longer used in Community Editions 11.9.8-ESR and 12.5. You may delete it manually."
    fi
    # Community Editions 11.9.8-ESR and 12.3 removed the subdirectories
    # for dynamic .NET Framework updates
    if [[ -d ../client/dotnet/x86-glb || -d ../client/dotnet/x64-glb ]]
    then
        log_warning_message "The directories ../client/dotnet/x86-glb and ../client/dotnet/x64-glb for dynamic .NET Framework updates are no longer used in Community Editions 11.9.8-ESR and 12.3. You may delete them manually, but do NOT delete the parent directory ../client/dotnet, which is still needed for the static .NET Framework installation files."
    fi
    if [[ -d ../client/wle ]]
    then
        log_warning_message "Windows Live Essentials are no longer supported."
    fi

    log_info_message "Removed obsolete files from previous versions."
    echo ""
    return 0
}


function update_configuration_files ()
{
    local timestamp_file="${timestamp_dir}/update-configuration-files.txt"
    local -i initial_errors="0"
    initial_errors="$(get_error_count)"

    log_info_message "Updating configuration files for the current version of WSUS Offline Update..."
    # Testing the files ExcludeList-superseded-exclude.txt and
    # ExcludeList-superseded-exclude-seconly.txt separately seems
    # to be redundant, because they could just be added to the file
    # ExcludeDownloadFiles-modified.txt.
    #
    # The Windows script DownloadUpdates.cmd does this, because the files
    # ExcludeList-superseded.txt and ExcludeList-superseded-seconly.txt
    # need to be recalculated, if these configuration files change.
    download_from_gitlab "../exclude" "${excludelist_superseded_exclude_url}"
    download_from_gitlab "../exclude" "${excludelist_superseded_exclude_seconly_url}"
    download_from_gitlab "../client/exclude" "${excludelist_url}"

    # The file ../client/exclude/HideList-seconly.txt was introduced
    # in WSUS Offline Update version 10.9. It replaces the former file
    # ../client/exclude/ExcludeUpdateFiles-modified.txt.
    download_from_gitlab "../client/exclude" "${hidelist_seconly_url}"
    echo ""

    log_info_message "Checking directory wsusoffline/static ..."
    recursive_download "../static" "${static_downloadfiles_modified_url}"
    echo ""

    log_info_message "Checking directory wsusoffline/exclude ..."
    recursive_download "../exclude" "${exclude_downloadfiles_modified_url}"
    echo ""

    log_info_message "Checking directory wsusoffline/client/static ..."
    recursive_download "../client/static" "${static_updatefiles_modified_url}"
    #echo ""

    if same_error_count "${initial_errors}"
    then
        log_info_message "Updated configuration files for WSUS Offline Update."
        update_timestamp "${timestamp_file}"
    else
        log_warning_message "The update of configuration files failed. See the download log for possible error messages."
    fi
    echo ""
    return 0
}


# Function recursive_download
#
# The function recursive_download is used for the configuration files
# StaticDownloadFiles-modified.txt, ExcludeDownloadFiles-modified.txt
# and StaticUpdateFiles-modified.txt. These files don't exist on the
# first download run.
#
# They contain download links for configuration files, which have been
# modified since the last release of WSUS Offline Update.
#
# Directly after a version update of WSUS Offline Update, these index
# files are usually empty.
#
# If they are not empty, then the contained URLs will be recursively
# downloaded.
#
# In earlier versions of WSUS Offline Update, this recursive download
# was only used for the static directory. Therefore, this step is still
# known as the "update of static download definitions (SDD)".
function recursive_download ()
{
    local download_dir="$1"
    local download_link="$2"
    local filename="${download_link##*/}"
    local -i number_of_links="0"
    local url=""
    local -i initial_errors="0"
    initial_errors="$(get_error_count)"

    log_info_message "Downloading/validating index file ${filename} ..."
    # Since version 1.19.2-CE and 2.1-CE of the Linux download scripts,
    # the three index files are downloaded to ../static/sdd, only the
    # included links are downloaded to the specified download directories
    # ../static, ../exclude and ../client/static.
    download_from_gitlab "../static/sdd" "${download_link}"
    if same_error_count "${initial_errors}"
    then
        log_debug_message "Downloaded/validated index file ${filename}"
    else
        log_warning_message "The download of index file ${filename} failed"
        return 0
    fi

    # After installing a new release of WSUS Offline
    # Update, the index files StaticDownloadFiles-modified.txt,
    # ExcludeDownloadFiles-modified.txt and StaticUpdateFiles-modified.txt
    # are usually empty.
    if [[ -s "../static/sdd/${filename}" ]]
    then
        number_of_links="$( wc -l < "../static/sdd/${filename}" )"
        log_info_message "Downloading/validating ${number_of_links} link(s) from index file ${filename} ..."

        while IFS=$'\r\n' read -r url
        do
            download_from_gitlab "${download_dir}" "${url}"
        done < "../static/sdd/${filename}"

        if same_error_count "${initial_errors}"
        then
            log_info_message "Downloaded/validated ${number_of_links} link(s) from index file ${filename}"
        else
            log_warning_message "Some downloads from index file ${filename} failed -- see the download log for details"
        fi
    fi

    return 0
}

# ========== Commands =====================================================

run_update_configuration_files
# Update the file ../static/SelfUpdateVersion-static.txt
restore_etag_database
return 0
